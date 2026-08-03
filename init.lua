--[[

=====================================================================
==================== READ THIS BEFORE CONTINUING ====================
=====================================================================
========                                    .-----.          ========
========         .----------------------.   | === |          ========
========         |.-""""""""""""""""""-.|   |-----|          ========
========         ||                    ||   | === |          ========
========         ||   KICKSTART.NVIM   ||   |-----|          ========
========         ||                    ||   | === |          ========
========         ||                    ||   |-----|          ========
========         ||:Tutor              ||   |:::::|          ========
========         |'-..................-'|   |____o|          ========
========         `"")----------------(""`   ___________      ========
========        /::::::::::|  |::::::::::\  \ no mouse \     ========
========       /:::========|  |==hjkl==:::\  \ required \    ========
========      '""""""""""""'  '""""""""""""'  '""""""""""'   ========
========                                                     ========
=====================================================================
=====================================================================

What is Kickstart?

  Kickstart.nvim is *not* a distribution.

  Kickstart.nvim is a starting point for your own configuration.
    The goal is that you can read every line of code, top-to-bottom, understand
    what your configuration is doing, and modify it to suit your needs.

    Once you've done that, you can start exploring, configuring and tinkering to
    make Neovim your own! That might mean leaving Kickstart just the way it is for a while
    or immediately breaking it into modular pieces. It's up to you!

    If you don't know anything about Lua, I recommend taking some time to read through
    a guide. One possible example which will only take 10-15 minutes:
      - https://learnxinyminutes.com/docs/lua/

    After understanding a bit more about Lua, you can use `:help lua-guide` as a
    reference for how Neovim integrates Lua.
    - :help lua-guide
    - (or HTML version): https://neovim.io/doc/user/lua-guide.html

Kickstart Guide:

  TODO: The very first thing you should do is to run the command `:Tutor` in Neovim.

    If you don't know what this means, type the following:
      - <escape key>
      - :
      - Tutor
      - <enter key>

    (If you already know the Neovim basics, you can skip this step.)

  Once you've completed that, you can continue working through **AND READING** the rest
  of the kickstart init.lua.

  Next, run AND READ `:help`.
    This will open up a help window with some basic information
    about reading, navigating and searching the builtin help documentation.

    This should be the first place you go to look when you're stuck or confused
    with something. It's one of my favorite Neovim features.

    MOST IMPORTANTLY, we provide a keymap "<space>sh" to [s]earch the [h]elp documentation,
    which is very useful when you're not exactly sure of what you're looking for.

  I have left several `:help X` comments throughout the init.lua
    These are hints about where to find more information about the relevant settings,
    plugins or Neovim features used in Kickstart.

   NOTE: Look for lines like this

    Throughout the file. These are for you, the reader, to help you understand what is happening.
    Feel free to delete them once you know what you're doing, but they should serve as a guide
    for when you are first encountering a few different constructs in your Neovim config.

If you experience any errors while trying to install kickstart, run `:checkhealth` for more info.

I hope you enjoy your Neovim journey,
- TJ

P.S. You can delete this when you're done too. It's your config now! :)
--]]

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

  vim.keymap.set('n', '<leader>q', vim.diagnostic.setloclist, { desc = 'Open diagnostic [Q]uickfix list' })

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

-- The debugger core, shared by the Swift lane (SECTION 22, macOS only) and the
-- Flutter lane (SECTION 23, everywhere). Either may be the one that runs on a
-- given machine, and on a Mac both do, so whichever gets here first pays for it
-- and the other reuses it. Everything language-specific stays in its own
-- section; this is only the pieces neither owns.
local dap_ready = false
local function ensure_debugger()
  if dap_ready then return require 'dap' end

  vim.pack.add {
    gh 'mfussenegger/nvim-dap',
    gh 'nvim-neotest/nvim-nio', -- nvim-dap-ui's only hard dependency
    gh 'rcarriga/nvim-dap-ui',
  }

  local dap, dapui = require 'dap', require 'dapui'
  dapui.setup {} -- the default layout already includes the console pane app logs go to
  dap.listeners.after.event_initialized.dapui = dapui.open
  dap.listeners.before.event_terminated.dapui = dapui.close
  dap.listeners.before.event_exited.dapui = dapui.close

  -- Flagged only once everything above survived. Setting it on the way in would
  -- latch a half-built debugger (say, an offline first launch where the clone
  -- fails) and every later call would hand back a dap with no panes wired.
  dap_ready = true
  return dap
end

-- Stepping keeps DAP's cross-editor F-key defaults (same as VS Code), so the
-- muscle memory carries over and the `<leader>d*` namespaces stay flat lists of
-- verbs rather than half verbs and half steps. Bound once here rather than per
-- lane: two lanes binding the same four keys would come down to section order,
-- and the loser would silently win.
for key, step in pairs { ['<F5>'] = 'continue', ['<F10>'] = 'step_over', ['<F11>'] = 'step_into', ['<F12>'] = 'step_out' } do
  vim.keymap.set('n', key, function() ensure_debugger()[step]() end, { desc = '[D]ebug: ' .. step:gsub('_', ' ') })
end
vim.keymap.set('n', '<leader>du', function()
  ensure_debugger()
  require('dapui').toggle()
end, { desc = '[D]ebug: toggle [U]I panels' })
-- The `<leader>d` which-key group is registered in SECTION 24, not here:
-- which-key itself isn't installed until SECTION 4.

-- ============================================================
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
        if not is_staged then
          gitsigns.setqflist('all', { open = false }, callback)
          return
        end

        local root = vim.fn.systemlist('git rev-parse --show-toplevel')[1]
        if vim.v.shell_error ~= 0 then
          vim.notify('Not in a git repo', vim.log.levels.WARN)
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
            -- Rebuilding the qflist resets its "current entry" pointer back
            -- to the top every time, so without re-syncing it to wherever
            -- the cursor actually is first, every press after the first
            -- would land back on the same (second) entry instead of
            -- advancing further.
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
  -- 'hackerman' is our own theme, published at github.com/OwaisQuadri/hackerman.nvim.
  vim.pack.add { gh 'OwaisQuadri/hackerman.nvim' }
  vim.cmd.colorscheme 'hackerman'

  -- Pull new commits from the theme's repo at most once a day, so pushing a
  -- change there doesn't require remembering to run `vim.pack.update()` by
  -- hand. Deferred so a slow/offline git fetch never blocks startup, and it
  -- only takes effect on the *next* restart (this session already loaded the
  -- colorscheme by the time the update lands).
  do
    vim.fn.mkdir(vim.fn.stdpath 'data', 'p')
    local stamp_file = vim.fn.stdpath 'data' .. '/hackerman-last-update'
    local ok, lines = pcall(vim.fn.readfile, stamp_file)
    local last_update = ok and tonumber(lines[1])
    if not last_update or (os.time() - last_update) > 86400 then
      pcall(vim.fn.writefile, { tostring(os.time()) }, stamp_file)
      vim.defer_fn(function() pcall(vim.pack.update, { 'hackerman.nvim' }, { force = true }) end, 500)
    end
  end

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
  vim.api.nvim_create_autocmd('ColorScheme', { desc = 'Keep the background transparent on any colorscheme', callback = clear_bg })
  clear_bg()

  -- Highlight todo, notes, etc in comments
  vim.pack.add { gh 'folke/todo-comments.nvim' }
  require('todo-comments').setup { signs = false }

  -- Cycle todo comments project-wide (ripgrep search), quickfix-list-based
  -- the same way ]d/[d and ]c/[c cross files above -- rebuild the list on
  -- every press, then re-sync its "current entry" to the cursor's actual
  -- position before calling cnext/cprev, since rebuilding resets that
  -- pointer to the top every time.
  local function jump_todo(direction)
    require('todo-comments.search').search(function(results)
      vim.schedule(function()
        if vim.tbl_isempty(results) then
          vim.notify('No todos found', vim.log.levels.WARN)
          return
        end
        vim.fn.setqflist({}, 'r', { title = 'Todo', items = results })
        local qf = vim.fn.getqflist()
        local cur_file = vim.fn.fnamemodify(vim.api.nvim_buf_get_name(0), ':p')
        local cur_line = vim.api.nvim_win_get_cursor(0)[1]
        local idx = 1
        for i, entry in ipairs(qf) do
          local fname = entry.filename
          if (not fname or fname == '') and entry.bufnr and entry.bufnr > 0 then
            fname = vim.api.nvim_buf_get_name(entry.bufnr)
          end
          fname = fname and vim.fn.fnamemodify(fname, ':p') or fname
          if fname == cur_file and entry.lnum <= cur_line then idx = i end
        end
        pcall(vim.fn.setqflist, {}, 'r', { idx = idx })

        local ok = pcall(vim.cmd, direction == 'next' and 'cnext' or 'cprev')
        if not ok then
          vim.cmd(direction == 'next' and 'cfirst' or 'clast')
        end
        vim.cmd 'normal! zz'
      end)
    end, { disable_not_found_warnings = true })
  end

  vim.keymap.set('n', ']t', function() jump_todo 'next' end, { desc = 'Next [t]odo comment (crosses files)' })
  vim.keymap.set('n', '[t', function() jump_todo 'prev' end, { desc = 'Prev [t]odo comment (crosses files)' })

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

  -- Cursor animation stays off: smear-cursor already animates the cursor.
  local animate = require 'mini.animate'
  animate.setup {
    cursor = { enable = false },
    -- Scroll animation off: it interferes with mousewheel scrolling.
    scroll = { enable = false },
    -- Window open/close/resize animations off too.
    resize = { enable = false },
    open = { enable = false },
    close = { enable = false },
  }

  -- Wrap a visual selection by typing a bracket/quote directly (like most
  -- GUI editors), e.g. select a word and press `(` to get `(word)`.
  for _, pair in ipairs { { '(', ')' }, { '[', ']' }, { '{', '}' }, { '"', '"' }, { "'", "'" }, { '`', '`' } } do
    local left, right = pair[1], pair[2]
    for _, key in ipairs(left == right and { left } or { left, right }) do
      vim.keymap.set(
        'x',
        key,
        string.format('<Esc>`>a%s<Esc>`<i%s<Esc>', right, left),
        { desc = 'Surround selection with ' .. left .. right }
      )
    end
  end

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
    vim.api.nvim_set_hl(0, 'MiniStatuslineFilenameBase', { link = 'Boolean', default = false })
  end
  vim.api.nvim_create_autocmd('ColorScheme', { desc = 'Keep the statusline filename prominent', callback = make_filename_prominent })
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
  vim.keymap.set('n', '<leader>sh', builtin.help_tags, { desc = '[S]earch [H]elp' })
  vim.keymap.set('n', '<leader>sk', builtin.keymaps, { desc = '[S]earch [K]eymaps' })
  vim.keymap.set('n', '<leader>sf', builtin.find_files, { desc = '[S]earch [F]iles' })
  vim.keymap.set('n', '<leader>ss', builtin.builtin, { desc = '[S]earch [S]elect Telescope' })
  vim.keymap.set({ 'n', 'v' }, '<leader>sw', builtin.grep_string, { desc = '[S]earch current [W]ord' })
  vim.keymap.set('n', '<leader>sg', builtin.live_grep, { desc = '[S]earch by [G]rep' })
  vim.keymap.set('n', '<leader>sd', builtin.diagnostics, { desc = '[S]earch [D]iagnostics' })
  vim.keymap.set('n', '<leader>sr', builtin.resume, { desc = '[S]earch [R]esume' })
  vim.keymap.set('n', '<leader>s.', builtin.oldfiles, { desc = '[S]earch Recent Files ("." for repeat)' })
  vim.keymap.set('n', '<leader>sc', builtin.commands, { desc = '[S]earch [C]ommands' })
  vim.keymap.set('n', '<leader><leader>', builtin.buffers, { desc = '[ ] Find existing buffers' })

  -- [[ Recent project roots ]]
  -- Remember every directory nvim was launched from (most-recent-first,
  -- deduped) and offer to switch into one when starting with no file args.
  local roots_file = vim.fn.stdpath 'data' .. '/recent_roots.txt'
  vim.fn.mkdir(vim.fn.stdpath 'data', 'p')

  -- fnamemodify(..., ':p') appends a trailing slash for directories, so
  -- always strip it before storing/comparing or the same directory ends up
  -- recorded as two different strings (e.g. ".../seville" and ".../seville/").
  local function normalize_dir(dir) return (vim.fn.fnamemodify(dir, ':p'):gsub('/$', '')) end

  local function read_roots()
    local ok, lines = pcall(vim.fn.readfile, roots_file)
    if not ok then return {} end

    local seen, result = {}, {}
    for _, line in ipairs(lines) do
      local dir = normalize_dir(line)
      if not seen[dir] then
        seen[dir] = true
        table.insert(result, dir)
      end
    end
    return result
  end

  local function record_root(dir)
    dir = normalize_dir(dir)
    local list = read_roots()
    for i = #list, 1, -1 do
      if list[i] == dir then table.remove(list, i) end
    end
    table.insert(list, 1, dir)
    while #list > 20 do
      table.remove(list)
    end
    pcall(vim.fn.writefile, list, roots_file)
  end

  local function is_blank_buffer()
    return vim.api.nvim_buf_get_name(0) == ''
      and not vim.bo.modified
      and vim.api.nvim_buf_line_count(0) == 1
      and vim.api.nvim_buf_get_lines(0, 0, 1, false)[1] == ''
  end

  local function find_last_opened_in_dir(dir)
    local prefix = dir .. '/'
    for _, f in ipairs(vim.v.oldfiles) do
      if vim.startswith(f, prefix) and vim.uv.fs_stat(f) then return f end
    end
  end

  local function find_readme(dir)
    for _, entry in ipairs(vim.fn.readdir(dir)) do
      if entry:lower():match '^readme' then return dir .. '/' .. entry end
    end
  end

  local function find_first_nonempty_file(dir)
    local entries = vim.fn.readdir(dir)
    table.sort(entries)
    for _, entry in ipairs(entries) do
      if not vim.startswith(entry, '.') then
        local path = dir .. '/' .. entry
        local stat = vim.uv.fs_stat(path)
        if stat and stat.type == 'file' and stat.size > 0 then return path end
      end
    end
  end

  -- Instead of a blank buffer, land on: the last file opened under this
  -- directory, else its README, else the first non-empty top-level file,
  -- else fall back to a netrw sidebar if the directory has nothing to show.
  local function open_landing_buffer(dir)
    dir = normalize_dir(dir)
    local ok, target = pcall(function() return find_last_opened_in_dir(dir) or find_readme(dir) or find_first_nonempty_file(dir) end)
    if ok and target then
      vim.cmd.edit(vim.fn.fnameescape(target))
    else
      vim.cmd('Lexplore ' .. vim.fn.fnameescape(dir))
    end
  end

  -- A dedicated Telescope picker (rather than vim.ui.select) so it can open
  -- in Normal mode without changing that behavior for every other ui-select
  -- consumer (LSP code actions, etc.) globally.
  local function pick_root()
    local cwd = normalize_dir(vim.fn.getcwd())
    local roots = { cwd }
    for _, dir in ipairs(read_roots()) do
      if dir ~= cwd and vim.uv.fs_stat(dir) ~= nil then table.insert(roots, dir) end
    end

    local pickers = require 'telescope.pickers'
    local finders = require 'telescope.finders'
    local conf = require('telescope.config').values
    local actions = require 'telescope.actions'
    local action_state = require 'telescope.actions.state'

    local function on_select(choice)
      if choice and choice ~= normalize_dir(vim.fn.getcwd()) then vim.cmd.cd(choice) end
      -- Only replace the buffer if it's still the blank scratch buffer nvim
      -- started with -- don't clobber real work when switching roots mid-session.
      if is_blank_buffer() then open_landing_buffer(vim.fn.getcwd()) end
    end

    pickers
      .new(require('telescope.themes').get_dropdown { initial_mode = 'normal' }, {
        prompt_title = 'Open root',
        finder = finders.new_table { results = roots },
        sorter = conf.generic_sorter {},
        attach_mappings = function(prompt_bufnr)
          actions.select_default:replace(function()
            local selection = action_state.get_selected_entry()
            actions.close(prompt_bufnr)
            on_select(selection and selection.value)
          end)
          return true
        end,
      })
      :find()
  end

  vim.keymap.set('n', '<leader>sp', pick_root, { desc = '[S]earch [P]roject roots' })

  vim.api.nvim_create_autocmd('VimEnter', {
    desc = 'Track recent project roots and offer to switch on a bare launch',
    callback = function()
      -- `nvim <some-dir>` -- go straight to that directory's landing buffer,
      -- no need to ask which root since one was given explicitly.
      if vim.fn.argc() == 1 and vim.fn.isdirectory(vim.fn.argv(0)) == 1 then
        local dir = vim.fn.fnamemodify(vim.fn.argv(0), ':p')
        record_root(dir)
        open_landing_buffer(dir)
        return
      end

      record_root(vim.fn.getcwd())
      if vim.fn.argc() == 0 then vim.schedule(pick_root) end
    end,
  })

  -- [[ Goto-definition "real source" fallback (Swift only) ]]
  --
  -- sourcekit-lsp resolves system/stdlib `gd` into a generated `.swiftinterface`
  -- (declarations only, no body). ts_ls resolves node_modules packages that
  -- shipped without declaration maps into a `.d.ts` (types only, no body). Both
  -- are valid definition locations but not the real implementation the user
  -- wants to read.
  --
  -- This wraps the definition lookup: when the LSP resolves to one of those
  -- stubs, we try to fetch the real source file from the owning GitHub repo,
  -- cache it on disk, and open the cached copy. For anything that is NOT a stub
  -- we fall straight through to today's behavior (`builtin.lsp_definitions`,
  -- the telescope picker), unchanged. Every failure path also falls through --
  -- the user is never left with nothing.
  --
  -- Design notes (see also memory/decisions.md rationale in the PR):
  --   * We fetch from raw.githubusercontent.com, not the REST API: raw content
  --     is auth-free and effectively unthrottled, whereas the REST/search API is
  --     rate-limited to 60 req/hr unauthenticated. For *locating* a file we use
  --     the git Trees API once (also unauthenticated) and cache the result.
  --   * `curl` is used via `vim.system` async (callback + vim.schedule), never
  --     `:wait()`, because this runs on the `gd` keypress and must not block.
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

      -- Jump to the definition of the word under your cursor.
      -- This is where a variable was first declared, or where a function is defined, etc.
      -- To jump back, press <C-t>.
      --
      -- For Swift/TS/JS system symbols the LSP resolves to a declarations-only
      -- stub (.swiftinterface / .d.ts). `gotodef.go` intercepts only those cases
      -- to fetch the real source; every other case (and every failure) falls
      -- through to the telescope picker below, unchanged.
      local function goto_definition() gotodef.go(builtin.lsp_definitions) end
      vim.keymap.set('n', 'grd', goto_definition, { buffer = buf, desc = '[G]oto [D]efinition' })
      vim.keymap.set('n', 'gd', goto_definition, { buffer = buf, desc = '[G]oto [D]efinition' })

      -- Fuzzy find all the symbols in your current document.
      -- Symbols are things like variables, functions, types, etc.
      vim.keymap.set('n', 'gO', builtin.lsp_document_symbols, { buffer = buf, desc = 'Open Document Symbols' })

      -- Fuzzy find all the symbols in your current workspace.
      -- Similar to document symbols, except searches over your entire project.
      vim.keymap.set('n', 'gW', builtin.lsp_dynamic_workspace_symbols, { buffer = buf, desc = 'Open Workspace Symbols' })

      -- Jump to the type of the word under your cursor.
      -- Useful when you're not sure what type a variable is and you want to see
      -- the definition of its *type*, not where it was *defined*.
      vim.keymap.set('n', 'grt', builtin.lsp_type_definitions, { buffer = buf, desc = '[G]oto [T]ype Definition' })
    end,
  })

  -- Override default behavior and theme when searching
  vim.keymap.set('n', '<leader>/', function()
    -- You can pass additional configuration to Telescope to change the theme, layout, etc.
    builtin.current_buffer_fuzzy_find(require('telescope.themes').get_dropdown {
      winblend = 10,
      previewer = false,
    })
  end, { desc = '[/] Fuzzily search in current buffer' })

  -- It's also possible to pass additional configuration options.
  --  See `:help telescope.builtin.live_grep()` for information about particular keys
  vim.keymap.set(
    'n',
    '<leader>s/',
    function()
      builtin.live_grep {
        grep_open_files = true,
        prompt_title = 'Live Grep in Open Files',
      }
    end,
    { desc = '[S]earch [/] in Open Files' }
  )

  -- Shortcut for searching your Neovim configuration files
  vim.keymap.set('n', '<leader>sn', function() builtin.find_files { cwd = vim.fn.stdpath 'config', follow = true } end, { desc = '[S]earch [N]eovim files' })
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

  -- Hover docs, but auto-focused: skip the "press K/gD twice to jump into the
  -- float" step, and let <Esc> dismiss the float (in addition to the default
  -- `q`). Works by temporarily wrapping `open_floating_preview` -- the function
  -- the hover response handler calls once the server actually replies -- so it
  -- self-restores after firing once and never touches other floats (signature
  -- help, etc.), which should keep stealing focus mid-insert.
  local function hover_and_focus()
    local orig = vim.lsp.util.open_floating_preview
    local function wrapper(contents, syntax, opts)
      if vim.lsp.util.open_floating_preview == wrapper then vim.lsp.util.open_floating_preview = orig end
      local floatbuf, floatwin = orig(contents, syntax, opts)
      vim.api.nvim_set_current_win(floatwin)
      vim.keymap.set('n', '<Esc>', '<cmd>close<CR>', { buffer = floatbuf, nowait = true, silent = true, desc = 'Close hover' })
      return floatbuf, floatwin
    end
    vim.lsp.util.open_floating_preview = wrapper
    -- Self-heal: if hover never resolves (no docs, error, etc.), don't leave the
    -- wrapper installed forever -- restore it after a beat unless something else
    -- already did.
    vim.defer_fn(function()
      if vim.lsp.util.open_floating_preview == wrapper then vim.lsp.util.open_floating_preview = orig end
    end, 4000)
    vim.lsp.buf.hover()
  end

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
    ensure_tiny_code_action().code_action { range = { start = { row, 0 }, ['end'] = { row, #vim.api.nvim_get_current_line() } } }
  end

  -- Whole-file source actions get their own chords: they are never
  -- diagnostic-anchored, so they don't belong in the quick-fix list. Kind
  -- prefixes match dot-children per the LSP spec ('source.organizeImports'
  -- also catches ts_ls's 'source.organizeImports.ts'); apply = true applies
  -- directly when the server returns exactly one action.
  local function source_action(kind)
    return function() vim.lsp.buf.code_action { apply = true, context = { only = { kind }, diagnostics = {} } } end
  end
  vim.keymap.set('n', '<leader>co', source_action 'source.organizeImports', { desc = '[C]ode: [o]rganize imports' })
  vim.keymap.set('n', '<leader>cm', source_action 'source.addMissingImports', { desc = '[C]ode: add [m]issing imports' })
  vim.keymap.set('n', '<leader>cf', source_action 'source.fixAll', { desc = '[C]ode: [f]ix all auto-fixable' })

  -- Gutter lightbulb marking where a code action exists. First LspAttach
  -- loads it: no server, no startup cost.
  vim.api.nvim_create_autocmd('LspAttach', {
    desc = 'Load nvim-lightbulb once a language server attaches',
    once = true,
    callback = function()
      vim.pack.add { gh 'kosayoda/nvim-lightbulb' }
      require('nvim-lightbulb').setup { autocmd = { enabled = true } }
    end,
  })

  -- Top level, not buffer-local to LspAttach: a key that silently does not exist
  -- in a buffer with no server is indistinguishable from a key that found no
  -- fixes, and "I can't find it" is the bug being fixed here. `<C-.>` (the
  -- physical Cmd+.) is the chord every other editor uses for this;
  -- `<leader>ca` is the cross-platform twin. In insert mode the same chord
  -- instead pops the completion menu with these quick fixes ranked on top
  -- (SECTION 8). Both descriptions say "quick fix" in as many words, because
  -- that is what someone searching their own keymaps will type.
  vim.keymap.set({ 'n', 'x' }, '<leader>ca', quick_fix, { desc = '[C]ode [A]ction -- quick fix for this line' })
  map_platform({ 'n', 'x' }, '<C-.>', nil, quick_fix, { desc = 'Code action -- quick fix for this line' })

  -- A rename edits every file the server names, but only in MEMORY:
  -- `apply_workspace_edit` loads the other files as hidden buffers, edits them,
  -- and stops there. The file you were IN still reaches disk -- loading those
  -- other buffers fires a `BufLeave`, and the autosave in SECTION 16 answers it
  -- -- which is precisely why this reads as "rename doesn't cross files": one
  -- file is saved for you and the rest stay dirty in hidden buffers and die
  -- with the session. Wrap the rename RESPONSE handler rather than the `grn`
  -- keymap: `grn` is also a Neovim 0.11 core default and a rename can come from
  -- a code action or a picker, and every one of them lands here.
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
      -- This covers the files the rename REACHED. It cannot cover the buffer you
      -- are sitting in: loading the others fires a BufLeave for it, SECTION 16's
      -- autosave answers that a tick later, and your half-typed line goes to
      -- disk regardless -- with or without this writeback, before it existed and
      -- after. Suppressing BufLeave across the edit was tried and does NOT fix
      -- it (the event arrives after the handler has already put `eventignore`
      -- back), so README.md documents it rather than promising otherwise.
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

      -- Execute a code action ("quick fix"). Kickstart bound this to the raw
      -- `vim.lsp.buf.code_action`, which only offers what sits under the cursor
      -- COLUMN; `quick_fix` above widens it to the line. Same key, and `gra` is
      -- a Neovim 0.11 core default, so it keeps working with no relearning.
      map('gra', quick_fix, '[G]oto Code [A]ction -- quick fix for this line', { 'n', 'x' })

      -- WARN: This is not Goto Definition, this is Goto Declaration.
      --  For example, in C this would take you to the header.
      map('grD', vim.lsp.buf.declaration, '[G]oto [D]eclaration')

      -- Xcode alt-click style: peek docs for the symbol under the cursor. `K`
      -- does the same lookup, but this one auto-focuses the float immediately
      -- (no double-press needed) and <Esc> dismisses it.
      map('gD', hover_and_focus, '[H]over [D]ocs (focused)')

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

      -- The following code creates a keymap to toggle inlay hints in your
      -- code, if the language server you are using supports them
      --
      -- This may be unwanted, since they displace some of your code
      if client and client:supports_method('textDocument/inlayHint', event.buf) then
        map('<leader>th', function() vim.lsp.inlay_hint.enable(not vim.lsp.inlay_hint.is_enabled { bufnr = event.buf }) end, '[T]oggle Inlay [H]ints')
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

    stylua = {}, -- Used to format Lua code

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
  vim.lsp.config('sourcekit', {})
  vim.lsp.enable('sourcekit')

  -- Rust, via rustup's own rust-analyzer, is also outside the mason table, and
  -- for a sharper reason than sourcekit: rustup ships a rust-analyzer that is
  -- version-matched to the active toolchain, and the proc-macro server ABI is
  -- NOT stable across releases -- a mason copy can silently stop expanding
  -- macros after a `rustup update`, and would shadow ~/.cargo/bin on PATH
  -- besides. nvim-lspconfig's default `cmd = { 'rust-analyzer' }` finds the
  -- rustup binary as-is (check with `which rust-analyzer`; install with
  -- `rustup component add rust-analyzer`).
  vim.lsp.config('rust_analyzer', {})
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
    notify_on_error = false,
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
    local line = vim.api.nvim_buf_get_lines(bufnr, row - 1, row, false)[1] or ''
    local diagnostics = vim.diagnostic.get(bufnr, { lnum = row - 1 })

    vim.lsp.buf_request_all(bufnr, 'textDocument/codeAction', function(client)
      return {
        textDocument = { uri = vim.uri_from_bufnr(bufnr) },
        range = {
          start = { line = row - 1, character = 0 },
          ['end'] = { line = row - 1, character = vim.str_utfindex(line, client.offset_encoding) },
        },
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
            data = { title = action.title, row = row, line_len = #line },
          })
        end
      end
      callback { items = items, is_incomplete_forward = false, is_incomplete_backward = false }
    end)
  end

  function quickfix_source:execute(ctx, item, callback)
    vim.lsp.buf.code_action {
      range = { start = { item.data.row, 0 }, ['end'] = { item.data.row, item.data.line_len } },
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

      -- <Tab> priority chain: visible AI ghost text (SECTION 8.5), else
      -- snippet jump, else a real tab. It lives here, in the one keymap
      -- that owns <Tab>, so all three uses of the key coexist.
      ['<Tab>'] = {
        function()
          -- v:true crosses the Lua boundary as a boolean, not 1.
          local is_ok, shown = pcall(vim.fn['llama#is_fim_hint_shown'])
          if is_ok and (shown == true or shown == 1) then
            -- blink runs keymap functions under textlock (E565); the buffer
            -- edit must escape it. fim_accept rechecks hint state, so the
            -- deferred call is safe.
            vim.schedule(function() vim.fn['llama#fim_accept'] 'full' end)
            return true
          end
        end,
        'snippet_forward',
        'fallback',
      },

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
-- SECTION 8.5: AI GHOST TEXT -- LLAMA.VIM (LOCAL, ALWAYS FREE)
-- Cursor-style inline AI suggestions from a local llama.cpp server
-- ============================================================
do
  -- A local Qwen2.5-Coder-3B FIM (fill-in-the-middle) model: open weights
  -- running locally cannot be metered, gated, or shut down the way
  -- account-backed free tiers can. Ollama cannot serve this plugin -- it
  -- needs llama.cpp's native /infill endpoint (`brew install llama.cpp`).
  -- 3B, not the README-default 7B: Xcode and simulators already eat several
  -- GB on a 16GB machine.
  --
  -- The plugin's keymaps stay on Alt chords -- its Tab/S-Tab defaults would
  -- collide with blink.cmp's snippet jumps; the plain-<Tab> accept lives in
  -- blink's keymap (SECTION 8), the one owner of that key. show_info = 0
  -- hides the inline inference-stats overlay.
  vim.g.llama_config = {
    show_info = 0,
    keymap_fim_trigger = '<C-F>',
    keymap_fim_accept_full = '<A-f>',
    keymap_fim_accept_line = '<A-a>',
    keymap_fim_accept_word = '<A-w>',
    keymap_fim_next = '<A-e>',
    keymap_fim_prev = '<A-r>',
    keymap_inst_accept = '<A-f>',
  }

  local is_llama_ready = false
  local function ensure_llama()
    if is_llama_ready then return end
    vim.pack.add { gh 'ggml-org/llama.vim' }
    is_llama_ready = true
  end

  -- Detached rather than a terminal split: the server outlives every nvim,
  -- so the first insert after a reboot pays the spawn and later sessions
  -- find port 8012 already answering. A first-ever run downloads the ~2GB
  -- model before suggestions appear.
  local function start_llama_server()
    if vim.fn.executable 'llama-server' == 0 then
      vim.notify('llama-server not found -- `brew install llama.cpp` first', vim.log.levels.ERROR)
      return
    end
    vim.fn.jobstart({ 'llama-server', '--fim-qwen-3b-default' }, { detach = true })
  end

  -- Deferred to the first InsertEnter: a suggestion can't render before
  -- insert mode, and the startup path is guarded by tools/perf/bench.sh,
  -- so VimEnter pays only for this autocmd.
  vim.api.nvim_create_autocmd('InsertEnter', {
    desc = 'Load llama.vim on first insert, starting the server if nothing answers',
    once = true,
    callback = function()
      ensure_llama()
      vim.system({ 'curl', '-sf', '-m', '1', 'http://127.0.0.1:8012/health' }, {}, function(result)
        if result.code ~= 0 then vim.schedule(start_llama_server) end
      end)
    end,
  })

  vim.api.nvim_create_user_command('LlamaServer', start_llama_server, { desc = 'Start the local FIM completion server (detached)' })

  vim.keymap.set('n', '<leader>ta', function()
    ensure_llama()
    vim.cmd 'LlamaToggle'
  end, { desc = '[T]oggle [a]I ghost text' })
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
-- SECTION 14: PERSONAL EXTRAS -- CTRL-CHORD SHORTCUTS (GHOSTTY)
-- Editor-style Ctrl chords (the physical Cmd key, via Karabiner Cmd->Ctrl)
-- ============================================================
do
  -- The physical keys are unchanged from this section's `<D-...>` days --
  -- Karabiner delivers them as Ctrl (SECTION 0). If a chord below doesn't
  -- fire, check Karabiner and Ghostty's `keybind` config first, not this
  -- file.
  local builtin = require 'telescope.builtin'

  -- Show everything under root, gitignored or not -- these two shouldn't
  -- care whether the directory is even a git repo. Junk dirs are still
  -- excluded via explicit globs -- without them, --no-ignore walks
  -- node_modules/.git/build artifacts on every keystroke, and rg/fd jobs
  -- pile up faster than they can finish as you keep typing.
  local junk_globs = {
    '!.git/*',
    '!node_modules/*',
    '!dist/*',
    '!build/*',
    '!target/*',
    '!.venv/*',
    '!vendor/*',
    '!Pods/*',
    '!DerivedData/*',
    '!.next/*',
  }
  local rg_glob_args = { '--hidden', '--no-ignore' }
  for _, g in ipairs(junk_globs) do
    table.insert(rg_glob_args, '--glob')
    table.insert(rg_glob_args, g)
  end

  vim.keymap.set('n', '<C-S-f>', function() builtin.live_grep { additional_args = rg_glob_args } end, { desc = 'Project-wide search (live grep)' })

  local find_files_command = { 'rg', '--files' }
  vim.list_extend(find_files_command, rg_glob_args)
  vim.keymap.set('n', '<C-S-o>', function() builtin.find_files { find_command = find_files_command } end, { desc = 'Find files' })
  vim.keymap.set('n', '<C-p>', builtin.find_files, { desc = 'Find files' })

  -- Xcode-style history: <C-[>/<C-]> walk the jumplist like <C-o>/<C-i>.
  -- <C-[> is only distinct from <Esc> under the Kitty keyboard protocol,
  -- and <C-]> shadows the native tag-jump -- the help-buffer map below
  -- keeps `:help` link-following alive.
  vim.keymap.set('n', '<C-[>', '<C-o>zz', { desc = 'Back in jump history' })
  vim.keymap.set('n', '<C-]>', '<C-i>zz', { desc = 'Forward in jump history' })
  vim.api.nvim_create_autocmd('FileType', {
    desc = 'Keep native <C-]> tag-follow in help buffers',
    pattern = 'help',
    callback = function(ev) vim.keymap.set('n', '<C-]>', '<C-]>', { buffer = ev.buf, desc = 'Follow help link (native tag jump)' }) end,
  })

  local function run_script_near_file(script_name)
    local dir = vim.fn.expand '%:p:h'
    if vim.fn.filereadable(vim.fs.joinpath(dir, script_name)) == 0 then
      vim.notify('No ' .. script_name .. ' in ' .. dir, vim.log.levels.WARN)
      return
    end
    vim.cmd.split()
    vim.cmd.lcd(dir)
    -- The scripts are POSIX shell (`run.sh`/`build.sh`). On Windows they can't
    -- run directly, so invoke them through Git Bash's `bash`; on macOS just
    -- exec them relative to the (now lcd'd) directory.
    if is_win then
      vim.cmd.terminal('bash ' .. vim.fn.shellescape('./' .. script_name))
    else
      vim.cmd.terminal('./' .. script_name)
    end
  end

  -- Plain Ctrl+r/b collide with redo and page-up, so run/build take the
  -- shift layer on macOS (physical Cmd+Shift+r/b) and keep the
  -- window-prefix namespace on Windows.
  map_platform('n', '<C-S-r>', '<leader>wr', function() run_script_near_file 'run.sh' end, { desc = 'Run run.sh next to the current file' })
  map_platform('n', '<C-S-b>', '<leader>wb', function() run_script_near_file 'build.sh' end, { desc = 'Run build.sh next to the current file' })
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

-- SECTION 16: SAVING -- SAVE-ALL SHORTCUT AND CONSERVATIVE AUTOSAVE
-- ============================================================
do
  -- Save every modified buffer, not just the current one.
  vim.keymap.set({ 'n', 'i', 'v' }, '<C-s>', '<cmd>wa<CR>', { desc = 'Save all files' })

  -- Autosave, but conservative on purpose: this only fires `:update` (which is
  -- a no-op unless the buffer actually has unsaved changes) when you leave
  -- insert mode, leave a buffer, or the window loses focus -- never on a
  -- blind timer. That matters if an external tool (an AI agent, another
  -- editor, `git checkout`, etc.) is also writing to the same file: a
  -- timer-based autosave could stomp those external changes moments after
  -- they land. `autoread` handles the other direction -- when your buffer
  -- has no local edits, nvim will pick up external changes automatically
  -- instead of you carrying stale content forward.
  --
  -- This does NOT make truly simultaneous edits to the same lines safe --
  -- nothing short of real merge tooling does that. It just means: if you
  -- pause editing a file while something else is writing to it, nvim won't
  -- fight it or silently overwrite it.
  vim.o.autoread = true
  vim.api.nvim_create_autocmd({ 'FocusLost', 'BufLeave', 'InsertLeave' }, {
    desc = 'Autosave modified buffers (no-op if nothing changed)',
    pattern = '*',
    command = 'silent! update',
  })
end

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
-- SECTION 21: HABIT COACH -- HARDTIME (inefficiency detection substrate)
-- ============================================================
do
  -- hardtime.nvim watches for inefficient key habits (mashing j/k/arrows,
  -- repeated w/b, hjkl instead of a motion, ...) and suggests a better move.
  -- In the gentle default "hint" mode it only SUGGESTS -- the keystroke still
  -- goes through. This is the detection layer the real-time best-path coach
  -- (roadmap g2) builds on; `:Hardtime report` is its habit training data.
  --
  -- Flip `strict` to true for "block" mode: an over-repeated key is actually
  -- blocked after max_count presses instead of merely hinted.
  local strict = false

  vim.pack.add { gh 'm4xshen/hardtime.nvim' } -- nui.nvim (its dep) already added by neo-tree
  require('hardtime').setup {
    restriction_mode = strict and 'block' or 'hint',
    disable_mouse = false, -- gentle: leave the mouse usable
    -- `hint` (better-motion suggestions) and `notification` are on by default.
    --
    -- `disabled_keys` is NOT governed by restriction_mode. Its default swallows
    -- the four arrow keys in every mode plus insert (config.lua:62-67), so they
    -- die silently however gentle the rest of the setup is. Each key needs its
    -- own `false`: setup merges with `tbl_deep_extend('force', ...)`, so a bare
    -- `disabled_keys = {}` merges into the defaults and changes nothing.
    -- Arrows stay live; the habit coach still hints when you lean on them.
    disabled_keys = { ['<Up>'] = false, ['<Down>'] = false, ['<Left>'] = false, ['<Right>'] = false },
  }

  vim.keymap.set('n', '<leader>tH', '<cmd>Hardtime toggle<CR>', { desc = '[T]oggle [H]ardtime habit coach' })
end

-- ============================================================
-- SECTION 22: SWIFT / XCODE -- BUILD, RUN, TEST, DEBUG, LINT
-- xcodebuild.nvim, nvim-dap(-ui), nvim-lint + swiftlint
-- ============================================================
--
-- Swift's *editor* side is already wired up elsewhere: the `sourcekit` LSP in
-- SECTION 6, the `swift` treesitter parser in SECTION 9, `swiftformat` in
-- SECTION 7. This section adds the Xcode *project* side -- choosing a scheme
-- and a device, building, running on a simulator, tests, coverage, previews,
-- and the debugger -- so an iOS/macOS app can be developed without opening
-- Xcode.
--
-- Everything here shells out to `xcodebuild` and `xcrun simctl`, the same tools
-- Xcode itself drives, so the section is Mac-only and is skipped wholesale on
-- Windows and Linux rather than half-loaded. `if is_mac then` doubles as this
-- section's scope block (a bare `return` inside a `do` block would abandon the
-- rest of the file, not just the section).
if is_mac then
  -- xcodebuild.nvim finds its pickers in telescope (SECTION 5) and its floating
  -- coverage report in nui (added by neo-tree, SECTION 15); both are already on.
  -- nvim-dap and nvim-dap-ui come from `ensure_debugger()` at file scope, shared
  -- with the Flutter lane.
  vim.pack.add {
    gh 'wojciech-kulik/xcodebuild.nvim',
    gh 'mfussenegger/nvim-lint',
  }

  -- Loaded eagerly rather than gated behind "is there an .xcodeproj under the
  -- cwd?". The three mobile sections together move the measured floor from
  -- ~60.5ms to ~69.6ms, and only because the debugger is deferred -- leaving it
  -- eager put startup past 130ms. A cwd gate would have to re-run project detection
  -- on every `:cd` to stay correct, which is more moving parts than the
  -- remaining milliseconds buy back.
  --
  -- The plugin keys everything off the cwd, and both of the flags below ship
  -- off, which makes it strictly a "launch nvim from the project root" tool.
  -- Turning them on is what lets it follow you around instead:
  --   * search_in_parent_dirs -- opening nvim in a subfolder (Sources/, a
  --     package inside a monorepo) still finds the settings written at the
  --     project root, rather than treating that subfolder as a new project.
  --   * reload_on_cwd_change -- a `:cd` mid-session re-reads the settings for
  --     wherever you landed, so cd-ing from a Lua repo into an app just works.
  -- `:XcodebuildSetup` then searches four levels down for the project file and
  -- makes *its* directory the build's working directory, so the app doesn't
  -- have to sit at the repo root either. Choices are saved per project, in
  -- `.nvim/xcodebuild/settings.json`.
  require('xcodebuild').setup {
    project_config = {
      search_in_parent_dirs = true,
      reload_on_cwd_change = true,
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
  map('<leader>xa', '<cmd>XcodebuildCodeActions<CR>', 'Xcode: code [A]ctions')
  map('<leader>xo', '<cmd>XcodebuildOpenInXcode<CR>', 'Xcode: [O]pen this file in Xcode')

  -- [[ Debugger ]]
  -- Xcode 16 and later ship `lldb-dap`, which the integration finds on its own
  -- -- the codelldb download the plugin's docs describe is only needed below
  -- that. The panes, the listeners, and the F-key stepping are the shared
  -- `ensure_debugger()`; what follows is only the Swift-specific half.
  --
  -- The Swift debugger's own setup shells out to `xcodebuild -version` -- that's
  -- how it decides which lldb-dap flavour to register -- which measured 50-170ms
  -- depending on how warm Xcode is: the bulk of this whole section, otherwise
  -- paid on every launch including all the ones nowhere near a Swift file. So
  -- it's deferred to the first moment it can matter: opening a Swift buffer, or
  -- reaching for a debug key.
  local debugger_ready = false
  local function debugger()
    local integration = require 'xcodebuild.integrations.dap'
    if not debugger_ready then
      ensure_debugger()
      integration.setup()
      debugger_ready = true
    end
    return integration
  end

  -- Deliberately not `once = true`: a `once` autocmd is consumed even when its
  -- callback throws, so one transient failure would kill the trigger for the
  -- rest of the session AND turn opening any Swift file into a hard `:edit`
  -- error. `debugger_ready` already makes repeat calls a boolean check, and the
  -- pcall downgrades a broken setup to a warning you can act on.
  --
  -- `.swiftinterface` is excluded on purpose. SECTION 5's goto-definition
  -- fallback gives those generated stubs filetype `swift`, so without this a
  -- `gd` into a stdlib symbol would pay the whole blocking setup mid-keypress,
  -- in a repo that may well have no Xcode project at all.
  vim.api.nvim_create_autocmd('FileType', {
    group = vim.api.nvim_create_augroup('xcode-debugger', { clear = true }),
    pattern = 'swift',
    callback = function(event)
      if vim.api.nvim_buf_get_name(event.buf):match '%.swiftinterface$' then return end

      local ok, err = pcall(debugger)
      if not ok then
        vim.notify('Swift debugger setup failed: ' .. tostring(err), vim.log.levels.WARN)
        return
      end

      -- Restoring saved breakpoints is the debugger's own `BufReadPost` hook,
      -- registered by the setup we just deferred -- and Vim does not run
      -- autocmds added during the dispatch that added them. So the very first
      -- Swift file of each session would come up bare, and worse: the next
      -- breakpoint toggle rewrites the whole file with what's in memory, which
      -- would delete that file's saved breakpoints from disk. Load them here.
      require('xcodebuild.integrations.dap').load_breakpoints(event.buf)
    end,
  })

  ---@param action string name of a function on `xcodebuild.integrations.dap`
  local function debug_action(action)
    return function() debugger()[action]() end
  end

  map('<leader>dd', debug_action 'build_and_debug', '[D]ebug: build & debug')
  map('<leader>dr', debug_action 'debug_without_build', '[D]ebug: [R]un without building')
  map('<leader>dt', debug_action 'debug_tests', '[D]ebug: [T]ests')
  map('<leader>dT', debug_action 'debug_class_tests', '[D]ebug: current [T]est class')
  map('<leader>db', debug_action 'toggle_breakpoint', '[D]ebug: toggle [B]reakpoint')
  map('<leader>dB', debug_action 'toggle_message_breakpoint', '[D]ebug: toggle message [B]reakpoint')
  map('<leader>dx', debug_action 'terminate_session', '[D]ebug: terminate session')

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
  map('<leader>xL', function() require('lint').try_lint 'swiftlint' end, 'Xcode: run Swift[L]int now')
end

-- ============================================================
-- SECTION 23: FLUTTER
-- flutter-tools.nvim: dartls, devices, hot reload, widget outline, debugger
-- ============================================================
do
  -- flutter-tools owns `dartls` itself, which is why Dart is absent from
  -- SECTION 6's `servers` table -- configuring it in both places would start two
  -- clients. Its picker UI is `vim.ui.select`, already routed through Telescope
  -- by SECTION 5, so the `dressing.nvim` its README suggests isn't needed here.
  vim.pack.add { gh 'nvim-flutter/flutter-tools.nvim' } -- plenary, its other dep, comes with telescope
  -- flutter-tools registers its Dart adapter during setup, so dap has to exist
  -- first -- but "first" means before the adapter is USED, not before the editor
  -- finishes starting. Doing it here cost ~8.5ms of every launch on every
  -- platform, Dart project or not, which is most of this section's startup bill
  -- and exactly what SECTION 22 goes to lengths to avoid. Deferred to the first
  -- Dart buffer instead, which is the earliest point Flutter debugging can
  -- matter. pcall'd because a failure must not take SECTION 24's keymaps down.
  vim.api.nvim_create_autocmd('FileType', {
    group = vim.api.nvim_create_augroup('flutter-debugger', { clear = true }),
    pattern = 'dart',
    callback = function()
      local ok, err = pcall(ensure_debugger)
      if not ok then vim.notify('Debugger setup failed, Flutter debugging disabled: ' .. tostring(err), vim.log.levels.WARN) end
    end,
  })

  -- Finding the SDK. Left alone, flutter-tools resolves whatever `flutter` is on
  -- PATH -- but under a version manager that's a shim, not the SDK, and the
  -- analysis server lives inside the SDK. `asdf where flutter` resolves the shim
  -- to the real install for the *current directory*, which keeps per-project
  -- pinning (a `.tool-versions` next to `pubspec.yaml`) working. It fails loudly
  -- when no version is pinned at all -- see `<leader>m?` in SECTION 24, which
  -- checks exactly that.
  local lookup_cmd = vim.fn.executable 'asdf' == 1 and 'asdf where flutter' or nil

  require('flutter-tools').setup {
    flutter_lookup_cmd = lookup_cmd,
    ui = { border = 'rounded' },
    -- `root_patterns` is left at its default on purpose. It reads like the order
    -- ought to matter in a monorepo -- the repo's `.git` outranking the app's
    -- own `pubspec.yaml` -- but flutter-tools resolves the nearest DIRECTORY
    -- containing any pattern, not the first pattern in the list, so reordering
    -- changes nothing. Being in the right directory is what actually matters,
    -- and that's SECTION 24's `enter`.
    -- The widget guides are the reason to use this over a bare dartls: they draw
    -- the tree structure of a nested build() in the gutter, which is most of
    -- what reading Flutter code is.
    widget_guides = { enabled = true },
    closing_tags = { enabled = true, prefix = '// ' },
    lsp = {
      -- Deliberately not flutter-tools' own `color.enabled`: on 0.12 it warns at
      -- startup that plugin-managed document colors are deprecated in favour of
      -- `vim.lsp.document_color`, which the autocommand below turns on instead.
      settings = {
        showTodos = false, -- todo-comments.nvim (SECTION 4) already highlights these
        renameFilesWithClasses = 'prompt',
        updateImportsOnRename = true,
      },
    },
    debugger = {
      enabled = true,
      -- No `register_configurations`. flutter-tools populates
      -- `dap.configurations.dart` itself just before invoking that hook, so the
      -- usual snippet (reset the table, then `dap.ext.vscode.load_launchjs()`)
      -- deletes the configuration it was about to run and every launch dies
      -- with "No launch configuration for DAP found". `load_launchjs` is also
      -- deprecated now: nvim-dap reads `.vscode/launch.json` on demand.
    },
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
-- SECTION 24: MOBILE LANE -- ONE SET OF VERBS FOR XCODE / FLUTTER / EXPO
-- <leader>m* dispatches to whichever stack the current project is
-- ============================================================
do
  -- Three mobile stacks, three completely different vocabularies:
  -- `:XcodebuildBuildRun`, `:FlutterRun`, `npx expo start`. This section is one
  -- set of verbs over all of them -- `<leader>mr` is "run my app" whichever kind
  -- of project you're sitting in -- so the muscle memory is per-action, not
  -- per-stack. Each stack's own commands stay available underneath; this only
  -- adds the shortest path through them.
  --
  -- Two rules learned the hard way from the Xcode lane:
  --   * `<leader>mr` configures first if the project isn't configured yet,
  --     rather than telling you to go run setup and try again.
  --   * `<leader>m?` exists at all. Every one of these stacks fails in ways the
  --     editor can't fix but CAN name (no SDK version pinned, no scheme chosen,
  --     no node_modules), and guessing from a red error is the worst part of
  --     mobile tooling.

  ---Opens a terminal in a split running `cmd` from `dir`, the way `<C-S-r>` does.
  ---
  ---`magic = { file = false }` on both commands is load-bearing, not tidiness.
  ---Ex commands expand `%` to the current file name and `#` to the alternate
  ---one, and that expansion happens AFTER any `shellescape` we did -- so a
  ---project path or project name containing `%` splices the current buffer's
  ---name into the middle of an already-quoted shell argument. With a file open
  ---whose name contains a quote and a semicolon, that is arbitrary command
  ---execution; without one it is merely a corrupted command. Turning the magic
  ---off makes both strings literal.
  ---@param cmd string
  ---@param dir string|nil defaults to the cwd
  local function run_in_terminal(cmd, dir)
    vim.cmd.split()
    if dir then vim.cmd { cmd = 'lcd', args = { dir }, magic = { file = false } } end
    vim.cmd { cmd = 'terminal', args = { cmd }, magic = { file = false } }
    vim.cmd.startinsert()
  end

  ---@return string|nil dir the nearest ancestor of the cwd containing `marker`
  local function find_up(marker)
    local found = vim.fs.find(marker, { upward = true, path = vim.fn.getcwd(), limit = 1 })[1]
    return found and vim.fs.dirname(found) or nil
  end

  ---Which kind of mobile project are we in?
  ---
  ---The DEEPEST marker wins, not a fixed stack order. An `ios/` folder with an
  ---xcodeproj inside an Expo app is the normal case and Expo has to win there,
  ---but a fixed "Expo beats Xcode" rule gets the mirror case wrong: a native
  ---iOS app sitting in a JS monorepo would be dragged to the monorepo root by
  ---any `package.json` anywhere above it. Nearest-marker-wins handles both, and
  ---is also just what you mean by "this project".
  ---@return string|nil stack, string|nil root
  local function detect()
    ---@type {stack: string, root: string, depth: integer}|nil
    local best

    local function consider(stack, root)
      if not root then return end
      local depth = select(2, root:gsub('/', ''))
      if not best or depth > best.depth then best = { stack = stack, root = root, depth = depth } end
    end

    consider('flutter', find_up 'pubspec.yaml')

    local package_json = find_up 'package.json'
    if package_json then
      -- Unreadable, a directory, or nonexistent-by-the-time-we-look: a manifest
      -- we can't read is a manifest that doesn't identify anything, not a
      -- reason for every mobile key to throw.
      local ok, lines = pcall(vim.fn.readfile, vim.fs.joinpath(package_json, 'package.json'))
      local manifest = ok and table.concat(lines, '\n') or ''
      -- `expo` as a dependency is the reliable marker; `app.json` alone is not,
      -- plenty of non-Expo projects have one.
      if manifest:match '"expo"%s*:' then
        consider('expo', package_json)
      elseif manifest:match '"react%-native"%s*:' then
        consider('react-native', package_json)
      end
    end

    -- Every Xcode verb needs SECTION 22, which only loads on macOS. Detecting a
    -- stack we can't act on would just move the failure from "no mobile project
    -- here" to E492 on a missing command.
    if is_mac then
      consider('xcode', find_up 'Package.swift')
      -- `.xcodeproj`/`.xcworkspace` are directories, so `vim.fs.find`'s
      -- file-name matching doesn't see them the way it sees the manifests --
      -- scan each ancestor's entries instead, so opening nvim in a subfolder of
      -- an app still finds it, matching what SECTION 22's own settings lookup
      -- does. Read the directory rather than globbing a path built by
      -- concatenation: `vim.fn.glob` would treat `[`, `*` or `?` in a real
      -- folder name as pattern syntax and quietly find nothing.
      for dir in vim.fs.parents(vim.fs.joinpath(vim.fn.getcwd(), 'x')) do
        for entry in vim.fs.dir(dir) do
          if entry:match '%.xcodeproj$' or entry:match '%.xcworkspace$' then
            consider('xcode', dir)
            break
          end
        end
        if best and best.stack == 'xcode' then break end
      end
    end

    if not best then return nil, nil end
    return best.stack, best.root
  end

  -- [[ Monorepo: looking DOWNWARD ]]
  -- Walking up answers "which project am I in", which is the wrong question at
  -- a monorepo root -- there the apps are below you, and `<leader>mr` from the
  -- top would otherwise just say "no mobile project here" and make you `:cd`.
  --
  -- Only consulted when the upward walk found nothing, so the common case never
  -- pays for it.
  local JUNK = { 'node_modules', '.git', 'build', 'Pods', '.dart_tool', 'DerivedData', 'dist', '.next', 'vendor', '.venv', 'Carthage' }
  local SEARCH_DEPTH = 4 -- same bound `:XcodebuildSetup` uses for its own project search

  ---@return {stack: string, root: string}[]
  local function find_projects_below()
    local cwd = vim.fn.getcwd()
    local command
    if vim.fn.executable 'fd' == 1 then
      command = { 'fd', '--hidden', '--no-ignore', '--max-depth', tostring(SEARCH_DEPTH), '--absolute-path' }
      for _, dir in ipairs(JUNK) do
        vim.list_extend(command, { '--exclude', dir })
      end
      vim.list_extend(command, { '^(pubspec\\.yaml|package\\.json|Package\\.swift)$|\\.(xcodeproj|xcworkspace)$', cwd })
    else
      command = { 'find', cwd, '-maxdepth', tostring(SEARCH_DEPTH) }
      for _, dir in ipairs(JUNK) do
        vim.list_extend(command, { '-name', dir, '-prune', '-o' })
      end
      vim.list_extend(command, { '(', '-name', 'pubspec.yaml', '-o', '-name', 'package.json', '-o', '-name', 'Package.swift', '-o', '-name', '*.xcodeproj', '-o', '-name', '*.xcworkspace', ')', '-print' })
    end

    local found, xcode_roots = {}, {}
    for _, path in ipairs(vim.fn.systemlist(command)) do
      -- `fd` terminates directory results with a slash, and `.xcodeproj` /
      -- `.xcworkspace` (and, occasionally, something named `package.json`) ARE
      -- directories. Left on, `basename` comes back empty and `dirname` returns
      -- the match itself instead of its parent, so every such hit is misread.
      path = path:gsub('/+$', '')
      local dir, name = vim.fs.dirname(path), vim.fs.basename(path)
      -- `or` on every arm, not just some: `fd` and `find` return a directory's
      -- entries in different orders, so a dir holding both a pubspec.yaml and an
      -- expo package.json would resolve to a different stack depending on which
      -- tool is installed. First marker seen wins, and the scan is sorted below,
      -- so the answer is at least stable per machine.
      if name == 'pubspec.yaml' then
        found[dir] = found[dir] or 'flutter'
      elseif name == 'Package.swift' then
        -- Same `is_mac` gate `detect()` applies: a stack we cannot act on is
        -- worse than no stack, because SECTION 22 never loaded to serve it.
        if is_mac then found[dir] = found[dir] or 'xcode' end
      elseif name == 'package.json' then
        local ok, lines = pcall(vim.fn.readfile, path)
        local manifest = ok and table.concat(lines, '\n') or ''
        if manifest:match '"expo"%s*:' then
          found[dir] = found[dir] or 'expo'
        elseif manifest:match '"react%-native"%s*:' then
          found[dir] = found[dir] or 'react-native'
        end
      else
        table.insert(xcode_roots, dir)
      end
    end

    -- Flutter and React Native both generate `ios/` and `macos/` folders with a
    -- real xcodeproj inside. Offering those as separate projects would bury the
    -- one project the repo actually has under three spellings of it.
    for _, dir in ipairs(xcode_roots) do
      local generated = false
      for owner, stack in pairs(found) do
        if (stack == 'flutter' or stack == 'expo' or stack == 'react-native') and vim.startswith(dir, owner .. '/') then generated = true end
      end
      if not generated and is_mac then found[dir] = found[dir] or 'xcode' end
    end

    local projects = {}
    for root, stack in pairs(found) do
      table.insert(projects, { stack = stack, root = root })
    end
    table.sort(projects, function(a, b) return a.root < b.root end)
    return projects
  end

  -- One pick per directory, remembered for the session: a monorepo with several
  -- apps shouldn't ask again on every keypress.
  local chosen_below = {}

  ---Every one of these tools resolves its own project by walking UP from where
  ---Neovim is sitting -- xcodebuild.nvim keys its whole settings file off the
  ---cwd, flutter-tools walks up from the current buffer, and `npx expo` just
  ---uses the process cwd. So having picked a project two directories down, we
  ---have to actually go there, or every tool re-derives a different answer and
  ---you get "No pubspec.yaml file found" from a repo that plainly has one.
  ---
  ---`tcd` rather than `cd`: the move is scoped to this tab, so a second tab
  ---sitting in another app of the same monorepo keeps its own project.
  ---@param root string
  ---@return boolean entered false if the directory is gone
  local function enter(root)
    if vim.fn.getcwd() == root then return true end

    -- `magic = { file = false }` for the same reason `run_in_terminal` needs it,
    -- and it is NOT optional here: `:tcd` expands its argument, so a backtick in
    -- a project path runs as a shell command and `%`/`#` splice in buffer names.
    -- Verified: a directory named with backticks executed the command and then
    -- silently left the cwd unchanged, so the failure isn't even loud.
    local ok = pcall(vim.cmd, { cmd = 'tcd', args = { root }, magic = { file = false } })
    if not ok then
      vim.notify(('%s is gone.'):format(vim.fn.fnamemodify(root, ':~')), vim.log.levels.WARN)
      return false
    end

    vim.notify(('Working in %s'):format(vim.fn.fnamemodify(root, ':~')), vim.log.levels.INFO)
    return true
  end

  ---Resolves the project to act on, asking when a monorepo offers a choice.
  ---@param on_project fun(stack: string, root: string)
  local function with_project(on_project)
    local stack, root = detect()
    if stack then
      if enter(root) then on_project(stack, root) end
      return
    end

    local cwd = vim.fn.getcwd()
    local remembered = chosen_below[cwd]
    if remembered then
      -- A remembered project can be deleted underneath us -- a branch switch, a
      -- `flutter clean`, a moved folder. Without dropping the memo on that, every
      -- mobile key stays wedged on the dead path until `:MobileForget`, and any
      -- new project below is unreachable.
      if enter(remembered.root) then return on_project(remembered.stack, remembered.root) end
      chosen_below[cwd] = nil
      vim.notify('Forgot it -- press again to pick another.', vim.log.levels.INFO)
      return
    end

    local xcode_note = is_mac and ', and an .xcodeproj/.xcworkspace/Package.swift' or ''
    local projects = find_projects_below()
    if #projects == 0 then
      vim.notify(
        ('No mobile project here or in the %d levels below. Looked for pubspec.yaml, an "expo" dependency in package.json%s, from %s.'):format(SEARCH_DEPTH, xcode_note, cwd),
        vim.log.levels.WARN
      )
      return
    end

    local function use(project)
      -- Keyed by the directory the question was asked FROM, which `enter` is
      -- about to change -- so capture it before moving, or the answer gets
      -- filed under the project's own path and the monorepo root asks again.
      -- Written only once the move succeeded: the picker is async, so the root
      -- can vanish while it's open, and remembering a root we already know is
      -- dead burns the next press re-discovering that.
      if not enter(project.root) then return end
      chosen_below[cwd] = project
      on_project(project.stack, project.root)
    end

    if #projects == 1 then return use(projects[1]) end

    vim.ui.select(projects, {
      prompt = 'Which project?',
      format_item = function(project) return ('%-13s %s'):format(project.stack, vim.fs.relpath(cwd, project.root) or project.root) end,
    }, function(project)
      if project then use(project) end
    end)
  end

  -- Flutter's chosen device, per project root. See the APP_STARTED hook below.
  local flutter_device = {}

  -- Matched by PREFIX, because `flutter devices` reports the platform
  -- arch-suffixed: a Mac is `darwin-arm64` (or `darwin-x64`), an Android device
  -- is `android-arm64`/`android-x86`. An exact-match table looks right and
  -- matches almost nothing -- and `macos` isn't a platform at all, it's the
  -- device ID in the previous column. Anything unmatched falls to the picker.
  local FLUTTER_BUILD_TARGET = {
    { '^ios', 'ios' },
    { '^android', 'apk' },
    { '^darwin', 'macos' },
    { '^web', 'web' },
    { '^linux', 'linux' },
    { '^windows', 'windows' },
  }

  ---@param platform string|nil as reported by `flutter devices`
  ---@return string|nil target for `flutter build <target>`
  local function build_target_for(platform)
    if type(platform) ~= 'string' then return nil end
    for _, row in ipairs(FLUTTER_BUILD_TARGET) do
      if platform:match(row[1]) then return row[2] end
    end
  end

  vim.api.nvim_create_user_command('MobileForget', function()
    chosen_below, flutter_device = {}, {}
    vim.notify('Forgot the remembered project and device for every directory.', vim.log.levels.INFO)
  end, { desc = 'Re-ask which project and device the mobile lane should use' })

  ---Runs `action` for the resolved project, or explains why it can't.
  ---@param verb string the key's name, for the error message
  ---@param actions table<string, fun(root: string)>
  local function dispatch(verb, actions)
    with_project(function(stack, root)
      local action = actions[stack]
      if not action then
        vim.notify(('No "%s" for a %s project.'):format(verb, stack), vim.log.levels.WARN)
        return
      end
      action(root)
    end)
  end

  -- [[ Which device? ]]
  -- Xcode saves a chosen device in its project settings; Flutter has no such
  -- notion, so a bare `flutter run` with a phone AND a Mac AND Chrome attached
  -- exits(1) with "More than one device connected". flutter-tools does recover
  -- -- it catches that string and offers a picker -- but you eat a red error
  -- first, and nothing is remembered, so the next run does it again.
  --
  -- So: ask on the first run of a project, then reuse the answer. `<leader>md`
  -- re-picks (it runs on select, which lands back here and overwrites this).
  -- Learned from the plugin's own APP_STARTED event rather than from the picker,
  -- so a device chosen through any other route is remembered too -- including a
  -- plain `:FlutterRun` fired from a subdirectory, which is why the key is the
  -- project root rather than the cwd. Keying on cwd only agrees with the reader
  -- when you happened to be standing in the root, i.e. it fails in exactly the
  -- "any other route" case the paragraph above promises.
  vim.api.nvim_create_autocmd('User', {
    group = vim.api.nvim_create_augroup('mobile-flutter-device', { clear = true }),
    pattern = 'FlutterToolsAppStarted',
    callback = function()
      local device = require('flutter-tools.commands').current_device()
      if not (device and device.id) then return end
      local root = select(2, detect())
      if not root then return end

      -- A reuse run goes through `FlutterRun -d <id>`, and flutter-tools parses
      -- that back into literally `{ id = ... }` -- no name, no platform. Blindly
      -- storing it would erase what the picker taught us on the first run, so
      -- `<leader>mb` would lose its target and `<leader>mr` would start saying
      -- "Running on 00008140-..." instead of the device's name.
      local known = flutter_device[root]
      if known and known.id == device.id then device = vim.tbl_extend('keep', device, known) end
      flutter_device[root] = device
    end,
  })

  -- [[ Run ]]
  -- The Xcode half is where the auto-configure lives. xcodebuild.nvim's own
  -- `build_and_run` refuses with "run XcodebuildSetup first" when the project
  -- has no saved scheme/device, so this runs setup and picks the action back up
  -- once it's actually finished.
  --
  -- Finishing is detected by POLLING `is_configured()`, not by waiting on
  -- `XcodebuildProjectSettingsUpdated`. That event looked like the right hook
  -- and isn't: every emitter sits inside `select_testplan`, while the fields
  -- `is_app_configured()` requires -- bundleId, appPath, productName -- are
  -- written afterwards by `update_settings`, which the wizard calls with no
  -- callback and which emits nothing at all. So for an app project the last
  -- event always lands while `is_configured()` is still false, and an
  -- event-driven version walks you through the whole wizard and then silently
  -- does nothing. (SPM projects happen to escape it, which is what made this
  -- look like it worked.)
  local setup_poll

  ---`is_configured()` is a global boolean with no notion of WHICH project it
  ---describes, and the wizard's project picker overwrites only the project
  ---fields -- scheme, destination, bundleId and friends survive from whatever
  ---was configured before. So after switching projects it happily reports
  ---"configured" using the previous app's scheme, and a build fires against a
  ---mismatched setup. Tie the answer to the root we were actually dispatched
  ---for, which also stops an abandoned wizard's poll from being satisfied by an
  ---unrelated project's configuration completing later.
  ---@param root string
  ---@return boolean
  local function configured_for(root)
    local config = require 'xcodebuild.project.config'
    if not config.is_configured() then return false end
    local owner = config.settings.projectFile or config.settings.workingDirectory
    -- No owner recorded at all: trust `is_configured` rather than deadlock.
    if not owner then return true end
    return vim.startswith(vim.fs.normalize(owner), vim.fs.normalize(root))
  end

  ---Runs `action` now if the project is ready, otherwise sets it up first.
  ---@param root string the project the action belongs to
  ---@param action fun()
  local function xcode_after_setup(root, action)
    -- Guarded for the same reason the poll body is: reading the project's saved
    -- state can raise on a corrupt `settings.json`, and an unguarded read here
    -- takes the keypress down before any of the recovery below can run.
    local readable, ready = pcall(configured_for, root)
    if not readable then
      vim.notify(('Could not read this project\'s Xcode settings: %s'):format(ready), vim.log.levels.ERROR)
      return
    end
    if ready then return action() end

    -- Re-pressing mid-wizard swaps the queued action; it must NOT start a second
    -- wizard on top of the live one, or both chains run their own settings
    -- update and race. Only the first press opens it.
    local already_pending = setup_poll ~= nil
    if setup_poll then
      setup_poll:stop()
      setup_poll:close()
    end
    vim.notify(
      already_pending and 'Setup already open -- this action is queued instead.' or 'No scheme or device chosen yet -- setting up first.',
      vim.log.levels.INFO
    )
    setup_poll = assert(vim.uv.new_timer())

    local INTERVAL, DEADLINE = 400, 5 * 60 * 1000
    -- Wall clock, not tick-counting. libuv coalesces repeats it couldn't
    -- deliver, so a loop blocked by a synchronous shell-out advances a tick
    -- counter by roughly nothing -- measured 5 ticks across 6s of real time.
    -- The deadline exists to bound how long a stale trigger can linger, and a
    -- counter that stops advancing when the editor is busy bounds nothing.
    local started = vim.uv.now()
    local timer = setup_poll
    timer:start(
      INTERVAL,
      INTERVAL,
      vim.schedule_wrap(function()
        if timer:is_closing() then return end

        -- The whole body is guarded, and cleanup runs on BOTH paths. Unguarded,
        -- one throw skips the stop/close and the timer spins for the rest of the
        -- session at 400ms, one error per tick -- and because the same call
        -- throws on the next keypress too, the replace-and-close branch above
        -- can never be reached again. A `settings.json` containing `null` is
        -- enough to trigger it. Terminal cleanup belongs on the error path.
        local ok, done = pcall(configured_for, root)
        local expired = vim.uv.now() - started >= DEADLINE
        if ok and not done and not expired then return end

        timer:stop()
        timer:close()
        if setup_poll == timer then setup_poll = nil end

        if ok and done then
          action()
        elseif not ok then
          vim.notify(('Stopped waiting for setup: %s'):format(done), vim.log.levels.ERROR)
        else
          -- Silence here reads as "it's still coming" forever.
          vim.notify('Setup did not finish within 5 minutes -- press again when you are ready.', vim.log.levels.WARN)
        end
      end)
    )

    if not already_pending then require('xcodebuild.actions').configure_project() end
  end

  -- flutter-tools holds off registering its `:Flutter*` commands until you enter
  -- a `*.dart` buffer or a `pubspec.yaml`. So in a Flutter project where you
  -- haven't opened one yet -- which is exactly where you'd reach for "run my
  -- app" -- `:FlutterRun` does not exist and the key dies with E492. Firing its
  -- own trigger is cheaper and less surprising than opening a buffer behind
  -- your back, and it's a no-op once the commands are up.
  ---@param command string
  ---@return fun()
  local function flutter(command)
    return function()
      -- BEFORE the nudge below, not after, and not left to the `FileType dart`
      -- hook in SECTION 23. flutter-tools registers its Dart adapter inside the
      -- `start()` that the nudge triggers, and it only does so if nvim-dap is
      -- already loadable -- otherwise it silently falls back to the plain job
      -- runner and every `<leader>mr` runs UNDEBUGGED, notifying "debugger
      -- runner was request but nvim-dap is not installed!". The `FileType dart`
      -- hook doesn't cover this path at all: the nudge is a `BufEnter` on
      -- `pubspec.yaml`, which never produces a dart filetype, so pressing
      -- `<leader>mr` without a .dart buffer open missed it entirely.
      -- Reported, not swallowed. Its two sibling call sites both notify on
      -- failure, and a half-installed dap (require succeeds, `dapui.setup`
      -- throws) is invisible otherwise: flutter-tools sees dap and debugs
      -- happily, but no panes are wired and nothing ever says why.
      local debugger_ok, debugger_err = pcall(ensure_debugger)
      if not debugger_ok then vim.notify('Debugger setup failed, running undebugged: ' .. tostring(debugger_err), vim.log.levels.WARN) end

      if vim.fn.exists ':FlutterRun' == 0 then vim.api.nvim_exec_autocmds('BufEnter', { pattern = 'pubspec.yaml' }) end

      -- With no Flutter on PATH at all, flutter-tools hands its resolver a nil
      -- path and dies deep in `executable.lua` with a raw E5108 traceback that
      -- names nothing useful. Catch it here and point at the key that explains
      -- it. The narrower case of an SDK that IS on PATH but doesn't resolve (an
      -- asdf shim with no pinned version) fails asynchronously inside
      -- flutter-tools instead, so it can't be caught from this side -- that one
      -- surfaces as flutter-tools' own message, and `<leader>m?` diagnoses it.
      if vim.fn.executable 'flutter' == 0 then
        vim.notify('flutter is not on PATH. <leader>m? explains what to install.', vim.log.levels.ERROR)
        return
      end

      vim.cmd(command)
    end
  end

  ---Runs the app, asking which device the first time. Kept below `flutter`'s
  ---definition: Lua locals aren't in scope before it, so calling it earlier
  ---resolves `flutter` to a nil global.
  ---@param root string
  local function flutter_run(root)
    local device = flutter_device[root]
    if not device then
      -- `:FlutterDevices` runs the app on whatever you pick, so this IS the run.
      return flutter 'FlutterDevices'()
    end
    -- Name it every time. "Why did it pick that one?" is only a question when
    -- the editor stays quiet about what it chose.
    vim.notify(('Running on %s'):format(device.name or device.id), vim.log.levels.INFO)
    -- Deliberately NOT shellescaped. There is no shell here: flutter-tools does
    -- `vim.split(args, ' ')` and spawns via libuv, so quotes added for a shell
    -- that never runs end up inside the device id itself and match no device.
    flutter(('FlutterRun -d %s'):format(device.id))()
  end

  local function map(keys, action, desc) vim.keymap.set('n', keys, action, { desc = desc }) end

  map('<leader>mr', function()
    dispatch('run', {
      xcode = function(root) xcode_after_setup(root, function() require('xcodebuild.actions').build_and_run() end) end,
      flutter = flutter_run,
      expo = function(root) run_in_terminal('npx expo start', root) end,
      ['react-native'] = function(root) run_in_terminal('npx react-native start', root) end,
    })
  end, 'Mobile: [R]un this app')

  -- Compile, don't launch. Xcode has a real build-only action; Flutter needs a
  -- target platform, since `flutter build` alone isn't a command -- take it from
  -- the device you already picked and only ask when there's nothing to infer
  -- from. Expo's equivalent is `export`, which bundles without starting Metro.
  map('<leader>mb', function()
    dispatch('build', {
      xcode = function(root) xcode_after_setup(root, function() require('xcodebuild.actions').build() end) end,
      flutter = function(root)
        local remembered = flutter_device[root]
        local target = remembered and build_target_for(remembered.platform)
        if target then return run_in_terminal(('flutter build %s'):format(target), root) end

        vim.ui.select({ 'ios', 'apk', 'appbundle', 'macos', 'web' }, { prompt = 'flutter build' }, function(choice)
          if choice then run_in_terminal(('flutter build %s'):format(choice), root) end
        end)
      end,
      expo = function(root) run_in_terminal('npx expo export', root) end,
    })
  end, 'Mobile: [B]uild without launching')

  map('<leader>mR', function()
    dispatch('reload', {
      xcode = function() vim.cmd 'XcodebuildBuildRun' end, -- no hot reload for a native build
      flutter = flutter 'FlutterReload',
      expo = function() vim.notify("Metro reloads on save. Press 'r' in the Metro terminal to force it.", vim.log.levels.INFO) end,
    })
  end, 'Mobile: hot [R]eload')

  map('<leader>md', function()
    dispatch('device picker', {
      xcode = function() vim.cmd 'XcodebuildSelectDevice' end,
      flutter = flutter 'FlutterDevices',
      expo = function(root) run_in_terminal('npx expo start --ios', root) end,
    })
  end, 'Mobile: pick a [D]evice')

  map('<leader>mt', function()
    dispatch('test', {
      xcode = function() vim.cmd 'XcodebuildTest' end,
      flutter = function(root) run_in_terminal('flutter test', root) end,
      expo = function(root) run_in_terminal('npm test', root) end,
      ['react-native'] = function(root) run_in_terminal('npm test', root) end,
    })
  end, 'Mobile: run [T]ests')

  map('<leader>ms', function()
    dispatch('setup', {
      xcode = function() vim.cmd 'XcodebuildSetup' end,
      flutter = flutter 'FlutterDevices', -- a device is all Flutter needs chosen
      expo = function(root) run_in_terminal('npm install', root) end,
      ['react-native'] = function(root) run_in_terminal('npm install', root) end,
    })
  end, 'Mobile: [S]etup this project')

  -- [[ Doctor ]]
  -- Each stack has a real doctor; the value added here is checking the things
  -- that sit *between* the editor and that doctor, which is where the confusing
  -- failures actually live -- an unpinned asdf version, an unconfigured scheme,
  -- an uninstalled node_modules. Those are printed first, then the real tool runs.
  local function report(lines)
    vim.notify(table.concat(lines, '\n'), vim.log.levels.INFO, { title = 'Mobile doctor' })
  end

  -- A Flutter or RN app has a native half, and opening `ios/Runner/AppDelegate.swift`
  -- lights it up red: sourcekit-lsp attaches, but with no `buildServer.json` it
  -- has no framework search paths, so `import Flutter` becomes "No such module
  -- 'Flutter'" on line 3 of a file that compiles perfectly -- one SourceKit
  -- error, entirely phantom, on a real Flutter app.
  --
  -- The Xcode doctor already names this, but you never reach it from here --
  -- `<leader>m?` in a Flutter project is the Flutter doctor. So it gets checked
  -- from this side too, where the Swift file you're staring at actually lives.
  ---@param dir string a native shell directory (`<root>/ios`, `<root>/macos`)
  ---@return string|nil path where THIS project's compile flags would live
  local function compile_flags_path(dir)
    local ok, lines = pcall(vim.fn.readfile, vim.fs.joinpath(dir, 'buildServer.json'))
    if not ok then return nil end
    local decoded, config = pcall(vim.json.decode, table.concat(lines, '\n'))
    if not decoded or type(config) ~= 'table' then return nil end

    -- Two storage layouts, and picking the wrong one reports a working project
    -- as broken. `xcode-build-server config` writes kind="xcode", whose flags go
    -- to a hashed file in the shared cache. Anything else -- `parse`, or no
    -- `kind` key at all, which the server itself defaults to "manual" -- uses
    -- `<dir>/.compile`. Mirrors `get_compile_file` in the server.
    if config.kind == 'xcode' then
      local build_root = config.build_root or dir
      -- `md5` is BSD-only. It's reachable here because this whole check runs on
      -- every host (a Flutter repo commits its `ios/` folder), and an
      -- unguarded `vim.system` on a missing binary doesn't fail soft -- it
      -- throws ENOENT out of the keymap. `native_shell_notes` gates the whole
      -- thing on macOS now, so this is the second line of defence rather than
      -- the only one, but the doctor is the LAST thing that should ever be the
      -- error you have to debug.
      local ran, result = pcall(function() return vim.system({ 'md5', '-q', '-s', build_root }):wait() end)
      local hash = ran and vim.trim(result.stdout or '') or ''
      if hash == '' then return nil end

      -- The cache is nested one level deeper than it looks: the server keys it
      -- by the LSP root path with every `/` turned into `-`, THEN puts the
      -- hashed compile file inside. Flattening that away points at a path that
      -- never exists, so every correctly-configured project reports as broken --
      -- the exact false alarm this check was rewritten to stop producing.
      -- Mirrors `build_initialize` + `get_compile_file` in the server.
      return vim.fs.joinpath(
        vim.env.HOME,
        'Library/Caches/xcode-build-server',
        (dir:gsub('/', '-')),
        ('compile_file-%s-%s'):format(config.scheme or '_last', hash)
      )
    end

    return vim.fs.joinpath(dir, '.compile')
  end

  ---@param root string
  ---@return string[]
  local function native_shell_notes(root)
    local notes = {}
    -- macOS only, and not merely because the tooling is: an `ios/` folder is
    -- committed to every Flutter repo, so this runs on Linux too, where none of
    -- sourcekit-lsp, xcode-build-server or Xcode exists. There is no phantom
    -- error to warn about on a host that can't produce one, and the advice
    -- ("brew install ...") would be wrong.
    if not is_mac then return notes end

    for _, platform in ipairs { 'ios', 'macos' } do
      local dir = vim.fs.joinpath(root, platform)
      if vim.uv.fs_stat(vim.fs.joinpath(dir, 'Runner.xcodeproj')) then
        -- Both halves are required and neither implies the other.
        -- `buildServer.json` is what makes sourcekit-lsp launch the build server
        -- at all; the harvested flags are what that server has to answer with.
        -- Checking only the flags would call a project healthy that sourcekit
        -- never even talks to.
        local flags = compile_flags_path(dir)
        if not flags then
          local fix = vim.fn.executable 'xcode-build-server' == 0 and 'Start with: brew install xcode-build-server'
            or ('Run: cd %s && xcode-build-server config -workspace Runner.xcworkspace -scheme Runner'):format(platform)
          table.insert(notes, ('! %s/ Swift shows phantom errors ("No such module \'Flutter\'"). %s'):format(platform, fix))
        elseif vim.uv.fs_stat(flags) then
          table.insert(notes, ('ok %s/ has compile flags'):format(platform))
        else
          table.insert(
            notes,
            ('! %s/ build server is bound but has no flags yet -- needs one CLEAN build to harvest them (see the README recipe)'):format(platform)
          )
        end
      end
    end
    return notes
  end

  map('<leader>m?', function()
    dispatch('doctor', {
      flutter = function(root)
        local notes = {}
        if vim.fn.executable 'flutter' == 0 then
          table.insert(notes, 'x flutter is not on PATH')
        elseif vim.fn.executable 'asdf' == 1 and vim.system({ 'asdf', 'where', 'flutter' }, { cwd = root }):wait().code ~= 0 then
          -- The exact failure this machine had: asdf shims exist, so `flutter`
          -- looks installed, but nothing is pinned so every invocation errors.
          table.insert(notes, 'x asdf has no flutter version set for this directory -- run `asdf set flutter <version>` (`asdf list flutter` to see what is installed)')
        else
          table.insert(notes, 'ok flutter SDK resolves')
        end
        vim.list_extend(notes, native_shell_notes(root))
        report(notes)
        run_in_terminal('flutter doctor', root)
      end,
      expo = function(root)
        local notes = {}
        table.insert(notes, vim.uv.fs_stat(vim.fs.joinpath(root, 'node_modules')) and 'ok node_modules present' or 'x node_modules missing -- <leader>ms installs them')
        table.insert(notes, vim.fn.executable 'watchman' == 1 and 'ok watchman present' or '! watchman not installed (Metro is slower without it: brew install watchman)')
        report(notes)
        run_in_terminal('npx expo-doctor', root)
      end,
      xcode = function()
        local config = require 'xcodebuild.project.config'
        report {
          config.is_configured() and ('ok configured: scheme %s, device %s'):format(config.settings.scheme or '?', config.settings.deviceName or '?') or 'x not configured yet -- <leader>ms, or just press <leader>mr and it will ask',
          vim.fn.executable 'xcbeautify' == 1 and 'ok xcbeautify present' or '! xcbeautify missing, build logs stay raw (brew install xcbeautify)',
          vim.fn.executable 'xcode-build-server' == 1 and 'ok xcode-build-server present' or '! xcode-build-server missing, so sourcekit-lsp will not understand an .xcodeproj (brew install xcode-build-server)',
        }
        vim.cmd 'checkhealth xcodebuild'
      end,
    })
  end, 'Mobile: doctor (what is wrong with this project?)')

  -- [[ New project ]]
  -- The honest answer to "what about a project that doesn't exist yet": both
  -- scaffolders are one CLI call, they just aren't ones you remember. Xcode is
  -- absent on purpose -- there is no supported way to generate an .xcodeproj
  -- from the command line, so that one really is "open Xcode once".
  map('<leader>mn', function()
    vim.ui.select({ 'Flutter app', 'Expo app (TypeScript)' }, { prompt = 'New mobile project' }, function(choice)
      if not choice then return end
      vim.ui.input({ prompt = 'Project name: ' }, function(name)
        if not name or name == '' then return end
        local command = choice:match '^Flutter' and ('flutter create %s'):format(vim.fn.shellescape(name))
          or ('npx create-expo-app@latest %s --template blank-typescript'):format(vim.fn.shellescape(name))
        run_in_terminal(command, vim.fn.getcwd())
      end)
    end)
  end, 'Mobile: [N]ew project')

  require('which-key').add {
    { '<leader>m', group = '[M]obile' },
    { '<leader>d', group = '[D]ebug' }, -- bound at file scope, grouped here where which-key exists
  }
end

-- The line beneath this is called `modeline`. See `:help modeline`
-- vim: ts=2 sts=2 sw=2 et
