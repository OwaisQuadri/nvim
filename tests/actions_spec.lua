return function(check)
  check('actions.normal_visual_insert_consumers', function()
    vim.pack.add { 'https://github.com/rachartier/tiny-code-action.nvim' }
    local picker = require('tiny-code-action.picker').get_picker_module 'telescope'
    local original_create = picker.create
    local offered
    picker.create = function(_, actions) offered = actions end
    local was_enabled = vim.lsp.is_enabled 'sourcekit'
    vim.lsp.enable('sourcekit', false)
    local root = vim.fn.tempname()
    vim.fn.mkdir(root, 'p')
    local file = root .. '/actions.txt'
    vim.fn.writefile({ 'local target = 1', 'print(target)' }, file)
    vim.cmd.edit(file)
    local buf = vim.api.nvim_get_current_buf()
    local recorded, executed = {}, 0
    local diagnostic = {
      range = { start = { line = 0, character = 6 }, ['end'] = { line = 0, character = 12 } },
      severity = 1, message = 'Fixture diagnostic', source = 'actions-fixture',
    }
    local client = assert(vim.lsp.start({
      name = 'actions-fixture', root_dir = root,
      cmd = function(dispatchers)
        local closing = false
        return {
          request = function(method, params, callback)
            if method == 'initialize' then
              callback(nil, { capabilities = { codeActionProvider = true, textDocumentSync = 1, executeCommandProvider = { commands = { 'fixture.fix' } } } })
            elseif method == 'textDocument/codeAction' then
              recorded[#recorded + 1] = params
              callback(nil, { { title = 'Fixture fix', kind = 'quickfix', command = { title = 'Fixture fix', command = 'fixture.fix' } } })
            elseif method == 'workspace/executeCommand' then
              executed = executed + 1
              callback(nil, nil)
            else
              callback(nil, nil)
            end
            return true, 1
          end,
          notify = function(method)
            if method == 'textDocument/didOpen' then
              vim.schedule(function()
                dispatchers.notification('textDocument/publishDiagnostics', { uri = vim.uri_from_bufnr(buf), diagnostics = { diagnostic } })
              end)
            end
            return true
          end,
          is_closing = function() return closing end,
          terminate = function() closing = true end,
        }
      end,
    }, { bufnr = buf }))
    local ok, err = pcall(function()
      assert(vim.wait(5000, function() return #vim.diagnostic.get(buf) > 0 end, 20), 'Fixture diagnostic did not arrive')
      vim.api.nvim_win_set_cursor(0, { 1, 15 })
      vim.fn.maparg('<C-.>', 'n', false, true).callback()
      assert(vim.wait(5000, function() return offered ~= nil end, 20), 'Normal action did not reach its picker')
      assert(recorded[#recorded].range.start.character == 0, 'Non-Swift action did not cover the line')
      assert(#offered == 1, 'Normal action was not offered')

      vim.bo[buf].filetype = 'swift'
      offered = nil
      vim.fn.maparg('<C-.>', 'n', false, true).callback()
      assert(vim.wait(5000, function() return offered ~= nil end, 20), 'Swift action did not reach its picker')
      assert(recorded[#recorded].range.start.character == 6, 'Swift normal action missed its diagnostic')

      local source = require('blink_quickfix_source').new()
      local completions
      source:get_completions({ bufnr = buf, cursor = { 1, 15 } }, function(result) completions = result.items end)
      assert(vim.wait(5000, function() return completions ~= nil end, 20), 'Insert actions were not returned')
      assert(#completions == 1 and completions[1].insertText == '', 'Insert action would insert its title')
      assert(recorded[#recorded].range.start.character == 6, 'Insert action missed its Swift diagnostic')
      source:execute({}, completions[1], function() end)
      assert(vim.wait(5000, function() return executed == 1 end, 20), 'Accepting the insert action did not execute it')

      vim.api.nvim_win_set_cursor(0, { 1, 0 })
      vim.api.nvim_feedkeys(vim.keycode 'Vj', 'x', false)
      local before = #recorded
      vim.fn.maparg('<C-.>', 'x', false, true).callback()
      assert(vim.wait(5000, function() return #recorded > before end, 20), 'Visual action did not reach the server')
      local range = recorded[#recorded].range
      assert(range.start.line == 0 and range['end'].line == 1, 'Visual action lost its two-line selection')
    end)
    vim.api.nvim_feedkeys(vim.keycode '<Esc>', 'x', false)
    picker.create = original_create
    vim.lsp.stop_client(client, true)
    vim.lsp.enable('sourcekit', was_enabled)
    assert(ok, err)
  end)
end
