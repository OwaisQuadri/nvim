return function(check)
local function drive_rename(opts)
  opts = opts or {}
  local root = vim.fn.tempname()
  vim.fn.mkdir(root, 'p')
  local a, b = vim.fs.joinpath(root, 'a.txt'), vim.fs.joinpath(root, 'b.txt')
  vim.fn.writefile({ 'local target = 1' }, a)
  vim.fn.writefile({ 'print(target)' }, b)
  local uri_a, uri_b = vim.uri_from_fname(a), vim.uri_from_fname(b)
  local function edits()
    return { { range = { start = { line = 0, character = 6 }, ['end'] = { line = 0, character = 12 } }, newText = 'renamed' } }
  end
  local workspace_edit
  if opts.shape == 'documentChanges' or opts.extra_changes then
    local changes = {}
    for _, extra in ipairs(opts.extra_changes or {}) do changes[#changes + 1] = extra end
    changes[#changes + 1] = { textDocument = { uri = uri_a, version = 0 }, edits = edits() }
    changes[#changes + 1] = { textDocument = { uri = uri_b, version = 0 }, edits = opts.no_edit_for_b and {} or edits() }
    workspace_edit = { documentChanges = changes }
  else
    workspace_edit = { changes = { [uri_a] = edits(), [uri_b] = opts.no_edit_for_b and {} or edits() } }
  end

  local server = function()
    local closing = false
    return {
      request = function(method, _, callback)
        if method == 'initialize' then
          callback(nil, { capabilities = { renameProvider = true } })
        elseif method == 'textDocument/rename' then
          callback(nil, workspace_edit)
        else
          callback(nil, nil)
        end
        return true, 1
      end,
      notify = function() return true end,
      is_closing = function() return closing end,
      terminate = function() closing = true end,
    }
  end
  pcall(vim.cmd, 'only')
  vim.cmd.edit(a)
  local buf = vim.api.nvim_get_current_buf()
  local client_id = assert(vim.lsp.start({ name = 'rename_fixture', cmd = server, root_dir = root }, { bufnr = buf }), 'fake client did not start')
  assert(vim.wait(5000, function() return #vim.lsp.get_clients { bufnr = buf, name = 'rename_fixture' } > 0 end, 20), 'fake client never attached')
  local notes = {}
  local notify = vim.notify
  vim.notify = function(msg, level, ...)
    notes[#notes + 1] = { msg = tostring(msg), level = level }
    return notify(msg, level, ...)
  end
  local function restore()
    vim.notify = notify
  end

  local function disk(path) return table.concat(vim.fn.readfile(path), '\n') end
  local eventignore_before, error_before = vim.o.eventignore, vim.v.errmsg
  local immediate, messages
  local ok, err = pcall(function()
    if opts.prepare then opts.prepare { root = root, a = a, b = b, uri_b = uri_b, buf_a = buf } end
    vim.api.nvim_win_set_buf(0, buf)
    vim.api.nvim_win_set_cursor(0, { 1, 6 })
    vim.cmd 'messages clear'
    vim.lsp.buf.rename('renamed', { bufnr = buf, name = 'rename_fixture' })
    immediate = disk(a)
    vim.wait(5000, function() return disk(a) ~= 'local target = 1' end, 20)
    messages = vim.api.nvim_exec2('messages', { output = true }).output
  end)
  restore()
  vim.v.errmsg = error_before
  vim.lsp.stop_client(client_id)
  if not ok then error(err, 0) end
  assert(vim.o.eventignore == eventignore_before, 'eventignore was left as ' .. vim.inspect(vim.o.eventignore))

  local warnings = 0
  for _, note in ipairs(notes) do
    if note.msg:find('b.txt', 1, true) then warnings = warnings + 1 end
  end
  return {
    a = disk(a),
    b = disk(b),
    path_a = a,
    path_b = b,
    warnings = warnings,
    notes = notes,
    messages = messages,
    immediate = immediate,
    buf_a = buf,
    buf_b = vim.uri_to_bufnr(uri_b),
  }
end
check('lsp.rename_writes_every_file_it_touched', function()
  for _, shape in ipairs { 'changes', 'documentChanges' } do
    local out = drive_rename { shape = shape }
    assert(out.a == 'local renamed = 1', shape .. ': the renamed file never reached disk')
    assert(out.b == 'print(renamed)', shape .. ': the OTHER renamed file never reached disk')
    assert(out.warnings == 0, shape .. ': warned about a file it wrote fine')
    assert(out.immediate == 'local renamed = 1', shape .. ': the write was deferred out of the handler, not done in it')
    assert(not out.messages:find(' written', 1, true), shape .. ': the write announced itself: ' .. vim.inspect(out.messages))
  end
  return true
end)
check('lsp.rename_leaves_your_unsaved_work_alone', function()
  for _, shape in ipairs { 'changes', 'documentChanges' } do
    local out = drive_rename {
      shape = shape,
      prepare = function(paths)
        local buf = vim.fn.bufadd(paths.b)
        vim.fn.bufload(buf)
        vim.api.nvim_buf_set_lines(buf, 1, -1, false, { 'half-typed junk' })
      end,
    }
    assert(out.a == 'local renamed = 1', shape .. ': the renamed file never reached disk')
    assert(out.b == 'print(target)', shape .. ': wrote a buffer the user had unsaved edits in: ' .. vim.inspect(out.b))
    assert(vim.bo[out.buf_b].modified, shape .. ': left the unsaved buffer looking saved')
    local lines = vim.api.nvim_buf_get_lines(out.buf_b, 0, -1, false)
    assert(lines[1] == 'print(renamed)' and lines[2] == 'half-typed junk', shape .. ': the in-buffer rename was lost: ' .. vim.inspect(lines))
  end
  return true
end)
check('lsp.rename_leaves_the_current_buffer_unsaved_work_alone', function()
  local out = drive_rename {
    shape = 'documentChanges',
    prepare = function(paths)
      vim.api.nvim_buf_set_lines(paths.buf_a, 1, -1, false, { 'half-typed junk' })
    end,
  }
  assert(out.a == 'local target = 1', 'the writeback wrote the buffer you were mid-edit in: ' .. vim.inspect(out.a))
  assert(vim.bo[out.buf_a].modified, 'left the current buffer looking saved')
  assert(out.b == 'print(renamed)', 'the OTHER file should still have been written')
  return true
end)
check('lsp.rename_reports_a_file_it_could_not_write', function()
  local out = drive_rename {
    prepare = function(paths) vim.fn.setfperm(paths.b, 'r--r--r--') end,
  }
  assert(out.a == 'local renamed = 1', 'the writable file never reached disk')
  assert(out.b == 'print(target)', 'a readonly file changed, so this fixture proves nothing')
  assert(out.warnings == 1, 'expected exactly one warning naming the unwritable file, got ' .. out.warnings)
  local warning = out.notes[#out.notes]
  assert(warning.level == vim.log.levels.WARN, 'a file that did not get written was reported below WARN: ' .. tostring(warning.level))
  assert(warning.msg:find(out.path_b, 1, true), 'the report does not name the file by path: ' .. warning.msg)
  assert(not warning.msg:find('file://', 1, true), 'the report shows a raw URI instead of a path: ' .. warning.msg)
  return true
end)
check('lsp.rename_ignores_a_buffer_that_is_not_a_file', function()
  local out = drive_rename {
    prepare = function(paths)
      local buf = vim.fn.bufadd(paths.b)
      vim.fn.bufload(buf)
      vim.bo[buf].buftype = 'nofile'
    end,
  }
  assert(out.a == 'local renamed = 1', 'the real file never reached disk')
  assert(out.warnings == 0, 'warned about a buffer that was never writable, got ' .. out.warnings)
  assert(out.b == 'print(target)', 'wrote a buffer that is not a file')
  return true
end)
check('lsp.rename_survives_a_server_that_cannot_rename', function()
  local notes = {}
  local notify = vim.notify
  vim.notify = function(msg, level) notes[#notes + 1] = { msg = tostring(msg), level = level } end
  local ok, err = pcall(vim.lsp.handlers['textDocument/rename'], nil, nil, { client_id = 1, bufnr = 0, method = 'textDocument/rename' })
  vim.notify = notify
  assert(ok, 'a null rename result crashed the handler: ' .. tostring(err))
  assert(#notes == 1, ('a null result produced %d messages, not the one that says why nothing happened'):format(#notes))
  assert(notes[1].msg:lower():find('rename', 1, true), 'the message never mentions the rename: ' .. notes[1].msg)
  return true
end)
check('lsp.rename_leaves_a_named_but_unchanged_file_alone', function()
  local backdated = os.time() - 3600
  local out = drive_rename {
    no_edit_for_b = true,
    prepare = function(paths)
      assert(vim.uv.fs_utime(paths.b, backdated, backdated), 'could not backdate the fixture')
      vim.fn.bufload(vim.fn.bufadd(paths.b))
    end,
  }
  assert(out.a == 'local renamed = 1', 'the renamed file never reached disk')
  assert(out.b == 'print(target)', 'changed a file the edit never touched')
  local mtime = vim.uv.fs_stat(out.path_b).mtime.sec
  assert(mtime == backdated, ('rewrote a file the edit never changed (mtime moved %d seconds)'):format(mtime - backdated))
  return true
end)
check('lsp.rename_hands_an_acwrite_buffer_to_its_own_writer', function()
  local fired = 0
  local out = drive_rename {
    prepare = function(paths)
      local buf = vim.fn.bufadd(paths.b)
      vim.fn.bufload(buf)
      vim.bo[buf].buftype = 'acwrite'
      vim.api.nvim_create_autocmd('BufWriteCmd', {
        buffer = buf,
        callback = function()
          fired = fired + 1
          vim.fn.writefile(vim.api.nvim_buf_get_lines(buf, 0, -1, false), paths.b)
        end,
      })
    end,
  }
  assert(fired == 1, ('the plugin writer ran %d times, not once'):format(fired))
  assert(out.b == 'print(renamed)', 'the plugin writer ran but the rename is not on disk: ' .. vim.inspect(out.b))
  assert(out.warnings == 0, 'reported a failure for a file its owner wrote successfully')
  return true
end)
check('lsp.rename_writeback_keeps_a_later_wrapper_in_the_chain', function()
  local seen = 0
  local before = vim.lsp.handlers['textDocument/rename']
  local ok, out = pcall(drive_rename, {
    prepare = function()
      local inner = vim.lsp.handlers['textDocument/rename']
      vim.lsp.handlers['textDocument/rename'] = function(...)
        seen = seen + 1
        return inner(...)
      end
      local client = vim.lsp.get_clients { name = 'rename_fixture' }[1]
      vim.api.nvim_exec_autocmds('LspAttach', { buffer = 0, data = { client_id = client.id } })
    end,
  })
  vim.lsp.handlers['textDocument/rename'] = before
  assert(ok, out)
  assert(seen == 1, ('a wrapper installed after us was dropped from the chain (ran %d times)'):format(seen))
  assert(out.a == 'local renamed = 1' and out.b == 'print(renamed)', 'the writeback stopped writing while sharing the chain')
  return true
end)
check('lsp.rename_handles_an_edit_that_also_creates_a_file', function()
  local created = vim.fn.tempname() .. '.txt'
  local out = drive_rename { extra_changes = { { kind = 'create', uri = vim.uri_from_fname(created) } } }
  assert(out.a == 'local renamed = 1' and out.b == 'print(renamed)', 'a file op stopped the ordinary edits from being written')
  assert(vim.fn.filereadable(created) == 1, 'the create op never happened, so this fixture proves nothing')
  assert(out.warnings == 0, 'warned about a file it wrote fine')
  return true
end)
check('lsp.resource_rename_does_not_save_dirty_buffers', function()
  local root = vim.fn.tempname()
  vim.fn.mkdir(root, 'p')
  root = assert(vim.uv.fs_realpath(root))
  local old, new = root .. '/Old.txt', root .. '/New.txt'
  vim.fn.writefile({ 'local target = 1' }, old)
  vim.cmd.edit(old)
  local buf = vim.api.nvim_get_current_buf()
  vim.api.nvim_buf_set_lines(buf, 1, -1, false, { 'unsaved work' })
  local notices, notify = {}, vim.notify
  vim.notify = function(message, level) notices[#notices + 1] = { message, level } end
  local is_ok, err = pcall(vim.lsp.handlers['textDocument/rename'], nil, {
    documentChanges = {
      { kind = 'rename', oldUri = vim.uri_from_fname(old), newUri = vim.uri_from_fname(new) },
      { textDocument = { uri = vim.uri_from_fname(new), version = 0 }, edits = {
        { range = { start = { line = 0, character = 6 }, ['end'] = { line = 0, character = 12 } }, newText = 'renamed' },
      } },
    },
  }, { bufnr = buf })
  vim.notify = notify
  assert(is_ok, err)
  assert(vim.fn.readfile(old)[1] == 'local target = 1', 'Resource rename wrote unsaved work')
  assert(vim.fn.filereadable(new) == 0, 'Resource rename was partially applied')
  assert(vim.api.nvim_buf_get_name(buf) == old and vim.bo[buf].modified, 'Dirty buffer was renamed or marked saved')
  assert(vim.api.nvim_buf_get_lines(buf, 0, -1, false)[2] == 'unsaved work')
  assert(#notices == 1 and notices[1][2] == vim.log.levels.WARN, 'Blocked rename was not explained')
  vim.api.nvim_buf_delete(buf, { force = true })
end)
check('lsp.rename_reports_a_uri_it_cannot_write', function()
  local uri = 'jdt://contents/fixture/Fixture.class'
  local out = drive_rename {
    extra_changes = { { textDocument = { uri = uri, version = 0 }, edits = { { range = { start = { line = 0, character = 0 }, ['end'] = { line = 0, character = 0 } }, newText = 'x' } } } },
  }
  assert(out.a == 'local renamed = 1', 'an unwritable URI stopped the real files from being written')
  assert(out.b == 'print(renamed)', 'an unwritable URI stopped the OTHER real file from being written')
  local reported = 0
  for _, note in ipairs(out.notes) do
    if note.msg:find('jdt://', 1, true) then reported = reported + 1 end
  end
  assert(reported == 1, 'expected exactly one report naming the unwritable URI, got ' .. reported)
  return true
end)

end
