local M = {}

local function terminal(root, command)
  vim.cmd 'botright new'
  if vim.fn.jobstart(command, { term = true, cwd = root }) <= 0 then
    vim.notify('Could not start ' .. command[1], vim.log.levels.ERROR)
  end
end

local function existing_binary(root, is_flutter)
  vim.ui.input({ prompt = 'Built application: ', default = root .. '/', completion = 'file' }, function(path)
    if not path or path == '' then return end
    if is_flutter then
      terminal(root, { 'flutter', 'run', '--use-application-binary=' .. path })
    else
      terminal(root, { path })
    end
  end)
end

function M.run(action)
  local name = vim.api.nvim_buf_get_name(0)
  local from = name ~= '' and vim.fs.dirname(name) or vim.fn.getcwd()
  local marker = vim.fs.find(function(entry)
    return entry == 'pubspec.yaml' or entry == 'Cargo.toml' or entry == 'package.json' or entry == 'Package.swift'
      or entry:match '%.xcodeproj$' ~= nil or entry:match '%.xcworkspace$' ~= nil
  end, { path = from, upward = true, limit = 1 })[1]
  if not marker then
    vim.notify('No supported app project found from ' .. from, vim.log.levels.WARN)
    return
  end
  local root, kind = vim.fs.dirname(marker), vim.fs.basename(marker)
  if kind:match '%.xcodeproj$' or kind:match '%.xcworkspace$' then
    if vim.fn.has 'macunix' ~= 1 then
      vim.notify('Xcode app commands require macOS', vim.log.levels.WARN)
      return
    end
    local commands = { build = 'XcodebuildBuild', run = 'XcodebuildBuildRun', existing = 'XcodebuildRun' }
    vim.cmd { cmd = 'cd', args = { root }, magic = { file = false } }
    vim.cmd(commands[action])
  elseif kind == 'Package.swift' then
    local commands = { build = { 'swift', 'build' }, run = { 'swift', 'run' }, existing = { 'swift', 'run', '--skip-build' } }
    terminal(root, commands[action])
  elseif kind == 'Cargo.toml' then
    if action == 'existing' then return existing_binary(root, false) end
    terminal(root, { 'cargo', action == 'build' and 'build' or 'run' })
  elseif kind == 'pubspec.yaml' then
    if action == 'existing' then return existing_binary(root, true) end
    if action == 'run' then return terminal(root, { 'flutter', 'run' }) end
    local targets = { 'apk', 'appbundle', 'web' }
    if vim.fn.has 'macunix' == 1 then
      vim.list_extend(targets, { 'ios', 'macos' })
    elseif vim.fn.has 'win32' == 1 then
      table.insert(targets, 'windows')
    else
      table.insert(targets, 'linux')
    end
    vim.ui.select(targets, { prompt = 'Flutter build target' }, function(target)
      if target then terminal(root, { 'flutter', 'build', target }) end
    end)
  else
    local package = vim.json.decode(table.concat(vim.fn.readfile(marker), '\n'))
    local scripts = package.scripts or {}
    if action == 'existing' then
      vim.notify("Package scripts can build implicitly. Run the project's documented preview command explicitly.", vim.log.levels.WARN)
      return
    end
    if action == 'build' then
      if not scripts.build then
        vim.notify('This package has no build script', vim.log.levels.WARN)
        return
      end
      return terminal(root, { 'npm', 'run', 'build' })
    end
    local candidates = {}
    for script in pairs(scripts) do
      if script == 'dev' or script == 'start' then table.insert(candidates, script) end
    end
    table.sort(candidates)
    if #candidates == 0 then
      vim.notify('This package has no dev or start script', vim.log.levels.WARN)
      return
    end
    vim.ui.select(candidates, { prompt = 'Run app script' }, function(script)
      if script then terminal(root, { 'npm', 'run', script }) end
    end)
  end
end

return M
