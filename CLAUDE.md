# Conventions

## Branch naming

`<taskId>_<task-description>` — the roadmap task id, an underscore, then a short
kebab-case description.

```
r2_perf-baseline
g2_best-path-coach
r11_test-harness
```

The task id is the row id from `roadmap.md` (`r*` = reliability/tooling, `g*` =
the golf coach loop). No task id (a one-off fix, not on the roadmap)? Use a bare
kebab-case description: `fix-telescope-grep-path`.

Never rename a branch you didn't create without being asked.

## Perf

`tools/perf/bench.sh` guards Neovim startup time. Every run appends one JSON row
to `tools/perf/history.ndjson` (committed — it is the dataset) and compares its
median against the **floor**: the minimum median over the rows **this machine**
recorded since the last `--accept`. Regression = median more than 10% above the
floor.

There is no recorded baseline and no `--write`. Load only ever inflates a
wall-clock sample, never deflates it, so the min is the closest thing to the
config's true cost, and one quiet run repairs a run of loaded ones. Four
baselines in a row were recorded under load and a verification run at load 23.53
still reported PASS against the inflated scalar; chasing an idle machine failed
four times, so load is now recorded as data instead of fought.

Each row carries `host`/`os`/`arch`/`cpus`, `load_before`/`load_after`, `commit` +
`dirty`, the nvim version, a plugin-lock hash, and every per-run sample (including
the dropped cold one). The floor is **machine-scoped**: only rows matching this
host and arch feed the verdict, so a shared, committed dataset can never compare a
laptop against a desktop. Foreign rows stay in the file for graphing.

`--accept` markers are scoped **the same way**, and that is load-bearing: a marker
resets the floor of the machine that wrote it and no other. Unscoped, another
machine's `--accept` — committed to this shared file — wiped the local floor and
the next run reported FIRST / exit 0 over a +200% regression. A marker with a
foreign host+arch, or with neither (the pre-provenance shape), resets nothing; it
is counted and reported so "my `--accept` did nothing" is never a mystery. If you
see that note, rerun `--accept` on this machine.

Deliberately NOT scoped by commit or plugin set: a plugin-driven slowdown IS a
regression worth flagging, and `--accept` is the switch for "yes, I meant it."
Since inflation can never become the minimum, the only risk left is **deflation**
— a gutted or half-loaded config posting an impossibly fast row and sticking as
the floor — so medians at or below a 5ms sanity floor are excluded from
derivation, not filtered by provenance.

Runtime deps are `nvim` and `perl` with `JSON::PP` (core since perl 5.14), and
deliberately **not** python3: the README's Windows Git Bash path ships perl but
usually not python3, and a guard that cannot run on a supported platform is not a
guard. History is parsed strictly — a truncated row is skipped and counted, never
coerced into a number.

```
./tools/perf/bench.sh                 # 10 runs: median, p90, wall, verdict
./tools/perf/bench.sh --runs 3        # >=2, <=50 (a row stays one atomic write)
./tools/perf/bench.sh --json          # print the recorded row
./tools/perf/bench.sh --accept "why"  # deliberate slowdown: reset the floor (note <= 500 chars)
```

Exit: 0 = PASS/FIRST, 1 = REGRESS, 2 = usage/environment **or a broken dataset**,
3 = INCONCLUSIVE (load over 0.5/cpu — the row is still recorded, the reading just
is not evidence). FIRST means there is genuinely nothing to compare against; a
history that exists but yields zero parseable rows is exit 2, never FIRST, because
"nothing to compare" and "the comparison broke" looking alike is exactly how a real
regression gets waved through. A row that cannot be **written** (read-only history,
full disk) is exit 2 for the same reason — it used to exit 1, the REGRESS code, on
a run whose verdict was PASS.
Two numbers per run: `median` is the `--startuptime` total (the verdict input,
comparable to older rows), `wall` is end-to-end wall clock including process
spawn and timer-deferred setup, which is closer to felt startup.
`./tools/perf/bench_test.sh` is the guard's own regression suite (fake `nvim`,
scratch dir, never touches the real config or history).
