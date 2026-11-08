-- ============================================================
-- SECTION 0: PLATFORM HELPERS
-- Authored on macOS, where Karabiner-Elements rebinds the physical Cmd key
-- to Ctrl -- the former Cmd (`<D-...>`) chords are registered as Ctrl
-- chords, shared with Windows/Linux. Shifted and punctuation Ctrl chords
-- (`<C-S-f>`, `<C-.>`, `<C-[>`) only arrive in terminals speaking the Kitty
-- keyboard protocol (Ghostty). The helper below covers the chords where the
-- platforms still differ, each side only taking effect on its own platform.
-- ============================================================
local is_mac = vim.uv.os_uname().sysname == 'Darwin'
local is_win = vim.fn.has 'win32' == 1

-- Map the same rhs under a Mac chord and/or a Windows chord, each only on the
-- platform it belongs to. Pass nil for either key to skip that platform.
local function map_platform(modes, mac_key, win_key, rhs, opts)
  if is_mac and mac_key then vim.keymap.set(modes, mac_key, rhs, opts) end
  if is_win and win_key then vim.keymap.set(modes, win_key, rhs, opts) end
end

-- ============================================================
-- SECTION 1: OPTIONS
-- Core Neovim settings, leaders, options, basic keymaps, basic autocmds
-- ============================================================
do
  -- Enable faster startup by caching compiled Lua modules
  vim.loader.enable()

  -- Set <space> as the leader key
  -- See `:help mapleader`
  --  NOTE: Must happen before plugins are loaded (otherwise wrong leader will be used)
  vim.g.mapleader = ' '
  vim.g.maplocalleader = ' '

  -- Set to true if you have a Nerd Font installed and selected in the terminal
  vim.g.have_nerd_font = true

  -- [[ Setting options ]]
  --  See `:help vim.o`
  -- NOTE: You can change these options as you wish!
  --  For more options, you can see `:help option-list`

  -- Make line numbers default
  vim.o.number = true
  -- Also show relative line numbers, to help with jumping.
  vim.o.relativenumber = true

  -- Enable mouse mode, can be useful for resizing splits for example!
  vim.o.mouse = 'a'

  -- Don't show the mode, since it's already in the status line
  vim.o.showmode = false

  -- Sync clipboard between OS and Neovim.
  --  Schedule the setting after `UiEnter` because it can increase startup-time.
  --  Remove this option if you want your OS clipboard to remain independent.
  --  See `:help 'clipboard'`
  vim.schedule(function() vim.o.clipboard = 'unnamedplus' end)

  -- Enable break indent
  vim.o.breakindent = true

  -- Four spaces, never tabs -- unless the project says otherwise. These are
  -- only the DEFAULTS a fresh buffer starts from: built-in editorconfig
  -- support, guess-indent's per-file detection (SECTION 4), ftplugins, and
  -- modelines (this file's own `ts=2 et` line at the bottom) all retune the
  -- buffer on read when there is evidence to go on. tabstop matches shiftwidth
  -- so a stray real tab renders at the same width everything else indents by
  -- (and listchars below keeps it visible as `» `).
  vim.o.expandtab = true
  vim.o.tabstop = 4
  vim.o.softtabstop = 4
  vim.o.shiftwidth = 4

  -- Enable undo/redo changes even after closing and reopening a file
  vim.o.undofile = true

  -- Case-insensitive searching UNLESS \C or one or more capital letters in the search term
  vim.o.ignorecase = true
  vim.o.smartcase = true

  -- Keep signcolumn on by default
  vim.o.signcolumn = 'yes'

  -- Decrease update time
  vim.o.updatetime = 250

  -- Decrease mapped sequence wait time
  vim.o.timeoutlen = 300

  -- Configure how new splits should be opened
  vim.o.splitright = true
  vim.o.splitbelow = true

  -- 82, not 80: prettier only wraps lines that EXCEED its default printWidth of
  -- 80, so a ruler at 80 flags lines the formatter is happy with.
  vim.o.colorcolumn = '82'

  -- Sets how neovim will display certain whitespace characters in the editor.
  --  See `:help 'list'`
  --  and `:help 'listchars'`
  --
  --  Notice listchars is set using `vim.opt` instead of `vim.o`.
  --  It is very similar to `vim.o` but offers an interface for conveniently interacting with tables.
  --   See `:help lua-options`
  --   and `:help lua-guide-options`
  vim.o.list = true
  vim.opt.listchars = { tab = '» ', trail = '·', nbsp = '␣' }

  -- Preview substitutions live, as you type!
  vim.o.inccommand = 'split'

  -- Show which line your cursor is on
  vim.o.cursorline = true

  -- Minimal number of screen lines to keep above and below the cursor.
  vim.o.scrolloff = 10

  -- if performing an operation that would fail due to unsaved changes in the buffer (like `:q`),
  -- instead raise a dialog asking if you wish to save the current file(s)
  -- See `:help 'confirm'`
  vim.o.confirm = true
end

-- ============================================================
-- SECTION 2: KEYMAPS
-- basic keymaps
-- ============================================================
do
  -- [[ Basic Keymaps ]]
  --  See `:help vim.keymap.set()`

  -- Clear highlights on search when pressing <Esc> in normal mode
  --  See `:help hlsearch`
  vim.keymap.set('n', '<Esc>', '<cmd>nohlsearch<CR>')

  -- Center the cursor line whenever a motion actually jumps around the buffer
  vim.keymap.set('n', 'n', 'nzzzv', { desc = 'Next search match (centered)' })
  vim.keymap.set('n', 'N', 'Nzzzv', { desc = 'Prev search match (centered)' })
  vim.keymap.set('n', 'gg', 'ggzz', { desc = 'Go to top (centered)' })
  vim.keymap.set('n', 'G', 'Gzz', { desc = 'Go to bottom (centered)' })
  vim.keymap.set('n', '<C-d>', '<C-d>zz', { desc = 'Half-page down (centered)' })
  vim.keymap.set('n', '<C-u>', '<C-u>zz', { desc = 'Half-page up (centered)' })
  vim.keymap.set('n', '<C-o>', '<C-o>zz', { desc = 'Older jumplist entry (centered)' })
  vim.keymap.set('n', '<C-i>', '<C-i>zz', { desc = 'Newer jumplist entry (centered)' })

  -- Word/line delete. macOS: option+backspace deletes the previous word,
  -- physical cmd+backspace (arriving as ctrl+backspace) deletes to the start
  -- of the line. Windows: ctrl+backspace deletes the previous word, and
  -- ctrl+u (insert) deletes to line start.
  map_platform('i', '<M-BS>', '<C-BS>', '<C-w>', { desc = 'Delete word before cursor' })
  map_platform('i', '<C-BS>', '<C-u>', '<C-u>', { desc = 'Delete to start of line' })

  -- Undo/redo everywhere: ctrl+z undoes on both platforms (mapping it also
  -- means nvim no longer suspends to the background on it); redo differs --
  -- ctrl+shift+z on macOS, ctrl+y on Windows.
  vim.keymap.set('n', '<C-z>', 'u', { desc = 'Undo' })
  map_platform('n', '<C-S-z>', '<C-y>', '<C-r>', { desc = 'Redo' })
  vim.keymap.set('i', '<C-z>', '<C-o>u', { desc = 'Undo' })
  map_platform('i', '<C-S-z>', '<C-y>', '<C-o><C-r>', { desc = 'Redo' })
  vim.keymap.set('v', '<C-z>', '<Esc>u', { desc = 'Undo' })
  map_platform('v', '<C-S-z>', '<C-y>', '<Esc><C-r>', { desc = 'Redo' })

  -- Diagnostic Config & Keymaps
  --  See `:help vim.diagnostic.Opts`
  vim.diagnostic.config {
    update_in_insert = false,
    severity_sort = true,
    float = { border = 'rounded', source = 'if_many' },
    underline = { severity = { min = vim.diagnostic.severity.WARN } },

    -- Can switch between these as you prefer
    virtual_text = true, -- Text shows up at the end of the line
    virtual_lines = false, -- Text shows up underneath the line, with virtual lines

    -- Auto open the float, so you can easily read the errors when jumping with `[d` and `]d`
    jump = {
      on_jump = function(_, bufnr)
        vim.cmd 'normal! zz'
        vim.diagnostic.open_float {
          bufnr = bufnr,
          scope = 'cursor',
          focus = false,
        }
      end,
    },
  }

  vim.keymap.set('n', '<leader>q', vim.diagnostic.setloclist, { desc = 'Open diagnostic location list' })

  -- Neovim's default `]d`/`[d` only jump within the current buffer. Override
  -- them to jump across every buffer with diagnostics, quickfix-list-based
  -- the same way the cross-file git hunk jumps (]c/[c) work below -- rebuild
  -- the list, then re-sync its "current entry" to the cursor's actual
  -- position before calling cnext/cprev, since rebuilding resets that
  -- pointer to the top every time (without this, repeated presses would get
  -- stuck re-landing on the same entry instead of advancing).
  local function jump_diagnostic_any_file(direction)
    vim.diagnostic.setqflist { open = false }
    local qf = vim.fn.getqflist()
    local cur_file = vim.api.nvim_buf_get_name(0)
    local cur_line = vim.api.nvim_win_get_cursor(0)[1]
    local idx = 1
    for i, entry in ipairs(qf) do
      local fname = entry.filename
      if (not fname or fname == '') and entry.bufnr and entry.bufnr > 0 then
        fname = vim.api.nvim_buf_get_name(entry.bufnr)
      end
      if fname == cur_file and entry.lnum <= cur_line then idx = i end
    end
    pcall(vim.fn.setqflist, {}, 'r', { idx = idx })

    local ok = pcall(vim.cmd, direction == 'next' and 'cnext' or 'cprev')
    if not ok then
      vim.cmd(direction == 'next' and 'cfirst' or 'clast')
    end
    vim.cmd 'normal! zz'
    vim.diagnostic.open_float { scope = 'cursor', focus = false }
  end

  vim.keymap.set('n', ']d', function() jump_diagnostic_any_file 'next' end, { desc = 'Next diagnostic (crosses files)' })
  vim.keymap.set('n', '[d', function() jump_diagnostic_any_file 'prev' end, { desc = 'Prev diagnostic (crosses files)' })

  -- Copy diagnostics (message + severity) to the clipboard
  local function yank_diagnostics(diagnostics, format, header)
    if vim.tbl_isempty(diagnostics) then
      vim.notify('No diagnostics found', vim.log.levels.WARN)
      return
    end

    local lines = { header }
    for _, d in ipairs(diagnostics) do
      table.insert(lines, format(d))
    end

    local text = table.concat(lines, '\n')
    vim.fn.setreg('"', text)
    vim.fn.setreg('+', text)
    vim.notify(('Copied %d diagnostic(s)'):format(#diagnostics))
  end

  vim.keymap.set('n', 'yd', function()
    local diagnostics = vim.diagnostic.get(0, { lnum = vim.fn.line '.' - 1 })
    table.sort(diagnostics, function(a, b) return a.col < b.col end)
    yank_diagnostics(
      diagnostics,
      function(d) return string.format('%s: %s', vim.diagnostic.severity[d.severity], d.message) end,
      string.format('%s:%d', vim.fn.expand '%', vim.fn.line '.')
    )
  end, { desc = '[Y]ank [d]iagnostics on line' })

  vim.keymap.set('n', 'yD', function()
    local diagnostics = vim.diagnostic.get(0)
    table.sort(diagnostics, function(a, b)
      if a.lnum ~= b.lnum then
        return a.lnum < b.lnum
      end
      return a.col < b.col
    end)
    yank_diagnostics(
      diagnostics,
      function(d) return string.format('%d: %s: %s', d.lnum + 1, vim.diagnostic.severity[d.severity], d.message) end,
      vim.fn.expand '%'
    )
  end, { desc = '[Y]ank all [D]iagnostics in file' })

  -- Exit terminal mode in the builtin terminal with a shortcut that is a bit easier
  -- for people to discover. Otherwise, you normally need to press <C-\><C-n>, which
  -- is not what someone will guess without a bit more experience.
  --
  -- NOTE: This won't work in all terminal emulators/tmux/etc. Try your own mapping
  -- or just use <C-\><C-n> to exit terminal mode
  vim.keymap.set('t', '<Esc><Esc>', '<C-\\><C-n>', { desc = 'Exit terminal mode' })

  -- TIP: Disable arrow keys in normal mode
  -- vim.keymap.set('n', '<left>', '<cmd>echo "Use h to move!!"<CR>')
  -- vim.keymap.set('n', '<right>', '<cmd>echo "Use l to move!!"<CR>')
  -- vim.keymap.set('n', '<up>', '<cmd>echo "Use k to move!!"<CR>')
  -- vim.keymap.set('n', '<down>', '<cmd>echo "Use j to move!!"<CR>')

  -- Plain `<C-w>q` uses `:close` under the hood, which refuses to close the
  -- very last window (E444). Route it through `:quit` instead, which just
  -- exits Neovim gracefully in that case -- same behavior otherwise.
  local function quit_window() vim.cmd 'quit' end

  local function open_terminal_split()
    vim.cmd.split()
    vim.cmd.terminal()
  end

  local function open_terminal_vsplit()
    vim.cmd.vsplit() -- 'splitright' is set above, so this opens on the right
    vim.cmd.terminal()
  end

  -- Personal addition: <leader>w as a prefix for the full `<C-w>` window-command
  -- family, from the old config. `:help CTRL-W` for the full list; the ones that
  -- matter most: <leader>ws/<leader>wv split horizontal/vertical,
  -- <leader>wh/j/k/l move focus in any direction, <leader>wc close this window,
  -- <leader>wo close every other window, <leader>w= equalize window sizes.
  -- `remap = true` so that if the `<C-w>` expansion below is left pending
  -- (e.g. you paused between `<leader>w` and the next key, past `timeoutlen`),
  -- the resulting <C-w> is still looked up in the mapping table -- letting it
  -- combine with a later keypress to match mappings like `<C-w>Q` below.
  -- Without this, a noremap'd `<C-w>` falls straight to Vim's native <C-w>
  -- prefix (no Q action there), and it silently no-ops.
  vim.keymap.set('n', '<leader>w', '<C-w>', { remap = true, desc = '[W]indow commands prefix' })

  vim.keymap.set('n', '<leader>wq', quit_window, { desc = '[W]indow [q]uit' })
  vim.keymap.set('n', '<leader>wQ', '<cmd>quitall<CR>', { desc = '[W]indow [Q]uit all' })
  vim.keymap.set('n', '<C-w>Q', '<cmd>quitall<CR>', { desc = '[W]indow [Q]uit all' })

  -- Open a terminal in a new split. Once inside, you're in Terminal mode --
  -- typing goes straight to the shell, not to Neovim. To get back to Normal
  -- mode so window/buffer keymaps work again, press <Esc> TWICE (a single
  -- <Esc> is sent to the shell like any other key, so it looks like nothing
  -- happened). See `:help Terminal-mode`.
  vim.keymap.set('n', '<leader>wt', open_terminal_split, { desc = '[W]indow: open [t]erminal in split' })

  -- Overrides the native <C-w>T ("break out into a new tab") proxied under
  -- <leader>w -- open a terminal in a vertical split on the right instead.
  vim.keymap.set('n', '<leader>wT', open_terminal_vsplit, { desc = '[W]indow: open [T]erminal in right split' })

  -- [[ Basic Autocommands ]]
  --  See `:help lua-guide-autocommands`

  -- Highlight when yanking (copying) text
  --  Try it with `yap` in normal mode
  --  See `:help vim.hl.on_yank()`
  vim.api.nvim_create_autocmd('TextYankPost', {
    desc = 'Highlight when yanking (copying) text',
    group = vim.api.nvim_create_augroup('kickstart-highlight-yank', { clear = true }),
    callback = function() vim.hl.on_yank() end,
  })
end

-- ============================================================
-- SECTION 3: PLUGIN MANAGER INTRO
-- vim.pack intro, build hooks
-- ============================================================
do
  -- [[ Intro to `vim.pack` ]]
  -- `vim.pack` is a new plugin manager built into Neovim,
  --  which provides a Lua interface for installing and managing plugins.
  --
  --  See `:help vim.pack`, `:help vim.pack-examples` or the
  --  excellent blog post from the creator of vim.pack and mini.nvim:
  --  https://echasnovski.com/blog/2026-03-13-a-guide-to-vim-pack
  --
  --  To inspect plugin state and pending updates, run
  --    :lua vim.pack.update(nil, { offline = true })
  --
  --  To update plugins, run
  --    :lua vim.pack.update()
  --
  --
  --  Throughout the rest of the config there will be examples
  --  of how to install and configure plugins using `vim.pack`.
  --
  --  In this section we set up some autocommands to run build
  --  steps for certain plugins after they are installed or updated.

  local function run_build(name, cmd, cwd)
    local result = vim.system(cmd, { cwd = cwd }):wait()
    if result.code ~= 0 then
      local stderr = result.stderr or ''
      local stdout = result.stdout or ''
      local output = stderr ~= '' and stderr or stdout
      if output == '' then output = 'No output from build command.' end
      vim.notify(('Build failed for %s:\n%s'):format(name, output), vim.log.levels.ERROR)
    end
  end

  -- This autocommand runs after a plugin is installed or updated and
  --  runs the appropriate build command for that plugin if necessary.
  --
  -- See `:help vim.pack-events`
  vim.api.nvim_create_autocmd('PackChanged', {
    group = vim.api.nvim_create_augroup('config-plugin-builds', { clear = true }),
    callback = function(ev)
      local name = ev.data.spec.name
      local kind = ev.data.kind
      if kind ~= 'install' and kind ~= 'update' then return end

      if name == 'telescope-fzf-native.nvim' and vim.fn.executable 'make' == 1 then
        run_build(name, { 'make' }, ev.data.path)
        return
      end

      if name == 'LuaSnip' then
        if vim.fn.has 'win32' ~= 1 and vim.fn.executable 'make' == 1 then run_build(name, { 'make', 'install_jsregexp' }, ev.data.path) end
        return
      end

      if name == 'nvim-treesitter' then
        if not ev.data.active then vim.cmd.packadd 'nvim-treesitter' end
        vim.cmd 'TSUpdate'
        return
      end
    end,
  })
end

---Because most plugins are hosted on GitHub, you can use the helper
---function to have less repetition in the following sections.
---@param repo string
---@return string
local function gh(repo) return 'https://github.com/' .. repo end

-- SECTION 4: UI / CORE UX PLUGINS
-- guess-indent, gitsigns, which-key, colorscheme, todo-comments, mini modules
-- ============================================================
do
  -- [[ Installing and Configuring Plugins ]]
  --
  -- To install a plugin simply call `vim.pack.add` with its git url.
  -- This will download the default branch of the plugin, which will usually be `main` or `master`
  -- You can also have more advanced specs, which we will talk about later.
  --
  -- For most plugins its not enough to install them, you also need to call their `.setup()` to start them.
  --
  -- For example, lets say we want to install `guess-indent.nvim` - a plugin for
  -- automatically detecting and setting the indentation.
  --
  -- We first install it from https://github.com/NMAC427/guess-indent.nvim
  -- and then call its `setup()` function to start it with default settings.
  vim.pack.add { gh 'NMAC427/guess-indent.nvim' }
  require('guess-indent').setup {}

  -- Here is a more advanced configuration example that passes options to `gitsigns.nvim`
  --
  -- See `:help gitsigns` to understand what each configuration key does.
  -- Adds git related signs to the gutter, as well as utilities for managing changes.
  --
  -- This also enables kickstart's optional `kickstart.plugins.gitsigns` recommended
  -- keymaps (hunk stage/reset/preview/nav under <leader>h*, see the which-key spec
  -- below) inline, since sourcekit-lsp/personal-extras below assume they're already on.
  vim.pack.add { gh 'lewis6991/gitsigns.nvim' }
  require('gitsigns').setup {
    signs_staged_enable = true,
    signs = {
      add = { text = '+' }, ---@diagnostic disable-line: missing-fields
      change = { text = '~' }, ---@diagnostic disable-line: missing-fields
      delete = { text = '_' }, ---@diagnostic disable-line: missing-fields
      topdelete = { text = '‾' }, ---@diagnostic disable-line: missing-fields
      changedelete = { text = '~' }, ---@diagnostic disable-line: missing-fields
    },
    on_attach = function(bufnr)
      local gitsigns = require 'gitsigns'

      local function map(mode, l, r, opts)
        opts = opts or {}
        opts.buffer = bufnr
        vim.keymap.set(mode, l, r, opts)
      end

      -- Navigation
      -- gitsigns has no repo-wide "staged" target, so for staged hunks the
      -- quickfix list is built ourselves from `git diff --cached` (index vs
      -- HEAD); for unstaged, gitsigns' own 'all' target scan is used.
      local function build_hunk_qflist(is_staged, callback)
        local directory = vim.fs.dirname(vim.api.nvim_buf_get_name(bufnr))
        local root = vim.fn.systemlist { 'git', '-C', directory, 'rev-parse', '--show-toplevel' }
        if vim.v.shell_error ~= 0 then
          vim.notify('Not in a git repo', vim.log.levels.WARN)
          return
        end
        root = root[1]
        if not is_staged then
          gitsigns.setqflist('all', { open = false }, function(err)
            if err then
              vim.notify(tostring(err), vim.log.levels.ERROR)
              return
            end
            local entries = vim.tbl_filter(function(entry)
              local path = entry.filename or vim.api.nvim_buf_get_name(entry.bufnr)
              return vim.startswith(path, root .. '/')
            end, vim.fn.getqflist())
            vim.fn.setqflist(entries, 'r')
            callback()
          end)
          return
        end

        local diff = vim.fn.systemlist { 'git', '-C', root, 'diff', '--cached', '--unified=0', '--no-color' }
        local qflist = {}
        local file
        for _, line in ipairs(diff) do
          local f = line:match '^%+%+%+ b/(.*)'
          if f then
            file = root .. '/' .. f
          end
          local newline = line:match '^@@ %-%d+,?%d* %+(%d+)'
          if newline and file then
            table.insert(qflist, { filename = file, lnum = tonumber(newline), text = 'Staged change' })
          end
        end

        if vim.tbl_isempty(qflist) then
          vim.notify('No staged hunks', vim.log.levels.WARN)
          return
        end

        vim.fn.setqflist(qflist, 'r')
        callback()
      end

      local function jump_hunk(direction, is_staged)
        build_hunk_qflist(is_staged, function()
          vim.schedule(function()
            local qf = vim.fn.getqflist()
            if #qf == 0 then
              vim.notify('No hunks', vim.log.levels.INFO)
              return
            end
            local cur_file = vim.api.nvim_buf_get_name(0)
            local cur_line = vim.api.nvim_win_get_cursor(0)[1]
            local target, first, last
            for i, entry in ipairs(qf) do
              local path = entry.filename or vim.api.nvim_buf_get_name(entry.bufnr)
              if path == cur_file then
                first, last = first or i, i
                if direction == 'next' and entry.lnum > cur_line and not target then target = i end
                if direction == 'prev' and entry.lnum < cur_line then target = i end
              end
            end
            target = target or (direction == 'next' and ((last or 0) + 1) or ((first or (#qf + 1)) - 1))
            if target > #qf then target = 1 end
            if target < 1 then target = #qf end
            vim.cmd.cc(target)
            vim.cmd 'normal! zz'
          end)
        end)
      end

      map('n', ']c', function()
        if vim.wo.diff then
          vim.cmd.normal { ']c', bang = true }
        else
          jump_hunk('next', false)
        end
      end, { desc = 'Jump to next git [c]hange (crosses files)' })

      map('n', '[c', function()
        if vim.wo.diff then
          vim.cmd.normal { '[c', bang = true }
        else
          jump_hunk('prev', false)
        end
      end, { desc = 'Jump to prev git [c]hange (crosses files)' })

      map('n', ']C', function() jump_hunk('next', true) end, { desc = 'Jump to next staged git [C]hange (crosses files)' })
      map('n', '[C', function() jump_hunk('prev', true) end, { desc = 'Jump to prev staged git [C]hange (crosses files)' })

      -- Actions
      -- visual mode
      map('v', '<leader>hs', function() gitsigns.stage_hunk { vim.fn.line '.', vim.fn.line 'v' } end, { desc = 'git [s]tage hunk' })
      map('v', '<leader>hr', function() gitsigns.reset_hunk { vim.fn.line '.', vim.fn.line 'v' } end, { desc = 'git [r]eset hunk' })
      -- normal mode
      map('n', '<leader>hs', gitsigns.stage_hunk, { desc = 'git [s]tage hunk' })
      map('n', '<leader>hr', gitsigns.reset_hunk, { desc = 'git [r]eset hunk' })
      map('n', '<leader>hS', gitsigns.stage_buffer, { desc = 'git [S]tage buffer' })
      map('n', '<leader>hR', gitsigns.reset_buffer, { desc = 'git [R]eset buffer' })
      map('n', '<leader>hp', gitsigns.preview_hunk, { desc = 'git [p]review hunk' })
      map('n', '<leader>hi', gitsigns.preview_hunk_inline, { desc = 'git preview hunk [i]nline' })
      map('n', '<leader>hb', function() gitsigns.blame_line { full = true } end, { desc = 'git [b]lame line' })
      map('n', '<leader>hd', gitsigns.diffthis, { desc = 'git [d]iff against index' })
      map('n', '<leader>hD', function() gitsigns.diffthis '@' end, { desc = 'git [D]iff against last commit' })
      map('n', '<leader>hQ', function() gitsigns.setqflist 'all' end, { desc = 'git hunk [Q]uickfix list (all files in repo)' })
      map('n', '<leader>hq', gitsigns.setqflist, { desc = 'git hunk [q]uickfix list (all changes in this file)' })
      -- Toggles
      map('n', '<leader>tb', gitsigns.toggle_current_line_blame, { desc = '[T]oggle git show [b]lame line' })
      map('n', '<leader>tw', gitsigns.toggle_word_diff, { desc = '[T]oggle git intra-line [w]ord diff' })

      -- Text object
      map({ 'o', 'x' }, 'ih', gitsigns.select_hunk)
    end,
  }

  -- Useful plugin to show you pending keybinds.
  vim.pack.add { gh 'folke/which-key.nvim' }
  require('which-key').setup {
    -- Delay between pressing a key and opening which-key (milliseconds)
    delay = 0,
    icons = { mappings = vim.g.have_nerd_font },
    -- Document existing key chains
    spec = {
      { '<leader>s', group = '[S]earch', mode = { 'n', 'v' } },
      { '<leader>t', group = '[T]oggle' },
      { '<leader>h', group = 'Git [H]unk', mode = { 'n', 'v' } }, -- Enable gitsigns recommended keymaps first
      { 'gr', group = 'LSP Actions', mode = { 'n' } },
      { '<leader>c', group = '[C]ode', mode = { 'n', 'v' } },
      -- <leader>w forwards raw to <C-w>, but which-key doesn't know that by
      -- itself -- proxy it so the full native <C-w> preset list (h/j/k/l,
      -- s/v splits, etc.) shows up under <leader>w too, not just the keys
      -- (q/Q/t) that have their own explicit <leader>w<key> mapping.
      { '<leader>w', proxy = '<C-w>', group = '[W]indow' },
    },
  }

  -- [[ Colorscheme ]]
  -- You can easily change to a different colorscheme.
  -- Change the name of the colorscheme plugin below, and then
  -- change the command under that to load whatever the name of that colorscheme is.
  --
  -- If you want to see what colorschemes are already installed, you can use `:Telescope colorscheme`.
  -- vim.pack.add { gh 'rose-pine/neovim' }

  -- Load the colorscheme here.
  -- Xcode's own "Default (Dark)" palette, ported to Vim by lunacookies -- same
  -- colors in nvim as in Xcode, so switching between the two is seamless.
  vim.pack.add { gh 'lunacookies/vim-colors-xcode' }
  vim.cmd.colorscheme 'xcodedark'

  -- Transparent background, colorscheme-agnostic: clears the background on
  -- every `:colorscheme` change (including this one, since ColorScheme has
  -- already fired by the time this autocmd is created below -- so also run
  -- it once immediately). This is Ghostty's translucent/glass background
  -- showing through instead of nvim painting over it with an opaque color.
  -- Built-in colorschemes (like `ron` above) don't ship their own
  -- transparency option the way some plugin colorschemes (rose-pine,
  -- tokyonight, catppuccin, ...) do, so this clears the relevant highlight
  -- groups directly instead of relying on a per-theme setting -- it keeps
  -- working no matter what colorscheme you switch to next.
  local function clear_bg()
    for _, group in ipairs { 'Normal', 'NormalNC', 'NormalFloat', 'SignColumn', 'EndOfBuffer', 'FloatBorder', 'MsgArea' } do
      vim.api.nvim_set_hl(0, group, { bg = 'none' })
    end
  end
  vim.api.nvim_create_autocmd('ColorScheme', {
    group = vim.api.nvim_create_augroup('config-transparency', { clear = true }),
    desc = 'Keep the background transparent on any colorscheme',
    callback = clear_bg,
  })
  clear_bg()

  -- Highlight todo, notes, etc in comments
  vim.pack.add { gh 'folke/todo-comments.nvim' }
  require('todo-comments').setup { signs = false }

  -- [[ mini.nvim ]]
  --  A collection of various small independent plugins/modules
  vim.pack.add { gh 'nvim-mini/mini.nvim' }

  -- If a nerd font is available, load the icons module for pretty icons in various plugins.
  if vim.g.have_nerd_font then
    require('mini.icons').setup()
    -- Used for backwards compatibility with plugins that require `nvim-web-devicons` (e.g. telescope.nvim)
    MiniIcons.mock_nvim_web_devicons()
  end

  -- Better Around/Inside textobjects
  --
  -- Examples:
  --  - va)  - [V]isually select [A]round [)]paren
  --  - yiiq - [Y]ank [I]nside [I]+1 [Q]uote
  --  - ci'  - [C]hange [I]nside [']quote
  require('mini.ai').setup {
    -- NOTE: Avoid conflicts with the built-in incremental selection mappings on Neovim>=0.12 (see `:help treesitter-incremental-selection`)
    mappings = {
      around_next = 'aa',
      inside_next = 'ii',
    },
    n_lines = 500,
  }

  -- Add/delete/replace surroundings (brackets, quotes, etc.)
  --
  -- - saiw) - [S]urround [A]dd [I]nner [W]ord [)]Paren
  -- - sd'   - [S]urround [D]elete [']quotes
  -- - sr)'  - [S]urround [R]eplace [)] [']
  require('mini.surround').setup()

  -- Auto-close brackets and quotes as you type them.
  require('mini.pairs').setup()

  -- Simple and easy statusline.
  --  You could remove this setup call if you don't like it,
  --  and try some other statusline plugin
  local statusline = require 'mini.statusline'
  -- Set `use_icons` to true if you have a Nerd Font
  statusline.setup { use_icons = vim.g.have_nerd_font }

  -- You can configure sections in the statusline by overriding their
  -- default behavior. For example, here we set the section for
  -- cursor location to LINE:COLUMN
  ---@diagnostic disable-next-line: duplicate-set-field
  statusline.section_location = function() return '%2l:%-2v' end

  -- mini.statusline links the filename section to 'StatusLineNC' by default,
  -- which makes it look dim/inactive even in the focused window. Make it
  -- bold and colored instead, and keep it that way across colorscheme changes.
  local function make_filename_prominent()
    vim.api.nvim_set_hl(0, 'MiniStatuslineFilename', { link = 'Title', default = false })
    vim.api.nvim_set_hl(0, 'MiniStatuslineFilenameBase', { link = 'Directory', default = false })
  end
  vim.api.nvim_create_autocmd('ColorScheme', {
    group = vim.api.nvim_create_augroup('config-statusline', { clear = true }),
    desc = 'Keep the statusline filename prominent',
    callback = make_filename_prominent,
  })
  make_filename_prominent()

  -- Split the filename section so the actual filename (the last path
  -- segment) stands out from the directory it lives in.
  ---@diagnostic disable-next-line: duplicate-set-field
  statusline.section_filename = function(args)
    if vim.bo.buftype == 'terminal' then return '%t' end

    local path = statusline.is_truncated(args.trunc_width) and vim.fn.expand '%:~:.' or vim.fn.expand '%:p'
    local dir, base = path:match '^(.*/)([^/]*)$'
    dir, base = dir or '', base or path

    return dir .. '%#MiniStatuslineFilenameBase#' .. base .. '%#MiniStatuslineFilename#%m%r'
  end

  -- ... and there is more!
  --  Check out: https://github.com/nvim-mini/mini.nvim
end

-- ============================================================
-- SECTION 5: SEARCH & NAVIGATION
-- Telescope setup, keymaps, LSP picker mappings
-- ============================================================
do
  -- [[ Fuzzy Finder (files, lsp, etc) ]]
  --
  -- Telescope is a fuzzy finder that comes with a lot of different things that
  -- it can fuzzy find! It's more than just a "file finder", it can search
  -- many different aspects of Neovim, your workspace, LSP, and more!
  --
  -- There are lots of other alternative pickers (like snacks.picker, or fzf-lua)
  -- so feel free to experiment and see what you like!
  --
  -- The easiest way to use Telescope, is to start by doing something like:
  --  :Telescope help_tags
  --
  -- After running this command, a window will open up and you're able to
  -- type in the prompt window. You'll see a list of `help_tags` options and
  -- a corresponding preview of the help.
  --
  -- Two important keymaps to use while in Telescope are:
  --  - Insert mode: <c-/>
  --  - Normal mode: ?
  --
  -- This opens a window that shows you all of the keymaps for the current
  -- Telescope picker. This is really useful to discover what Telescope can
  -- do as well as how to actually do it!

  ---@type (string|vim.pack.Spec)[]
  local telescope_plugins = {
    gh 'nvim-lua/plenary.nvim',
    gh 'nvim-telescope/telescope.nvim',
    gh 'nvim-telescope/telescope-ui-select.nvim',
  }
  if vim.fn.executable 'make' == 1 then table.insert(telescope_plugins, gh 'nvim-telescope/telescope-fzf-native.nvim') end

  -- NOTE: You can install multiple plugins at once
  vim.pack.add(telescope_plugins)

  -- See `:help telescope` and `:help telescope.setup()`
  require('telescope').setup {
    -- You can put your default mappings / updates / etc. in here
    --  All the info you're looking for is in `:help telescope.setup()`
    --
    -- defaults = {
    --   mappings = {
    --     i = { ['<c-enter>'] = 'to_fuzzy_refine' },
    --   },
    -- },
    -- pickers = {}
    extensions = {
      ['ui-select'] = { require('telescope.themes').get_dropdown() },
    },
  }

  -- Enable Telescope extensions if they are installed
  pcall(require('telescope').load_extension, 'fzf')
  pcall(require('telescope').load_extension, 'ui-select')

  -- See `:help telescope.builtin`
  local builtin = require 'telescope.builtin'
  vim.keymap.set('n', '<leader>sf', builtin.find_files, { desc = '[S]earch [F]iles' })
  vim.keymap.set('n', '<leader>sg', builtin.live_grep, { desc = '[S]earch project text' })
  vim.keymap.set('n', '<leader>sp', function()
    local text = vim.fn.getreg '+'
    if text == '' then
      vim.notify('Clipboard is empty', vim.log.levels.INFO)
      return
    end
    builtin.grep_string { search = text, use_regex = false }
  end, { desc = '[S]earch clipboard ([P]aste)' })

  -- Explicit upstream browsing is separate from language-server navigation.
  local gotodef = {}
  do
    local cache_dir = vim.fn.stdpath 'data' .. '/gd-real-source'
    vim.fn.mkdir(cache_dir, 'p')

    -- Swift module -> GitHub "owner/repo". Only the modules whose `gd` lands in a
    -- .swiftinterface in practice; anything not here simply falls through.
    local swift_module_repos = {
      Swift = 'swiftlang/swift',
      _Concurrency = 'swiftlang/swift',
      Foundation = 'swiftlang/swift-corelibs-foundation',
      Dispatch = 'swiftlang/swift-corelibs-libdispatch',
    }

    -- Is this resolved definition URI a stub we can do better than?
    local function stub_kind(path)
      if path:match '%.swiftinterface$' then return 'swift' end
      -- Disabled: react-native ships .js source, not .ts, so this branch searched
      -- for a file that isn't there and never resolved. It cost a couple of
      -- seconds of unauthenticated GitHub round trips on every cold `gd` and
      -- landed on the same file it would have reached anyway, so nothing is lost
      -- by skipping it. Re-enabling is this one line, plus teaching the search to
      -- look for `.js` -- see t2 (goto-def stub fallback) in roadmap.md.
      -- if path:match '%.d%.ts$' and path:match '/node_modules/' then return 'ts' end
      return nil
    end

    local function has_curl() return vim.fn.executable 'curl' == 1 end

    -- Async GET a URL to `dest`. Calls cb(true) on HTTP 200 + non-empty file,
    -- cb(false) otherwise. Never blocks (no :wait()).
    local function fetch(url, dest, cb)
      if not has_curl() then return cb(false) end
      -- -f: fail (non-zero exit) on HTTP >= 400; -s silent; -L follow redirects.
      vim.system({ 'curl', '-fsSL', '-o', dest, url }, { text = true }, function(result)
        vim.schedule(function()
          local ok = result.code == 0 and (vim.uv.fs_stat(dest) or { size = 0 }).size > 0
          if not ok then pcall(vim.uv.fs_unlink, dest) end
          cb(ok)
        end)
      end)
    end

    -- Fetch a text URL and hand its body to cb(body|nil). Uses a temp file so we
    -- reuse the same curl path.
    local function fetch_body(url, cb)
      local tmp = vim.fn.tempname()
      fetch(url, tmp, function(ok)
        if not ok then return cb(nil) end
        local rok, lines = pcall(vim.fn.readfile, tmp)
        pcall(vim.uv.fs_unlink, tmp)
        cb(rok and table.concat(lines, '\n') or nil)
      end)
    end

    -- Deterministic on-disk cache path for a (repo, ref, path) triple, keyed by
    -- hash so it is filesystem-safe and collision-resistant, with the real
    -- basename preserved so the buffer keeps a sensible name + filetype.
    local function cache_path(repo, ref, path)
      local key = repo .. '@' .. ref .. ':' .. path
      local hash = vim.fn.sha256(key):sub(1, 16)
      return cache_dir .. '/' .. hash .. '-' .. vim.fn.fnamemodify(path, ':t')
    end

    -- Open a fetched file read-only (it is upstream source we should not edit).
    -- `origin` is the window/cursor context captured when the request started; if
    -- the user has since moved to a different window we open in a split instead of
    -- stomping whatever they switched to. `word` (optional) is searched for so the
    -- cursor lands near the symbol rather than at line 1.
    local function open_file(file, origin, word)
      -- If the user is no longer in the window they invoked `gd` from, don't
      -- hijack their current window -- open the source in a new split.
      if origin and vim.api.nvim_get_current_win() ~= origin.win then
        vim.cmd('split ' .. vim.fn.fnameescape(file))
      else
        vim.cmd.edit(vim.fn.fnameescape(file))
      end
      vim.bo.readonly = true
      vim.bo.modifiable = false
      -- Best-effort: place the cursor on the first line mentioning the symbol.
      if word and word ~= '' then
        local lines = vim.api.nvim_buf_get_lines(0, 0, -1, false)
        local pat = '%f[%w_]' .. vim.pesc(word) .. '%f[^%w_]'
        for i, l in ipairs(lines) do
          if l:find(pat) then
            pcall(vim.api.nvim_win_set_cursor, 0, { i, 0 })
            vim.cmd 'normal! zz'
            break
          end
        end
      end
    end

    -- Fetch repo/ref/path to cache (if not already cached) and open it.
    -- `origin` (window context) and `word` (symbol) are forwarded to open_file.
    -- Falls through via on_miss() on any failure.
    local function fetch_and_open(repo, ref, path, on_miss, origin, word)
      local dest = cache_path(repo, ref, path)
      if (vim.uv.fs_stat(dest) or { size = 0 }).size > 0 then return open_file(dest, origin, word) end
      local url = ('https://raw.githubusercontent.com/%s/%s/%s'):format(repo, ref, path)
      fetch(url, dest, function(ok)
        if ok then
          open_file(dest, origin, word)
        else
          on_miss()
        end
      end)
    end

    -- Locate a file inside a repo/ref by basename, via one Trees API call
    -- (recursive listing). Result list is cached on disk per repo+ref. Calls
    -- cb(path|nil).
    local function find_in_repo(repo, ref, basename, cb)
      local tree_cache = cache_dir .. '/tree-' .. vim.fn.sha256(repo .. '@' .. ref):sub(1, 16) .. '.txt'

      local function search(lines)
        -- Prefer an exact basename match; the API path is repo-relative.
        for _, p in ipairs(lines) do
          if vim.fn.fnamemodify(p, ':t') == basename then return cb(p) end
        end
        cb(nil)
      end

      local rok, cached = pcall(vim.fn.readfile, tree_cache)
      if rok and #cached > 0 then return search(cached) end

      local url = ('https://api.github.com/repos/%s/git/trees/%s?recursive=1'):format(repo, ref)
      fetch_body(url, function(body)
        if not body then return cb(nil) end
        local dok, decoded = pcall(vim.json.decode, body)
        if not dok or type(decoded) ~= 'table' or not decoded.tree then return cb(nil) end
        -- GitHub silently truncates large recursive trees (swiftlang/swift hits
        -- this) and flags it only via `truncated`. A partial listing that gets
        -- cached would permanently omit real files, so treat truncation as a miss:
        -- don't cache it, and fall through (search a partial list is unsafe, since
        -- a "not found" could just be an omitted entry).
        if decoded.truncated == true then return cb(nil) end
        local paths = {}
        for _, entry in ipairs(decoded.tree) do
          if entry.type == 'blob' and entry.path then table.insert(paths, entry.path) end
        end
        pcall(vim.fn.writefile, paths, tree_cache)
        search(paths)
      end)
    end

    -- Swift: read the module name out of the .swiftinterface header, map it to a
    -- repo, find the file whose basename matches the symbol type, open it.
    local function resolve_swift(iface_path, on_miss, origin, sym)
      local rok, lines = pcall(vim.fn.readfile, iface_path, '', 40)
      if not rok then return on_miss() end
      -- sourcekit emits a header line like:  swift-module-flags: -module-name Swift ...
      -- and/or:  // swift-interface-format-version / import lines. Grab -module-name.
      local module
      for _, l in ipairs(lines) do
        module = l:match '%-module%-name%s+([%w_]+)'
        if module then break end
      end
      local repo = module and swift_module_repos[module]
      if not repo then return on_miss() end

      -- The symbol under the cursor gives us the type/file name to look for.
      -- stdlib core files are named after their type (Array.swift, String.swift).
      if not sym or sym == '' then return on_miss() end
      local ref = 'main'
      find_in_repo(repo, ref, sym .. '.swift', function(path)
        if not path then return on_miss() end
        fetch_and_open(repo, ref, path, on_miss, origin, sym)
      end)
    end

    -- DEAD CODE, kept on purpose: stub_kind() above no longer returns 'ts' (see
    -- its comment for why), so find_package_json/repo_from_package/resolve_ts
    -- below are unreachable. Do not remove them as unused -- they are the
    -- starting point for t2 (goto-def stub fallback) in roadmap.md.
    --
    -- TS/JS: walk up from the .d.ts to the owning package.json, read repository +
    -- version, resolve the GitHub repo, then find the .ts source by basename.
    local function find_package_json(start_path)
      local dir = vim.fn.fnamemodify(start_path, ':h')
      while dir and dir ~= '/' and dir ~= '' do
        local pkg = dir .. '/package.json'
        if vim.uv.fs_stat(pkg) then return pkg, dir end
        local parent = vim.fn.fnamemodify(dir, ':h')
        if parent == dir then break end
        dir = parent
      end
    end

    -- Normalize the many `repository` shapes npm allows into "owner/repo".
    local function repo_from_package(pkg)
      local rok, lines = pcall(vim.fn.readfile, pkg)
      if not rok then return nil, nil end
      local dok, data = pcall(vim.json.decode, table.concat(lines, '\n'))
      if not dok or type(data) ~= 'table' then return nil, nil end

      local repo_field = data.repository
      local url
      if type(repo_field) == 'string' then
        url = repo_field
      elseif type(repo_field) == 'table' then
        url = repo_field.url
      end
      if type(url) ~= 'string' then return nil, data.version end

      -- Handles git+https://github.com/owner/repo.git, git@github.com:owner/repo,
      -- github:owner/repo, and bare owner/repo shorthands.
      local owner, name = url:match 'github%.com[:/]([%w%-_%.]+)/([%w%-_%.]+)'
      if not owner then owner, name = url:match '^github:([%w%-_%.]+)/([%w%-_%.]+)' end
      if not owner then owner, name = url:match '^([%w%-_%.]+)/([%w%-_%.]+)$' end
      if not owner then return nil, data.version end
      name = name:gsub('%.git$', '')
      return owner .. '/' .. name, data.version
    end

    local function resolve_ts(dts_path, on_miss, origin, sym)
      local pkg = find_package_json(dts_path)
      if not pkg then return on_miss() end
      local repo, version = repo_from_package(pkg)
      if not repo then return on_miss() end
      -- Prefer the published version as a tag (v1.2.3 or 1.2.3), fall back to HEAD.
      if not sym or sym == '' then return on_miss() end

      local function try_ref(ref, next_ref)
        find_in_repo(repo, ref, sym .. '.ts', function(path)
          if path then return fetch_and_open(repo, ref, path, on_miss, origin, sym) end
          if next_ref then return next_ref() end
          on_miss()
        end)
      end

      if version and version ~= '' then
        try_ref('v' .. version, function() try_ref(version, function() try_ref('main', function() try_ref('master', on_miss) end) end) end)
      else
        try_ref('main', function() try_ref('master', on_miss) end)
      end
    end

    -- Entry point bound to the keymap. Runs its own definition request so it can
    -- inspect the resolved URI *before* deciding stub-vs-normal. `fallback` is
    -- exactly today's behavior (the telescope picker).
    --
    -- Request/latency contract:
    --   * We request against ONE specific def-capable client (plus a single-shot
    --     guard), so the response/fallback logic runs EXACTLY ONCE regardless of
    --     how many clients are attached -- no double picker, no double fetch.
    --   * If NO attached client supports textDocument/definition, we fall through
    --     to `fallback()` immediately rather than silently no-op'ing.
    --   * Common (non-stub) path: for a SINGLE resolved location we jump directly
    --     ourselves using the result already in hand -- we do NOT call fallback()
    --     (which would fire a 2nd definition request). Only genuinely-multiple
    --     candidates hand off to fallback()'s picker for disambiguation. So the
    --     99% single-result case is one LSP round-trip, same as before.
    function gotodef.go(fallback)
      local bufnr = vim.api.nvim_get_current_buf()
      -- Capture the origin window + symbol synchronously, before any async work,
      -- so a later (async) buffer/window switch can't misdirect the jump.
      local origin = { win = vim.api.nvim_get_current_win(), buf = bufnr }
      local sym = vim.fn.expand '<cword>'

      -- Pick a single client that actually supports definition. If none do, the
      -- old builtin would have notified the user, so fall through to the picker
      -- rather than doing nothing.
      local client
      for _, c in ipairs(vim.lsp.get_clients { bufnr = bufnr }) do
        if c:supports_method('textDocument/definition', bufnr) then
          client = c
          break
        end
      end
      if not client then return fallback() end

      local params = vim.lsp.util.make_position_params(origin.win, client.offset_encoding or 'utf-8')
      local done = false
      client:request('textDocument/definition', params, function(err, result)
        if done then return end
        done = true
        if err or not result then return fallback() end

        -- Normalize to a list of locations.
        local list = result
        if not (vim.islist and vim.islist(result)) then list = { result } end
        if #list == 0 then return fallback() end

        local loc = list[1]
        if type(loc) == 'table' and loc[1] then loc = loc[1] end
        local uri = loc and (loc.uri or loc.targetUri)
        if type(uri) ~= 'string' then return fallback() end

        local path = vim.uri_to_fname(uri)
        local kind = stub_kind(path)

        if kind and has_curl() then
          -- Stub: try to fetch the real upstream source. Any miss -> fallback().
          if kind == 'swift' then
            return resolve_swift(path, fallback, origin, sym)
          else
            -- Unreachable: stub_kind() can no longer return 'ts' (see its
            -- comment), so kind is always 'swift' here. Kept for t2.
            return resolve_ts(path, fallback, origin, sym)
          end
        end

        -- Not a stub (or no curl). If there are multiple candidates, hand off to
        -- the telescope picker for disambiguation (that 2nd request is warranted).
        -- For a single candidate, jump directly with the result we already have --
        -- no second LSP round-trip.
        if #list > 1 then return fallback() end
        vim.lsp.util.show_document(loc, client.offset_encoding or 'utf-8', { focus = true })
      end, bufnr)
    end
  end

  vim.api.nvim_create_user_command('SwiftSource', function()
    gotodef.go(builtin.lsp_definitions)
  end, { desc = 'Browse upstream Swift implementation source', force = true })

  -- Add Telescope-based LSP pickers when an LSP attaches to a buffer.
  -- If you later switch picker plugins, this is where to update these mappings.
  vim.api.nvim_create_autocmd('LspAttach', {
    group = vim.api.nvim_create_augroup('telescope-lsp-attach', { clear = true }),
    callback = function(event)
      local buf = event.buf

      -- Find references for the word under your cursor.
      vim.keymap.set('n', 'grr', builtin.lsp_references, { buffer = buf, desc = '[G]oto [R]eferences' })

      -- Jump to the implementation of the word under your cursor.
      -- Useful when your language has ways of declaring types without an actual implementation.
      vim.keymap.set('n', 'gri', builtin.lsp_implementations, { buffer = buf, desc = '[G]oto [I]mplementation' })

      vim.keymap.set('n', 'grd', builtin.lsp_definitions, { buffer = buf, desc = '[G]oto [D]efinition' })
      vim.keymap.set('n', 'gd', builtin.lsp_definitions, { buffer = buf, desc = '[G]oto [D]efinition' })

      -- Jump to the type of the word under your cursor.
      -- Useful when you're not sure what type a variable is and you want to see
      -- the definition of its *type*, not where it was *defined*.
      vim.keymap.set('n', 'grt', builtin.lsp_type_definitions, { buffer = buf, desc = '[G]oto [T]ype Definition' })
    end,
  })

end

-- ============================================================
-- SECTION 6: LSP
-- LSP keymaps, server configuration, Mason tools installations
-- ============================================================
do
  -- [[ LSP Configuration ]]
  -- Brief aside: **What is LSP?**
  --
  -- LSP is an initialism you've probably heard, but might not understand what it is.
  --
  -- LSP stands for Language Server Protocol. It's a protocol that helps editors
  -- and language tooling communicate in a standardized fashion.
  --
  -- In general, you have a "server" which is some tool built to understand a particular
  -- language (such as `gopls`, `lua_ls`, `rust_analyzer`, etc.). These Language Servers
  -- (sometimes called LSP servers, but that's kind of like ATM Machine) are standalone
  -- processes that communicate with some "client" - in this case, Neovim!
  --
  -- LSP provides Neovim with features like:
  --  - Go to definition
  --  - Find references
  --  - Autocompletion
  --  - Symbol Search
  --  - and more!
  --
  -- Thus, Language Servers are external tools that must be installed separately from
  -- Neovim. This is where `mason` and related plugins come into play.
  --
  -- If you're wondering about lsp vs treesitter, you can check out the wonderfully
  -- and elegantly composed help section, `:help lsp-vs-treesitter`

  -- Useful status updates for LSP.
  vim.pack.add { gh 'j-hui/fidget.nvim' }
  require('fidget').setup {}

  -- The "quick fix" -- code actions for the whole LINE the cursor sits on.
  --
  -- The line-wide RANGE is load-bearing: a cursor-cell request drops any
  -- fix whose diagnostic doesn't contain the cursor COLUMN (nvim's
  -- `diagnostic_contains_cursor` filter, and ts_ls's server-side overlap
  -- check), which reads as "no quick fix here" from the indent. The PICKER
  -- is tiny-code-action because vim.ui.select is structurally title-only --
  -- the protocol has no preview hook -- while this renders the same
  -- telescope UI with a per-action diff, isPreferred first.
  local is_tiny_code_action_ready = false
  local function ensure_tiny_code_action()
    if not is_tiny_code_action_ready then
      vim.pack.add { gh 'rachartier/tiny-code-action.nvim' }
      require('tiny-code-action').setup {
        picker = 'telescope',
        backend = vim.fn.executable 'delta' == 1 and 'delta' or 'vim',
      }
      is_tiny_code_action_ready = true
    end
    return require 'tiny-code-action'
  end

  local function quick_fix()
    if #vim.lsp.get_clients { bufnr = 0, method = 'textDocument/codeAction' } == 0 then
      vim.notify('No language server is attached here, so there are no quick fixes to offer', vim.log.levels.WARN)
      return
    end
    -- A visual selection is already an explicit range; only normal mode
    -- needs the line widened for it.
    local mode = vim.api.nvim_get_mode().mode
    if mode == 'v' or mode == 'V' then return ensure_tiny_code_action().code_action {} end
    local row = vim.api.nvim_win_get_cursor(0)[1]
    ensure_tiny_code_action().code_action { range = require('config.code_action_range').get(0, row) }
  end

  -- Gutter lightbulb marking where a code action exists. First LspAttach
  -- loads it: no server, no startup cost.
  vim.api.nvim_create_autocmd('LspAttach', {
    group = vim.api.nvim_create_augroup('config-lightbulb', { clear = true }),
    desc = 'Load nvim-lightbulb once a language server attaches',
    once = true,
    callback = function()
      vim.pack.add { gh 'kosayoda/nvim-lightbulb' }
      require('nvim-lightbulb').setup { autocmd = { enabled = true } }
    end,
  })

  vim.keymap.set({ 'n', 'x' }, '<C-.>', quick_fix, { desc = 'Code action -- quick fix for this line' })

  -- Save rename edits without writing work that was already unsaved.
  local function install_rename_writeback()
    -- `:Reload` re-sources this file, so a closure-local "already installed"
    -- flag resets and the next LspAttach wraps our own wrapper -- N reloads, N
    -- redundant write loops, N duplicate warnings per rename. Both the handler
    -- being wrapped AND the wrapper live in globals, which survive `:source`,
    -- which makes three cases tellable apart:
    --   * the handler is our own wrapper -- a reload; rebuild around the same
    --     base so edits to this code take effect and the chain stays one deep;
    --   * nothing installed yet -- take what is there as the base;
    --   * someone else wrapped or replaced us since -- leave it alone. Blindly
    --     re-wrapping the stashed base would drop their wrapper on the floor.
    local current = vim.lsp.handlers['textDocument/rename']
    local ours = current == _G.kickstart_rename_writeback
    if _G.kickstart_rename_handler and not ours then return end
    _G.kickstart_rename_handler = ours and _G.kickstart_rename_handler or current
    local base = _G.kickstart_rename_handler
    local writeback
    writeback = function(err, result, ctx)
      -- A null result is the ordinary "can't rename that symbol" answer, and
      -- there is nothing to write; the default handler says so out loud.
      if not result then return base(err, result, ctx) end

      -- Only the files the edit actually named -- never the user's other dirty
      -- buffers. `documentChanges` takes precedence over `changes`, matching the
      -- order `apply_workspace_edit` applies them in; the create/rename/delete
      -- file ops carry no `textDocument` and it already did those on disk.
      for _, change in ipairs(result.documentChanges or {}) do
        if change.kind == 'rename' then
          for _, buf in ipairs(vim.api.nvim_list_bufs()) do
            if vim.bo[buf].modified then
              local uri = vim.uri_from_bufnr(buf)
              for _, resource in ipairs { change.oldUri, change.newUri } do
                if uri == resource or vim.startswith(uri, resource .. '/') then
                  vim.notify('Save unsaved work before renaming files: ' .. vim.api.nvim_buf_get_name(buf), vim.log.levels.WARN)
                  return
                end
              end
            end
          end
        end
      end
      local uris = {}
      if result.documentChanges then
        for _, change in ipairs(result.documentChanges) do
          if change.textDocument then uris[#uris + 1] = change.textDocument.uri end
        end
      else
        for uri in pairs(result.changes or {}) do uris[#uris + 1] = uri end
      end

      -- Sampled BEFORE the edit lands, because afterwards every one of them is
      -- modified. A file you already had unsaved work in is yours to save --
      -- writing it would push half-typed lines to disk behind your back -- and
      -- skipping it still leaves the rename in the buffer for your own `:w`.
      --
      local yours = {}
      for _, uri in ipairs(uris) do yours[uri] = vim.bo[vim.uri_to_bufnr(uri)].modified end

      base(err, result, ctx)

      local unwritten = {}
      for _, uri in ipairs(uris) do
        local buf = vim.uri_to_bufnr(uri)
        -- No `buftype` guard, and no `nvim_buf_is_loaded` one either: neither an
        -- unloaded buffer nor a `nofile`/`nowrite` scratch ever reports
        -- `modified`, so both would be branches nothing could ever make fail.
        -- What a `buftype` test WOULD change is `acwrite`, where a plugin owns
        -- the write through `BufWriteCmd` -- and handing it the write is right.
        if not yours[uri] and vim.bo[buf].modified then
          -- `silent` keeps a 30-file rename from printing 30 "written" lines.
          -- The pcall is for a write that RAISES (E212 on a `jdt://`-style URI);
          -- a readonly file is quieter than that -- `:write` no-ops and raises
          -- nothing -- so `modified` after the write is the only honest answer.
          --
          -- Except for `acwrite`, where a plugin's `BufWriteCmd` did the writing
          -- and plenty of them never clear `modified`. There, "the write did not
          -- raise" is the only confirmation on offer, and insisting on
          -- `modified` reports a failure over a file that is on disk.
          local wrote = pcall(vim.api.nvim_buf_call, buf, function() vim.cmd.write { mods = { silent = true } } end)
          if not wrote or (vim.bo[buf].modified and vim.bo[buf].buftype ~= 'acwrite') then unwritten[#unwritten + 1] = vim.uri_to_fname(uri) end
        end
      end
      if #unwritten > 0 then vim.notify('Renamed, but could not write:\n' .. table.concat(unwritten, '\n'), vim.log.levels.WARN) end
    end
    _G.kickstart_rename_writeback = writeback
    vim.lsp.handlers['textDocument/rename'] = writeback
  end

  --  This function gets run when an LSP attaches to a particular buffer.
  --    That is to say, every time a new file is opened that is associated with
  --    an lsp (for example, opening `main.rs` is associated with `rust_analyzer`) this
  --    function will be executed to configure the current buffer
  vim.api.nvim_create_autocmd('LspAttach', {
    group = vim.api.nvim_create_augroup('kickstart-lsp-attach', { clear = true }),
    callback = function(event)
      -- NOTE: Remember that Lua is a real programming language, and as such it is possible
      -- to define small helper and utility functions so you don't have to repeat yourself.
      --
      -- In this case, we create a function that lets us more easily define mappings specific
      -- for LSP related items. It sets the mode, buffer and description for us each time.
      local map = function(keys, func, desc, mode)
        mode = mode or 'n'
        vim.keymap.set(mode, keys, func, { buffer = event.buf, desc = 'LSP: ' .. desc })
      end

      -- Rename the variable under your cursor.
      --  Most Language Servers support renaming across files, etc. -- the
      --  writeback installed here is what makes those other files persist.
      --  Installed on attach, not at startup, so it costs nothing to launch.
      install_rename_writeback()
      map('grn', vim.lsp.buf.rename, '[R]e[n]ame')

      -- WARN: This is not Goto Definition, this is Goto Declaration.
      --  For example, in C this would take you to the header.
      map('grD', vim.lsp.buf.declaration, '[G]oto [D]eclaration')

      -- The following two autocommands are used to highlight references of the
      -- word under your cursor when your cursor rests there for a little while.
      --    See `:help CursorHold` for information about when this is executed
      --
      -- When you move your cursor, the highlights will be cleared (the second autocommand).
      local client = vim.lsp.get_client_by_id(event.data.client_id)
      if client and client:supports_method('textDocument/documentHighlight', event.buf) then
        local highlight_augroup = vim.api.nvim_create_augroup('kickstart-lsp-highlight', { clear = false })
        vim.api.nvim_create_autocmd({ 'CursorHold', 'CursorHoldI' }, {
          buffer = event.buf,
          group = highlight_augroup,
          callback = vim.lsp.buf.document_highlight,
        })

        vim.api.nvim_create_autocmd({ 'CursorMoved', 'CursorMovedI' }, {
          buffer = event.buf,
          group = highlight_augroup,
          callback = vim.lsp.buf.clear_references,
        })

        vim.api.nvim_create_autocmd('LspDetach', {
          group = vim.api.nvim_create_augroup('kickstart-lsp-detach', { clear = true }),
          callback = function(event2)
            vim.lsp.buf.clear_references()
            vim.api.nvim_clear_autocmds { group = 'kickstart-lsp-highlight', buffer = event2.buf }
          end,
        })
      end

    end,
  })

  -- Enable the following language servers
  --  Feel free to add/remove any LSPs that you want here. They will automatically be installed.
  --  See `:help lsp-config` for information about keys and how to configure
  ---@type table<string, vim.lsp.Config>
  local servers = {
    -- clangd = {},
    -- gopls = {},
    -- pyright = {},
    --
    -- Some languages (like typescript) have entire language plugins that can be useful:
    --    https://github.com/pmizio/typescript-tools.nvim
    --
    -- But for many setups, the LSP (`ts_ls`) will work just fine
    ts_ls = {},

    -- ESLint reads the project's own config and its own installed eslint, so it
    -- is inert in a repo that doesn't lint. Nothing to configure here.
    eslint = {},

    -- Special Lua Config, as recommended by neovim help docs
    lua_ls = {
      on_init = function(client)
        client.server_capabilities.documentFormattingProvider = false -- Disable formatting (formatting is done by stylua)

        if client.workspace_folders then
          local path = client.workspace_folders[1].name
          if path ~= vim.fn.stdpath 'config' and (vim.uv.fs_stat(path .. '/.luarc.json') or vim.uv.fs_stat(path .. '/.luarc.jsonc')) then return end
        end

        client.config.settings.Lua = vim.tbl_deep_extend('force', client.config.settings.Lua, {
          runtime = {
            version = 'LuaJIT',
            path = { 'lua/?.lua', 'lua/?/init.lua' },
          },
          workspace = {
            checkThirdParty = false,
            -- NOTE: this is a lot slower and will cause issues when working on your own configuration.
            --  See https://github.com/neovim/nvim-lspconfig/issues/3189
            library = vim.tbl_extend('force', vim.api.nvim_get_runtime_file('', true), {
              '${3rd}/luv/library',
              '${3rd}/busted/library',
            }),
          },
        })
      end,
      ---@type lspconfig.settings.lua_ls
      settings = {
        Lua = {
          format = { enable = false }, -- Disable formatting (formatting is done by stylua)
        },
      },
    },
  }

  vim.pack.add {
    gh 'neovim/nvim-lspconfig',
    gh 'mason-org/mason.nvim',
    gh 'mason-org/mason-lspconfig.nvim',
    gh 'WhoIsSethDaniel/mason-tool-installer.nvim',
  }

  -- Automatically install LSPs and related tools to stdpath for Neovim
  require('mason').setup {}

  -- Ensure the servers and tools above are installed
  --
  -- To check the current status of installed tools and/or manually install
  -- other tools, you can run
  --    :Mason
  --
  -- You can press `g?` for help in this menu.
  local ensure_installed = vim.tbl_keys(servers or {})
  vim.list_extend(ensure_installed, {
    -- You can add other tools here that you want Mason to install
    'prettier',
    'stylua',
  })

  -- SwiftFormat (SECTION 7) and SwiftLint (SECTION 22) are published as prebuilt
  -- binaries for Apple Silicon and glibc Linux only -- there is no Windows and
  -- no `darwin_x64` asset for either. Mason matches on that target triple, not
  -- on OS family, so asking for them anywhere else raises "The current platform
  -- is unsupported" and takes the whole install run down with it. Hence the
  -- arch check and not just a platform one: on an Intel Mac, `brew install
  -- swiftformat swiftlint` instead and the rest of the config is unaffected.
  if is_mac and vim.uv.os_uname().machine == 'arm64' then vim.list_extend(ensure_installed, { 'swiftformat', 'swiftlint' }) end

  require('mason-tool-installer').setup { ensure_installed = ensure_installed }

  for name, server in pairs(servers) do
    vim.lsp.config(name, server)
    vim.lsp.enable(name)
  end

  -- Swift, via sourcekit-lsp, is configured outside the `servers`/mason table above.
  -- Mason does not package sourcekit-lsp -- it ships with Xcode -- so it must not go
  -- through mason-tool-installer's `ensure_installed`. nvim-lspconfig's default
  -- `cmd = { 'sourcekit-lsp' }` works as-is as long as Xcode's command line tools are
  -- installed (check with `which sourcekit-lsp`).
  -- On Linux it comes from the swiftly toolchain instead. swiftly's bin dir is only
  -- on PATH once its env.sh is sourced, so a nvim started outside that shell would
  -- silently get no Swift LSP -- fall back to the bin dir directly.
  local swiftly_sourcekit = vim.fn.expand '~/.local/share/swiftly/bin/sourcekit-lsp'
  local sourcekit_cmd = 'sourcekit-lsp'
  if vim.fn.executable(sourcekit_cmd) == 0 and vim.fn.executable(swiftly_sourcekit) == 1 then sourcekit_cmd = swiftly_sourcekit end
  vim.lsp.config('sourcekit', { cmd = { sourcekit_cmd } })
  vim.lsp.enable('sourcekit')

  -- Rust, via rustup's own rust-analyzer, is also outside the mason table, and
  -- for a sharper reason than sourcekit: rustup ships a rust-analyzer that is
  -- version-matched to the active toolchain, and the proc-macro server ABI is
  -- NOT stable across releases -- a mason copy can silently stop expanding
  -- macros after a `rustup update`, and would shadow ~/.cargo/bin on PATH
  -- besides. nvim-lspconfig's default `cmd = { 'rust-analyzer' }` finds the
  -- rustup binary as-is (check with `which rust-analyzer`; install with
  -- `rustup component add rust-analyzer`).
  -- Arch's `rustup` package does NOT put a rust-analyzer proxy in /usr/bin (only
  -- cargo/rustc/etc.); it lives in /usr/lib/rustup/bin, which isn't on PATH. Use it
  -- directly when present, so we never fall back to a stray mason copy or nothing.
  local rustup_ra = '/usr/lib/rustup/bin/rust-analyzer'
  vim.lsp.config('rust_analyzer', {
    cmd = { vim.fn.executable(rustup_ra) == 1 and rustup_ra or 'rust-analyzer' },
  })
  vim.lsp.enable('rust_analyzer')
end

-- ============================================================
-- SECTION 7: FORMATTING
-- conform.nvim setup and keymap
-- ============================================================
do
  -- [[ Formatting ]]
  vim.pack.add { gh 'stevearc/conform.nvim' }
  require('conform').setup {
    notify_on_error = true,
    format_on_save = function(bufnr)
      -- You can specify filetypes to autoformat on save here:
      local enabled_filetypes = {
        -- lua = true,
        -- python = true,
      }
      if enabled_filetypes[vim.bo[bufnr].filetype] then
        return { timeout_ms = 500 }
      else
        return nil
      end
    end,
    default_format_opts = {
      lsp_format = 'fallback', -- Use external formatters if configured below, otherwise use LSP formatting. Set to `false` to disable LSP formatting entirely.
    },
    -- You can also specify external formatters in here.
    formatters_by_ft = {
      -- rust is deliberately absent: rust-analyzer's LSP formatting already
      -- shells out to rustfmt with the crate's edition from Cargo.toml, and
      -- `lsp_format = 'fallback'` above routes <leader>f there.
      -- Conform can also run multiple formatters sequentially
      -- python = { "isort", "black" },
      --
      -- You can use 'stop_after_first' to run the first available formatter from the list
      -- javascript = { "prettierd", "prettier", stop_after_first = true },
      lua = { 'stylua' },
      javascript = { 'prettier' },
      javascriptreact = { 'prettier' },
      typescript = { 'prettier' },
      typescriptreact = { 'prettier' },
      json = { 'prettier' },
      css = { 'prettier' },
      html = { 'prettier' },
      markdown = { 'prettier' },
      yaml = { 'prettier' },
      swift = { 'swiftformat' },
      dart = { 'dart_format' }, -- ships inside the Flutter SDK, so Mason has nothing to install
    },
  }

  vim.keymap.set({ 'n', 'v' }, '<leader>f', function() require('conform').format { async = true } end, { desc = '[F]ormat buffer' })
end

-- ============================================================
-- SECTION 8: AUTOCOMPLETE & SNIPPETS
-- blink.cmp and luasnip setup
-- ============================================================
do
  -- [[ Snippet Engine ]]

  -- NOTE: You can also specify plugin using a version range for its git tag.
  --  See `:help vim.version.range()` for more info
  vim.pack.add { { src = gh 'L3MON4D3/LuaSnip', version = vim.version.range '2.*' } }
  require('luasnip').setup {}

  -- `friendly-snippets` contains a variety of premade snippets.
  --    See the README about individual language/framework/plugin snippets:
  --    https://github.com/rafamadriz/friendly-snippets
  --
  -- vim.pack.add { gh 'rafamadriz/friendly-snippets' }
  -- require('luasnip.loaders.from_vscode').lazy_load()

  -- [[ Autocomplete Engine ]]
  vim.pack.add { { src = gh 'saghen/blink.cmp', version = vim.version.range '1.*' } }

  -- [[ Quick fixes inside the completion menu ]]
  -- Xcode-style insert-mode <C-.> (SECTION 6 owns the normal-mode twin):
  -- the menu opens with the line's quick fixes ranked above completions.
  -- Seeded into package.loaded because blink resolves sources via require()
  -- and this config is one file. insertText = '' keeps selection from
  -- previewing a title into the buffer, and execute never calls the default
  -- insertion -- accepting routes through vim.lsp.buf.code_action's own
  -- resolve/apply pipeline.
  local quickfix_source = {}
  quickfix_source.__index = quickfix_source

  function quickfix_source.new() return setmetatable({}, quickfix_source) end

  function quickfix_source:enabled() return #vim.lsp.get_clients { bufnr = 0, method = 'textDocument/codeAction' } > 0 end

  function quickfix_source:get_completions(ctx, callback)
    local bufnr = ctx.bufnr
    local row = ctx.cursor[1]
    local range = require('config.code_action_range').get(bufnr, row)
    local diagnostics = vim.diagnostic.get(bufnr, { lnum = row - 1 })

    vim.lsp.buf_request_all(bufnr, 'textDocument/codeAction', function(client)
      return {
        textDocument = { uri = vim.uri_from_bufnr(bufnr) },
        range = require('config.code_action_range').to_protocol(range, bufnr, client.offset_encoding),
        context = { diagnostics = vim.lsp.diagnostic.from(diagnostics), triggerKind = 1 },
      }
    end, function(results)
      local items = {}
      for _, res in pairs(results) do
        for _, action in ipairs(res.result or {}) do
          table.insert(items, {
            label = action.title,
            insertText = '',
            -- isPreferred first, quickfix-kind next: sort_text is the
            -- tiebreak blink consults when scores tie, as they do on the
            -- empty query <C-.> opens with.
            sortText = (action.isPreferred and '0' or (action.kind or ''):find '^quickfix' and '1' or '2') .. action.title,
            kind = vim.lsp.protocol.CompletionItemKind.Text,
            kind_name = 'QuickFix',
            kind_icon = '󰌵',
            data = { title = action.title, range = range },
          })
        end
      end
      callback { items = items, is_incomplete_forward = false, is_incomplete_backward = false }
    end)
  end

  function quickfix_source:execute(ctx, item, callback)
    vim.lsp.buf.code_action {
      range = item.data.range,
      filter = function(action) return action.title == item.data.title end,
      apply = true,
    }
    callback()
  end

  package.loaded['blink_quickfix_source'] = quickfix_source

  require('blink.cmp').setup {
    keymap = {
      -- 'default' (recommended) for mappings similar to built-in completions
      --   <c-y> to accept ([y]es) the completion.
      --    This will auto-import if your LSP supports it.
      --    This will expand snippets if the LSP sent a snippet.
      -- 'super-tab' for tab to accept
      -- 'enter' for enter to accept
      -- 'none' for no mappings
      --
      -- For an understanding of why the 'default' preset is recommended,
      -- you will need to read `:help ins-completion`
      --
      -- No, but seriously. Please read `:help ins-completion`, it is really good!
      --
      -- All presets have the following mappings:
      -- <tab>/<s-tab>: move to right/left of your snippet expansion
      -- <c-space>: Open menu or open docs if already open
      -- <c-n>/<c-p> or <up>/<down>: Select next/previous item
      -- <c-e>: Hide menu
      -- <c-k>: Toggle signature help
      --
      -- See `:help blink-cmp-config-keymap` for defining your own keymap
      preset = 'enter',

      -- <CR>: accept the selected suggestion, or fall through to a normal
      --   newline when the menu isn't showing one.
      -- <Esc>: dismiss the suggestion menu (falls through to normal <Esc>
      --   behavior, e.g. leaving insert mode, when the menu is already hidden).
      ['<Esc>'] = { 'hide', 'fallback' },

      -- <C-.> (the physical Cmd+.): open the menu with quick fixes on top.
      ['<C-.>'] = { function(cmp) return cmp.show { providers = { 'quickfix', 'lsp', 'path', 'snippets' } } end },

      -- For more advanced Luasnip keymaps (e.g. selecting choice nodes, expansion) see:
      --    https://github.com/L3MON4D3/LuaSnip?tab=readme-ov-file#keymaps
    },

    appearance = {
      -- 'mono' (default) for 'Nerd Font Mono' or 'normal' for 'Nerd Font'
      -- Adjusts spacing to ensure icons are aligned
      nerd_font_variant = 'mono',
    },

    completion = {
      documentation = { auto_show = true, auto_show_delay_ms = 200 },

      menu = {
        draw = {
          -- Treesitter-colored labels; mini.icons (SECTION 4) kind column.
          treesitter = { 'lsp' },
          components = vim.g.have_nerd_font and {
            kind_icon = {
              text = function(ctx) return (require('mini.icons').get('lsp', ctx.kind)) .. ctx.icon_gap end,
              highlight = function(ctx)
                local _, hl = require('mini.icons').get('lsp', ctx.kind)
                return hl
              end,
            },
          } or nil,
        },
      },
    },

    sources = {
      -- 'buffer' is fallback-gated: it only fills in when LSP and path come
      -- back empty, so LSP-attached buffers never see word-soup.
      default = { 'lsp', 'path', 'snippets', 'buffer' },
      providers = {
        -- Only reachable through the <C-.> show() above, never while typing;
        -- the score offset is what ranks the fixes above everything else.
        quickfix = { name = 'QuickFix', module = 'blink_quickfix_source', score_offset = 100 },
      },
    },

    snippets = { preset = 'luasnip' },

    -- The prebuilt rust matcher only auto-downloads because the vim.pack
    -- spec above pins a release tag ('1.*'); if that fails, blink warns
    -- once and falls back to Lua. 'exact' leads the sort order so a literal
    -- prefix outranks fuzzier matches.
    fuzzy = { implementation = 'prefer_rust_with_warning', sorts = { 'exact', 'score', 'sort_text' } },

    -- Shows a signature help window while you type arguments for a function
    signature = { enabled = true },
  }
end

-- ============================================================
-- SECTION 9: TREESITTER
-- Parser installation, syntax highlighting, folds, indentation
-- ============================================================
do
  -- [[ Configure Treesitter ]]
  --  Used to highlight, edit, and navigate code
  --
  --  See `:help nvim-treesitter-intro`

  -- NOTE: You can also specify a branch or a specific commit
  vim.pack.add { { src = gh 'nvim-treesitter/nvim-treesitter', version = 'main' } }

  -- Ensure basic parsers are installed
  local parsers =
    { 'bash', 'c', 'diff', 'html', 'lua', 'luadoc', 'markdown', 'markdown_inline', 'query', 'vim', 'vimdoc', 'swift', 'dart', 'javascript', 'typescript', 'tsx', 'json', 'yaml', 'rust', 'toml' }
  require('nvim-treesitter').install(parsers)

  -- mini.pairs auto-closes brackets and quotes on every filetype but has no
  -- concept of a tag, so typing `<View>` in a JSX/TSX buffer left no `</View>`
  -- behind. nvim-ts-autotag reads the tsx/jsx tree to close a tag as you type it
  -- and rename the pair as you edit either side. Its `>` remap is buffer-local to
  -- tag-aware filetypes, so `=>` and `Array<T>` are untouched, and Swift/Dart/Lua
  -- never see it.
  --
  -- It needs no nvim-ts-context-commentstring sibling: nvim-treesitter's own
  -- tsx/jsx highlight queries already set `commentstring` per node, so built-in
  -- `gc` emits `{/* ... */}` inside JSX with nothing extra configured. That
  -- lookup reads the node under ONE reference position, so keep the cursor on the
  -- tag: at column 0, or on a visual selection starting at the element's own
  -- opening line, there is no JSX node there and you get `//` instead.
  vim.pack.add { gh 'windwp/nvim-ts-autotag' }
  require('nvim-ts-autotag').setup {}

  ---@param buf integer
  ---@param language string
  local function treesitter_try_attach(buf, language)
    -- Check if a parser exists and load it
    if not vim.treesitter.language.add(language) then return end
    -- Enable syntax highlighting and other treesitter features
    vim.treesitter.start(buf, language)

    -- Enable treesitter based folds
    -- For more info on folds see `:help folds`
    -- vim.wo.foldexpr = 'v:lua.vim.treesitter.foldexpr()'
    -- vim.wo.foldmethod = 'expr'

    -- Check if treesitter indentation is available for this language, and if so enable it
    -- in case there is no indent query, the indentexpr will fallback to the vim's built in one
    local has_indent_query = vim.treesitter.query.get(language, 'indents') ~= nil

    -- Enable treesitter based indentation
    if has_indent_query then vim.bo.indentexpr = "v:lua.require'nvim-treesitter'.indentexpr()" end
  end

  local available_parsers = require('nvim-treesitter').get_available()
  vim.api.nvim_create_autocmd('FileType', {
    group = vim.api.nvim_create_augroup('config-treesitter', { clear = true }),
    callback = function(args)
      local buf, filetype = args.buf, args.match

      local language = vim.treesitter.language.get_lang(filetype)
      if not language then return end

      local installed_parsers = require('nvim-treesitter').get_installed 'parsers'

      if vim.tbl_contains(installed_parsers, language) then
        -- Enable the parser if it is already installed
        treesitter_try_attach(buf, language)
      elseif vim.tbl_contains(available_parsers, language) then
        -- If a parser is available in `nvim-treesitter`, auto-install it and enable it after the installation is done
        require('nvim-treesitter').install(language):await(function() treesitter_try_attach(buf, language) end)
      else
        -- Try to enable treesitter features in case the parser exists but is not available from `nvim-treesitter`
        treesitter_try_attach(buf, language)
      end
    end,
  })
end

-- ============================================================
-- SECTION 10: OPTIONAL EXAMPLES / NEXT STEPS
-- kickstart.plugins.* examples
-- ============================================================
do
  -- The following comments only work if you have downloaded the kickstart repo, not just copy pasted the
  -- init.lua. If you want these files, they are in the repository, so you can just download them and
  -- place them in the correct locations.

  -- NOTE: Next step on your Neovim journey: Add/Configure additional plugins for Kickstart
  --
  --  Here are some example plugins that I've included in the Kickstart repository.
  --  Uncomment any of the lines below to enable them (you will need to restart nvim).
  --
  -- require 'kickstart.plugins.debug'
  -- require 'kickstart.plugins.indent_line'
  -- require 'kickstart.plugins.lint'
  -- require 'kickstart.plugins.autopairs'
  -- require 'kickstart.plugins.neo-tree'
  -- require 'kickstart.plugins.gitsigns' -- adds gitsigns recommended keymaps

  -- NOTE: You can add your own plugins, configuration, etc from `lua/custom/plugins/*.lua`
  --
  --  Uncomment the following line and add your plugins to `lua/custom/plugins/*.lua` to get going.
  -- require 'custom.plugins'
end

-- ============================================================
-- SECTION 11: PERSONAL EXTRAS -- HARPOON
-- Quick file-list jumping, harpoon2 branch
-- ============================================================
do
  -- Use the maintained `harpoon2` branch, not `master` -- the old `harpoon.mark`/
  -- `harpoon.ui` modules from `master` are exactly what silently broke in the old
  -- packer-based config (never installed because packer was never even required).
  vim.pack.add { { src = gh 'ThePrimeagen/harpoon', version = 'harpoon2' } }
  require('harpoon'):setup()

  local harpoon = require 'harpoon'

  vim.keymap.set('n', '<leader>a', function() harpoon:list():add() end, { desc = '[A]dd file to Harpoon' })
  vim.keymap.set('n', '<C-e>', function() harpoon.ui:toggle_quick_menu(harpoon:list()) end, { desc = 'Toggle Harpoon quick menu' })

  vim.keymap.set('n', '<C-h>', function() harpoon:list():select(1) end, { desc = 'Harpoon to file 1' })
  vim.keymap.set('n', '<C-j>', function() harpoon:list():select(2) end, { desc = 'Harpoon to file 2' })
  vim.keymap.set('n', '<C-k>', function() harpoon:list():select(3) end, { desc = 'Harpoon to file 3' })
  vim.keymap.set('n', '<C-l>', function() harpoon:list():select(4) end, { desc = 'Harpoon to file 4' })
end

-- ============================================================
-- SECTION 12: PERSONAL EXTRAS -- UNDOTREE
-- Visualize and navigate the undo history tree
-- ============================================================
do
  vim.pack.add { gh 'mbbill/undotree' }

  -- No Ctrl chord: <C-z> is undo and <C-u> is half-page-up, so the toggle
  -- lives on <leader>u alone.
  vim.keymap.set('n', '<leader>u', vim.cmd.UndotreeToggle, { desc = 'Toggle [U]ndotree' })
end

-- ============================================================
-- SECTION 13: PERSONAL EXTRAS -- FUGITIVE
-- Full git porcelain (gitsigns above only does gutter/hunk-level work)
-- ============================================================
do
  vim.pack.add { gh 'tpope/vim-fugitive' }

  vim.keymap.set('n', '<leader>gh', vim.cmd.G, { desc = '[G]it status (fugitive)' })
  vim.keymap.set('n', '<leader>ga', function() vim.cmd.G 'add .' end, { desc = '[G]it [a]dd .' })
  vim.keymap.set('n', '<leader>gu', function() vim.cmd.G 'restore --staged .' end, { desc = '[G]it [u]nstage all' })
  vim.keymap.set('n', '<leader>gc', function() vim.cmd.G 'commit' end, { desc = '[G]it [c]ommit' })
  vim.keymap.set('n', '<leader>gp', function() vim.cmd.G 'push' end, { desc = '[G]it [p]ush' })
  vim.keymap.set('n', '<leader>gs', vim.cmd.G, { desc = '[G]it [s]tatus' })
  vim.keymap.set('n', '<leader>gl', function() vim.cmd.G 'log' end, { desc = '[G]it [l]og' })
end

-- ============================================================
-- SECTION 14: JUMP HISTORY
-- ============================================================
do
  vim.keymap.set('n', '<C-[>', '<C-o>zz', { desc = 'Back in jump history' })
  vim.keymap.set('n', '<C-]>', '<C-i>zz', { desc = 'Forward in jump history' })
  vim.api.nvim_create_autocmd('FileType', {
    group = vim.api.nvim_create_augroup('config-help-navigation', { clear = true }),
    pattern = 'help',
    callback = function(ev)
      vim.keymap.set('n', '<C-]>', '<C-]>', { buffer = ev.buf, desc = 'Follow help link' })
    end,
  })
end

-- ============================================================
-- SECTION 15: FILE EXPLORER (kickstart's optional neo-tree module, enabled)
-- ============================================================
do
  -- Neo-tree is a sidebar file-tree explorer. This is kickstart's own optional
  -- `kickstart.plugins.neo-tree` module (see the commented-out require in
  -- SECTION 10), inlined here since this config is a single file rather than
  -- kickstart's full multi-file repo layout.
  vim.pack.add {
    { src = gh 'nvim-neo-tree/neo-tree.nvim', version = vim.version.range '*' },
    gh 'nvim-lua/plenary.nvim',
    gh 'MunifTanjim/nui.nvim',
  }

  vim.keymap.set('n', '\\', '<Cmd>Neotree reveal<CR>', { desc = 'NeoTree reveal', silent = true })

  require('neo-tree').setup {
    filesystem = {
      window = {
        mappings = {
          ['\\'] = 'close_window',
        },
      },
    },
  }
end

-- ============================================================
-- SECTION 15.5: SMEAR CURSOR -- SMOOTH ANIMATED CURSOR ON MOTIONS
-- ============================================================
do
  vim.pack.add { { src = gh 'sphamba/smear-cursor.nvim' } }
  require('smear_cursor').setup {
    stiffness = 0.8,
    trailing_stiffness = 0.5,
    distance_stop_animating = 0.5,
    hide_target_hack = false,
  }
end

-- SECTION 16: EXPLICIT SAVING
-- ============================================================
vim.o.autoread = true
vim.keymap.set({ 'n', 'i', 'v' }, '<C-s>', '<cmd>wa<CR>', { desc = 'Save all files' })

-- ============================================================
-- SECTION 17: RELOAD CONFIG
-- ============================================================
do
  -- :Reload re-sources init.lua without restarting Neovim. :reload (lowercase)
  -- is accepted too, via a command-line abbreviation -- Neovim requires
  -- user-defined commands to start with an uppercase letter.
  --
  -- `:source` always reads from disk, not from the buffer's in-memory
  -- content -- so an edit that hasn't been saved yet reloads the OLD file
  -- with no visible change, which looks like :Reload silently did nothing.
  -- `:update` (a no-op if there's nothing to save) closes that gap.
  vim.api.nvim_create_user_command('Reload', function()
    vim.cmd.update()
    vim.cmd.source(vim.env.MYVIMRC)
    vim.notify('Reloaded ' .. vim.env.MYVIMRC, vim.log.levels.INFO)
  end, { desc = 'Reload init.lua' })
  vim.cmd.cnoreabbrev('reload Reload')
end

-- ============================================================
-- SECTION 18: PERSONAL EXTRAS -- AUTOSCROLL
-- ============================================================
do
  -- <leader>` toggles a slow, hands-free word-by-word walk of the current
  -- window (reading mode): the cursor advances one word at a time and the
  -- view follows it. While it's running, plain ` pauses/unpauses -- that
  -- mapping only exists for the duration of the session, so ` stays the
  -- normal go-to-mark prefix otherwise. It also pauses while the window
  -- isn't in Normal mode (so typing in Insert mode or selecting in Visual
  -- mode never fights the cursor), keeps walking the window it was started
  -- in even if you focus another split, and stops itself at the end of the
  -- buffer or when the window goes away.
  --
  -- Pace is words per second, adjustable live (even mid-session) with
  --   :Autoscroll speed 2.0
  -- (`:set` can't host custom options -- Vim only allows its own built-in
  -- option names there -- so a user command is the closest native shape.)
  local words_per_second = 10

  local function interval_ms() return math.floor(1000 / words_per_second) end

  local timer, scroll_win, paused

  local function stop(msg)
    if not timer then return end
    timer:stop()
    timer:close()
    timer, scroll_win, paused = nil, nil, nil
    pcall(vim.keymap.del, 'n', '`')
    if msg then vim.notify(msg) end
  end

  local function tick()
    if not timer then return end
    if not vim.api.nvim_win_is_valid(scroll_win) then return stop() end
    if paused then return end
    if vim.api.nvim_get_current_win() == scroll_win and vim.fn.mode() ~= 'n' then return end
    vim.api.nvim_win_call(scroll_win, function()
      -- `w` stops moving once the cursor sits on the buffer's last word --
      -- that's the end-of-buffer signal.
      local before = vim.api.nvim_win_get_cursor(0)
      vim.cmd 'normal! w'
      local after = vim.api.nvim_win_get_cursor(0)
      if before[1] == after[1] and before[2] == after[2] then return stop 'Autoscroll: reached end of buffer' end
    end)
  end

  local function pause_toggle()
    paused = not paused
    vim.notify(paused and 'Autoscroll paused' or 'Autoscroll resumed')
  end

  local function toggle()
    if timer then return stop 'Autoscroll off' end
    scroll_win = vim.api.nvim_get_current_win()
    paused = false
    vim.keymap.set('n', '`', pause_toggle, { desc = 'Autoscroll pause/unpause' })
    timer = assert(vim.uv.new_timer())
    timer:start(interval_ms(), interval_ms(), vim.schedule_wrap(tick))
    vim.notify 'Autoscroll on'
  end

  vim.keymap.set('n', '<leader>`', toggle, { desc = 'Autoscroll toggle' })

  vim.api.nvim_create_user_command('Autoscroll', function(opts)
    local sub, val = opts.fargs[1], opts.fargs[2]
    if sub ~= 'speed' then
      vim.notify('Usage: :Autoscroll speed <words-per-second>', vim.log.levels.WARN)
      return
    end
    if not val then
      vim.notify(('Autoscroll speed: %g words/sec'):format(words_per_second))
      return
    end
    local n = tonumber(val)
    if not n or n <= 0 then
      vim.notify('Autoscroll speed must be a positive number (words/sec)', vim.log.levels.ERROR)
      return
    end
    words_per_second = n
    -- Apply to a session already in flight, not just the next one.
    if timer then
      timer:stop()
      timer:start(interval_ms(), interval_ms(), vim.schedule_wrap(tick))
    end
    vim.notify(('Autoscroll speed: %g words/sec'):format(n))
  end, { nargs = '+', desc = 'Autoscroll settings (:Autoscroll speed <n>)', complete = function() return { 'speed' } end })
  vim.cmd.cnoreabbrev('autoscroll Autoscroll')
end

-- ============================================================
-- SECTION 19: PERSONAL EXTRAS -- MARKDOWN PREVIEW
-- ============================================================
do
  -- Render markdown (READMEs, notes) prettily in place: headings, lists,
  -- checkboxes, tables, and code blocks are drawn using the treesitter
  -- markdown parsers already installed above -- no browser, no build step.
  -- The buffer renders pretty in Normal mode and drops back to raw markdown
  -- for the line you're editing in Insert mode.
  vim.pack.add { gh 'MeanderingProgrammer/render-markdown.nvim' }
  require('render-markdown').setup {}

  vim.keymap.set('n', '<leader>tm', function() require('render-markdown').toggle() end, { desc = '[T]oggle [m]arkdown render' })
end

-- ============================================================
-- SECTION 20: PERSONAL EXTRAS -- STICKY SCOPE HEADERS
-- ============================================================
do
  -- Pin the lines that declare the scopes the cursor is inside (function,
  -- class/struct, if/for block, markdown heading, ...) to the top of the
  -- window as you scroll past them. Works in any filetype with a treesitter
  -- parser attached -- same parsers SECTION 9 already installs.
  vim.pack.add { gh 'nvim-treesitter/nvim-treesitter-context' }
  require('treesitter-context').setup {
    -- Cap how much of the window the pinned context may take, so deeply
    -- nested code doesn't bury the actual text under a wall of headers.
    max_lines = 4,
    -- Collapse each scope to its declaration line even if the declaration
    -- spans several (e.g. a long parameter list).
    multiline_threshold = 1,
  }

  vim.keymap.set('n', '<leader>tc', '<cmd>TSContext toggle<CR>', { desc = '[T]oggle sticky scope [c]ontext' })
end

-- ============================================================
-- SECTION 22: SWIFT / XCODE
-- ============================================================
if is_mac then
  -- xcodebuild.nvim finds its pickers in telescope (SECTION 5) and its floating
  -- coverage report in nui (added by neo-tree, SECTION 15); both are already on.
  vim.pack.add {
    gh 'wojciech-kulik/xcodebuild.nvim',
    gh 'mfussenegger/nvim-lint',
  }

  require('xcodebuild').setup {
    project_config = {
      search_in_parent_dirs = true,
      reload_on_cwd_change = true,
    },
    -- The plugin's own integration spawns `xcode-build-server config` from
    -- nvim's cwd, and `config` writes buildServer.json to the cwd -- launch
    -- nvim from a Flutter repo's root and the binding lands OUTSIDE ios/,
    -- where a second, stale copy then shadows the real one. Disabled in
    -- favour of the [[ sourcekit build server ]] hooks below, which pin every
    -- spawn to the project file's directory.
    integrations = {
      xcode_build_server = { enabled = false },
    },
  }

  local function map(keys, action, desc, mode) vim.keymap.set(mode or 'n', keys, action, { desc = desc }) end

  -- The which-key groups are registered here rather than alongside the others
  -- in SECTION 4, so that a Windows or Linux launch -- which skips this whole
  -- section -- doesn't show two prefixes that expand to nothing.
  require('which-key').add { { '<leader>x', group = 'X[c]ode', mode = { 'n', 'v' } } }

  -- `<leader>X` is the one bind worth memorizing: a picker listing every action
  -- below (and the ~50 more this config doesn't bind). The rest of the Xcode
  -- verbs hang off `<leader>x*`, following the plugin's own suggested bindings
  -- except for `<leader>xs`, which upstream gives to failing snapshots; setup
  -- is the thing you actually reach for, and per-project you reach for it once.
  map('<leader>X', '<cmd>XcodebuildPicker<CR>', 'Xcode: all actions')
  map('<leader>xs', '<cmd>XcodebuildSetup<CR>', 'Xcode: [S]etup project (file, scheme, device, test plan)')
  map('<leader>xb', '<cmd>XcodebuildBuild<CR>', 'Xcode: [B]uild')
  map('<leader>xr', '<cmd>XcodebuildBuildRun<CR>', 'Xcode: build & [R]un')
  map('<leader>xk', '<cmd>XcodebuildCancel<CR>', 'Xcode: [K]ill running action')
  map('<leader>xt', '<cmd>XcodebuildTest<CR>', 'Xcode: run [T]ests')
  map('<leader>xt', '<cmd>XcodebuildTestSelected<CR>', 'Xcode: run selected [T]ests', 'v')
  map('<leader>xT', '<cmd>XcodebuildTestClass<CR>', 'Xcode: run current [T]est class')
  map('<leader>xe', '<cmd>XcodebuildTestExplorerToggle<CR>', 'Xcode: toggle test [E]xplorer')
  map('<leader>xl', '<cmd>XcodebuildToggleLogs<CR>', 'Xcode: toggle build [L]ogs')
  map('<leader>xc', '<cmd>XcodebuildToggleCodeCoverage<CR>', 'Xcode: toggle [C]ode coverage marks')
  map('<leader>xC', '<cmd>XcodebuildShowCodeCoverageReport<CR>', 'Xcode: [C]overage report')
  map('<leader>xd', '<cmd>XcodebuildSelectDevice<CR>', 'Xcode: select [D]evice')
  map('<leader>xf', '<cmd>XcodebuildProjectManager<CR>', 'Xcode: project [F]ile manager')
  map('<leader>xo', '<cmd>XcodebuildOpenInXcode<CR>', 'Xcode: [O]pen this file in Xcode')

  -- [[ SwiftLint ]]
  -- The only linter in this config, hence the deliberately Swift-shaped setup:
  -- to lint another language, add a `linters_by_ft` row and its own autocmd.
  --
  -- The linter is named explicitly rather than resolved from `linters_by_ft`.
  -- `try_lint()` with no argument looks the linter up by the buffer's filetype,
  -- and on `BufReadPost` this autocmd runs BEFORE `filetypedetect` -- filetype
  -- is still empty, so the lookup finds nothing and lint-on-open silently does
  -- nothing. `linters_by_ft` is still set, for `:lua require('lint').try_lint()`
  -- and for anything else that reads it.
  --
  -- The executable check keeps the first launch quiet while Mason is still
  -- fetching swiftlint, instead of erroring on every write until it lands.
  require('lint').linters_by_ft = { swift = { 'swiftlint' } }
  vim.api.nvim_create_autocmd({ 'BufWritePost', 'BufReadPost', 'InsertLeave' }, {
    group = vim.api.nvim_create_augroup('swift-lint', { clear = true }),
    pattern = '*.swift', -- deliberately excludes the read-only `.swiftinterface` stubs SECTION 5 opens
    callback = function()
      if vim.fn.executable 'swiftlint' == 1 then require('lint').try_lint 'swiftlint' end
    end,
  })

  -- [[ sourcekit build server ]]
  -- An .xcodeproj tells sourcekit-lsp nothing by itself. The LSP needs two
  -- machine-specific, gitignored artifacts next to the project file: a
  -- `buildServer.json` binding it to xcode-build-server, and a `.compile` of
  -- per-file compile flags. Without them it still attaches -- and then answers
  -- every request with nothing, which reads as "LSP is dead" with no error
  -- anywhere. Because both artifacts are per-checkout, every fresh clone or
  -- worktree starts in that state. The three hooks below make a checkout
  -- self-healing: picking a scheme (re)binds, every successful build harvests
  -- flags, and an unbound Swift buffer says which step is missing.
  local build_server_group = vim.api.nvim_create_augroup('xcode-build-server', { clear = true })

  ---@param from string directory to search upward from
  ---@return string|nil root directory containing buildServer.json
  local function build_server_root(from)
    local found = vim.fs.find('buildServer.json', { path = from, upward = true })[1]
    return found and vim.fs.dirname(found) or nil
  end

  ---@param is_announced boolean notify with the next step once bound
  ---@return boolean whether a bind was attempted
  local function bind_build_server(is_announced)
    if vim.fn.executable 'xcode-build-server' == 0 then return false end
    local settings = require('xcodebuild.project.config').settings
    if not (settings.projectFile and settings.scheme and settings.workingDirectory) then return false end
    local flag = settings.projectFile:match '%.xcodeproj$' and '-project' or '-workspace'
    local scheme = settings.scheme
    local command = { 'xcode-build-server', 'config', flag, settings.projectFile, '-scheme', scheme }
    local derived_data = require('xcodebuild.core.xcode').find_derived_data_path(settings.productName or scheme, settings.projectFile)
    if derived_data then vim.list_extend(command, { '--build_root', derived_data }) end
    vim.system(
      command,
      { cwd = settings.workingDirectory },
      vim.schedule_wrap(function(out)
        if out.code ~= 0 then
          vim.notify('Build-server configuration failed: ' .. (out.stderr or out.stdout or ''), vim.log.levels.ERROR)
          return
        end
        require('xcodebuild.integrations.lsp').restart_sourcekit_lsp()
        if is_announced then vim.notify(('sourcekit bound to scheme %s -- one build (<leader>xb) feeds it flags'):format(scheme), vim.log.levels.INFO) end
      end)
    )
    return true
  end

  vim.api.nvim_create_autocmd('User', {
    pattern = 'XcodebuildProjectSettingsUpdated',
    group = build_server_group,
    desc = 'Rebind the sourcekit build server on scheme change',
    callback = function() bind_build_server(false) end,
  })

  -- `parse -a`, never plain `parse`: plain REPLACES `.compile`, so an
  -- incremental build -- which logs only what it recompiled, possibly nothing
  -- -- would wipe the accumulated flags. `-a` merges by file, so coverage only
  -- grows: targets and schemes accumulate across builds. It also resets `kind`
  -- to "manual" in buildServer.json, which is load-bearing: `config` above
  -- (re)binds with kind "xcode", a mode whose flags come from Xcode.app's own
  -- build logs -- logs a build from this editor never writes. The running
  -- server watches `.compile`'s mtime, so new flags land with no LSP restart.
  vim.api.nvim_create_autocmd('User', {
    pattern = 'XcodebuildBuildFinished',
    group = build_server_group,
    desc = 'Harvest sourcekit compile flags from the finished build',
    callback = function(event)
      if not (event.data and event.data.success) then return end
      if vim.fn.executable 'xcode-build-server' == 0 then return end
      local settings = require('xcodebuild.project.config').settings
      local root = build_server_root(settings.workingDirectory or vim.fn.getcwd())
      local log = require('xcodebuild.project.appdata').build_logs_filepath
      if not root or vim.fn.filereadable(log) == 0 then return end
      local is_first_flags = not vim.uv.fs_stat(vim.fs.joinpath(root, '.compile'))
      vim.system(
        { 'xcode-build-server', 'parse', '-a', log },
        { cwd = root },
        vim.schedule_wrap(function(out)
          if out.code ~= 0 then
            vim.notify('Build-server flag import failed: ' .. (out.stderr or out.stdout or ''), vim.log.levels.ERROR)
          elseif is_first_flags then
            vim.notify('sourcekit: compile flags harvested', vim.log.levels.INFO)
          end
        end)
      )
    end,
  })

  local nudged = {}
  vim.api.nvim_create_autocmd('FileType', {
    pattern = 'swift',
    group = build_server_group,
    desc = 'Bind or nudge when a Swift buffer has no build server',
    callback = function(event)
      local name = vim.api.nvim_buf_get_name(event.buf)
      if name == '' or name:match '%.swiftinterface$' then return end
      local dir = vim.fs.dirname(name)
      if build_server_root(dir) then return end
      -- SwiftPM packages and bare files serve their own flags; only an Xcode
      -- project is helpless without the binding.
      local project = vim.fs.find(
        function(n) return n:match '%.xcodeproj$' ~= nil or n:match '%.xcworkspace$' ~= nil end,
        { path = dir, upward = true, type = 'directory' }
      )[1]
      if not project or vim.fn.executable 'xcode-build-server' == 0 then return end
      if bind_build_server(true) then return end
      local project_dir = vim.fs.dirname(project)
      if nudged[project_dir] then return end
      nudged[project_dir] = true
      vim.notify('sourcekit has no build server here -- <leader>xs binds a scheme, then a build (<leader>xb) feeds it flags', vim.log.levels.WARN)
    end,
  })
end

-- SECTION 23: FLUTTER
-- ============================================================
do
  -- flutter-tools owns `dartls` itself, which is why Dart is absent from
  -- SECTION 6's `servers` table -- configuring it in both places would start two
  -- clients. Its picker UI is `vim.ui.select`, already routed through Telescope
  -- by SECTION 5, so the `dressing.nvim` its README suggests isn't needed here.
  vim.pack.add { gh 'nvim-flutter/flutter-tools.nvim' } -- plenary, its other dep, comes with telescope
  -- Resolve version-manager shims to the SDK that owns the analysis server.
  local lookup_cmd = vim.fn.executable 'asdf' == 1 and 'asdf where flutter' or nil

  require('flutter-tools').setup {
    flutter_lookup_cmd = lookup_cmd,
    ui = { border = 'rounded' },
    widget_guides = { enabled = true },
    closing_tags = { enabled = true, prefix = '// ' },
    lsp = {
      -- Deliberately not flutter-tools' own `color.enabled`: on 0.12 it warns at
      -- startup that plugin-managed document colors are deprecated in favour of
      -- `vim.lsp.document_color`, which the autocommand below turns on instead.
      settings = {
        renameFilesWithClasses = 'prompt',
        updateImportsOnRename = true,
      },
    },
    debugger = { enabled = false },
  }

  -- Inline swatches next to `Color(0xFF...)` and `Colors.blue`, via Neovim's own
  -- document-color support rather than the plugin's deprecated version of it.
  vim.api.nvim_create_autocmd('LspAttach', {
    group = vim.api.nvim_create_augroup('dart-document-color', { clear = true }),
    callback = function(event)
      local client = vim.lsp.get_client_by_id(event.data.client_id)
      if client and client.name == 'dartls' and client:supports_method 'textDocument/documentColor' then
        -- The second argument is a FILTER table, not a buffer number -- passing
        -- the bufnr bare throws "expected table, got number" on every attach.
        vim.lsp.document_color.enable(true, { bufnr = event.buf }, { style = 'background' })
      end
    end,
  })
end

-- ============================================================
-- SECTION 24: APP COMMANDS
-- ============================================================
for key, action in pairs { ['<C-r>'] = 'run', ['<C-b>'] = 'build', ['<C-S-r>'] = 'existing' } do
  vim.keymap.set('n', key, function() require('config.project').run(action) end, {
    desc = ({ run = 'Build and run app', build = 'Build app', existing = 'Run existing build' })[action],
  })
end

-- The line beneath this is called `modeline`. See `:help modeline`
-- vim: ts=2 sts=2 sw=2 et
