#!/usr/bin/env bash
# tools/perf/bench_test.sh — regression guard for bench.sh (roadmap r2).
#
# Pins the floor semantics (min, machine-scoped, sanity-bounded), the paths where
# a BROKEN dataset must be loud instead of looking like a first run, the load
# verdict, and the atomicity of the append. Uses a fake `nvim` on PATH and a
# scratch tools/perf/ copy, so it is fast, deterministic, and never touches the
# real init.lua or history.ndjson. Every case runs even after one fails; the
# accumulated count decides the exit status at the end. (Seeds the r11 harness.)
#
# perl + JSON::PP is the only interpreter this suite REQUIRES, matching bench.sh:
# python3 is used as an independent cross-check where it is present and skipped
# where it is not, so the suite proves the Windows-Git-Bash path stays alive.
set -euo pipefail

HERE="$(cd "$(dirname "$0")" && pwd)"
REAL_BENCH="$HERE/bench.sh"
[ -f "$REAL_BENCH" ] || { echo "bench.sh not found next to this test" >&2; exit 2; }
REAL_PERL="$(command -v perl 2>/dev/null || true)"
[ -n "$REAL_PERL" ] || { echo "perl required (bench.sh reads history with JSON::PP)" >&2; exit 2; }
"$REAL_PERL" -MJSON::PP -e 'exit 0' 2>/dev/null || { echo "perl JSON::PP required" >&2; exit 2; }

WORK="$(mktemp -d)"
trap 'rm -rf "$WORK"' EXIT

# Mirrors the real layout so bench.sh's own `dirname/../..` REPO_ROOT math resolves.
ROOT="$WORK/root"
mkdir -p "$ROOT/tools/perf" "$WORK/bin"
cp "$REAL_BENCH" "$ROOT/tools/perf/bench.sh"
chmod +x "$ROOT/tools/perf/bench.sh"
: > "$ROOT/init.lua"                      # dummy; the fake nvim ignores it
printf '{"plugins":[]}\n' > "$ROOT/nvim-pack-lock.json"   # gives the row a lock hash
BENCH="$ROOT/tools/perf/bench.sh"
HISTORY="$ROOT/tools/perf/history.ndjson"
OUT="$WORK/out.txt"

# This machine's identity, exactly as bench.sh derives it: the floor is scoped by
# host+arch, so a seeded row has to look local or it will (correctly) be excluded.
HOST="$(hostname -s 2>/dev/null || uname -n)"
HOST="${HOST%%.*}"
OS="$(uname -s)"
ARCH="$(uname -m)"

# --- fake nvim -------------------------------------------------------------
# Emits a DETERMINISTIC VARYING startuptime keyed off the run index, so the suite
# can tell WHICH statistic drives the verdict. With a constant 60.000 every run,
# mutating bench.sh's `median` to `p90` or to `max` both survived the whole
# suite — the fixture made the difference unobservable.
#
#   run 0 (cold, dropped)  -> 999.000
#   run i >= 1             -> i * FAKE_NVIM_BASE (default 60)
#
# so --runs 3 keeps 60/120 (median 60, p90 120), --runs 6 with BASE=10 keeps
# 10/20/30/40/50 (median 30, p90 50), and --runs 12 keeps 60..660 (median 360,
# p90 600, max 660 — all three distinct).
#
# FAKE_NVIM_MS=<raw> writes that token verbatim (character-guard fixtures).
# FAKE_NVIM_NOLOG=1 writes no log at all (a crashed nvim).
# The run index comes out of bench.sh's `$TMP/startup.<i>.log` naming; if that
# ever changes this fake writes no log and bench.sh fails loud (exit 2) rather
# than inventing a number.
cat > "$WORK/bin/nvim" <<'FAKE'
#!/usr/bin/env bash
# Real nvim forces LC_NUMERIC=C for its own output, so the fixture does too: the
# locale case in this suite is about bench.sh's OWN formatting, not nvim's.
export LC_ALL=C
for a in "$@"; do
  if [ "$a" = "--version" ]; then printf 'NVIM v9.9.9\nBuild type: Fake\n'; exit 0; fi
done
f=""; prev=""
for a in "$@"; do [ "$prev" = "--startuptime" ] && f="$a"; prev="$a"; done
if [ "${FAKE_NVIM_NOLOG:-0}" = "1" ]; then exit 1; fi
[ -n "$f" ] || exit 1
if [ -n "${FAKE_NVIM_MS:-}" ]; then
  ms="$FAKE_NVIM_MS"
else
  base="$(basename "$f")"
  idx="${base#startup.}"; idx="${idx%.log}"
  case "$idx" in
    '' | *[!0-9]*) echo "fake nvim: no run index in $f" >&2; exit 1 ;;
  esac
  if [ "$idx" -eq 0 ]; then
    ms="999.000"
  else
    # integer arithmetic only: no awk, so no locale can reformat it
    ms="$(printf '%03d.000' "$((idx * ${FAKE_NVIM_BASE:-60}))")"
  fi
fi
printf 'times in msec\n 000.000  000.000: --- NVIM STARTING ---\n %s  000.010: --- NVIM STARTED ---\n' "$ms" > "$f"
exit 0
FAKE
chmod +x "$WORK/bin/nvim"
export PATH="$WORK/bin:$PATH"
# Pin the load reading: this suite runs on whatever machine, and the real 1-min
# average would otherwise flip verdicts to INCONCLUSIVE at random. Cases that
# want load pressure set their own override.
export BENCH_LOAD_OVERRIDE=0.10

# --- fake interpreters / cpu counts (each in its own dir, applied per case) --
# A perl that fails outright. bench.sh's preflight must turn this into exit 2 with
# a named reason — including on the --accept path, which used to leak exit 9.
mkdir -p "$WORK/badperl"
cat > "$WORK/badperl/perl" <<'BAD'
#!/usr/bin/env bash
echo "perl: broken interpreter" >&2
exit 1
BAD
chmod +x "$WORK/badperl/perl"

# A perl that works for everything EXCEPT the history reader (recognised by the
# reader's own env), where it prints junk on stdout and exits 0. This is the
# repro that reported FIRST / floor null / exit 0 over a seeded 20.0 floor.
mkdir -p "$WORK/junkperl"
cat > "$WORK/junkperl/perl" <<BAD
#!/usr/bin/env bash
if [ -n "\${BENCH_TAG:-}" ] && [ -n "\${BENCH_HISTORY:-}" ]; then
  echo "awk: division by zero"
  exit 0
fi
exec "$REAL_PERL" "\$@"
BAD
chmod +x "$WORK/junkperl/perl"

# ...and one where only the reader exits non-zero: the status must not leak out
# as its own exit code, and must never be swallowed into FIRST.
mkdir -p "$WORK/rcperl"
cat > "$WORK/rcperl/perl" <<BAD
#!/usr/bin/env bash
if [ -n "\${BENCH_TAG:-}" ] && [ -n "\${BENCH_HISTORY:-}" ]; then
  echo "reader exploded" >&2
  exit 7
fi
exec "$REAL_PERL" "\$@"
BAD
chmod +x "$WORK/rcperl/perl"

mkdir -p "$WORK/cpus0" "$WORK/cpusx"
printf '#!/usr/bin/env bash\necho 0\n' > "$WORK/cpus0/nproc"
printf '#!/usr/bin/env bash\necho unknown\n' > "$WORK/cpusx/nproc"
chmod +x "$WORK/cpus0/nproc" "$WORK/cpusx/nproc"

# --- json helpers (perl/JSON::PP; python3 only ever cross-checks) -----------
# Values print as JSON tokens: strings stay QUOTED and undef prints bare `null`,
# so a null can never be mistaken for a 0 or for the string "null". Numbers print
# in perl's shortest form — the row's 60.000 shows as 60, 0.0 as 0 — which is a
# spelling change from the old python json.dumps helper, not a looser check.
# The *-str modes print a string value raw, for byte-for-byte round-trip checks.
JREAD="$WORK/jread.pl"
cat > "$JREAD" <<'PL'
use strict;
use warnings;
use JSON::PP;

binmode(STDOUT);
my $mode = shift(@ARGV);
my $file = shift(@ARGV);
my $dec  = JSON::PP->new;                       # strict: no relaxed, no allow_nonref
my $enc  = JSON::PP->new->allow_nonref->canonical;

sub lines {
  my @out;
  open(my $fh, "<", $file) or return @out;
  while (defined(my $l = <$fh>)) { push @out, $l; }
  close($fh);
  return @out;
}

sub show {
  my ($v) = @_;
  return "null" unless defined $v;
  return ($v ? "true" : "false") if ref($v) eq "JSON::PP::Boolean";
  return $enc->encode($v) if ref($v);
  my $re = eval { $enc->encode($v) };
  if (defined($re) && $re =~ /\A-?(?:0|[1-9][0-9]*)(?:\.[0-9]+)?(?:[eE][-+]?[0-9]+)?\z/) {
    return ($v + 0) . "";
  }
  return $enc->encode($v);
}

my @rows;
my ($blank, $nonblank, $bad) = (0, 0, 0);
my $lineno = 0;
for my $raw (lines()) {
  $lineno++;
  my $l = $raw;
  $l =~ s/\A\s+//;
  $l =~ s/\s+\z//;
  if ($l eq "") { $blank++; next; }
  $nonblank++;
  my $r = eval { $dec->decode($l) };
  if (!defined($r) || ref($r) ne "HASH") {
    $bad++;
    print STDERR "line $lineno: not a strict JSON object\n";
    next;
  }
  push @rows, $r;
}

if ($mode eq "strict") { exit($bad ? 1 : 0); }
if ($mode eq "nonblank") { print "$nonblank\n"; exit 0; }
if ($mode eq "blank") { print "$blank\n"; exit 0; }
if ($mode eq "parsed") { print scalar(@rows) . "\n"; exit 0; }

my ($last_row, $last_marker);
for my $r (@rows) {
  if (exists $r->{marker}) { $last_marker = $r; } else { $last_row = $r; }
}

sub raw {
  my ($v) = @_;
  return "null" unless defined $v;
  return ($v ? "true" : "false") if ref($v) eq "JSON::PP::Boolean";
  return $enc->encode($v) if ref($v);
  return $v;
}

if ($mode eq "field") {
  print(($last_row ? show($last_row->{ $ARGV[0] }) : "") . "\n");
  exit 0;
}
if ($mode eq "field-str") {
  print(($last_row ? raw($last_row->{ $ARGV[0] }) : "") . "\n");
  exit 0;
}
if ($mode eq "marker") {
  print(($last_marker ? show($last_marker->{ $ARGV[0] }) : "") . "\n");
  exit 0;
}
if ($mode eq "marker-str") {
  print(($last_marker ? raw($last_marker->{ $ARGV[0] }) : "") . "\n");
  exit 0;
}
if ($mode eq "samples-count") {
  my $s = $last_row ? $last_row->{samples} : undef;
  print((ref($s) eq "ARRAY" ? scalar(@$s) : -1) . "\n");
  exit 0;
}
if ($mode eq "sample") {
  my $s = $last_row ? $last_row->{samples} : undef;
  unless (ref($s) eq "ARRAY" && defined $s->[ $ARGV[0] ]) { print "\n"; exit 0; }
  print show($s->[ $ARGV[0] ]{ $ARGV[1] }) . "\n";
  exit 0;
}
if ($mode eq "samples-all-positive") {
  my $s = $last_row ? $last_row->{samples} : undef;
  unless (ref($s) eq "ARRAY" && @$s) { print "no\n"; exit 0; }
  for my $r (@$s) {
    my $v = $r->{ $ARGV[0] };
    unless (defined($v) && !ref($v) && show($v) =~ /\A[0-9]/ && $v + 0 > 0) { print "no\n"; exit 0; }
  }
  print "yes\n";
  exit 0;
}
if ($mode eq "positive") {
  my $v = $last_row ? $last_row->{ $ARGV[0] } : undef;
  print((defined($v) && !ref($v) && show($v) =~ /\A[0-9]/ && $v + 0 > 0) ? "yes\n" : "no\n");
  exit 0;
}
if ($mode eq "strlen") {
  my $v = $last_row ? $last_row->{ $ARGV[0] } : undef;
  print(((defined($v) && !ref($v)) ? length($v) : -1) . "\n");
  exit 0;
}
if ($mode eq "strlen-marker") {
  my $v = $last_marker ? $last_marker->{ $ARGV[0] } : undef;
  print(((defined($v) && !ref($v)) ? length($v) : -1) . "\n");
  exit 0;
}
print STDERR "unknown mode: $mode\n";
exit 2;
PL

jr() { perl "$JREAD" "$1" "$HISTORY" "${@:2}"; }
row_field() { jr field "$1"; }

# Strict JSON on EVERY line. perl/JSON::PP is authoritative (it is what bench.sh
# reads history with); python3 re-checks the same file when it is installed, so a
# bug in one parser cannot hide a malformed row — and masking python3 off PATH
# does not weaken the suite into passing vacuously.
xcheck_used=0
strict_json_file() { # <file>
  local rc=0
  perl "$JREAD" strict "$1" || rc=$?
  if [ "$rc" -eq 0 ] && command -v python3 >/dev/null 2>&1; then
    xcheck_used=1
    python3 - "$1" <<'PY' || rc=$?
import json, sys
bad = 0
for i, line in enumerate(open(sys.argv[1]), 1):
    if not line.strip():
        continue
    try:
        json.loads(line)
    except ValueError as e:
        bad += 1
        sys.stderr.write("python3 line %d: %s\n" % (i, e))
sys.exit(1 if bad else 0)
PY
  fi
  return "$rc"
}

pass=0; fail=0; skip=0
LAST_RC=0

# check <name> <expected-exit> -- <command...>
check() {
  local name="$1" want="$2"; shift 3   # drop name, want, and the "--" separator
  local got=0
  "$@" >/dev/null 2>&1 || got=$?
  if [ "$got" -eq "$want" ]; then
    echo "  ok   $name (exit $got)"; pass=$((pass + 1))
  else
    echo "  FAIL $name (want exit $want, got $got)"; fail=$((fail + 1))
  fi
}

# capture <command...> — combined output to $OUT, status in $LAST_RC
capture() {
  LAST_RC=0
  "$@" > "$OUT" 2>&1 || LAST_RC=$?
}

# expect <name> <want> <got>
expect() {
  if [ "$2" = "$3" ]; then
    echo "  ok   $1 ($3)"; pass=$((pass + 1))
  else
    echo "  FAIL $1 (want '$2', got '$3')"; fail=$((fail + 1))
  fi
}

expect_has() { # <name> <needle> [file]
  if grep -qF -- "$2" "${3:-$OUT}"; then
    echo "  ok   $1"; pass=$((pass + 1))
  else
    echo "  FAIL $1 (output lacks '$2')"; fail=$((fail + 1))
  fi
}

expect_lacks() { # <name> <needle> [file]
  if grep -qF -- "$2" "${3:-$OUT}"; then
    echo "  FAIL $1 (output leaked '$2')"; fail=$((fail + 1))
  else
    echo "  ok   $1"; pass=$((pass + 1))
  fi
}

hist_lines() { [ -f "$HISTORY" ] && wc -l < "$HISTORY" | tr -d ' ' || echo 0; }

seed_row() { # <median>  — a synthetic LOCAL history row, as a past run wrote it
  printf '{"ts":"2026-07-25T00:00:00Z","commit":null,"dirty":null,"nvim":"9.9.9","lock":null,"host":"%s","os":"%s","arch":"%s","cpus":10,"load_before":0.10,"load_after":0.10,"load_ratio":0.01,"runs_kept":2,"samples":[],"median":%s,"p90":%s,"wall_median":null,"floor":null,"delta_pct":null,"verdict":"PASS"}\n' \
    "$HOST" "$OS" "$ARCH" "$1" "$1" >> "$HISTORY"
}

seed_foreign_row() { # <median> — same shape, another machine
  printf '{"ts":"2026-07-25T00:00:00Z","commit":null,"dirty":null,"nvim":"9.9.9","lock":null,"host":"some-other-box","os":"Linux","arch":"ppc64","cpus":128,"load_before":0.10,"load_after":0.10,"load_ratio":0.00,"runs_kept":2,"samples":[],"median":%s,"p90":%s,"wall_median":null,"floor":null,"delta_pct":null,"verdict":"PASS"}\n' \
    "$1" "$1" >> "$HISTORY"
}

echo "bench.sh regression suite:"

# --- usage / environment guards (exit 2, never a verdict) ------------------
rm -f "$HISTORY"
check "--runs with no value -> exit 2" 2 -- "$BENCH" --runs
check "--runs 0 -> exit 2" 2 -- "$BENCH" --runs 0
# The row must stay one atomic write, so the sample count is bounded.
check "--runs 999 -> exit 2 (row must stay one write)" 2 -- "$BENCH" --runs 999
# --write is GONE (an inflated scalar was the whole defect); it must not be a
# silently-ignored no-op that a stale habit keeps typing.
check "--write -> exit 2 (flag removed)" 2 -- "$BENCH" --write
check "--accept with no value -> exit 2" 2 -- "$BENCH" --accept
check "--accept '' -> exit 2 (empty note)" 2 -- "$BENCH" --accept ""
# A marker line has the same one-write budget as a row: an unbounded note wrote a
# ~5100-byte line, past the 4096 bound `--runs <= 50` exists to hold.
check "--accept with a 5000-char note -> exit 2" 2 -- "$BENCH" --accept "$(perl -e 'print "x" x 5000')"
expect "usage errors record nothing" "0" "$(hist_lines)"
# A value bash cannot compare numerically must still die through die(), not leak
# `[: integer expression expected` from the -ge test ahead of our message.
capture "$BENCH" --runs 99999999999999999999999
expect "--runs with a 23-digit value -> exit 2" "2" "$LAST_RC"
expect_lacks "--runs overflow leaks no raw shell error" "integer expression expected"
expect_has "--runs overflow speaks as bench.sh" "bench.sh:"
expect "--runs overflow records nothing" "0" "$(hist_lines)"
# ...and that guard counts the VALUE, not the spelling: a zero-padded 10 is ten
# runs, not a four-digit monster to reject with a bogus "<= 50" message.
rm -f "$HISTORY"
check "--runs 0003 -> exit 0 (leading zeros are not width)" 0 -- "$BENCH" --runs 0003
expect "--runs 0003 really ran three times" "3" "$(jr samples-count)"
rm -f "$HISTORY"   # that one SUCCEEDED, so the next case starts from empty again

# A run that writes no log has no samples: exit 2, no crash, and NO row — a
# sample-less row would be a hole in the dataset, not a data point.
check "missing startuptime log -> clean exit 2" 2 -- env FAKE_NVIM_NOLOG=1 "$BENCH" --runs 3
expect "failed run appends no row" "0" "$(hist_lines)"

# --- first run seeds the history ------------------------------------------
rm -f "$HISTORY"
check "absent history -> FIRST, exit 0" 0 -- "$BENCH" --runs 3
expect "FIRST wrote exactly one row" "1" "$(hist_lines)"
expect "FIRST verdict recorded" '"FIRST"' "$(row_field verdict)"
expect "FIRST floor is null" "null" "$(row_field floor)"
expect "FIRST delta is null" "null" "$(row_field delta_pct)"
# Every run is recorded, including the dropped cold one, so a cold-run outlier
# stays visible instead of vanishing into the median.
expect "samples cover every run" "3" "$(jr samples-count)"
expect "cold run flagged, not dropped from samples" "true" "$(jr sample 0 cold)"
expect "runs_kept excludes the cold run" "2" "$(row_field runs_kept)"
# Dual timing: --startuptime misses spawn + timer-deferred setup, so wall_ms is
# the number closest to felt startup.
expect "median is the startuptime total" "60" "$(row_field median)"
expect "wall_median is a positive number" "yes" "$(jr positive wall_median)"
expect "every sample carries wall_ms" "yes" "$(jr samples-all-positive wall_ms)"
# Provenance: a median means nothing without the nvim/plugin-set/machine it was
# measured on, and host+arch are what scope the floor.
expect "nvim version recorded" '"9.9.9"' "$(row_field nvim)"
expect "lock hash is 12 chars" "12" "$(jr strlen lock)"
expect "host recorded" "$HOST" "$(jr field-str host)"
expect "os recorded" "$OS" "$(jr field-str os)"
expect "arch recorded" "$ARCH" "$(jr field-str arch)"
expect "cpus recorded as a positive number" "yes" "$(jr positive cpus)"

# Exactly ONE row per invocation: per-run detail lives inside samples[], so a
# 5-run bench must not leave 5 lines behind. (Fresh history: the fake's samples
# scale with --runs, and this case is about the row count, not the verdict.)
rm -f "$HISTORY"
before="$(hist_lines)"
check "5-run bench -> exit 0" 0 -- "$BENCH" --runs 5
expect "exactly one row appended per invocation" "$((before + 1))" "$(hist_lines)"

# --- WHICH statistic drives the verdict ----------------------------------
# The fake's samples vary, so median / p90 / max are three different numbers and
# a mutation swapping one for another cannot survive. Expected values computed
# out of band: cold 999 is dropped, and p90 is what proves the drop (with the
# cold sample included p90 would be 999).
rm -f "$HISTORY"
check "6 runs at base 10 -> exit 0" 0 -- env FAKE_NVIM_BASE=10 "$BENCH" --runs 6
expect "kept 10/20/30/40/50 -> median 30" "30" "$(row_field median)"
expect "kept 10/20/30/40/50 -> p90 50 (cold 999 dropped)" "50" "$(jr field p90)"
rm -f "$HISTORY"
check "12 runs at base 60 -> exit 0" 0 -- "$BENCH" --runs 12
expect "kept 60..660 -> median 360" "360" "$(row_field median)"
expect "kept 60..660 -> p90 600, not max 660" "600" "$(jr field p90)"
rm -f "$HISTORY"
check "3 runs -> exit 0" 0 -- "$BENCH" --runs 3
expect "kept 60/120 -> median 60" "60" "$(row_field median)"
expect "kept 60/120 -> p90 120 (median is not p90)" "120" "$(jr field p90)"

# --- floor semantics ------------------------------------------------------
# floor = MIN median, not the last row and not the mean: with 40/80/90 a 60ms
# median regresses (>44), while last=90 or mean=70 would both read PASS.
rm -f "$HISTORY"
seed_row 40.000; seed_row 80.000; seed_row 90.000
check "floor is the min -> REGRESS exit 1" 1 -- "$BENCH" --runs 3
expect "floor = min across rows" "40" "$(row_field floor)"
expect "REGRESS verdict recorded" '"REGRESS"' "$(row_field verdict)"
expect "delta measured against the floor" "50" "$(row_field delta_pct)"
expect "rows_valid counts the floor input" "3" "$(row_field rows_valid)"
expect "nothing excluded on a clean history" "0" "$(row_field rows_invalid)"
# ...and not the first row either.
rm -f "$HISTORY"
seed_row 200.000; seed_row 55.000
check "min from a later row -> PASS exit 0" 0 -- "$BENCH" --runs 3
expect "floor = 55 (not 200)" "55" "$(row_field floor)"

# A loaded (inflated) row can never lower the floor, so it cannot poison it:
# 40 stays the floor next to a 900ms outlier.
rm -f "$HISTORY"
seed_row 40.000; seed_row 900.000
check "inflated row does not move the floor" 1 -- "$BENCH" --runs 3
expect "floor unaffected by the outlier" "40" "$(row_field floor)"

# --- a BROKEN dataset is loud, never FIRST -------------------------------
# Ported from the old baseline-corruption cases, with the semantics the redesign
# dropped: a bad row must never become the floor, AND a history whose only data
# rows are all unparseable is CORRUPT, not empty. FIRST/exit 0 there is the exact
# hole this guard exists to close (a seeded 20.0 floor against a 60ms median once
# reported FIRST / floor null / rc 0).
#
# The 12x34 case is a REPEAT REGRESSION: flagged in review 2026-07-24, closed
# with "Without this a dropped char guard slips the suite", then deleted by the
# floor/history rewrite. Do not delete it a third time.
# The 400-digit case is the other dropped one: an absurd literal must not arrive
# as inf and sail through a `> 0` check.
# 1e308 and 1.5e308 pin the reader's OTHER overflow guard, `!($m < 1e308)`, which
# is NOT redundant with the number regex: both are FINITE doubles, both re-encode
# as bare tokens (1e+308) the regex accepts, and either would install a floor no
# honest run can exceed — PASS forever. Delete that guard and these two rows fall
# through to a floor instead of the BROKEN message.
big_digits="$(perl -e 'print "9" x 400')"
for bad in \
  'not json at all' \
  '{"median":40.0,"ts":"2026-07-25T00:00:00Z"' \
  '{"median":"abc"}' \
  '{"median":"60.0"}' \
  '{"median":-5}' \
  '{"median":0}' \
  '{"median":0.0}' \
  '{"median":66.}' \
  '{"median":Infinity}' \
  '{"median":1e400}' \
  '{"median":1e308}' \
  '{"median":1.5e308}' \
  '{"median":12x34}' \
  "{\"median\":$big_digits}" \
  '{"median":true}' \
  '{"median":null}' \
  '[40.0]' \
  '{"median":0.0004}' \
  '{"median":1e-300}' \
  ; do
  printf '%s\n' "$bad" > "$HISTORY"
  capture "$BENCH" --runs 3
  lines_after="$(hist_lines)"
  if [ "$LAST_RC" -eq 2 ] && [ "$lines_after" = "1" ] && grep -q 'BROKEN' "$OUT"; then
    echo "  ok   unusable-only history -> loud exit 2: $(printf '%s' "$bad" | cut -c1-40)"; pass=$((pass + 1))
  else
    echo "  FAIL unusable-only history not loud: $(printf '%s' "$bad" | cut -c1-40) (exit $LAST_RC, $lines_after lines)"
    fail=$((fail + 1))
  fi
done
# The named reason, not a raw interpreter diagnostic: the underflow rows used to
# print `awk: division by zero` after "0.000" reached a division.
printf '%s\n' '{"median":0.0004}' > "$HISTORY"
capture "$BENCH" --runs 3
expect "underflow row: exit 2" "2" "$LAST_RC"
expect_has "underflow row names the dataset as broken" "is BROKEN, not empty"
expect_lacks "underflow row leaks no awk division error" "division by zero"
expect_has "broken dataset points at the escape hatch" '--accept'

# A malformed line next to a good one skips only the malformed line, and the
# counts are surfaced instead of silently swallowed.
rm -f "$HISTORY"
printf 'garbage\n' >> "$HISTORY"
seed_row 40.000
printf '{"median":40.0,"truncat\n' >> "$HISTORY"
check "malformed lines skipped, good row still counts" 1 -- "$BENCH" --runs 3
expect "floor read past the malformed lines" "40" "$(row_field floor)"
expect "invalid rows counted in the row" "2" "$(row_field rows_invalid)"
expect "valid rows counted in the row" "1" "$(row_field rows_valid)"
capture "$BENCH" --runs 3
expect_has "invalid count surfaced to the human" "2 unparseable"

# ...and specifically next to a GOOD row: a finite-but-absurd 1e308 must be
# COUNTED INVALID, not merely out-competed by the smaller floor. Without the
# reader's `!($m < 1e308)` this row is "valid" and the counts give it away.
rm -f "$HISTORY"
seed_row 60.000
printf '%s\n' '{"median":1e308}' >> "$HISTORY"
check "1e308 next to a good row -> PASS on the good row" 0 -- "$BENCH" --runs 3
expect "1e308 row counted invalid" "1" "$(row_field rows_invalid)"
expect "only the good row is valid" "1" "$(row_field rows_valid)"
expect "floor comes from the good row" "60" "$(row_field floor)"

# An unreadable history file is not an absent one.
rm -f "$HISTORY"
seed_row 40.000
chmod 000 "$HISTORY"
if [ -r "$HISTORY" ]; then
  echo "  skip unreadable history (still readable — running as root?)"; skip=$((skip + 1))
else
  capture "$BENCH" --runs 3
  expect "unreadable history -> exit 2" "2" "$LAST_RC"
  expect_has "unreadable history names the reader" "could not read"
  expect_lacks "unreadable history is not reported as FIRST" "FIRST"
fi
chmod 644 "$HISTORY"

# A history that is READABLE but NOT WRITABLE is the other half: the read
# succeeds, a verdict is computed, and then the append fails. That was the one
# non-zero exit bypassing die() — `set -e` killed the script with status 1, the
# REGRESS code, on a run whose verdict was PASS, and printed a raw
# `bash: ...: Permission denied` instead of a bench.sh: message. --accept
# (documented 0 or 2) and --json exited 1 the same way.
rm -f "$HISTORY"
seed_row 60.000
chmod 444 "$HISTORY"
if [ -w "$HISTORY" ]; then
  echo "  skip unwritable history (still writable — running as root?)"; skip=$((skip + 1))
else
  capture "$BENCH" --runs 3
  expect "unwritable history -> exit 2, not 1 (the REGRESS code)" "2" "$LAST_RC"
  expect_has "unwritable history names the failed append" "could not append"
  expect_has "unwritable history speaks as bench.sh" "bench.sh:"
  expect_lacks "unwritable history leaks no raw shell error" "Permission denied"
  expect_lacks "a failed append reports no verdict" "-> PASS"
  capture "$BENCH" --accept "reset over an unwritable file"
  expect "--accept on an unwritable history -> exit 2 (documented 0 or 2)" "2" "$LAST_RC"
  expect_has "--accept names the failed append" "could not append"
  expect_lacks "--accept claims no reset it could not record" "floor reset:"
  capture "$BENCH" --runs 3 --json
  expect "--json on an unwritable history -> exit 2" "2" "$LAST_RC"
  expect_has "--json names the failed append" "could not append"
  expect_lacks "--json prints no row it failed to record" '"verdict"'
  expect "nothing was appended to the unwritable file" "1" "$(hist_lines)"
fi
chmod 644 "$HISTORY"

# --- reader failure must never become FIRST ------------------------------
# Seeded floor 20 vs a 60ms median is a +200% regression: if any of these paths
# exits 0, a real regression just shipped green.
rm -f "$HISTORY"
seed_row 20.000
capture env PATH="$WORK/junkperl:$PATH" "$BENCH" --runs 3
expect "reader printing junk -> exit 2" "2" "$LAST_RC"
expect_has "junk reader output named as unreadable" "unreadable output"
expect_lacks "junk reader is not reported as FIRST" "FIRST"
expect "junk reader appends no row" "1" "$(hist_lines)"

capture env PATH="$WORK/rcperl:$PATH" "$BENCH" --runs 3
expect "reader exiting non-zero -> exit 2 (not its own status)" "2" "$LAST_RC"
expect_has "non-zero reader named as a read failure" "could not read"
expect_lacks "non-zero reader is not reported as FIRST" "FIRST"
expect "non-zero reader appends no row" "1" "$(hist_lines)"

capture env PATH="$WORK/badperl:$PATH" "$BENCH" --runs 3
expect "broken interpreter -> exit 2" "2" "$LAST_RC"
expect_has "broken interpreter names JSON::PP" "JSON::PP"
expect_lacks "broken interpreter is not reported as FIRST" "FIRST"
expect "broken interpreter appends no row" "1" "$(hist_lines)"
# --accept has to keep the documented exit codes too: it exited 9 here, because a
# failed json encode propagated its own status straight out of the script.
capture env PATH="$WORK/badperl:$PATH" "$BENCH" --accept "deliberate"
expect "--accept under a broken interpreter -> exit 2, not 9" "2" "$LAST_RC"
expect "--accept under a broken interpreter appends nothing" "1" "$(hist_lines)"

# --- machine-scoped floor -------------------------------------------------
# Foreign rows stay in the committed file (it is shared, and the dataset is for
# graphing) but must never decide THIS machine's verdict. A faster foreign row is
# the dangerous direction: unscoped it would manufacture a regression.
rm -f "$HISTORY"
seed_foreign_row 20.000
check "foreign-only history -> FIRST, exit 0" 0 -- "$BENCH" --runs 3
expect "foreign row is not the floor" "null" "$(row_field floor)"
expect "foreign row counted as foreign" "1" "$(row_field rows_foreign)"
expect "foreign row is not counted invalid" "0" "$(row_field rows_invalid)"
expect "foreign-only history verdict" '"FIRST"' "$(row_field verdict)"
capture "$BENCH" --runs 3
expect_has "foreign exclusions surfaced to the human" "from another machine"

rm -f "$HISTORY"
seed_foreign_row 20.000; seed_row 60.000
check "local row wins over a faster foreign row -> PASS" 0 -- "$BENCH" --runs 3
expect "floor from the local row only" "60" "$(row_field floor)"
expect "foreign row excluded, local kept" "1" "$(row_field rows_valid)"

# A row recorded before provenance existed cannot be attributed to this machine.
rm -f "$HISTORY"
printf '{"ts":"2026-07-25T08:12:52Z","commit":"02ada2b","cpus":10,"median":20.0,"p90":21.0,"verdict":"FIRST"}\n' > "$HISTORY"
check "unattributable legacy row -> FIRST, exit 0" 0 -- "$BENCH" --runs 3
expect "legacy row is not the floor" "null" "$(row_field floor)"
expect "legacy row counted as foreign" "1" "$(row_field rows_foreign)"

# --- sanity floor: deflation is filtered, not provenance -----------------
# A gutted or half-loaded config must not become a sticky low floor that only
# --accept can clear. Load can only ever inflate a sample, so a too-LOW median is
# the one direction physics cannot explain.
rm -f "$HISTORY"
seed_row 0.500
check "implausibly low row -> FIRST, not a sticky floor" 0 -- "$BENCH" --runs 3
expect "low row is not the floor" "null" "$(row_field floor)"
expect "low row counted as implausible" "1" "$(row_field rows_low)"
expect "low row is not counted invalid" "0" "$(row_field rows_invalid)"
capture "$BENCH" --runs 3
expect_has "sanity exclusions surfaced to the human" "sanity floor"

rm -f "$HISTORY"
seed_row 0.500; seed_row 60.000
check "plausible row wins over an implausible one -> PASS" 0 -- "$BENCH" --runs 3
expect "floor skips the implausible row" "60" "$(row_field floor)"
expect "one row excluded as too low" "1" "$(row_field rows_low)"
rm -f "$HISTORY"
seed_row 5.000; seed_row 60.000
check "a 5ms row is at the sanity bound, excluded" 0 -- "$BENCH" --runs 3
expect "floor is 60, not the 5ms row" "60" "$(row_field floor)"

# --- the character guard at the sample level -----------------------------
# The other half of the 12x34 lesson: a startuptime value with an embedded letter
# must be rejected at parse time, never coerced to 12.
rm -f "$HISTORY"
capture env FAKE_NVIM_MS='12x34' "$BENCH" --runs 3
expect "embedded letter in the log -> exit 2" "2" "$LAST_RC"
expect "embedded letter records no row" "0" "$(hist_lines)"
capture env FAKE_NVIM_MS='0.0004' "$BENCH" --runs 3
expect "a sample that rounds to zero -> exit 2" "2" "$LAST_RC"
expect "a sample that rounds to zero records no row" "0" "$(hist_lines)"
capture env FAKE_NVIM_MS='1e-300' "$BENCH" --runs 3
expect "an underflowing sample -> exit 2" "2" "$LAST_RC"
expect_lacks "underflowing sample leaks no awk division error" "division by zero"

# THREE-TIME REGRESSION — num()'s `x + 0 < 1e308` overflow guard, pinned at the
# SAMPLE path. Reviews 1 and 2 fixed the char guard half and left this half
# unpinned: deleting the expression kept the suite 177/177 green while bench.sh
# wrote {"ms":inf} — not JSON — into history at exit 0/FIRST. The 400-digit
# history row above only exercises the READER; a value this shape has to come
# through a startuptime log to reach num(). All digits, so the char guard passes
# it through and only the overflow test can stop it.
rm -f "$HISTORY"
capture env FAKE_NVIM_MS="$big_digits" "$BENCH" --runs 3
expect "a 400-digit sample -> exit 2, not an inf row" "2" "$LAST_RC"
expect "a 400-digit sample records no row" "0" "$(hist_lines)"
expect_lacks "a 400-digit sample never prints the token inf" "inf"
printf '%s\n' '{"median":60.0,"host":"x"}' > "$HISTORY"   # a file to append to
capture env FAKE_NVIM_MS="$big_digits" "$BENCH" --runs 3 --json
expect "a 400-digit sample under --json -> exit 2" "2" "$LAST_RC"
if grep -q 'inf' "$HISTORY"; then
  echo "  FAIL a 400-digit sample wrote inf into history"; fail=$((fail + 1))
else
  echo "  ok   a 400-digit sample wrote no inf into history"; pass=$((pass + 1))
fi
if strict_json_file "$HISTORY" 2>/dev/null; then
  echo "  ok   history still strict-JSON after a 400-digit sample"; pass=$((pass + 1))
else
  echo "  FAIL a 400-digit sample left a non-strict-JSON line"; fail=$((fail + 1))
fi

# --- load pressure -------------------------------------------------------
rm -f "$HISTORY"
seed_row 60.000
before="$(hist_lines)"
check "high load -> INCONCLUSIVE exit 3" 3 -- env BENCH_LOAD_OVERRIDE=99 "$BENCH" --runs 3
expect "INCONCLUSIVE row still appended" "$((before + 1))" "$(hist_lines)"
expect "INCONCLUSIVE verdict recorded" '"INCONCLUSIVE"' "$(row_field verdict)"
expect "INCONCLUSIVE still records the floor" "60" "$(row_field floor)"
expect "INCONCLUSIVE still records the delta" "0" "$(row_field delta_pct)"
expect "INCONCLUSIVE records the load it saw" "99" "$(row_field load_before)"
expect "INCONCLUSIVE records the load ratio" "yes" "$(jr positive load_ratio)"
# Load pressure must not mask a real regression as a PASS: it is its own verdict.
rm -f "$HISTORY"
seed_row 20.000
check "high load over a regressing median -> exit 3, not 0" 3 -- env BENCH_LOAD_OVERRIDE=99 "$BENCH" --runs 3
# A first run has nothing to compare against, so the load reading cannot change
# the outcome — it seeds the history either way (an inflated seed self-corrects).
rm -f "$HISTORY"
check "high load on a first run -> FIRST exit 0" 0 -- env BENCH_LOAD_OVERRIDE=99 "$BENCH" --runs 3
expect "first run under load still seeds" '"FIRST"' "$(row_field verdict)"
# Load under the 0.5/cpu threshold is not pressure.
rm -f "$HISTORY"
seed_row 60.000
check "low load -> normal verdict" 0 -- env BENCH_LOAD_OVERRIDE=0.20 "$BENCH" --runs 3

# The verdict uses max(load_before, load_after), and with ONE constant override
# that max was invisible: replacing it with either operand alone survived all 177
# cases. The override is a comma sequence indexed by reading (0 = before,
# 1 = after), so a run can climb or fall mid-flight. The pair below fails if the
# max collapses to EITHER operand — climbing kills `load_before`, falling kills
# `load_after` — and both fail if the fixture ever goes constant again.
rm -f "$HISTORY"
seed_row 60.000
check "load climbing mid-run (0.10 -> 99) -> INCONCLUSIVE exit 3" 3 -- env BENCH_LOAD_OVERRIDE=0.10,99 "$BENCH" --runs 3
expect "the climbing run recorded its low before-reading" "0.1" "$(row_field load_before)"
expect "the climbing run recorded its high after-reading" "99" "$(row_field load_after)"
expect "the climbing run rated the load off the max" "9.9" "$(row_field load_ratio)"
expect "the climbing run is INCONCLUSIVE, not PASS" '"INCONCLUSIVE"' "$(row_field verdict)"
rm -f "$HISTORY"
seed_row 60.000
check "load falling mid-run (99 -> 0.10) -> INCONCLUSIVE exit 3" 3 -- env BENCH_LOAD_OVERRIDE=99,0.10 "$BENCH" --runs 3
expect "the falling run recorded its high before-reading" "99" "$(row_field load_before)"
expect "the falling run recorded its low after-reading" "0.1" "$(row_field load_after)"
expect "the falling run rated the load off the max" "9.9" "$(row_field load_ratio)"
# A single-value override still means "this load, both readings" — the sequence
# is an extension, not a new required spelling.
rm -f "$HISTORY"
seed_row 60.000
check "a single-value override still PASSes at low load" 0 -- env BENCH_LOAD_OVERRIDE=0.10 "$BENCH" --runs 3
expect "single value applies to the before-reading" "0.1" "$(row_field load_before)"
expect "single value applies to the after-reading too" "0.1" "$(row_field load_after)"

# --- unknown / zero cpus: no division, and the inert gate says so --------
# PASS printed at load 99 with nothing indicating the load gate never ran is
# indistinguishable from a real PASS, and cpus=0 used to leak a raw awk error.
rm -f "$HISTORY"
seed_row 60.000
capture env PATH="$WORK/cpus0:$PATH" BENCH_LOAD_OVERRIDE=99 "$BENCH" --runs 3
expect "cpus=0 -> no crash, verdict still reported" "0" "$LAST_RC"
expect_lacks "cpus=0 leaks no awk division error" "division by zero"
expect_has "cpus=0 announces the inert load gate" "load check skipped (cpu count unknown)"
expect "cpus=0 recorded as null" "null" "$(row_field cpus)"
expect "cpus=0 records a null load ratio" "null" "$(row_field load_ratio)"
capture env PATH="$WORK/cpusx:$PATH" BENCH_LOAD_OVERRIDE=99 "$BENCH" --runs 3
expect "non-numeric cpus -> no crash" "0" "$LAST_RC"
expect_has "non-numeric cpus announces the inert load gate" "load check skipped (cpu count unknown)"
expect "non-numeric cpus recorded as null" "null" "$(row_field cpus)"

# --- --accept resets the floor -------------------------------------------
rm -f "$HISTORY"
seed_row 40.000
check "before accept: slower median REGRESSes" 1 -- "$BENCH" --runs 3
before="$(hist_lines)"
check "--accept -> exit 0" 0 -- "$BENCH" --accept "added a plugin on purpose"
expect "--accept appends one marker line" "$((before + 1))" "$(hist_lines)"
expect "marker recorded" "floor-reset" "$(jr marker-str marker)"
expect "marker carries the note" "added a plugin on purpose" "$(jr marker-str note)"
# These two pin the WRITER. They say nothing about scoping on their own — the
# foreign/legacy marker cases further down are what pin the reader's check.
expect "marker carries the host" "$HOST" "$(jr marker-str host)"
expect "marker carries the arch" "$ARCH" "$(jr marker-str arch)"
# Rows before the marker are history, not floor input: the next run seeds afresh.
check "first run after accept -> FIRST exit 0" 0 -- "$BENCH" --runs 3
expect "accept cleared the old floor" "null" "$(row_field floor)"
check "run after that PASSes at the new floor" 0 -- "$BENCH" --runs 3
expect "new floor is the post-accept median" "60" "$(row_field floor)"
expect "post-accept verdict" '"PASS"' "$(row_field verdict)"
# A marker also clears a corrupt window: the escape hatch the error message names
# has to actually work.
rm -f "$HISTORY"
printf 'garbage row\n' > "$HISTORY"
check "corrupt-only history -> exit 2" 2 -- "$BENCH" --runs 3
check "--accept still works on a corrupt history" 0 -- "$BENCH" --accept "reset after corruption"
check "run after the reset -> FIRST exit 0" 0 -- "$BENCH" --runs 3
expect "post-reset run ignores the corrupt row" "null" "$(row_field floor)"
expect "post-reset run counts no invalid rows" "0" "$(row_field rows_invalid)"

# --- a marker is MACHINE-SCOPED, exactly like a row ----------------------
# history.ndjson is committed and shared, so another machine's --accept lands in
# this file. Unscoped, that foreign line wiped THIS machine's floor and the next
# run reported FIRST / exit 0 over a +200% regression — the same silent-green
# hole the row scoping exists to close, re-opened through the reset path. Each
# case below is a REGRESS that only stays a REGRESS while the scoping check
# lives; drop the check and every one of them turns into FIRST / exit 0.
marker_line() { # <host-json-fragment> — appends a floor-reset marker
  printf '{"marker":"floor-reset","ts":"2026-07-25T00:00:00Z","note":"n","commit":null%s}\n' "$1" >> "$HISTORY"
}
rm -f "$HISTORY"
seed_row 20.000
check "control: a 20ms floor REGRESSes with no marker at all" 1 -- "$BENCH" --runs 3

rm -f "$HISTORY"
seed_row 20.000
marker_line ',"host":"some-other-box","arch":"ppc64"'
check "another machine's --accept does NOT reset this floor -> REGRESS exit 1" 1 -- "$BENCH" --runs 3
expect "the floor survived the foreign marker" "20" "$(row_field floor)"
expect "the local row still feeds the floor" "1" "$(row_field rows_valid)"
expect "the ignored marker is counted" "1" "$(row_field markers_foreign)"
capture "$BENCH" --runs 3
expect_has "the ignored marker is surfaced to the human" "floor-reset marker(s) IGNORED"

# Same host, different arch (an x86 box and an arm box sharing a hostname, or a
# rosetta shell): still not this machine.
rm -f "$HISTORY"
seed_row 20.000
marker_line ",\"host\":\"$HOST\",\"arch\":\"ppc64\""
check "same host, foreign arch does NOT reset -> REGRESS exit 1" 1 -- "$BENCH" --runs 3
expect "floor survived the wrong-arch marker" "20" "$(row_field floor)"

# The shape the PREVIOUS bench.sh wrote: host, no arch. Unattributable, so inert.
rm -f "$HISTORY"
seed_row 20.000
marker_line ",\"host\":\"$HOST\""
check "a marker with no arch does NOT reset -> REGRESS exit 1" 1 -- "$BENCH" --runs 3
expect "floor survived the arch-less marker" "20" "$(row_field floor)"

# A legacy marker with no machine identity at all. Conservative reading: it
# resets nothing. Ignoring a marker that WAS mine costs a loud REGRESS one local
# --accept clears; honouring one that was NOT mine hides a regression behind
# exit 0.
rm -f "$HISTORY"
seed_row 20.000
marker_line ''
check "a marker with no machine identity does NOT reset -> REGRESS exit 1" 1 -- "$BENCH" --runs 3
expect "floor survived the identity-less marker" "20" "$(row_field floor)"
expect "the identity-less marker is counted as ignored" "1" "$(row_field markers_foreign)"

# Second consequence: a foreign marker must not launder a CORRUPT dataset into a
# clean first run either. Corrupt row, then somebody else's reset.
rm -f "$HISTORY"
printf 'garbage row\n' > "$HISTORY"
marker_line ',"host":"some-other-box","arch":"ppc64"'
check "a foreign marker does not turn a corrupt dataset into FIRST" 2 -- "$BENCH" --runs 3
capture "$BENCH" --runs 3
expect_has "the corrupt dataset is still named" "is BROKEN, not empty"

# ...and THIS machine's marker still does its job, over both.
rm -f "$HISTORY"
seed_row 20.000
marker_line ',"host":"some-other-box","arch":"ppc64"'
check "a local --accept still resets after a foreign marker" 0 -- "$BENCH" --accept "mine, this box"
check "the run after a local reset -> FIRST exit 0" 0 -- "$BENCH" --runs 3
expect "the local reset cleared the floor" "null" "$(row_field floor)"
expect "no marker is left ignored after the local reset" "0" "$(row_field markers_foreign)"

# --- append integrity ----------------------------------------------------
# Two concurrent runs must leave two WHOLE lines: the append is a single write()
# on an O_APPEND fd, so halves can never interleave.
rm -f "$HISTORY"
seed_row 60.000
before="$(hist_lines)"
( "$BENCH" --runs 3 >/dev/null 2>&1 || true ) &
( "$BENCH" --runs 3 >/dev/null 2>&1 || true ) &
wait
expect "two concurrent runs -> two rows" "$((before + 2))" "$(hist_lines)"
if strict_json_file "$HISTORY" 2>/dev/null; then
  echo "  ok   concurrent rows are both whole JSON"; pass=$((pass + 1))
else
  echo "  FAIL concurrent rows interleaved"; fail=$((fail + 1))
fi

# A truncated final line (killed run, or a merge on this committed append-only
# file) must not weld two rows into one invalid line: run 1 REGRESSed correctly
# and run 2 then read floor null / FIRST / exit 0, having destroyed both.
rm -f "$HISTORY"
seed_row 40.000
perl -e 'my $f = shift; open my $fh, "<", $f or die; my @l = <$fh>; close $fh; chomp $l[-1]; open my $o, ">", $f or die; print {$o} @l;' "$HISTORY"
expect "fixture really has no trailing newline" "0" "$(perl -e 'my $f=shift; open my $fh,"<",$f or die; my $c=do{local $/;<$fh>}; print(($c =~ /\n\z/) ? 1 : 0), "\n";' "$HISTORY")"
check "append after a truncated line -> REGRESS exit 1" 1 -- "$BENCH" --runs 3
expect "the truncated row was not welded (2 parseable lines)" "2" "$(jr parsed)"
expect "no blank line was introduced" "0" "$(jr blank)"
expect "the pre-existing row still fed the floor" "40" "$(row_field floor)"
if strict_json_file "$HISTORY" 2>/dev/null; then
  echo "  ok   both lines strict-JSON after the un-welded append"; pass=$((pass + 1))
else
  echo "  FAIL welded/invalid line after appending to a truncated file"; fail=$((fail + 1))
fi
before="$(hist_lines)"
check "a second append after the repair stays clean" 0 -- "$BENCH" --accept "post-weld reset"
expect "repaired file grows by exactly one line" "$((before + 1))" "$(hist_lines)"

# The widest --runs still has to fit one write. PIPE_BUF governs pipes, not
# regular files — the guarantee is that one write() to an O_APPEND fd is atomic —
# so this bound is belt-and-braces, kept because it is cheap. (Measured: 8
# concurrent runs at --runs 50 produced 8 whole strict-JSON lines, widest 2873
# bytes.)
rm -f "$HISTORY"
check "--runs 50 -> exit 0" 0 -- "$BENCH" --runs 50
longest="$(awk '{ if (length($0) > m) m = length($0) } END { print m + 0 }' "$HISTORY")"
if [ "$longest" -lt 4096 ]; then
  echo "  ok   widest row stays well inside one write ($longest bytes)"; pass=$((pass + 1))
else
  echo "  FAIL widest row exceeds the 4096-byte bound ($longest bytes)"; fail=$((fail + 1))
fi

# The other line this tool writes is the marker, and its width is driven by a
# free-text note. A note AT the bound must still work, and the line it produces
# must fit the same budget — worst case the note escapes to 6 bytes per byte.
rm -f "$HISTORY"
check "--accept with a 500-char note -> exit 0 (at the bound)" 0 -- "$BENCH" --accept "$(perl -e 'print "\x01" x 500')"
expect "the bounded note round-trips" "500" "$(jr strlen-marker note)"
longest="$(awk '{ if (length($0) > m) m = length($0) } END { print m + 0 }' "$HISTORY")"
if [ "$longest" -lt 4096 ]; then
  echo "  ok   worst-case marker line stays inside one write ($longest bytes)"; pass=$((pass + 1))
else
  echo "  FAIL marker line exceeds the 4096-byte bound ($longest bytes)"; fail=$((fail + 1))
fi

# --- strict JSON out, in every locale ------------------------------------
# Every line this tool writes — rows and markers, verdict by verdict — must be
# strict-JSON parseable, because the floor derivation reads it back strictly.
rm -f "$HISTORY"
"$BENCH" --runs 3 >/dev/null 2>&1 || true                                  # FIRST
"$BENCH" --runs 3 >/dev/null 2>&1 || true                                  # PASS
env BENCH_LOAD_OVERRIDE=99 "$BENCH" --runs 3 >/dev/null 2>&1 || true       # INCONCLUSIVE
"$BENCH" --accept 'note with "quotes", a \backslash and é' >/dev/null 2>&1 || true
"$BENCH" --runs 3 >/dev/null 2>&1 || true                                  # FIRST again
if strict_json_file "$HISTORY"; then
  echo "  ok   every history line strict-JSON parseable ($(hist_lines) lines)"; pass=$((pass + 1))
else
  echo "  FAIL history.ndjson has a non-strict-JSON line"; fail=$((fail + 1))
fi
expect "the marker note survived quoting round-trip" 'note with "quotes", a \backslash and é' "$(jr marker-str note)"

# A non-C locale reformats awk's %.*f: LC_ALL=de_DE.UTF-8 emitted
# {"median":60,000,...}, so EVERY row was unparseable, the floor never armed, and
# three consecutive runs reported FIRST / exit 0 with a +200% regression present.
#
# Detected WITHOUT a pipe: `locale -a | grep -q` makes grep exit on the first
# match, SIGPIPEs locale, and `set -o pipefail` turns that 141 into "not
# installed" — so this case skipped itself on a box where the locale IS present,
# non-deterministically (whether locale's output outruns grep is a race).
locales_available="$(locale -a 2>/dev/null || true)"
case "$locales_available" in *de_DE.UTF-8*) have_de_locale=1 ;; *) have_de_locale=0 ;; esac
if [ "$have_de_locale" -eq 1 ]; then
  rm -f "$HISTORY"
  seed_row 60.000
  capture env LC_ALL=de_DE.UTF-8 "$BENCH" --runs 3 --json
  expect "de_DE locale -> normal verdict, exit 0" "0" "$LAST_RC"
  if strict_json_file "$OUT" 2>/dev/null; then
    echo "  ok   de_DE --json output is strict JSON"; pass=$((pass + 1))
  else
    echo "  FAIL de_DE --json output is not strict JSON: $(cat "$OUT")"; fail=$((fail + 1))
  fi
  expect_lacks "de_DE row has no comma decimal" "60,000"
  if strict_json_file "$HISTORY" 2>/dev/null; then
    echo "  ok   de_DE history line is strict JSON"; pass=$((pass + 1))
  else
    echo "  FAIL de_DE wrote a non-strict-JSON history line"; fail=$((fail + 1))
  fi
  expect "de_DE median is a plain number" "60" "$(row_field median)"
  expect "de_DE run still compared against the floor" "60" "$(row_field floor)"
  # ...and the whole suite is meant to survive being RUN in that locale too.
  capture env LC_ALL=de_DE.UTF-8 "$BENCH" --runs 3
  expect "de_DE human output, exit 0" "0" "$LAST_RC"
  expect_has "de_DE human output keeps a dot decimal" "60.000"
else
  echo "  skip de_DE.UTF-8 locale not installed on this box (locale -a)"; skip=$((skip + 1))
fi

# --json prints the row it recorded, and that line parses on its own.
out="$WORK/json.out"
if "$BENCH" --runs 3 --json > "$out" 2>/dev/null && strict_json_file "$out" 2>/dev/null; then
  echo "  ok   --json is strict-parseable"; pass=$((pass + 1))
else
  echo "  FAIL --json not strict-parseable"; fail=$((fail + 1))
fi
expect "--json prints exactly the recorded row" "$(tail -n1 "$HISTORY")" "$(cat "$out")"

echo "----"
if [ "$xcheck_used" -eq 1 ]; then
  echo "strict-JSON cross-check: perl/JSON::PP + python3"
else
  echo "strict-JSON cross-check: perl/JSON::PP only (python3 absent — bench.sh does not need it)"
fi
echo "passed $pass, failed $fail, skipped $skip"
[ "$fail" -eq 0 ]
