# nvim config

Personal Neovim config, built on [kickstart.nvim](https://github.com/nvim-lua/kickstart.nvim).
Single `init.lua`, meant to be read top to bottom.

## Setup

```sh
git clone <this repo> ~/.config/nvim
nvim
```

That's it. This config uses `vim.pack`, Neovim's own built-in plugin manager
(new in 0.12) — there's no separate plugin manager to install and no sync
step to run. The first time you launch `nvim` it will clone every plugin
listed in `init.lua` automatically, then you're up and running.

Requires **Neovim ≥ 0.12**.

For Swift support, `sourcekit-lsp` must be on your `PATH` — it ships with the
Xcode command line tools (`xcode-select --install` if you don't have them).
Everything else (LSP servers, formatters) installs itself via Mason.

Also install `ripgrep`, `fd`, and `tree-sitter-cli` (`brew install ripgrep fd
tree-sitter-cli`) — Telescope's live grep (`<leader>sg`, `<D-S-f>`)
hard-requires `ripgrep` and won't work without it; `fd` just makes file
search faster; `tree-sitter-cli` is required to compile treesitter parsers
(note: Homebrew's `tree-sitter` formula only installs the library, not the
CLI — it's a separate package).

`run.sh`, `build.sh`, and `test.sh` in this repo's root are hello-world
scripts for testing the `<D-r>`/`<D-b>` Cmd-chords below.

## Plugins

**UI / core**
- `guess-indent.nvim` — auto-detect file indentation
- `gitsigns.nvim` — git gutter signs + hunk stage/reset/preview/nav
- `which-key.nvim` — shows pending keybinds as you type them
- `rose-pine/neovim` — colorscheme
- `todo-comments.nvim` — highlights TODO/NOTE/etc in comments
- `mini.nvim` — grab-bag: `mini.ai` (textobjects), `mini.surround`, `mini.statusline`

**Search**
- `telescope.nvim` (+ `plenary.nvim`, `telescope-ui-select.nvim`, `telescope-fzf-native.nvim`) — fuzzy finder for files, grep, LSP, help, etc.

**LSP**
- `nvim-lspconfig`, `mason.nvim`, `mason-lspconfig.nvim`, `mason-tool-installer.nvim` — LSP server management
- `fidget.nvim` — LSP progress notifications
- Servers: `lua_ls`, `ts_ls` (JS/TS/React Native), `sourcekit` (Swift, via Xcode's `sourcekit-lsp` — not managed by Mason)

**Formatting**
- `conform.nvim` — `stylua` for Lua, `prettier` for JS/TS/JSX/TSX/JSON

**Completion**
- `blink.cmp`, `LuaSnip` — autocomplete + snippets

**Treesitter**
- `nvim-treesitter` — parsers for bash, c, diff, html, lua, luadoc, markdown(+inline), query, vim, vimdoc, swift, javascript, typescript, tsx, json

**Personal extras**
- `harpoon` (harpoon2 branch) — jump between a handful of pinned files
- `undotree` — visualize and navigate undo history
- `vim-fugitive` — full git porcelain (status/commit/push/log), complementing gitsigns' hunk-level work

## Keymaps

Leader key is **Space**.

### Search (`<leader>s*`, via Telescope)

| Key | Action |
|---|---|
| `<leader>sh` | Search help |
| `<leader>sk` | Search keymaps |
| `<leader>sf` | Search files |
| `<leader>ss` | Select Telescope picker |
| `<leader>sw` | Search current word |
| `<leader>sg` | Live grep |
| `<leader>sd` | Search diagnostics |
| `<leader>sr` | Resume last search |
| `<leader>s.` | Search recent files |
| `<leader>sc` | Search commands |
| `<leader>sn` | Search Neovim config files |
| `<leader>s/` | Live grep in open files |
| `<leader>/` | Fuzzy search in current buffer |
| `<leader><leader>` | Find existing buffers |

### LSP

| Key | Action |
|---|---|
| `grn` | Rename symbol |
| `gra` | Code action |
| `grD` | Goto declaration |
| `grr` | Goto references |
| `gri` | Goto implementation |
| `grd` | Goto definition |
| `grt` | Goto type definition |
| `gO` | Document symbols |
| `gW` | Workspace symbols |
| `<leader>th` | Toggle inlay hints |
| `<leader>q` | Diagnostics to quickfix list |

### Toggles (`<leader>t*`)

| Key | Action |
|---|---|
| `<leader>th` | Toggle inlay hints |
| `<leader>tb` | Toggle git blame line |
| `<leader>tw` | Toggle git word diff |

### Git hunks (`<leader>h*`, via gitsigns)

| Key | Action |
|---|---|
| `]c` / `[c` | Next / previous git change |
| `<leader>hs` | Stage hunk |
| `<leader>hr` | Reset hunk |
| `<leader>hS` | Stage buffer |
| `<leader>hR` | Reset buffer |
| `<leader>hp` | Preview hunk |
| `<leader>hi` | Preview hunk inline |
| `<leader>hb` | Blame line |
| `<leader>hd` | Diff against index |
| `<leader>hD` | Diff against last commit |
| `<leader>hq` / `<leader>hQ` | Hunk quickfix list (file / whole repo) |
| `ih` (in `o`/`x` mode) | Hunk textobject |

### Git porcelain (`<leader>g*`, via fugitive)

| Key | Action |
|---|---|
| `<leader>gh` / `<leader>gs` | Git status |
| `<leader>ga` | Git add . |
| `<leader>gu` | Git restore --staged . (unstage all) |
| `<leader>gc` | Git commit |
| `<leader>gp` | Git push |
| `<leader>gl` | Git log |

### Harpoon

| Key | Action |
|---|---|
| `<leader>a` | Add current file to Harpoon list |
| `<C-e>` | Toggle Harpoon quick menu |
| `<C-1>` .. `<C-4>` | Jump to Harpoon file 1-4 |

### Undotree

| Key | Action |
|---|---|
| `<leader>u` | Toggle Undotree |

### Formatting

| Key | Action |
|---|---|
| `<leader>f` | Format buffer |

### Cmd-chords (Ghostty)

Requires a terminal that forwards Cmd as `<D-...>` via the Kitty keyboard
protocol — Ghostty does this, plain Terminal.app does not. If a chord below
doesn't fire, that's a Ghostty `keybind` passthrough config issue, not an
`init.lua` bug.

| Key | Action |
|---|---|
| `<D-S-f>` | Project-wide search (live grep) |
| `<D-S-o>` / `<D-p>` | Find files |
| `<D-r>` | Run `run.sh` next to the current file, in a horizontal split terminal |
| `<D-b>` | Run `build.sh` next to the current file, in a horizontal split terminal |

### Misc

| Key | Action |
|---|---|
| `<C-h/j/k/l>` | Move focus between windows |
| `<Esc>` | Clear search highlight |
| `<Esc><Esc>` (terminal mode) | Exit terminal mode |

## Navigation refresher

A few core vim motions worth having muscle memory for:

- `h` `j` `k` `l` — left, down, up, right
- `w` / `b` / `e` — jump forward/back by word, or to end of word
- `0` / `^` / `$` — start of line, first non-blank char, end of line
- `gg` / `G` — top / bottom of file
- `f{char}` / `t{char}` — jump to (find) / before (till) a character on the line; `;`/`,` repeat
- `/pattern` + `n` / `N` — search forward, repeat next/previous match
- `ciw`, `daw`, `yiw` — change/delete/yank "inner word" (works with lots of other textobjects too, e.g. `ci"`, `da(`)

If any of this is unfamiliar, run `:Tutor` inside Neovim — it's an
interactive walkthrough and the fastest way to build the muscle memory.
