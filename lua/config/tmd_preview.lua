local M = {}
local preview

local function notice(message)
  vim.notify('tmd: ' .. message, vim.log.levels.INFO)
end

local function command(argv)
  local result = vim.system(argv, { text = true }):wait(3000)
  if result.code ~= 0 then error(vim.trim(result.stderr or '') ~= '' and vim.trim(result.stderr) or 'command failed: ' .. argv[1], 0) end
  return result.stdout or ''
end

local function dispose()
  local current = preview
  if not current then return end
  preview = nil
  if current.timer then
    current.timer:stop()
    current.timer:close()
  end
  if current.pane then
    pcall(command, { current.herdr, 'pane', 'close', current.pane })
    pcall(command, { current.herdr, 'pane', 'zoom', current.origin, current.is_origin_zoomed and '--on' or '--off' })
  end
  local pid_file = current.dir .. '/pid'
  if vim.fn.filereadable(pid_file) == 1 and vim.fn.filereadable(current.dir .. '/done') == 0 then
    local pid = tonumber(vim.fn.readfile(pid_file)[1])
    if pid then vim.uv.kill(pid, 'sigterm') end
  end
  vim.fn.delete(current.dir, 'rf')
end

local function is_markdown(buf, lines)
  local kind = vim.bo[buf].buftype
  if kind ~= '' and kind ~= 'nofile' then return false end
  local filetype = vim.bo[buf].filetype
  if filetype == 'markdown' or filetype == 'mdx' or filetype == 'quarto' then return true end
  if filetype ~= '' then return false end
  if vim.api.nvim_buf_get_name(buf) ~= '' or vim.fn.win_gettype() ~= 'popup' and vim.api.nvim_win_get_config(0).relative == '' then return false end
  local is_prose = false
  local is_markup = false
  local is_fence = false
  for _, line in ipairs(lines) do
    if line:find('[%z\1-\8\11\12\14-\31]') then return false end
    if line:match '^%s*```' or line:match '^%s*~~~' then
      is_fence = not is_fence
      is_markup = true
    elseif not is_fence then
      if line:match '^%s*#+%s+%S' or line:match '^%s*[%-%*+]%s+%S' or line:match '%[[^%]]+%]%([^%)]+%)' or line:match '%*%*[^*]+%*%*' then is_markup = true end
      if line:match '%a+%s+%a+%s+%a+' then is_prose = true end
    end
  end
  return is_markup and is_prose
end

function M.open(buf)
  if not vim.api.nvim_buf_is_valid(buf) then return end
  local lines = vim.api.nvim_buf_get_lines(buf, 0, -1, false)
  if not is_markdown(buf, lines) or vim.trim(table.concat(lines, '\n')) == '' then
    notice('Focus a Markdown/MDX buffer or a Markdown documentation float first (use K, then enter the float). Code and terminal buffers are not previewed.')
    return
  end
  if preview then
    if preview.phase == 'pending' then
      notice('A preview is still starting.')
    else
      if preview.pane then pcall(command, { preview.herdr, 'pane', 'zoom', preview.pane, '--on' }) end
      notice('Reusing the open snapshot. Close it with Ctrl+Q before previewing new edits.')
    end
    return
  end
  local tmd = vim.fn.exepath 'tmd'
  if tmd == '' then
    local fallback = vim.fn.expand '~/.local/bin/tmd'
    if vim.fn.executable(fallback) == 1 then tmd = fallback end
  end
  if tmd == '' then return notice('Install jtnk/tmd v0.2.0 on PATH or at ~/.local/bin/tmd.') end
  local origin = vim.env.HERDR_PANE_ID
  local herdr = vim.fn.exepath 'herdr'
  if origin and origin ~= '' then
    if herdr == '' then return notice('HERDR_PANE_ID is set, but herdr is not on PATH.') end
  elseif vim.uv.os_uname().sysname ~= 'Darwin' or vim.fn.executable 'open' == 0 then
    return notice('Outside Herdr, preview requires macOS and Ghostty.app.')
  else
    local is_available = pcall(command, { '/usr/bin/open', '-Ra', 'Ghostty.app' })
    if not is_available then return notice('Install Ghostty.app to open a graphics-capable preview window.') end
    origin = nil
  end
  local name = vim.api.nvim_buf_get_name(buf)
  local cwd = name ~= '' and vim.fs.dirname(vim.fn.fnamemodify(name, ':p')) or vim.fn.getcwd()
  local dir, mkdir_error = vim.uv.fs_mkdtemp(vim.fs.joinpath(vim.fn.stdpath 'run', 'tmd-XXXXXX'))
  if not dir then return notice('Cannot create a private snapshot directory: ' .. tostring(mkdir_error)) end
  preview = { phase = 'pending', dir = dir, origin = origin, herdr = herdr }
  local current = preview
  local is_ok, failure = pcall(function()
    local snapshot = dir .. '/snapshot.md'
    if vim.fn.writefile(lines, snapshot, vim.bo[buf].endofline and '' or 'b') ~= 0 then error('Cannot write snapshot.', 0) end
    local script = dir .. '/preview.sh'
    local body = {
      '#!/bin/sh',
      'dir=$1',
      'cwd=$2',
      'viewer=$3',
      'child=',
      'finish() {',
      '  status=$?',
      '  trap - EXIT HUP INT TERM',
      '  if [ -n "$child" ]; then kill "$child" 2>/dev/null; wait "$child" 2>/dev/null; fi',
      '  rm -f "$dir/snapshot.md"',
      '  if [ -d "$dir" ]; then printf "%s\\n" "$status" > "$dir/done"; fi',
      '}',
      'trap finish EXIT',
      'trap "exit 129" HUP',
      'trap "exit 130" INT',
      'trap "exit 143" TERM',
      'printf "%s\\n" "$$" > "$dir/pid"',
      'cd "$cwd" || exit 1',
      '"$viewer" < "$dir/snapshot.md" &',
      'child=$!',
      'wait "$child"',
      'status=$?',
      'child=',
      'exit "$status"',
    }
    if vim.fn.writefile(body, script) ~= 0 then error('Cannot write preview launcher.', 0) end
    local argv = { '/bin/sh', script, dir, cwd, tmd }
    if origin then
      local layout_response = vim.json.decode(command { herdr, 'pane', 'layout', '--pane', origin })
      local layout = layout_response.result and layout_response.result.layout
      if type(layout) ~= 'table' or type(layout.zoomed) ~= 'boolean' then error('Cannot read the originating Herdr layout.', 0) end
      current.is_origin_zoomed = layout.zoomed
      local response = vim.json.decode(command { herdr, 'pane', 'split', origin, '--direction', 'right', '--cwd', cwd, '--focus' })
      local pane = response.result and response.result.pane
      if type(pane) ~= 'table' or type(pane.pane_id) ~= 'string' or pane.pane_id == origin then error('Herdr did not return a new preview pane ID.', 0) end
      current.pane = pane.pane_id
      command { herdr, 'pane', 'zoom', current.pane, '--on' }
      local escaped = {}
      for _, arg in ipairs(argv) do escaped[#escaped + 1] = vim.fn.shellescape(arg) end
      command { herdr, 'pane', 'run', current.pane, 'exec ' .. table.concat(escaped, ' ') }
    else
      local launch = { '/usr/bin/open', '-na', 'Ghostty.app', '--args', '-e' }
      vim.list_extend(launch, argv)
      command(launch)
    end
    local deadline = vim.uv.hrtime() + 15e9
    current.timer = vim.uv.new_timer()
    current.timer:start(250, 250, vim.schedule_wrap(function()
      if preview ~= current then return end
      local done = dir .. '/done'
      if vim.fn.filereadable(done) == 1 then
        local status = vim.fn.readfile(done)[1]
        dispose()
        if status ~= '0' and status ~= '129' and status ~= '143' then notice('Viewer exited with status ' .. tostring(status) .. '. Check the terminal for details.') end
      elseif vim.fn.filereadable(dir .. '/pid') == 1 then
        current.phase = 'open'
      elseif vim.uv.hrtime() > deadline then
        dispose()
        notice('The terminal did not start the viewer within 15 seconds.')
      end
    end))
  end)
  if not is_ok then
    dispose()
    notice(tostring(failure))
  end
end

function M.setup()
  vim.keymap.set('n', '<leader>mp', function() M.open(vim.api.nvim_get_current_buf()) end, { desc = 'Preview focused Markdown buffer with tmd' })
  vim.api.nvim_create_autocmd('VimLeavePre', {
    group = vim.api.nvim_create_augroup('tmd-preview', { clear = true }),
    callback = dispose,
  })
end

return M
