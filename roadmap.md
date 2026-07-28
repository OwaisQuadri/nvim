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
4. **r2 shipped (2026-07-25), redesigned the same day.** `tools/perf/bench.sh` +
   `history.ndjson` + `bench_test.sh`: headless `--startuptime` runs, cold dropped,
   median+p90 (plus an end-to-end `wall_ms` that catches spawn + timer-deferred setup)
   appended as ONE JSON row per run and compared against the **floor** — the minimum
   median over the rows since the last `--accept`. Regression = median >10% over the
   floor. Clean-machine median **~54.7ms** — the config is ALREADY healthy, which
   deflates r5 (see Ranking). WHY the redesign: v1 compared against a single scalar in
   `baseline.txt`, and FOUR baselines in a row got recorded on a loaded machine (66.736,
   67.959, 63.877, 62.712 ms at loads up to 15.18 on 10 cpus) while the quiet median is
   ~54.7ms — a verification run at load 23.53 still reported PASS. **An inflated scalar
   silently hides a real regression, and chasing an idle machine failed four times
   running.** Load can only ever inflate a wall-clock sample, never deflate it, so the
   min over history is the best available estimate of the true cost and it self-corrects
   on the first quiet run; an inflated row is harmless because it can never become the
   min. Consequences — `--write` and `baseline.txt` are DELETED (no scalar to poison,
   nothing to re-record); **r12 is DELETED rather than deferred** (there is no `--write`
   to refuse under load); and the INCONCLUSIVE verdict dropped earlier the same day is
   REINSTATED as exit 3 (see the brainstorm section for that reversal), because with the
   write path gone the only remaining risk is a human trusting a garbage delta.

## Ranking (WSJF = value+time-crit+unblock ÷ size, ranked WITHIN a lane)

`unblock` = count of LIVE (incomplete) transitive dependents, floor 1 — mechanical, not
freehand. Two lanes because WSJF's denominator floats size-1 chores above size-3 epics
(SAFe itself dropped WSJF at story level for this reason); gut allocates BETWEEN lanes,
WSJF ranks WITHIN one. Every deviation from raw score is labeled OVERRIDE below.

Lane A — features/epics (size ≥ 3)

| id | item | value | tc | unblock | CoD | size | WSJF | MoSCoW |
|---|---|---|---|---|---|---|---|---|
| g2 | real-time best-path coach (pattern table ← r1) | 5 | 3 | 2 | 10 | 3 | 3.3 | Must |
| g1 | mandatory session-entry vim-golf gate | 5 | 3 | 1 | 9 | 3 | 3.0 | Must (headline) |
| g3 | redo-with-handholding (← g2 + r11) | 4 | 2 | 1 | 7 | 3 | 2.3 | Should |
| r4 | log-mining → propose new g2 rules + dead binds | 4 | 2 | 1 | 7 | 3 | 2.3 | Should |
| r8 | coaching digest (← r4) | 4 | 1 | 1 | 6 | 3 | 2.0 | Could |
| g4 | general optimal-path solver (research) | 5 | 1 | 1 | 7 | 5 | 1.4 | Won't-yet |
| r9 | tmux/zellij pane nav (gated) | 2 | 1 | 1 | 4 | 3 | 1.3 | Won't-yet |
| r10 | make-it-fast backlog (← r5) | 2 | 1 | 1 | 4 | 3 | 1.3 | Could |

Lane B — chores/tooling (size ≤ 2)

| id | item | value | tc | unblock | CoD | size | WSJF | MoSCoW |
|---|---|---|---|---|---|---|---|---|
| t1 | TICKET-1 acceptance run (manual, on the real machine) | 4 | 5 | 1 | 10 | 1 | 10.0 | ✅ done |
| r3 | keystroke-log source (adopt keystats/keylog) | 3 | 2 | 2 | 7 | 1 | 7.0 | Should |
| t3 | pin auto-rename with a check (claimed in init.lua + README, guarded by nothing) | 2 | 1 | 1 | 4 | 1 | 4.0 | Should |
| t2 | goto-def stub fallback: search `.js`, collapse 4 ref attempts to 1 | 3 | 1 | 1 | 5 | 2 | 2.5 | Should |
| t4 | test.sh is not hermetic — shares plugin/data dirs with `~/.config/nvim` | 2 | 1 | 2 | 5 | 2 | 2.5 | Could |
| m2 | async mobile project scan (kills a 1.6s UI freeze) | 3 | 2 | 1 | 6 | 1 | 6.0 | Should |
| m3 | doctor: skip_validate_bin cache filename | 1 | 1 | 1 | 3 | 1 | 3.0 | Could |
| r14 | make the perf guard run itself (README + test.sh) | 3 | 2 | 1 | 6 | 1 | 6.0 | Should |
| r13 | small-sample REGRESS gap (min kept samples / N-aware tolerance) | 3 | 2 | 1 | 6 | 1 | 6.0 | Should |
| r6 | adopt precognition.nvim (toggle, off) | 3 | 2 | 1 | 6 | 1 | 6.0 | Could |
| r11 | durable headless test harness | 4 | 4 | 3 | 11 | 2 | 5.5 | Must |
| r5 | perf TRIAGE, was "perf pass" (← r2) | 2 | 1 | 1 | 4 | 1 | 4.0 | Could |
| r1 | adopt hardtime.nvim (detection substrate) | 4 | 3 | 3 | 10 | 1 | 10.0 | ✅ done |
| r2 | perf guard (bench.sh + history.ndjson floor) | 3 | 2 | 2 | 7 | 1 | 7.0 | ✅ done |

Overrides (gut is final, but each one gets said out loud):

- **g1** elevated above its 3.0 — it IS the headline; the whole point of the repo.
- **r11** taken first in lane B despite 5.5 — the only live blocker of g1, and every
  "verified in a headless test" DoD in this file is unverifiable without it.
- **r3** (7.0) and **r6** (6.0) are DAG-READY and outrank g2 on raw score, yet stay in
  NEXT: telemetry FEEDS the coach rather than precedes it, and r6 is a toggle nobody
  asked for.

COMPLETED rows (✅) keep the score they carried AT COMPLETION — they are a record of
why the work was picked, not a live queue position. So r2's `unblock=2` is not
recomputed against the edges added after it shipped (g1, g2, r5, r14 now depend on
it); only incomplete rows get re-scored against the live-dependents rule above.

Score corrections this pass (2026-07-25): r2's old `unblock=4` was inflated (2 real
dependents, so 7.0 not 9) — the conclusion "guard before headline" was still right, but
for a reason the score never captured, so it is now a real CONSTRAINT edge on g1/g2
instead of a padded cell. r11 scored for the first time (it was a blank row). r5 and r10
deflated by r2's evidence that clean startup ~54.7ms is already healthy. MoSCoW hybrids
("Could/Won't-yet") resolved to plain Won't-yet on g4 and r9.

(vim-be-good = the likely CONTENT source for g1's challenges, not a standalone step.)

## Horizons + DAG

```json
{"steps": [
  {"id": "r1", "description": "Adopt hardtime.nvim as the inefficiency-detection substrate the coach builds on: add to init.lua's vim.pack list with a gentle config (hints + habit reports on; hard key-blocking non-punishing), document the toggle. DoD: spam jjjj -> hint appears; :Hardtime toggle works; README row added.", "route": "light", "depends_on": [], "status": "done"},
  {"id": "r2", "description": "Perf guard: tools/perf/bench.sh runs `nvim --headless -u init.lua --startuptime` x10 (drop cold run), prints median+p90 and a median end-to-end wall clock, appends ONE JSON row per invocation to tools/perf/history.ndjson (committed dataset), and compares the median against the floor = min median since the last --accept marker. Regression = >10% over the floor; load >0.5/cpu = INCONCLUSIVE (exit 3) with the row still recorded. DoD: two runs stable within ~10%, a history row written per run, bench_test.sh green.", "route": "light", "depends_on": [], "status": "done"},
  {"id": "g1", "description": "Mandatory daily vim-golf gate: a VimEnter hook opens a modal challenge buffer (input->target text, keystroke-counted, VimGolf-style content) that must be solved before normal editing. Required once per day, resetting at 06:00 local time: the first launch after the 6am boundary requires a fresh clear and records a last-cleared day-stamp; later same-day launches skip the gate. Mandatory escape hatch :GolfSkip (+ difficulty dial) so a buggy win-check never locks the editor. DoD: on the first post-6am launch the challenge shows; solving it dismisses+restores the session and stamps the day; a second same-day launch does NOT re-gate; :GolfSkip bypasses; a headless test drives a solve and asserts dismissal + the no-re-gate-same-day behavior. CONSTRAINT (r11): the gate MUST no-op when Neovim has no UI (headless, `#vim.api.nvim_list_uis() == 0`) so r11's smoke runner and any `nvim --headless` automation never hang on the challenge. CONSTRAINT (r2): the VimEnter hook IS the surface tools/perf/bench.sh measures — DoD includes bench.sh median within 10% of the floor in tools/perf/history.ndjson; an INCONCLUSIVE run (exit 3, machine loaded) is not evidence, rerun it quieter.", "route": "heavy", "depends_on": ["r11", "r2"], "status": "todo"},
  {"id": "g2", "description": "Real-time best-path coach: on a hardtime-detected inefficient action, look it up in a curated pattern->optimal-keys table and show the best path for what was just done (e.g. A+backspace line-merge -> J). New rules are one table entry. DoD: performing the A+backspace pattern surfaces the 'use J' best path; a clean action surfaces nothing (no false positives); rule table has a headless unit test. CONSTRAINT (r2): on-keystroke detection runs in the hot path — DoD includes bench.sh median within 10% of the floor in tools/perf/history.ndjson; an INCONCLUSIVE run (exit 3, machine loaded) is not evidence, rerun it quieter.", "route": "heavy", "depends_on": ["r1", "r2"], "status": "todo"},
  {"id": "g3", "description": "Redo-with-handholding: after g2 flags an inefficiency, optionally revert the just-made edit and step the user through the optimal keystrokes (highlight next key, advance on correct press), with a config of off / hint-only / full-handhold (disableable per user ask). DoD: with handholding on, a flagged edit is reverted and the guided redo advances key-by-key to the target; with it off, nothing triggers; config switch verified in a headless test (r11's runner drives the key-by-key state transitions; do NOT hand-roll a one-off harness).", "route": "heavy", "depends_on": ["g2", "r11"], "status": "todo"},
  {"id": "r3", "description": "Adopt a keystroke-log source (keystats.nvim or keylog.nvim), gated/toggleable, log under stdpath('data'/'state') — this becomes the coach's training data. DoD: after a session the log has per-key counts; toggle works; README row added.", "route": "light", "depends_on": [], "status": "todo"},
  {"id": "r4", "description": "Log-mining report (tools/telemetry/report): dump init.lua's defined keymaps via `nvim --headless`, read r3's log, output most/least-used keys, defined-but-never-used binds, and repeated-inefficiency candidates to add as new g2 rules. DoD: against a committed fixture log, names the top key, flags a known dead bind, and proposes a known repeated pattern.", "route": "heavy", "depends_on": ["r3"], "status": "todo"},
  {"id": "r5", "description": "Perf TRIAGE (was 'perf pass'): against the floor in tools/perf/history.ndjson, profile startup and either name the single largest cost (>5ms) as its own r10 ticket, or close r5 resolved/no-action. Clean median ~54.7ms already reads healthy, so the premise is no longer 'make it faster', it is 'know what we would cut if we ever needed to'. DoD: a one-screen profile note naming the top 3 costs with ms; then EITHER a filed r10 candidate with a >=10% projected win OR an explicit no-action verdict. NON-GOALS: no lazy-load rewrite here, no chasing an idle machine (the floor absorbs load; an INCONCLUSIVE run is simply rerun), no chasing sub-5ms noise.", "route": "light", "depends_on": ["r2"], "status": "todo"},
  {"id": "g4", "description": "COARSE placeholder — general optimal-path solver: given an arbitrary buffer transform A->B, search for a near-minimal keystroke sequence to replace the curated table's lookups. Likely hard/unreliable; earns its own research + harness-plan pass before any build.", "route": "heavy", "depends_on": ["g2"], "status": "todo"},
  {"id": "r6", "description": "Adopt precognition.nvim, off by default with a toggle. DoD: toggle shows motion hints; README row added.", "route": "light", "depends_on": [], "status": "todo"},
  {"id": "r8", "description": "COARSE placeholder — coaching digest: on-demand/weekly summary combining r4's mining with hardtime's flagged habits into 'cut these dead binds, replace these patterns'. Own harness-plan pass.", "route": "heavy", "depends_on": ["r4"], "status": "todo"},
  {"id": "r9", "description": "COARSE placeholder — seamless <C-h/j/k/l> nav between Neovim and a terminal multiplexer. GATED: confirm the user runs tmux/zellij (Ghostty splits may make it moot). Own harness-plan pass.", "route": "heavy", "depends_on": [], "status": "todo"},
  {"id": "r10", "description": "COARSE placeholder — make-it-fast backlog: each optimization surfaced by r5 filed as its own ticket with its own research + verify DoD.", "route": "heavy", "depends_on": ["r5"], "status": "todo"},
  {"id": "r11", "description": "Durable headless test harness: promote test.sh from a stub to a real `nvim --headless -u init.lua` smoke runner that asserts each plugin/command loads and drives a feature through its states. DoD: test.sh exits non-zero on a deliberately-broken config and zero on green; its first case drives the hardtime hint+toggle. DELIVERED BY m1 (2026-07-26): 46 checks, every one mutation-tested (deleting the code a check covers turns it red), plus a startup-error gate that greps error signatures AND this config's own WARN-level `setup failed` notices. The g1-headless-skip clause was NOT built here -- it is a constraint g1 must satisfy, recorded on g1.", "route": "heavy", "depends_on": [], "status": "done"},
  {"id": "r14", "description": "Make the guard run itself (distribution): add a README row for tools/perf/bench.sh beside build.sh/test.sh, and call `bench.sh --runs 3` from r11's test.sh as a NON-BLOCKING section printing median/floor/verdict. bench.sh is currently documented only in CLAUDE.md and nothing invokes it — an unrun guard is not a guard. DoD: test.sh on a green config prints the bench verdict line and exits 0; a bench exit 3 (INCONCLUSIVE, drivable via BENCH_LOAD_OVERRIDE) is reported as SKIPPED (load) and test.sh still exits 0; README lists the script. NON-GOALS: not a blocking gate, no git hooks, no CI, no graphing of history.ndjson.", "route": "light", "depends_on": ["r2", "r11"], "status": "todo"},
  {"id": "r13", "description": "Close the small-sample REGRESS gap: with --runs 3 only TWO samples survive the cold drop, and on a moderately busy box that pair reported REGRESS at +12% while the 0.5/cpu INCONCLUSIVE gate stayed quiet at 0.37/cpu — a false alarm the default --runs 10 does not produce. Decide the verdict rule (a minimum kept-sample count before REGRESS is allowed at all, an N-aware tolerance that widens as samples shrink, or a load gate that tightens when N is small) and pin it. Surfaced during r2's round-3 verification, deliberately NOT fixed there because tuning a verdict threshold to make one's own gate pass is gaming it. DoD: a bench_test.sh case proves a 2-sample run on a loaded fixture cannot silently REGRESS; the default --runs 10 path keeps its current behaviour byte-for-byte; the chosen rule is documented in CLAUDE.md's Perf section with the reasoning. NON-GOALS: no change to the 10% threshold for full-sample runs, no retry-until-quiet loop (chasing an idle machine is the approach this design dismissed four times).", "route": "light", "depends_on": ["r2"], "status": "todo"},
  {"id": "m1", "description": "Mobile lane: xcodebuild.nvim (macOS), flutter-tools.nvim, and a unified `<leader>m*` that detects Flutter/Expo/React-Native/Xcode and dispatches run/build/reload/device/test/setup/doctor/new to the right stack, entering the project it picks (works from a monorepo root). Plus eslint LSP, dart+yaml parsers, dart_format, and a shared lazy nvim-dap core. DoD: 46 headless checks green, mutation-tested; `<leader>m?` names the between-the-editor-and-the-tool failures. Shipped 2026-07-26. Cost: startup floor 60.5 -> ~69.6ms, accepted via bench.sh --accept.", "route": "heavy", "depends_on": [], "status": "done"},
  {"id": "m2", "description": "Make the mobile project scan non-blocking. `find_projects_below` shells out via synchronous `vim.fn.systemlist`; measured 1.6s of frozen UI pressing `<leader>mr` from $HOME (57 candidate projects), 3.1s on the `find` fallback. Only fires when the upward walk finds nothing, so it is invisible inside a project and punishing at a monorepo/home root. DoD: the scan runs async (vim.system callback or a bounded uv walk) and the keypress returns immediately; a headless check asserts the lane still resolves the right project from a monorepo root; measured block time from $HOME under 100ms.", "route": "light", "depends_on": ["m1"], "status": "todo"},
  {"id": "m3", "description": "Doctor: handle xcode-build-server`s `skip_validate_bin` mode, which renames the cached compile file `compile_file1-<scheme>-<md5>` (server.py:86). The doctor only looks for `compile_file-`, so a project configured that way reports as unharvested forever. Opt-in and rare, hence deferred rather than guessed at. DoD: a fixture with skip_validate_bin set reads as healthy; the existing kind=xcode check still passes.", "route": "light", "depends_on": ["m1"], "status": "todo"}
]}
```

- **READY (DAG-satisfied, mechanical — every dep in {done, resolved}):** {g2, r3, r5, r6,
  r9, r11, r13}. NOW is a CURATED SUBSET of this; anything held back is a named override
  above, never a silent DAG claim. (r12 was DELETED by the r2 redesign, not deferred; r5
  became DAG-ready when its r12 dependency went away, and stays in LATER behind its own
  trigger.)
- **NOW (Deep):** ✅ r1 · ✅ r2 · ✅ r11 (delivered by m1's 46-check harness) · ✅ m1 ·
  **g1 (headline, unblocked 2026-07-26 — r11 was its only live blocker)** · g2 (top of
  lane A). g1 and g2 are now both ready; g1 is the headline, so it goes first.
- **NEXT (Deep, directional):** g3 (←g2) · r3 · r4 (←r3) · r13 · r14 · m2 (←m1).
- **LATER (Coarse, own pass) — each with its Later→Next trigger:**
  g4 ← g2's pattern table exceeds ~20 rows AND r4 proposes rules the table can't express.
  r8 ← r4's report exists and gets read twice unprompted.
  r9 ← the user confirms a tmux/zellij daily driver (today: Ghostty splits).
  r5 ← bench.sh reports >10% regression vs the floor (a PASS/REGRESS run, not an
    INCONCLUSIVE one), or startup crosses 80ms.
  r10 ← r5 names a >=10% win.
- **Emergent milestone (re-derived 2026-07-25):** the nearest INCOMPLETE convergence point
  is **g1** — fan-in 2 (r11 + r2), and r2 ✅ leaves exactly one incomplete ancestor (r11),
  so distance 1. Current milestone = "the daily golf gate ships on a verified harness with
  a trustworthy perf guard." The terminal convergence of both live tracks is **g3** (g2 and
  r11 both drain into it) = M1 "the coach loop works", remaining g1 + g2 + g3. Pointer
  moved: r1 was the widest prerequisite last pass, **r11 is now**.
- Soft edges INTENTIONALLY unwired (they would create false blocks): r4 proposes rules for
  g2's table, and r4's weak spots could feed g1's challenges. Neither gates the other.

## Brainstorm follow-on (ranked; you pick)
**novel:** g1 challenges auto-drawn from YOUR real logged weak spots (r4→g1 loop); "streak"
tracking for the daily gate. **fun/dangerous:** end-of-day roast of your worst habit;
handholding "boss mode" that escalates difficulty. **adjacent:** r6 precognition.
**make-it-fast:** DEFLATED by r2's evidence (clean ~54.7ms) — lazy-loading
telescope/treesitter/neo-tree and vim.pack build caching stay parked behind r5's trigger.
**filed from r2's evidence:** r14 (auto-run the guard) · r13 (small-sample REGRESS gap) — r12 (refuse `--write` under load)
was filed the same day and then DELETED by the r2 redesign: with no `--write` and a
min-of-history floor, there is no scalar to poison and nothing to refuse.
**dropped 2026-07-25, then REINSTATED the same day (r2 redesign):** an INCONCLUSIVE verdict
(exit 3) for compare runs under load. The drop assumed r12's `--write` guard was carrying
the load problem; once `--write` and r12 were deleted, exit 3 became the ONLY thing between
a loaded machine and a human trusting its delta, so bench.sh emits it (load >0.5/cpu) while
still recording the row.
**fun/dangerous, unranked:** `bench.sh --compare-to <git-ref>` to bisect a regression.

## Sources
- hardtime.nvim — https://github.com/m4xshen/hardtime.nvim
- keystats.nvim — https://github.com/OscarCreator/keystats.nvim · keylog.nvim — https://github.com/glottologist/keylog.nvim
- precognition.nvim — https://github.com/tris203/precognition.nvim
- vim-be-good — https://github.com/ThePrimeagen/vim-be-good · VimGolf — https://github.com/igrigorik/vimgolf
- WSJF — https://www.productplan.com/glossary/weighted-shortest-job-first
- WSJF failure modes (2026-07-25 pass): Reinertsen/Black Swan Farming — https://blackswanfarming.com/wsjf-weighted-shortest-job-first/ · Jason Yip, "Problems I have with SAFe-style WSJF" — https://jchyip.medium.com/problems-i-have-with-safe-style-wsjf-772df2beaf02 · "less useful when backlogs are very small or capacity is not a material constraint" — https://agility-at-scale.com/safe/lpm/wsjf-weighted-shortest-job-first/ (this is why gut overrides are legitimate here, not sloppy)
- MoSCoW needs a scoring method alongside it — https://www.productplan.com/glossary/moscow-prioritization
- Now/Next/Later horizon detail rules — https://www.aakashg.com/now-next-later-roadmap/
- Solo projects: ship the slice, defer infrastructure until it's an actual bottleneck — https://www.smashingmagazine.com/2025/01/solo-development-learning-to-let-go-of-perfection/
