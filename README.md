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

For Swift and Xcode support (macOS only — the whole of `init.lua`'s SECTION 22
is skipped elsewhere): `sourcekit-lsp` comes with the Xcode command line tools
(`xcode-select --install`), so LSP alone works without Xcode. `xcodebuild` does
**not** — it needs full Xcode installed and selected (`xcode-select -p` must
point inside an `Xcode.app`, not at `/Library/Developer/CommandLineTools`), so
the build/run/test/debug half of SECTION 22 requires it. Two optional extras
make it noticeably nicer:

```sh
brew install xcbeautify xcode-build-server
```

`xcbeautify` formats the build log into something readable; `xcode-build-server`
is what teaches `sourcekit-lsp` to understand an `.xcodeproj`/`.xcworkspace`
(without it, completion works in Swift packages but not in an Xcode app
target). Both are detected at runtime — the config degrades quietly if they're
missing rather than erroring. Everything else (LSP servers, formatters) installs
itself via Mason — including `swiftformat` and `swiftlint`, though only on Apple
Silicon: neither publishes an `x86_64` macOS binary Mason can fetch, so on an
Intel Mac use `brew install swiftformat swiftlint` and the rest is unaffected.

Also install `ripgrep`, `fd`, and `tree-sitter-cli` (`brew install ripgrep fd
tree-sitter-cli`) — Telescope's live grep (`<leader>sg`, `<D-S-f>`)
hard-requires `ripgrep` and won't work without it; `fd` just makes file
search faster; `tree-sitter-cli` is required to compile treesitter parsers
(note: Homebrew's `tree-sitter` formula only installs the library, not the
CLI — it's a separate package).

Branch naming and other repo conventions live in [`CLAUDE.md`](CLAUDE.md).

`run.sh` opens a new Ghostty window running Neovim with this repo's
`init.lua` (`nvim -u init.lua .`) so you can try out config changes without
touching `~/.config/nvim`. `build.sh` is still a hello-world script for testing
the `<D-b>` Cmd-chord below.

`test.sh` is the headless smoke test: it boots `nvim --headless -u init.lua`
and asserts that the plugins, keymaps, formatters, linters, and LSP this config
wires up actually landed. It prints one JSON object per check and exits
non-zero if any fail, so it works as a pre-merge gate:

```sh
./test.sh
./test.sh | jq -c 'select(.ok == false)'
```

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
- Servers: `lua_ls`, `ts_ls` (JS/TS/React Native), `eslint`, `sourcekit` (Swift, via Xcode's `sourcekit-lsp` — not managed by Mason), `dartls` (Flutter, owned by `flutter-tools.nvim` — also not Mason's)

**Formatting & linting**
- `conform.nvim` — `stylua` for Lua, `prettier` for JS/TS/JSX/TSX/JSON/CSS/HTML/Markdown/YAML, `swiftformat` for Swift, `dart format` for Dart
- `nvim-lint` — `swiftlint` on Swift buffers (write / read / leaving insert mode)

**Mobile** — one `<leader>m*` lane over three stacks, see [Mobile](#mobile-leaderm)
- `xcodebuild.nvim` (macOS only) — build, run, test, debug, and manage an iOS/macOS/Swift-package project without opening Xcode: scheme and device pickers, test explorer, code coverage, log parsing
- `flutter-tools.nvim` — `dartls`, device/emulator pickers, hot reload, widget guides, the widget outline, and the Dart debugger
- React Native / Expo has no build/run plugin — it's `ts_ls` + `eslint` + `prettier` + `nvim-ts-autotag` for the code, and the mobile lane shells out to `npx expo` for the dev loop
- `nvim-dap`, `nvim-dap-ui` (+ `nvim-nio`) — the debugger, shared by the Swift lane (via Xcode's `lldb-dap`) and the Flutter lane

**Completion**
- `blink.cmp`, `LuaSnip` — autocomplete + snippets

**Treesitter**
- `nvim-treesitter` — parsers for bash, c, diff, html, lua, luadoc, markdown(+inline), query, vim, vimdoc, swift, dart, javascript, typescript, tsx, json, yaml
- `nvim-ts-autotag` — auto-close and auto-rename JSX/TSX tags (`<View>` gets its `</View>`, editing either side of the pair updates the other); mini.pairs closes brackets and quotes but has no concept of a tag

**Personal extras**
- `harpoon` (harpoon2 branch) — jump between a handful of pinned files
- `undotree` — visualize and navigate undo history
- `vim-fugitive` — full git porcelain (status/commit/push/log), complementing gitsigns' hunk-level work
- `neo-tree.nvim` (+ `nui.nvim`) — sidebar file explorer, kickstart's optional module, enabled
- `render-markdown.nvim` — renders markdown (READMEs, notes) prettily in the buffer
- `nvim-treesitter-context` — sticky headers: pins the enclosing function/class/struct (or markdown heading) to the top of the window
- `hardtime.nvim` — habit coach: flags inefficient key use (mashing `j`/`k`/arrows, repeated `w`/`b`, …) and hints a better motion. Gentle "hint" mode by default — it suggests, never blocks; `:Hardtime report` lists your top habits, `:Hardtime toggle` / `<leader>tH` turns it off. Flip the `strict` local in init.lua's SECTION 21 to `true` for blocking mode.

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
| `grn` | Rename symbol, and save the files it changed. Files you already had unsaved edits in are left for you to save, and anything it can't write is named in a warning. (The buffer you're standing in is the exception: the autosave writes it a moment later, unsaved work and all.) |
| `<D-.>` / `<leader>ca` | Quick fix -- code actions for the whole line the cursor is on (normal and visual; says so when no language server is attached) |
| `gra` | Quick fix / code action, same line-wide behaviour (Neovim's own default key) |
| `grD` | Goto declaration |
| `grr` | Goto references |
| `gri` | Goto implementation |
| `grd` | Goto definition |
| `grt` | Goto type definition |
| `gO` | Document symbols |
| `gW` | Workspace symbols |
| `<leader>th` | Toggle inlay hints |
| `<leader>q` | Diagnostics to quickfix LIST (the list of problems, not the quick fix menu -- that's `<D-.>`) |
| `]d` / `[d` | Next / previous diagnostic (crosses files) |
| `yd` | Yank the diagnostics on this line to the clipboard |
| `yD` | Yank every diagnostic in the buffer, line-numbered |

`yd` / `yD` copy the language server's own message as text, prefixed with the
file and line, rather than the rendered virtual text — so a `ts_ls` complaint
lands on the clipboard as:

```
broken.ts:1
ERROR: Type 'string' is not assignable to type 'number'.
```

which pastes into an issue or a chat as-is. Note `clipboard=unnamedplus` is on,
so these write to the real system clipboard.

### Toggles (`<leader>t*`)

| Key | Action |
|---|---|
| `<leader>th` | Toggle inlay hints |
| `<leader>tb` | Toggle git blame line |
| `<leader>tw` | Toggle git word diff |
| `<leader>tm` | Toggle markdown render (on by default in markdown buffers) |
| `<leader>tc` | Toggle sticky scope context (on by default) |
| `<leader>tH` | Toggle hardtime habit coach (on by default) |

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

### Mobile (`<leader>m*`)

One set of verbs over three stacks. Every key figures out what kind of project
you're in and talks to the right tool, so "run my app" is the same keystroke
whether it's an iOS app, a Flutter app, or an Expo app.

Detection walks up from the cwd and the **nearest** marker wins: `pubspec.yaml`
→ Flutter, an `expo` (or `react-native`) dependency in `package.json` → Expo/RN,
`Package.swift` / `*.xcodeproj` / `*.xcworkspace` → Xcode. Nearest-wins rather
than a fixed stack order, so an Expo app's own `ios/` xcodeproj doesn't hijack
it, and a native app sitting in a JS monorepo doesn't get dragged up to the
monorepo's `package.json`.

| Key | Action |
|---|---|
| `<leader>mr` | Run this app. Nothing chosen yet? It asks first (Xcode: scheme + device; Flutter: device) and then runs, rather than failing at you. The choice is reused after that — `:MobileForget` re-asks. With no SDK installed it says so instead of throwing |
| `<leader>mb` | **Build without launching.** Xcode builds; Flutter builds for the platform of the device you picked (matched by prefix, so `darwin-arm64` → `macos`); Expo bundles via `expo export` |
| `<leader>mR` | Hot reload (Flutter); rebuild-and-run for Xcode; Metro reloads on save |
| `<leader>md` | Pick a device / emulator |
| `<leader>mt` | Run tests |
| `<leader>ms` | Setup: scheme+device (Xcode), device (Flutter), `npm install` (Expo) |
| `<leader>m?` | **Doctor** — what's wrong with this project |
| `<leader>mn` | New project (`flutter create` / `create-expo-app`) |

`<leader>m?` is the one to remember. Each stack fails in ways the editor can't
fix but can name, and it checks those before handing off to the real tool
(`flutter doctor`, `npx expo-doctor`, `:checkhealth xcodebuild`): an asdf
install with no Flutter version pinned, an Xcode project with no scheme chosen,
a missing `node_modules`, a missing `xcbeautify` or `xcode-build-server`.

Whichever way it resolved, the lane then **moves you into that project**
(`:tcd`, so it's per-tab). It has to: every one of these tools re-derives its
own root from where Neovim is sitting, so dispatching from a monorepo root
without moving first gets you `flutter run` in the repo root and "No pubspec.yaml
file found".

From a **monorepo root** there's nothing to walk up to, so the lane searches
down instead (4 levels, skipping `node_modules`, `Pods`, `.dart_tool`, `build`
and friends). One project found means it just acts; several means it asks once
and remembers per directory — `:MobileForget` re-asks (it clears the remembered
Flutter device too). A Flutter or RN app's
generated `ios/`/`macos/` shells are folded into their parent rather than
offered as separate projects.

#### Phantom Swift errors in a Flutter app

Opening `ios/Runner/AppDelegate.swift` shows a red `No such module 'Flutter'` on
a file that builds fine. sourcekit-lsp attaches, but with no compile flags it
can't see the Flutter framework. `<leader>m?` flags this.

It is **not** unresolved packages — Pods can be fully installed and it still
happens. Two separate things have to be true: sourcekit must know to launch the
build server (`buildServer.json`), and that server must have flags to answer
with. Bind it first:

```sh
brew install xcode-build-server
cd ios && xcode-build-server config -workspace Runner.xcworkspace -scheme Runner
```

That writes `buildServer.json` with `kind: "xcode"`, meaning flags are harvested
from Xcode's own builds and cached under `~/Library/Caches/xcode-build-server/`.
Build once from Xcode.app and you're done.

If you build from the terminal instead, harvest them yourself — but note a
**clean** build is required, because an incremental one recompiles nothing and
so logs no compile commands:

```sh
xcodebuild -workspace Runner.xcworkspace -scheme Runner \
  -destination 'generic/platform=iOS' -configuration Debug \
  CODE_SIGNING_ALLOWED=NO clean build > /tmp/xcb.log 2>&1
xcode-build-server parse /tmp/xcb.log     # writes ios/.compile, flips kind to "manual"
```

Things that look sufficient and aren't: `config` on its own (binds the server,
gives it no flags); `flutter build ios` (leaves no parseable log — it drives
xcodebuild through its own build dir); and an incremental `xcodebuild` (0 compile
commands, so `.compile` comes out empty). `<leader>m?` knows both layouts and
tells you which step is missing rather than guessing.

Afterwards sourcekit type-checks the file properly — on a real app the phantom
error was replaced by a genuine unused-variable warning. Re-harvest after changing
dependencies. Add `ios/.compile` and `ios/buildServer.json` to the app's
`.gitignore`; they're machine-specific. SwiftLint's warnings in these files were
always real — only the SourceKit module errors were phantom.

### Occasional commands (no keymap, just type them)

Things you reach for a few times a year, so they're commands rather than keys.
`:Flutter<Tab>` and `:Xcodebuild<Tab>` complete the full list; `<leader>X` is a
searchable picker over every Xcode action.

| Command | Does |
|---|---|
| `:FlutterPubGet` / `:FlutterPubUpgrade` | Resolve / upgrade package versions |
| `:FlutterLspRestart` / `:FlutterReanalyze` | Restart `dartls` / re-run analysis after a dependency change |
| `:FlutterEmulators` | Launch an emulator (vs `<leader>md`, which picks an already-running device) |
| `:FlutterOutlineToggle` | Widget tree sidebar |
| `:FlutterDevTools` | Start DevTools |
| `:XcodebuildCleanDerivedData` | Nuke DerivedData — the "why won't it build" button |
| `:XcodebuildCleanBuild` | Clean, then build |
| `:XcodebuildBuildForTesting` | Build the test bundle without running it |
| `:XcodebuildAssetsManager` | Manage image/colour/data assets |
| `:XcodebuildShowConfig` | Print the current scheme/device/test plan |

For Expo, package resolution is plain `npm install` — that's what `<leader>ms`
runs. Metro's cache is `npx expo start --clear`.

**Flutter needs an SDK version pinned.** Under a version manager, `flutter` on
your `PATH` is a shim, and the analysis server lives inside the SDK itself. The
config resolves it with `asdf where flutter`, which respects a per-project
`.tool-versions`, but errors if nothing is pinned anywhere:

```sh
asdf list flutter          # what's installed
asdf set flutter <version> # globally, or in the project for per-project pinning
```

`<leader>m?` in a Flutter project tells you if this is your problem.

### Xcode (`<leader>x*`, macOS only)

Start in the project root and run `<leader>xs` once — it walks you through
picking the project file, scheme, device, and test plan, and saves them to
`.nvim/xcodebuild/settings.json` so it's a one-time step per project. The
project file may live in a subfolder (searched four levels deep); its directory
becomes the build's working directory. `:cd`-ing to another project mid-session
switches settings automatically.

| Key | Action |
|---|---|
| `<leader>X` | Picker with **every** Xcode action, including the ones not bound below |
| `<leader>xs` | Setup project (file, scheme, device, test plan) |
| `<leader>xb` / `<leader>xr` | Build / build & run |
| `<leader>xk` | Kill the running build or test |
| `<leader>xt` | Run tests (visual mode: run the selected tests) |
| `<leader>xT` | Run the current test class |
| `<leader>xe` | Toggle test explorer |
| `<leader>xl` | Toggle build logs |
| `<leader>xc` / `<leader>xC` | Toggle coverage marks / show coverage report |
| `<leader>xd` | Select device |
| `<leader>xf` | Project file manager (add/rename/delete, updating the Xcode project) |
| `<leader>xa` | Xcode code actions |
| `<leader>xL` | Run SwiftLint on this buffer now |
| `<leader>xo` | Open the current file in Xcode |

### Debug (`<leader>d*` + F-keys)

The F-keys and `<leader>du` are shared by every debugger; the `<leader>d*` verbs
below are the Swift ones (macOS only). Flutter debugging runs through
`<leader>mr`, which starts the app under the debugger via `flutter-tools`.

| Key | Action |
|---|---|
| `<leader>dd` / `<leader>dr` | Build & debug / debug without building (Swift) |
| `<leader>dt` / `<leader>dT` | Debug tests / debug the current test class |
| `<leader>db` / `<leader>dB` | Toggle breakpoint / message breakpoint |
| `<leader>du` | Toggle the debugger UI panels |
| `<leader>dx` | Terminate the debug session |
| `<F5>` | Continue |
| `<F10>` / `<F11>` / `<F12>` | Step over / into / out |

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
| `<leader>w` + `s/v/h/j/k/l/c/o/=` | Window commands prefix (split, move focus, close, etc. — see `:help CTRL-W`) |
| `\` | Toggle Neo-tree file explorer |
| `<leader>wt` | Open a terminal in a new split |
| `` <leader>` `` | Autoscroll toggle — hands-free word-by-word reading mode |
| `` ` `` (while autoscrolling) | Pause / unpause autoscroll |
| `:Autoscroll speed 2.0` | Set autoscroll pace in words per second (default 10, applies mid-session) |
| `<Esc>` | Clear search highlight |
| `<Esc><Esc>` (terminal mode) | Exit terminal mode — a single `<Esc>` just gets sent to the shell |

### Neo-tree file operations (focus the sidebar with `\`, then)

| Key | Action |
|---|---|
| `a` / `A` | Add file / add directory |
| `d` | Delete |
| `r` | Rename |
| `y` / `x` / `p` | Copy / cut / paste |
| `c` / `m` | Copy to / move to (typed destination path) |
| `T` / `u` / `U` | Trash / undo trash / restore from trash |
| `?` | Show every Neo-tree keymap (in-app help) |

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

## Windows setup

This config is authored on macOS but runs on Windows too. The Cmd (`<D-…>`)
chords are Mac/Ghostty-only; on Windows the same actions are bound to
Ctrl/leader chords (see the table below). Launch Neovim from **Git Bash** so
the shell and `PATH` match the `.sh` helper scripts.

### 1. Config path (junction, not `~/.config/nvim`)

Windows looks for the config at `%LOCALAPPDATA%\nvim`. Point it at this repo
with a directory junction (no admin required):

```cmd
:: back up any existing config first
if exist "%LOCALAPPDATA%\nvim" ren "%LOCALAPPDATA%\nvim" nvim.bak
mklink /J "%LOCALAPPDATA%\nvim" "C:\Users\Owais\Documents\github\nvim"
```

Edits in the repo now apply immediately — the junction is the live config.

### 2. Install Neovim and CLI tools (winget)

```powershell
winget install --id Neovim.Neovim -e            # must be >= 0.12 for vim.pack
winget install --id BurntSushi.ripgrep.MSVC -e  # live grep (<leader>sg) hard-requires this
winget install --id sharkdp.fd -e               # faster file search
winget install --id tree-sitter.tree-sitter-cli -e
```

The Swift/Xcode lane is **not** available on Windows — `sourcekit-lsp`,
`xcodebuild`, `swiftformat`, and `swiftlint` are Mac/Xcode only, so `init.lua`'s
SECTION 22 skips itself and Mason isn't asked to install those tools. Flutter and
React Native/Expo work fine: SECTIONS 23 and 24 are cross-platform, and the
mobile lane simply reports "no mobile project here" for an Xcode project it
can't build. Everything else (LSP servers, `stylua`, `prettier`, `eslint`)
auto-installs via Mason on first use.

### 3. A C compiler for treesitter parsers (the non-obvious part)

The config's `nvim-treesitter` (main branch) **compiles each parser from C
source**, so it needs a C compiler. There's no C toolchain on a stock Windows
box, and `tree-sitter build` won't find one. The lightest fix is **zig**, whose
`zig cc` frontend ships its own libc headers (no Visual Studio / Windows SDK
required):

```powershell
winget install --id zig.zig -e
```

`tree-sitter build` reads the `CC` environment variable but passes its host
triple `x86_64-pc-windows-msvc`, which `zig cc` rejects (and the msvc ABI would
need the absent SDK anyway). So `CC` points at a tiny shim,
[`zcc.c`](tools/zcc.c) → `zcc.exe`, that invokes `zig cc` and rewrites that
triple to `x86_64-windows-gnu` (zig's self-contained mingw libc). Build and
register it once:

```powershell
zig cc "C:\Users\Owais\bin\zcc.c" -o "C:\Users\Owais\bin\zcc.exe" -O2
[Environment]::SetEnvironmentVariable("CC", "C:\Users\Owais\bin\zcc.exe", "User")
```

(A copy of the shim source lives at [`tools/zcc.c`](tools/zcc.c) in this repo.)
With `CC` set, `:TSInstall`/auto-install compiles every parser cleanly. If you
later install the Visual Studio C++ Build Tools, you can drop the shim and unset
`CC` — `tree-sitter build` will use `cl.exe` natively.

### 4. Nerd Font

Install any Nerd Font and select it in your Git Bash / Windows Terminal
profile so the statusline and file-explorer icons render (`vim.g.have_nerd_font`
is on).

### 5. First launch

Run `nvim` from Git Bash. `vim.pack` clones every plugin (a few minutes the
first time), then Mason and treesitter pull servers/parsers on demand. Run
`:checkhealth` to confirm.

### Windows keybinds (Ctrl/leader equivalents of the Mac Cmd-chords)

| Action | macOS | Windows |
|---|---|---|
| Save all buffers | `<D-s>` | `<C-s>` |
| Project-wide search (live grep) | `<D-S-f>` | `<C-S-f>` |
| Find files | `<D-p>` / `<D-S-o>` | `<C-p>` / `<C-S-o>` |
| Undo / redo | `<D-z>` / `<D-Z>` | `<C-z>` / `<C-y>` |
| Delete word (insert) | `<M-BS>` | `<C-BS>` |
| Delete to line start (insert) | `<D-BS>` | `<C-u>` |
| Toggle Undotree | `<D-u>` | `<leader>u` |
| Run `run.sh` beside file | `<D-r>` | `<leader>wr` |
| Run `build.sh` beside file | `<D-b>` | `<leader>wb` |
| Back / forward in jump history | `<D-[>` / `<D-]>` | `<C-o>` / `<C-i>` |

The `run.sh`/`build.sh` runners execute the scripts through Git Bash's `bash`
on Windows (they run directly via `./script.sh` on macOS), so no `.bat`
equivalents are needed.
