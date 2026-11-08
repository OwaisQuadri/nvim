return function(check)
  local function fixture(files, suffix)
    local root = vim.fn.tempname() .. (suffix or '')
    vim.fn.mkdir(root, 'p')
    root = assert(vim.uv.fs_realpath(root))
    for name, lines in pairs(files) do
      local path = root .. '/' .. name
      vim.fn.mkdir(vim.fs.dirname(path), 'p')
      vim.fn.writefile(lines, path)
    end
    return root
  end

  local function open(path)
    local buf = vim.fn.bufadd(path)
    vim.fn.bufload(buf)
    vim.api.nvim_set_current_buf(buf)
    return buf
  end

  check('project.all_language_commands_and_literal_paths', function()
    local project = require 'config.project'
    local saved = { cmd = vim.cmd, jobstart = vim.fn.jobstart, select = vim.ui.select, input = vim.ui.input, cwd = vim.fn.getcwd() }
    local calls, xcode = {}, {}
    vim.fn.jobstart = function(argv, opts)
      calls[#calls + 1] = { argv = argv, cwd = opts.cwd }
      return 1
    end
    vim.ui.select = function(items, _, callback) callback(items[1]) end
    vim.ui.input = function(opts, callback) callback(opts.default .. 'existing') end
    vim.cmd = setmetatable({}, {
      __index = function(_, key) return saved.cmd[key] end,
      __call = function(_, args)
        if type(args) == 'string' and args:match '^Xcodebuild' then
          xcode[#xcode + 1] = args
        else
          return saved.cmd(args)
        end
      end,
    })
    local ok, err = pcall(function()
      local fixtures = {
        { marker = 'Package.swift', lines = { '// swift-tools-version: 6.0' }, build = { 'swift', 'build' }, run = { 'swift', 'run' }, existing = { 'swift', 'run', '--skip-build' } },
        { marker = 'pubspec.yaml', lines = { 'name: fixture' }, build = { 'flutter', 'build', 'apk' }, run = { 'flutter', 'run' } },
        { marker = 'package.json', lines = { '{"scripts":{"dev":"fixture","build":"fixture"}}' }, build = { 'npm', 'run', 'build' }, run = { 'npm', 'run', 'dev' } },
      }
      for _, spec in ipairs(fixtures) do
        local root = fixture({ [spec.marker] = spec.lines, ['src/source.txt'] = { 'fixture' } }, ' % # `literal`')
        for _, action in ipairs { 'build', 'run', 'existing' } do
          open(root .. '/src/source.txt')
          local before = #calls
          project.run(action)
          if spec[action] then
            assert(#calls == before + 1 and vim.deep_equal(calls[#calls].argv, spec[action]), vim.inspect(calls))
            assert(calls[#calls].cwd == root, 'Project cwd changed')
          elseif spec.marker == 'pubspec.yaml' then
            assert(vim.deep_equal(calls[#calls].argv, { 'flutter', 'run', '--use-application-binary=' .. root .. '/existing' }))
          else
            assert(#calls == before, 'Existing-build request spawned an implicit build')
          end
        end
      end
      if vim.fn.has 'macunix' == 1 then
        local root = fixture({ ['src/App.swift'] = { 'import SwiftUI' } }, ' % # `literal`')
        vim.fn.mkdir(root .. '/Fixture.xcodeproj', 'p')
        for _, action in ipairs { 'build', 'run', 'existing' } do
          open(root .. '/src/App.swift')
          project.run(action)
          assert(vim.fn.getcwd() == root, 'Xcode root was not passed literally')
        end
        assert(vim.deep_equal(xcode, { 'XcodebuildBuild', 'XcodebuildBuildRun', 'XcodebuildRun' }), vim.inspect(xcode))
      end
    end)
    vim.cmd, vim.fn.jobstart, vim.ui.select, vim.ui.input = saved.cmd, saved.jobstart, saved.select, saved.input
    vim.api.nvim_set_current_dir(saved.cwd)
    vim.cmd 'only!'
    assert(ok, err)
  end)

  check('project.terminal_preserves_dirty_source_buffer', function()
    local root = fixture { ['Cargo.toml'] = { '[package]', 'name = "fixture"', 'version = "0.1.0"' }, ['source.txt'] = { 'saved' } }
    local source = open(root .. '/source.txt')
    vim.api.nvim_buf_set_lines(source, 0, -1, false, { 'unsaved' })
    local input = vim.ui.input
    vim.ui.input = function(_, callback) callback(assert(vim.fn.exepath 'true')) end
    local is_ok, err = pcall(require('config.project').run, 'existing')
    vim.ui.input = input
    assert(is_ok, err)
    assert(vim.api.nvim_get_current_buf() ~= source, 'Source buffer became the terminal')
    assert(vim.bo.buftype == 'terminal', 'No real terminal was created')
    assert(vim.fn.jobwait({ vim.b.terminal_job_id }, 5000)[1] == 0, 'Terminal command failed')
    assert(vim.bo[source].buftype == '' and vim.bo[source].modified, 'Source buffer state changed')
    assert(vim.api.nvim_buf_get_lines(source, 0, -1, false)[1] == 'unsaved')
    assert(vim.fn.readfile(root .. '/source.txt')[1] == 'saved', 'App command saved source edits')
    vim.cmd 'bwipeout!'
    vim.cmd 'only!'
    vim.api.nvim_buf_delete(source, { force = true })
  end)

  check('git.buffer_local_hunk_navigation', function()
    local lines = {}
    for i = 1, 25 do lines[i] = 'line ' .. i end
    local root = fixture { ['tracked.txt'] = lines }
    local function git(args, directory)
      local command = { 'git', '-C', directory or root }
      vim.list_extend(command, args)
      local output = vim.fn.system(command)
      assert(vim.v.shell_error == 0, output)
    end
    git { 'init', '--quiet' }
    git { 'add', 'tracked.txt' }
    git { '-c', 'user.name=Fixture', '-c', 'user.email=fixture@example.test', 'commit', '--quiet', '-m', 'fixture' }
    lines[2], lines[20] = 'changed two', 'changed twenty'
    vim.fn.writefile(lines, root .. '/tracked.txt')
    local foreign = fixture { ['foreign.txt'] = { 'one', 'two', 'three' } }
    git({ 'init', '--quiet' }, foreign)
    git({ 'add', 'foreign.txt' }, foreign)
    git({ '-c', 'user.name=Fixture', '-c', 'user.email=fixture@example.test', 'commit', '--quiet', '-m', 'fixture' }, foreign)
    vim.fn.writefile({ 'one', 'changed', 'three' }, foreign .. '/foreign.txt')
    local foreign_buf = open(foreign .. '/foreign.txt')
    assert(vim.wait(10000, function() return #(require('gitsigns').get_hunks(foreign_buf) or {}) == 1 end, 50), 'Second repository did not attach')
    local cwd = vim.fn.getcwd()
    vim.api.nvim_set_current_dir(foreign)
    local buf = open(root .. '/tracked.txt')
    assert(vim.wait(10000, function()
      return vim.fn.maparg('[c', 'n') ~= '' and #(require('gitsigns').get_hunks(buf) or {}) == 2
    end, 50), 'Git mappings or hunks did not attach')
    vim.api.nvim_win_set_cursor(0, { 1, 0 })
    vim.api.nvim_feedkeys(vim.keycode ']c', 'x', false)
    assert(vim.wait(5000, function() return vim.api.nvim_win_get_cursor(0)[1] == 2 end, 20), ']c did not move to a hunk')
    vim.api.nvim_win_set_cursor(0, { 25, 0 })
    vim.api.nvim_feedkeys(vim.keycode '[c', 'x', false)
    assert(vim.wait(5000, function() return vim.api.nvim_win_get_cursor(0)[1] == 20 end, 20), '[c did not move to a hunk')
    assert(vim.api.nvim_get_current_buf() == buf, 'Hunk navigation crossed into another repository')
    local entries = vim.fn.getqflist()
    assert(#entries == 2, 'Quickfix includes another repository')
    for _, entry in ipairs(entries) do
      assert(vim.startswith(vim.api.nvim_buf_get_name(entry.bufnr), root .. '/'), 'Foreign repository entry in quickfix')
    end
    vim.api.nvim_feedkeys(vim.keycode ']c', 'x', false)
    assert(vim.wait(5000, function() return vim.api.nvim_win_get_cursor(0)[1] == 2 end, 20), ']c did not wrap to the first hunk')
    vim.api.nvim_feedkeys(vim.keycode '[c', 'x', false)
    assert(vim.wait(5000, function() return vim.api.nvim_win_get_cursor(0)[1] == 20 end, 20), '[c did not wrap to the last hunk')
    vim.api.nvim_set_current_dir(cwd)
    vim.api.nvim_buf_delete(buf, { force = true })
    vim.api.nvim_buf_delete(foreign_buf, { force = true })
  end)

  if vim.fn.has 'macunix' == 1 then
    check('xcode.mapping_targets', function()
      local targets = {
        X = 'Picker', xs = 'Setup', xb = 'Build', xr = 'BuildRun', xk = 'Cancel',
        xd = 'SelectDevice', xo = 'OpenInXcode', xt = 'Test', xT = 'TestClass',
        xe = 'TestExplorerToggle', xl = 'ToggleLogs', xc = 'ToggleCodeCoverage',
        xC = 'ShowCodeCoverageReport', xf = 'ProjectManager',
      }
      for key, command in pairs(targets) do
        local mapping = vim.fn.maparg('<leader>' .. key, 'n', false, true)
        assert(mapping.rhs == '<cmd>Xcodebuild' .. command .. '<CR>', key .. ': ' .. vim.inspect(mapping))
      end
      assert(vim.fn.maparg('<leader>xt', 'x'):find('XcodebuildTestSelected', 1, true), 'Visual test selection lost')
    end)

    check('xcode.scheme_binding_and_flag_import', function()
      local settings = require('xcodebuild.project.config').settings
      local xcode, appdata, integration = require 'xcodebuild.core.xcode', require 'xcodebuild.project.appdata', require 'xcodebuild.integrations.lsp'
      local original = { settings = vim.deepcopy(settings), find = xcode.find_derived_data_path, system = vim.system, log = appdata.build_logs_filepath, restart = integration.restart_sourcekit_lsp }
      local root = fixture({ ['buildServer.json'] = { '{"kind":"manual"}' }, ['build.log'] = { 'fixture' } })
      settings.projectFile, settings.scheme, settings.productName = root .. '/Fixture.xcodeproj', 'Fixture', 'Fixture'
      settings.workingDirectory = root
      local derived = root .. '/DerivedData'
      xcode.find_derived_data_path = function(product, project)
        assert(product == 'Fixture' and project == settings.projectFile, 'Wrong DerivedData identity')
        return derived
      end
      integration.restart_sourcekit_lsp = function() end
      appdata.build_logs_filepath = root .. '/build.log'
      local calls = {}
      vim.system = function(argv, opts, callback)
        if argv[1] ~= 'xcode-build-server' then return original.system(argv, opts, callback) end
        calls[#calls + 1] = { argv = argv, cwd = opts.cwd }
        callback { code = 0, stdout = '', stderr = '' }
        return {}
      end
      local ok, err = pcall(function()
        vim.api.nvim_exec_autocmds('User', { pattern = 'XcodebuildProjectSettingsUpdated' })
        assert(vim.wait(5000, function() return #calls == 1 end), 'Scheme binding did not run')
        assert(vim.deep_equal(calls[1].argv, { 'xcode-build-server', 'config', '-project', settings.projectFile, '-scheme', 'Fixture', '--build_root', derived }), vim.inspect(calls))
        assert(calls[1].cwd == root, 'Binding did not use project cwd')
        vim.api.nvim_exec_autocmds('User', { pattern = 'XcodebuildBuildFinished', data = { success = false } })
        assert(#calls == 1, 'Failed build was imported')
        vim.api.nvim_exec_autocmds('User', { pattern = 'XcodebuildBuildFinished', data = { success = true } })
        assert(vim.wait(5000, function() return #calls == 2 end), 'Successful build was not imported')
        assert(vim.deep_equal(calls[2].argv, { 'xcode-build-server', 'parse', '-a', root .. '/build.log' }), vim.inspect(calls))
        assert(calls[2].cwd == root)
      end)
      vim.wait(20)
      for key in pairs(settings) do settings[key] = nil end
      for key, value in pairs(original.settings) do settings[key] = value end
      xcode.find_derived_data_path, vim.system = original.find, original.system
      appdata.build_logs_filepath, integration.restart_sourcekit_lsp = original.log, original.restart
      assert(ok, err)
    end)
  end

  for _, spec in ipairs {
    { 'swift', 'Fixture.swift', { 'import Foundation', 'let value = 1' } },
    { 'dart', 'fixture.dart', { 'void main() { print(1); }' } },
    { 'rust', 'fixture.rs', { 'fn main() {}' } },
  } do
    check('treesitter.highlights_' .. spec[1], function()
      local root = fixture { [spec[2]] = spec[3] }
      local flutter_lsp = require 'flutter-tools.lsp'
      local attach = flutter_lsp.attach
      if spec[1] == 'dart' then flutter_lsp.attach = function() end end
      local is_ok, err = pcall(function()
        local buf = open(root .. '/' .. spec[2])
        assert(vim.wait(20000, function() return vim.treesitter.highlighter.active[buf] ~= nil end, 100), 'No highlighter for ' .. spec[1])
      end)
      flutter_lsp.attach = attach
      assert(is_ok, err)
    end)
  end

  check('formatting.swiftformat_and_swiftlint', function()
    local root = fixture { ['Format.swift'] = { 'struct Person{', 'let name:String', '}' } }
    local buf = open(root .. '/Format.swift')
    assert(vim.wait(20000, function()
      for _, diagnostic in ipairs(vim.diagnostic.get(buf)) do
        if diagnostic.source == 'swiftlint' then return true end
      end
      return false
    end, 100), 'SwiftLint did not report on opening the file')
    assert(require('conform').format { bufnr = buf, async = false, timeout_ms = 15000 }, 'SwiftFormat failed')
    assert(vim.tbl_contains(vim.api.nvim_buf_get_lines(buf, 0, -1, false), '    let name: String'), 'SwiftFormat did not format the declaration')
  end)

  check('lsp.sourcekit_attaches', function()
    local root = fixture { ['Fixture.swift'] = { 'import Foundation', 'let value = 1' } }
    local buf = open(root .. '/Fixture.swift')
    assert(vim.wait(30000, function() return #vim.lsp.get_clients { bufnr = buf, name = 'sourcekit' } > 0 end, 100), 'SourceKit did not attach')
  end)

  check('lsp.rust_analyzer_attaches', function()
    local root = fixture { ['Cargo.toml'] = { '[package]', 'name = "fixture"', 'version = "0.1.0"', 'edition = "2021"' }, ['src/main.rs'] = { 'fn main() {}' } }
    local buf = open(root .. '/src/main.rs')
    assert(vim.wait(30000, function() return #vim.lsp.get_clients { bufnr = buf, name = 'rust_analyzer' } > 0 end, 100), 'rust-analyzer did not attach')
  end)

  check('autoscroll.moves_pauses_and_restores_key', function()
    local lines = {}
    for i = 1, 300 do lines[i] = 'line ' .. i end
    local buf = vim.api.nvim_create_buf(false, true)
    vim.api.nvim_set_current_buf(buf)
    vim.api.nvim_buf_set_lines(buf, 0, -1, false, lines)
    vim.api.nvim_win_set_cursor(0, { 1, 0 })
    local toggle = assert(vim.fn.maparg('<leader>`', 'n', false, true).callback)
    local previous = vim.fn.maparg('`', 'n')
    vim.cmd 'Autoscroll speed 1000'
    toggle()
    assert(vim.wait(5000, function() return vim.api.nvim_win_get_cursor(0)[1] > 1 end, 20), 'Autoscroll did not move')
    local pause = assert(vim.fn.maparg('`', 'n', false, true).callback)
    pause()
    local row = vim.api.nvim_win_get_cursor(0)[1]
    vim.wait(250)
    assert(vim.api.nvim_win_get_cursor(0)[1] == row, 'Paused autoscroll moved')
    toggle()
    assert(vim.fn.maparg('`', 'n') == previous, 'Autoscroll did not restore the mark key')
  end)
end
