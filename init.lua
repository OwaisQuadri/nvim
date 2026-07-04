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
  vim.keymap.set('n', '<leader>w', '<C-w>', { desc = '[W]indow commands prefix' })

  vim.keymap.set('n', '<leader>wq', quit_window, { desc = '[W]indow [q]uit' })
  vim.keymap.set('n', '<leader>wQ', '<cmd>quitall<CR>', { desc = '[W]indow [Q]uit all' })

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
  vim.cmd.colorscheme 'catppuccin'

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
  local function make_filename_prominent() vim.api.nvim_set_hl(0, 'MiniStatuslineFilename', { link = 'Title', default = false }) end
  vim.api.nvim_create_autocmd('ColorScheme', { desc = 'Keep the statusline filename prominent', callback = make_filename_prominent })
  make_filename_prominent()

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
      vim.keymap.set('n', 'grd', builtin.lsp_definitions, { buffer = buf, desc = '[G]oto [D]efinition' })

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
      --  Most Language Servers support renaming across files, etc.
      map('grn', vim.lsp.buf.rename, '[R]e[n]ame')

      -- Execute a code action, usually your cursor needs to be on top of an error
      -- or a suggestion from your LSP for this to activate.
      map('gra', vim.lsp.buf.code_action, '[G]oto Code [A]ction', { 'n', 'x' })

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
    -- rust_analyzer = {},
    --
    -- Some languages (like typescript) have entire language plugins that can be useful:
    --    https://github.com/pmizio/typescript-tools.nvim
    --
    -- But for many setups, the LSP (`ts_ls`) will work just fine
    ts_ls = {},

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
      -- rust = { 'rustfmt' },
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

      -- For more advanced Luasnip keymaps (e.g. selecting choice nodes, expansion) see:
      --    https://github.com/L3MON4D3/LuaSnip?tab=readme-ov-file#keymaps
    },

    appearance = {
      -- 'mono' (default) for 'Nerd Font Mono' or 'normal' for 'Nerd Font'
      -- Adjusts spacing to ensure icons are aligned
      nerd_font_variant = 'mono',
    },

    completion = {
      -- By default, you may press `<c-space>` to show the documentation.
      -- Optionally, set `auto_show = true` to show the documentation after a delay.
      documentation = { auto_show = false, auto_show_delay_ms = 500 },
    },

    sources = {
      default = { 'lsp', 'path', 'snippets' },
    },

    snippets = { preset = 'luasnip' },

    -- Blink.cmp includes an optional, recommended rust fuzzy matcher,
    -- which automatically downloads a prebuilt binary when enabled.
    --
    -- By default, we use the Lua implementation instead, but you may enable
    -- the rust implementation via `'prefer_rust_with_warning'`
    --
    -- See `:help blink-cmp-config-fuzzy` for more information
    fuzzy = { implementation = 'lua' },

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
    { 'bash', 'c', 'diff', 'html', 'lua', 'luadoc', 'markdown', 'markdown_inline', 'query', 'vim', 'vimdoc', 'swift', 'javascript', 'typescript', 'tsx', 'json' }
  require('nvim-treesitter').install(parsers)

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

  vim.keymap.set('n', '<C-1>', function() harpoon:list():select(1) end, { desc = 'Harpoon to file 1' })
  vim.keymap.set('n', '<C-2>', function() harpoon:list():select(2) end, { desc = 'Harpoon to file 2' })
  vim.keymap.set('n', '<C-3>', function() harpoon:list():select(3) end, { desc = 'Harpoon to file 3' })
  vim.keymap.set('n', '<C-4>', function() harpoon:list():select(4) end, { desc = 'Harpoon to file 4' })
end

-- ============================================================
-- SECTION 12: PERSONAL EXTRAS -- UNDOTREE
-- Visualize and navigate the undo history tree
-- ============================================================
do
  vim.pack.add { gh 'mbbill/undotree' }

  -- Old config used <C-z>, which fights with the OS's own suspend-to-background chord.
  vim.keymap.set('n', '<leader>u', vim.cmd.UndotreeToggle, { desc = 'Toggle [U]ndotree' })
  vim.keymap.set('n', '<D-u>', vim.cmd.UndotreeToggle, { desc = 'Toggle [U]ndotree' })
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
-- SECTION 14: PERSONAL EXTRAS -- CMD-CHORD SHORTCUTS (GHOSTTY)
-- Mac Cmd/D-key chords, forwarded by Ghostty's Kitty-keyboard-protocol support
-- ============================================================
do
  -- Neovim's notation for the Mac Cmd/⌘ key is `<D-...>`. This only works in a
  -- terminal that forwards Cmd-chords using the Kitty keyboard protocol (Ghostty
  -- does; plain Terminal.app does not). If a chord below doesn't fire, that's a
  -- Ghostty `keybind` passthrough config issue, not a bug in this file.
  local builtin = require 'telescope.builtin'

  -- Show everything under root, gitignored or not -- these two shouldn't
  -- care whether the directory is even a git repo.
  vim.keymap.set(
    'n',
    '<D-S-f>',
    function() builtin.live_grep { additional_args = { '--hidden', '--no-ignore' } } end,
    { desc = 'Project-wide search (live grep)' }
  )
  vim.keymap.set(
    'n',
    '<D-S-o>',
    function() builtin.find_files { hidden = true, no_ignore = true } end,
    { desc = 'Find files' }
  )
  vim.keymap.set('n', '<D-p>', builtin.find_files, { desc = 'Find files' })

  -- Xcode-style file/location history: Cmd+[ / Cmd+] walks the jumplist
  -- backward/forward, same as <C-o>/<C-i> (already zz-centered). Cmd+Left/
  -- Right was the first choice, but Ghostty's defaults hard-consume those
  -- (translated to literal Ctrl-A/Ctrl-E, never reaching nvim); Cmd+[/]
  -- collided too (default: goto_split previous/next) until unbound in
  -- ~/.config/ghostty/config.
  vim.keymap.set('n', '<D-[>', '<C-o>zz', { desc = 'Back in jump history' })
  vim.keymap.set('n', '<D-]>', '<C-i>zz', { desc = 'Forward in jump history' })

  local function run_script_near_file(script_name)
    local dir = vim.fn.expand '%:p:h'
    if vim.fn.filereadable(dir .. '/' .. script_name) == 0 then
      vim.notify('No ' .. script_name .. ' in ' .. dir, vim.log.levels.WARN)
      return
    end
    vim.cmd.split()
    vim.cmd.lcd(dir)
    vim.cmd.terminal('./' .. script_name)
  end

  vim.keymap.set('n', '<D-r>', function() run_script_near_file 'run.sh' end, { desc = 'Run run.sh next to the current file' })
  vim.keymap.set('n', '<D-b>', function() run_script_near_file 'build.sh' end, { desc = 'Run build.sh next to the current file' })
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
  -- Cmd+S saves every modified buffer, not just the current one.
  vim.keymap.set({ 'n', 'i', 'v' }, '<D-s>', '<cmd>wa<CR>', { desc = 'Save all files' })

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

-- The line beneath this is called `modeline`. See `:help modeline`
-- vim: ts=2 sts=2 sw=2 et
