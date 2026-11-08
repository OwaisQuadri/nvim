local failures = 0
local async_errors = {}
local schedule, notify = vim.schedule, vim.notify
vim.schedule = function(callback)
  return schedule(function()
    local is_ok, err = xpcall(callback, debug.traceback)
    if not is_ok then
      async_errors[#async_errors + 1] = err
      notify(err, vim.log.levels.ERROR)
    end
  end)
end
vim.notify = function(message, level, ...)
  if level == vim.log.levels.ERROR then async_errors[#async_errors + 1] = tostring(message) end
  return notify(message, level, ...)
end
local function check(name, callback)
  local ok, err = pcall(function() assert(callback() ~= false, 'Check returned false') end)
  print(vim.json.encode { check = name, ok = ok, detail = not ok and tostring(err) or nil })
  if not ok then failures = failures + 1 end
end

local function mapped(key, mode)
  return vim.fn.maparg(key, mode or 'n', false, true)
end

local function scratch(lines, filetype)
  local buf = vim.api.nvim_create_buf(false, true)
  vim.api.nvim_set_current_buf(buf)
  vim.api.nvim_buf_set_lines(buf, 0, -1, false, lines)
  vim.bo[buf].filetype = filetype or ''
  return buf
end

check('config.loads_without_errors', function()
  assert(vim.v.errmsg == '', vim.v.errmsg)
end)

check('config.reload_preserves_persistent_handlers', function()
  assert(vim.env.MYVIMRC and vim.fn.filereadable(vim.env.MYVIMRC) == 1, 'No loaded configuration path')
  local function settle()
    local ready = false
    vim.defer_fn(function() ready = true end, 0)
    assert(vim.wait(5000, function() return ready and vim.fn.exists '#Todo#ColorScheme' == 1 end, 10), 'Deferred plugin setup did not finish')
  end
  local function counts()
    local result = {}
    for _, event in ipairs { 'FileType', 'LspAttach', 'InsertLeave', 'ColorScheme', 'PackChanged', 'VimEnter' } do
      for _, handler in ipairs(vim.api.nvim_get_autocmds { event = event }) do
        if not (event == 'VimEnter' and handler.once) then
          local key = event .. ':' .. (handler.group_name or '(ungrouped)')
          result[key] = (result[key] or 0) + 1
        end
      end
    end
    return result
  end
  settle()
  local before = counts()
  dofile(vim.env.MYVIMRC)
  settle()
  local after = counts()
  assert(vim.deep_equal(before, after), 'Handler counts by event/group changed: ' .. vim.inspect { before = before, after = after })
end)

check('config.retained_plugins', function()
  for _, module in ipairs {
    'mini.ai', 'mini.surround', 'mini.pairs', 'mini.statusline',
    'telescope', 'harpoon', 'neo-tree', 'gitsigns', 'blink.cmp',
    'render-markdown', 'treesitter-context', 'flutter-tools',
  } do
    assert(package.loaded[module], module .. ' was not configured')
  end
end)

check('config.removed_plugins', function()
  assert(not package.loaded.hardtime, 'Hardtime still loads')
  assert(not package.loaded.dap, 'Debugger still loads')
  assert(vim.fn.exists ':Hardtime' == 0, 'Hardtime command still exists')
end)

check('keys.retained_custom_shortcuts', function()
  for _, key in ipairs {
    '<C-z>', '<C-S-z>', '<C-s>', '<C-[>', '<C-]>',
    '<C-h>', '<C-j>', '<C-k>', '<C-l>', '<C-e>', '<leader>a',
    '<leader>sf', '<leader>sg', '<leader>sp', '<C-.>', 'yd', 'yD',
    '<leader>q', '<leader>u', '<leader>tm', '<leader>tc', '<leader>`',
    '[d', ']d', '<C-r>', '<C-b>', '<C-S-r>',
  } do
    assert(next(mapped(key)), key .. ' is missing')
  end
  if vim.fn.has 'macunix' == 1 then
    for _, key in ipairs { '<leader>xt', '<leader>xT', '<leader>xe', '<leader>xl', '<leader>xc', '<leader>xC', '<leader>xf' } do
      assert(next(mapped(key)), key .. ' is missing')
    end
  end
end)

check('keys.removed_custom_aliases', function()
  for _, key in ipairs {
    '<leader>ca', '<leader>co', '<leader>cm', '<leader>cf', '<leader>th',
    '<leader>sw', '<leader>sh', '<leader>sk', '<leader>ss', '<leader>sd',
    '<leader>sr', '<leader>s.', '<leader>sc', '<leader>s/', '<leader>sn',
    '<leader><leader>', '<leader>tH', '<leader>xa', '<leader>xL',
    '<leader>mr', '<leader>mb', '<leader>mR', '<leader>ms', '<leader>m?',
    '<leader>db', '<leader>dc', 'gD', '<C-p>',
  } do
    assert(not next(mapped(key)), key .. ' still has a custom mapping')
  end
end)

check('keys.paragraph_motions_and_surround', function()
  for _, key in ipairs { '(', ')', '[', ']', '{', '}', '"', "'", '`' } do
    assert(not next(mapped(key, 'x')), key .. ' still overrides visual editing')
  end
  local buf = scratch { 'one', '', 'two', '', 'three' }
  vim.api.nvim_win_set_cursor(0, { 3, 0 })
  vim.api.nvim_feedkeys(vim.keycode('v{<Esc>'), 'x', false)
  assert(vim.api.nvim_win_get_cursor(0)[1] == 2, '{ did not move to the previous paragraph')
  assert(table.concat(vim.api.nvim_buf_get_lines(buf, 0, -1, false), '\n') == 'one\n\ntwo\n\nthree', '{ changed text')
  vim.api.nvim_win_set_cursor(0, { 3, 0 })
  vim.api.nvim_feedkeys(vim.keycode('v}<Esc>'), 'x', false)
  assert(vim.api.nvim_win_get_cursor(0)[1] == 4, '} did not move to the next paragraph')
  scratch { 'hello' }
  vim.api.nvim_feedkeys(vim.keycode('saiw"'), 'x', false)
  assert(vim.api.nvim_get_current_line() == '"hello"', 'sa did not surround the word')
  vim.api.nvim_feedkeys(vim.keycode('sd"'), 'x', false)
  assert(vim.api.nvim_get_current_line() == 'hello', 'sd did not remove quotes')
  vim.api.nvim_feedkeys(vim.keycode('saiw"sr"\''), 'x', false)
  assert(vim.api.nvim_get_current_line() == "'hello'", 'sr did not replace quotes')
end)

check('search.clipboard_is_literal', function()
  local builtin = require 'telescope.builtin'
  local original, register = builtin.grep_string, vim.fn.getreginfo '+'
  local received
  builtin.grep_string = function(opts) received = opts end
  local ok, err = pcall(function()
    vim.fn.setreg('+', 'a.b[0]')
    mapped('<leader>sp').callback()
    assert(received and received.search == 'a.b[0]', 'Clipboard contents were not passed to search')
    assert(received.use_regex == false, 'Clipboard search is not literal')
  end)
  builtin.grep_string = original
  vim.fn.setreg('+', register)
  assert(ok, err)
end)

check('formatting.lua_uses_stylua', function()
  scratch({ 'local x={a=1}' }, 'lua')
  assert(require('conform').format { async = false, lsp_format = 'never' }, 'Formatting failed')
  assert(vim.api.nvim_get_current_line() == 'local x = { a = 1 }', 'StyLua did not format the buffer')
end)

check('saving.is_explicit', function()
  local root = vim.fn.tempname()
  vim.fn.mkdir(root, 'p')
  local path = root .. '/notes.txt'
  vim.fn.writefile({ 'saved' }, path)
  vim.cmd.edit(path)
  vim.api.nvim_set_current_line('unsaved')
  for _, event in ipairs { 'InsertLeave', 'FocusLost', 'BufLeave' } do
    vim.api.nvim_exec_autocmds(event, { buffer = 0 })
  end
  assert(vim.fn.readfile(path)[1] == 'saved', 'An event saved the buffer')
  vim.api.nvim_feedkeys(vim.keycode('<C-s>'), 'x', false)
  assert(vim.fn.readfile(path)[1] == 'unsaved', 'Save-all did not write the buffer')
  vim.cmd 'bwipeout!'
  vim.fn.delete(root, 'rf')
end)

check('actions.swift_range_is_diagnostic_anchored', function()
  local buf = scratch({ '    unresolved()' }, 'swift')
  local ns = vim.api.nvim_create_namespace 'config-test-swift'
  vim.diagnostic.set(ns, buf, { { lnum = 0, col = 4, end_lnum = 0, end_col = 14, message = 'Unknown name' } })
  local helper = require 'config.code_action_range'
  local range = helper.get(buf, 1)
  assert(range.start[2] == 4 and range['end'][2] == 4, 'Swift action is not anchored to its diagnostic')
  local params = helper.to_protocol(range, buf, 'utf-16')
  assert(params.start.line == 0 and params.start.character == 4, 'Swift protocol range is wrong')
  vim.diagnostic.reset(ns, buf)
end)

check('actions.other_languages_use_the_whole_line', function()
  local buf = scratch({ '  const x = bad();' }, 'typescript')
  local range = require('config.code_action_range').get(buf, 1)
  assert(range.start[2] == 0 and range['end'][2] == 18, 'The full line was not selected')
end)

check('project.shortcuts_dispatch_the_right_action', function()
  local project = require 'config.project'
  local original, seen = project.run, {}
  project.run = function(action) seen[#seen + 1] = action end
  local ok, err = pcall(function()
    mapped('<C-r>').callback()
    mapped('<C-b>').callback()
    mapped('<C-S-r>').callback()
    assert(vim.deep_equal(seen, { 'run', 'build', 'existing' }), vim.inspect(seen))
  end)
  project.run = original
  assert(ok, err)
end)

check('project.commands_use_argv_and_project_root', function()
  local project = require 'config.project'
  local root = vim.fn.tempname()
  vim.fn.mkdir(root .. '/src', 'p')
  root = assert(vim.uv.fs_realpath(root))
  vim.fn.writefile({ '[package]', 'name = "fixture"', 'version = "0.1.0"' }, root .. '/Cargo.toml')
  local file = root .. '/src/source.txt'
  vim.fn.writefile({ 'fixture' }, file)
  vim.cmd.edit(file)
  local original_jobstart, original_input = vim.fn.jobstart, vim.ui.input
  local calls = {}
  vim.fn.jobstart = function(argv, opts)
    calls[#calls + 1] = { argv = argv, cwd = opts.cwd, term = opts.term }
    return 1
  end
  vim.ui.input = function(_, callback) callback(root .. '/existing') end
  local ok, err = pcall(function()
    for _, action in ipairs { 'build', 'run', 'existing' } do
      vim.cmd.edit(file)
      project.run(action)
    end
    assert(vim.deep_equal(calls[1].argv, { 'cargo', 'build' }), vim.inspect(calls))
    assert(vim.deep_equal(calls[2].argv, { 'cargo', 'run' }), vim.inspect(calls))
    assert(vim.deep_equal(calls[3].argv, { root .. '/existing' }), 'Existing-build action invoked a build')
    for _, call in ipairs(calls) do assert(call.cwd == root and call.term, 'Wrong terminal working directory') end
  end)
  vim.fn.jobstart, vim.ui.input = original_jobstart, original_input
  vim.cmd 'only!'
  vim.cmd 'bwipeout!'
  vim.fn.delete(root, 'rf')
  assert(ok, err)
end)

check('xcode.retained_commands', function()
  assert(vim.fn.exists ':SwiftSource' == 2, 'SwiftSource is missing')
  if vim.fn.has 'macunix' ~= 1 then
    assert(not package.loaded.xcodebuild, 'Xcode support loaded outside macOS')
    return
  end
  for _, command in ipairs { 'XcodebuildSetup', 'XcodebuildBuild', 'XcodebuildBuildRun', 'XcodebuildRun', 'XcodebuildPicker', 'SwiftSource' } do
    assert(vim.fn.exists(':' .. command) == 2, command .. ' is missing')
  end
end)

check('lsp.retained_navigation', function()
  local buf = scratch { 'local value = 1' }
  local client = vim.lsp.start({
    name = 'config-fixture',
    cmd = function()
      local closing = false
      return {
        request = function(method, _, callback)
          callback(nil, method == 'initialize' and { capabilities = { renameProvider = true, definitionProvider = true } } or nil)
          return true, 1
        end,
        notify = function() return true end,
        is_closing = function() return closing end,
        terminate = function() closing = true end,
      }
    end,
    root_dir = vim.fn.getcwd(),
  }, { bufnr = buf })
  assert(client, 'Fixture client did not start')
  assert(vim.wait(5000, function() return #vim.lsp.get_clients { bufnr = buf, name = 'config-fixture' } > 0 end, 20), 'Fixture client did not attach')
  for _, key in ipairs { 'gd', 'grd', 'grr', 'gri', 'grt', 'grn', 'grD' } do
    assert(next(mapped(key)), key .. ' is missing')
  end
  assert(mapped('gd').callback == require('telescope.builtin').lsp_definitions, 'gd uses a source fallback instead of the language server')
  assert(not next(mapped('gD')), 'gD still overrides hover')
  vim.lsp.stop_client(client, true)
end)

dofile('tests/retained_spec.lua')(check)
dofile('tests/actions_spec.lua')(check)
dofile('tests/rename_spec.lua')(check)

vim.wait(500, function() return false end, 50)
check('config.no_asynchronous_errors', function()
  assert(#async_errors == 0, table.concat(async_errors, '\n'))
  assert(vim.v.errmsg == '', vim.v.errmsg)
end)
vim.schedule, vim.notify = schedule, notify
if failures > 0 then vim.cmd.cquit(failures) end
vim.cmd 'qa!'
