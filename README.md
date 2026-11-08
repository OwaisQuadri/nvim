# Neovim configuration

Personal configuration based on [kickstart.nvim](https://github.com/nvim-lua/kickstart.nvim).
It supports Swift/Xcode, Flutter/Dart, JavaScript/TypeScript/React Native, Rust, and Lua.

## Requirements

- Neovim 0.12 or newer. The configuration uses its built-in `vim.pack` manager.
- Git, ripgrep, fd, a C compiler, and the Tree-sitter command-line tool.
- Node.js for the JavaScript language tools.
- A terminal with Kitty keyboard-protocol support for shifted Control shortcuts.
- Full Xcode selected on macOS for Xcode projects. Install `xcode-build-server` and `xcbeautify` for project diagnostics and readable logs.
- A Flutter software development kit (SDK) for Dart analysis and Flutter commands. When using asdf, pin its version in the project or user configuration.
- Rustup with the `rust-analyzer` and `rustfmt` components for Rust. These must match the compiler toolchain.

Mason manages Lua and JavaScript language servers and formatting tools. SourceKit comes from Xcode or the selected Swift toolchain. Flutter owns the Dart analysis server; Rustup owns rust-analyzer.

On Windows, place the configuration under `%LOCALAPPDATA%\nvim`. Parser compilation needs a C toolchain. The existing [compiler shim](tools/zcc.c) supports Zig; build it and point the `CC` environment variable at the resulting executable if needed. Xcode commands are macOS-only.

## Structure

- [`init.lua`](init.lua): editor options, mappings, plugins, language setup, and Xcode integration.
- [`lua/config/project.lua`](lua/config/project.lua): project-root discovery and app command routing.
- [`lua/config/code_action_range.lua`](lua/config/code_action_range.lua): diagnostic-anchored Swift code-action ranges, shared by normal and insert modes.
- [`tests/`](tests/): headless checks for configuration, project commands, code actions, and rename writeback.

The mapping definitions are the source of truth. Use `:Telescope keymaps` to inspect active mappings, or `:verbose nmap <C-r>` to see where a mapping was set. Which-key shows the retained leader-key groups.

## Editing and search

The leader is Space. The retained search commands find files, search project text, and search the clipboard literally. Clipboard search does not interpret punctuation as a regular expression. The configuration no longer keeps a recent-project picker or alternate desktop-style search shortcuts.

Harpoon uses Control with H/J/K/L for files 1–4, not window navigation. Use the leader-window prefix for splits and window movement.

Use mini.surround to edit surrounding delimiters: `saiw"` quotes a word, `sd"` removes its quotes, and `sr"'` replaces double quotes with single quotes. Visual-mode brackets and quotes retain their native behavior. In particular, `{` and `}` move by paragraph rather than changing the selected text.

Saving is explicit. Save-all remains available. A language-server rename saves files changed by that rename only if they had no unsaved edits before it; existing unsaved work stays in the buffer. Failed writes produce a warning.

## Diagnostics and navigation

Inline diagnostics and code actions remain enabled. The quick-action shortcut works in normal, visual, and insert modes. Swift actions use a diagnostic position; other languages use the line or explicit selection. Diagnostic copying and cross-file diagnostic navigation remain available. The diagnostic-list shortcut opens a location list, not a quickfix list.

Definition navigation uses the language server without an upstream-source fallback. Hover uses the standard `K` command. `:SwiftSource` explicitly browses upstream Swift implementations; those sources can differ from the frameworks shipped with the selected Xcode version.

## App commands

The Control run/build mappings are defined at the end of [`init.lua`](init.lua). They resolve the nearest supported project above the current file:

- Xcode: build, build-and-run, or run the existing build. Use the retained Xcode setup shortcut once per checkout to choose a project, scheme, and device.
- Swift packages: `swift build`, `swift run`, or `swift run --skip-build`.
- Rust: `cargo build` or `cargo run`. Running without a build asks for an existing executable.
- Flutter: run, choose a build target, or select an existing application artifact.
- JavaScript/TypeScript: run a project-defined `dev` or `start` script, or its `build` script. A generic run-without-build command is not assumed: use the project's documented preview command.

Terminal commands use argument arrays and the detected project directory. They do not install packages automatically. The old mobile setup, repair, and project-scaffolding layer is removed. Debugger panels and debugger shortcuts are removed.

## Swift build information

An attached SourceKit server is not proof that it has the correct target settings. For an Xcode app, it needs `buildServer.json` and compiler arguments for the selected target.

Scheme setup binds xcode-build-server to the actual Xcode DerivedData directory when it can be found. This matters when the project overrides `SYMROOT`: deriving the activity-log root from the products path can point at a directory with no Xcode build logs. A successful editor build also imports compiler arguments. Configuration and import failures produce errors instead of returning silently.

Keep machine-local `buildServer.json`, `.compile`, and `.nvim` data out of application commits. A new clone or worktree needs its own scheme selection and build information.

## Updates and checks

Use `:lua vim.pack.update()` to review plugin updates. After a Tree-sitter update, run `:TSUpdate`. `:MasonToolsUpdate` updates managed language tools. Restart Neovim after plugin or mapping changes; sourcing a file cannot unload a removed plugin or erase every old mapping.

The headless checks run with `./test.sh` from a fresh reviewer context. They report one JavaScript Object Notation (JSON) object per check and return a nonzero status on failure. They cover retained mappings, paragraph motions, surround edits, formatters, explicit saving, code-action dispatch, project commands, build-server hooks, highlighting, server attachment, autoscroll, and rename writeback. They do not prove a particular application's compilation or device behavior.

The existing `run.sh` opens a separate Ghostty session for this configuration. `build.sh` is a demonstration script, not an app build command.

Repository conventions are in [`CLAUDE.md`](CLAUDE.md).
