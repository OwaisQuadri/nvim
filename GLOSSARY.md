# Glossary

Canonical resolution for the shortforms this repo's code and docs use. Resolve against this
table before guessing; an unresolvable shortform is the signal to add a row.

## Roadmap ids

[`roadmap.md`](roadmap.md) labels every step with a short id. The letter is the track, the
number is just an ordinal — ids are labels, not an ordering.

| Prefix | Track |
|---|---|
| `rN` | Repo/tooling work — plugin adoption, perf, telemetry, test harness |
| `gN` | Golf/coach work — the forced vim coach loop that is this config's headline direction |
| `tN` | TypeScript/React-Native lane — JS/TSX editing, added by TICKET-1 |

Always write an id with its description on every mention: `r11 (headless test harness)`,
never a bare `r11`.

## Editor and tooling

| Shortform | Resolves to |
|---|---|
| DAP | Debug Adapter Protocol — the editor↔debugger protocol `nvim-dap` speaks |
| DoD | Definition of Done — the checkable finish line each roadmap step carries |
| LSP | Language Server Protocol — see `:help lsp-vs-treesitter` |
| WSJF | Weighted Shortest Job First — cost-of-delay ÷ job-size, how `roadmap.md` ranks |
| cwd | Current working directory — what `xcodebuild.nvim` keys its per-project settings off |
| ndjson | Newline-delimited JSON — one JSON object per line, the format `test.sh` emits |
| rhs / lhs | Right/left-hand side of a keymap (the action / the keys) |

## This config's own terms

| Shortform | Resolves to |
|---|---|
| Cmd-chord | A `<D-...>` keybind, forwarded only by terminals speaking the Kitty keyboard protocol (Ghostty) |
| SECTION N | A numbered block in [`init.lua`](init.lua) — the single-file config's unit of organization |
| `<leader>` | Space, set in SECTION 1 |
