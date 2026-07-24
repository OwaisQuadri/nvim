# nvim config — living roadmap (pair-program `roadmap` phase, 2026-07-24)

Brainstorm-only session. Supersedes the from-scratch plan in `.context/todos.md`.
Headline (owais, 2026-07-24): make the editor a **forced coach loop** —
(1) every session you MUST clear one vim-golf problem before you start,
(2) when you do something inefficient it shows you the best path,
(3) it lets you redo it the right way with handholding, all configurable/disableable.
Sources at bottom.

## Audit + feasibility verdict

- **Detection is already solved** — hardtime.nvim blocks bad-habit keys, hints better
  motions, and reports frequent habits. We build the coach ON TOP of it, not from scratch.
- **"Best path for an arbitrary edit" has NO off-the-shelf solver** — VimGolf is a human
  competition; nobody auto-computes minimal keystrokes reliably. So the tractable "best
  path" is a **curated pattern→optimal-keys table** (e.g. `A`+bksp merge → `J`), which
  GROWS as your keystroke log surfaces new repeated inefficiencies. A general solver is a
  LATER research bet that may never be reliable — scoped out of the headline.
- **The mandatory startup gate is trivially feasible** (VimEnter + a modal buffer with
  win-detection). The only real risk is locking yourself out — so an escape hatch and
  cadence choice are mandatory design, not optional.
- **The telemetry track stops competing with the coach and FEEDS it**: the keystroke log
  (r3) + mining report (r4) become the coach's training data — "you keep doing X, here's a
  new best-path rule." One system, not two.

## Decisions (settled 2026-07-24)

1. **Gate cadence + escape hatch.** Required **once per day, resetting at 06:00 local
   time** — the first `nvim` launch after the 6am boundary requires a fresh clear;
   later same-day launches skip it (store a last-cleared day-stamp). Escape hatch:
   `:GolfSkip` plus a difficulty dial, so a buggy win-check can never lock the editor.
2. **Best-path scope.** Start with the curated pattern→optimal-keys table that GROWS from
   the keystroke log (r4→g2). The general optimal-path solver (g4) stays a LATER research
   bet, not in the headline.
3. **r1 shipped (2026-07-24).** hardtime.nvim adopted in gentle `restriction_mode='hint'`
   (suggests, never blocks), `disable_mouse=false`, `<leader>tH` toggle; a `strict` local
   in init.lua SECTION 21 flips it to block mode. This clears the widest prerequisite for
   the coach loop — g2 (real-time best-path coach) is now unblocked.

## Ranking (WSJF = value+time-crit+unblock ÷ size; founder gut elevates the coach loop)

| id | item | value | tc | unblock | size | WSJF | MoSCoW |
|---|---|---|---|---|---|---|---|
| r1 | adopt hardtime.nvim (detection substrate) | 4 | 3 | 4 | 1 | 11 | Must (do first) |
| r2 | perf baseline (bench.sh + baseline.txt) | 3 | 2 | 4 | 1 | 9 | Must |
| g1 | mandatory session-entry vim-golf gate | 5 | 3 | 2 | 3 | 3.3 | Must (headline) |
| g2 | real-time best-path coach (pattern table ← r1) | 5 | 3 | 3 | 3 | 3.7 | Must |
| g3 | redo-with-handholding (← g2, configurable/off) | 4 | 2 | 1 | 3 | 2.3 | Should |
| r3 | keystroke-log source (adopt keystats/keylog) | 3 | 2 | 3 | 1 | 8 | Should |
| r4 | log-mining → propose new g2 rules + dead binds | 4 | 2 | 2 | 3 | 2.7 | Should |
| r5 | perf pass (act on r2's top cost, re-measure) | 4 | 3 | 1 | 3 | 2.7 | Should |
| g4 | general optimal-path solver (research) | 5 | 1 | 1 | 5 | 1.4 | Could/Won't-yet |
| r6 | adopt precognition.nvim (toggle, off) | 3 | 2 | 1 | 1 | 6 | Could |
| r8 | coaching digest (← r4) | 4 | 1 | 1 | 3 | 2.0 | Could |
| r9 | tmux/zellij pane nav (gated) | 2 | 1 | 1 | 3 | 1.3 | Could/Won't-yet |
| r10 | make-it-fast backlog (← r5) | 3 | 1 | 1 | 3 | 1.7 | Could |

(vim-be-good = the likely CONTENT source for g1's challenges, not a standalone step.)

## Horizons + DAG

```json
{"steps": [
  {"id": "r1", "description": "Adopt hardtime.nvim as the inefficiency-detection substrate the coach builds on: add to init.lua's vim.pack list with a gentle config (hints + habit reports on; hard key-blocking non-punishing), document the toggle. DoD: spam jjjj -> hint appears; :Hardtime toggle works; README row added.", "route": "light", "depends_on": [], "status": "done"},
  {"id": "r2", "description": "Perf baseline: tools/perf/bench.sh runs `nvim --headless -u init.lua --startuptime` x10 (drop cold run), prints median+p90, writes median to tools/perf/baseline.txt. DoD: two runs stable within ~10%, baseline file written.", "route": "light", "depends_on": [], "status": "todo"},
  {"id": "g1", "description": "Mandatory daily vim-golf gate: a VimEnter hook opens a modal challenge buffer (input->target text, keystroke-counted, VimGolf-style content) that must be solved before normal editing. Required once per day, resetting at 06:00 local time: the first launch after the 6am boundary requires a fresh clear and records a last-cleared day-stamp; later same-day launches skip the gate. Mandatory escape hatch :GolfSkip (+ difficulty dial) so a buggy win-check never locks the editor. DoD: on the first post-6am launch the challenge shows; solving it dismisses+restores the session and stamps the day; a second same-day launch does NOT re-gate; :GolfSkip bypasses; a headless test drives a solve and asserts dismissal + the no-re-gate-same-day behavior. CONSTRAINT (r11): the gate MUST no-op when Neovim has no UI (headless, `#vim.api.nvim_list_uis() == 0`) so r11's smoke runner and any `nvim --headless` automation never hang on the challenge.", "route": "heavy", "depends_on": ["r11"], "status": "todo"},
  {"id": "g2", "description": "Real-time best-path coach: on a hardtime-detected inefficient action, look it up in a curated pattern->optimal-keys table and show the best path for what was just done (e.g. A+backspace line-merge -> J). New rules are one table entry. DoD: performing the A+backspace pattern surfaces the 'use J' best path; a clean action surfaces nothing (no false positives); rule table has a headless unit test.", "route": "heavy", "depends_on": ["r1"], "status": "todo"},
  {"id": "g3", "description": "Redo-with-handholding: after g2 flags an inefficiency, optionally revert the just-made edit and step the user through the optimal keystrokes (highlight next key, advance on correct press), with a config of off / hint-only / full-handhold (disableable per user ask). DoD: with handholding on, a flagged edit is reverted and the guided redo advances key-by-key to the target; with it off, nothing triggers; config switch verified in a headless test.", "route": "heavy", "depends_on": ["g2"], "status": "todo"},
  {"id": "r3", "description": "Adopt a keystroke-log source (keystats.nvim or keylog.nvim), gated/toggleable, log under stdpath('data'/'state') — this becomes the coach's training data. DoD: after a session the log has per-key counts; toggle works; README row added.", "route": "light", "depends_on": [], "status": "todo"},
  {"id": "r4", "description": "Log-mining report (tools/telemetry/report): dump init.lua's defined keymaps via `nvim --headless`, read r3's log, output most/least-used keys, defined-but-never-used binds, and repeated-inefficiency candidates to add as new g2 rules. DoD: against a committed fixture log, names the top key, flags a known dead bind, and proposes a known repeated pattern.", "route": "heavy", "depends_on": ["r3"], "status": "todo"},
  {"id": "r5", "description": "Perf pass: via r2's bench find the largest startup cost (telescope/treesitter/neo-tree eager loads) and apply safe lazy/event-gating, re-measure. DoD: new median from bench.sh <= tools/perf/baseline.txt.", "route": "heavy", "depends_on": ["r2"], "status": "todo"},
  {"id": "g4", "description": "COARSE placeholder — general optimal-path solver: given an arbitrary buffer transform A->B, search for a near-minimal keystroke sequence to replace the curated table's lookups. Likely hard/unreliable; earns its own research + harness-plan pass before any build.", "route": "heavy", "depends_on": ["g2"], "status": "todo"},
  {"id": "r6", "description": "Adopt precognition.nvim, off by default with a toggle. DoD: toggle shows motion hints; README row added.", "route": "light", "depends_on": [], "status": "todo"},
  {"id": "r8", "description": "COARSE placeholder — coaching digest: on-demand/weekly summary combining r4's mining with hardtime's flagged habits into 'cut these dead binds, replace these patterns'. Own harness-plan pass.", "route": "heavy", "depends_on": ["r4"], "status": "todo"},
  {"id": "r9", "description": "COARSE placeholder — seamless <C-h/j/k/l> nav between Neovim and a terminal multiplexer. GATED: confirm the user runs tmux/zellij (Ghostty splits may make it moot). Own harness-plan pass.", "route": "heavy", "depends_on": [], "status": "todo"},
  {"id": "r10", "description": "COARSE placeholder — make-it-fast backlog: each optimization surfaced by r5 filed as its own ticket with its own research + verify DoD.", "route": "heavy", "depends_on": ["r5"], "status": "todo"},
  {"id": "r11", "description": "Durable headless test harness: promote test.sh from a stub to a real `nvim --headless -u init.lua` smoke runner that asserts each plugin/command loads and drives a feature through its states (pair-program verification model: one JSON state per line). Bake in the two gotchas this repo already hit: (1) hardtime's ~500ms deferred setup needs a `vim.wait` before asserting; (2) any startup gate (g1) must be skipped under headless so the runner never hangs. DoD: test.sh exits non-zero on a deliberately-broken config and zero on green; its first case drives the hardtime hint+toggle; g1 (and future features) call it to satisfy their headless-test DoD.", "route": "heavy", "depends_on": [], "status": "todo"}
]}
```

- **NOW (Deep):** ✅ r1 done (substrate) · r2 (perf guard) · r11 (test harness, hard-blocks
  g1) · g1 (headline gate, now ←r11) · g2 (coach, unblocked). Ready set = {r2, r11, g2};
  g1 waits on r11 so the golf gate and the headless runner don't collide.
- **NEXT (Deep):** g3 (←g2) · r3 (adopt) · r4 (←r3) · r5 (←r2) · r6.
- **LATER (Coarse, own pass):** g4 (←g2, research) · r8 (←r4) · r9 (gated) · r10 (←r5).
- **Emergent milestone M1 = "the coach loop works":** convergence where r1+g1+g2+g3 land
  (detect → best-path → guided redo). r1 ✅ was the widest prerequisite and is now cleared;
  M1 remaining = g1 + g2 + g3. Reaching M1 = the product you described exists end-to-end.

## Brainstorm follow-on (ranked; you pick)
**novel:** g1 challenges auto-drawn from YOUR real logged weak spots (r4→g1 loop); "streak"
tracking for the daily gate. **fun/dangerous:** end-of-day roast of your worst habit;
handholding "boss mode" that escalates difficulty. **adjacent:** r6 precognition.
**make-it-fast:** lazy-load telescope/treesitter/neo-tree; vim.pack build caching.

## Sources
- hardtime.nvim — https://github.com/m4xshen/hardtime.nvim
- keystats.nvim — https://github.com/OscarCreator/keystats.nvim · keylog.nvim — https://github.com/glottologist/keylog.nvim
- precognition.nvim — https://github.com/tris203/precognition.nvim
- vim-be-good — https://github.com/ThePrimeagen/vim-be-good · VimGolf — https://github.com/igrigorik/vimgolf
- WSJF — https://www.productplan.com/glossary/weighted-shortest-job-first
