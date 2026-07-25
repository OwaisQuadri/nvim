#!/usr/bin/env bash
# tools/perf/bench.sh — Neovim startup-time perf guard (roadmap r2).
#
# Runs `nvim --headless -u init.lua --startuptime` N times, drops the cold first
# run (disk-cache warmup), and reports the median + p90 of the reported total
# plus the median end-to-end wall clock. Every invocation appends exactly one row
# to tools/perf/history.ndjson and compares its median against the FLOOR: the
# minimum median over the rows THIS MACHINE recorded since the last --accept.
#
#   ./tools/perf/bench.sh                  # 10 runs, human table + verdict
#   ./tools/perf/bench.sh --runs 3         # fewer runs (>=2, <=50; cold is dropped)
#   ./tools/perf/bench.sh --json           # print the recorded history row instead
#   ./tools/perf/bench.sh --accept "why"   # reset the floor (deliberate slowdown)
#
# Runtime deps: nvim, perl with JSON::PP (core since perl 5.14). Not python3.
#
# Exit codes: 0 = PASS or FIRST, 1 = REGRESS, 2 = usage/environment error or a
# broken dataset, 3 = INCONCLUSIVE (machine too loaded for the reading to mean
# anything).
#
set -euo pipefail

# LC_ALL=C before any awk/printf/sort: awk's locale-dependent %.*f under
# de_DE.UTF-8 emits comma decimals (60,000), which is not JSON and silently
# voids the floor; `sort -n` misreads the same comma.
export LC_ALL=C

# A median at or below this cannot be real startup with a plugin set loaded
# (the quiet-machine median is ~54.7ms), so it means a gutted or half-loaded
# config. Load can only ever inflate a sample, so deflation is the one
# direction that must be filtered or it sticks as an unbeatable floor.
SANITY_MIN_MS=5.0

# Sentinel on the history reader's one output line: anything else on stdout
# (broken interpreter, stray warning, junk) must be rejected, not parsed into
# a floor.
HISTORY_READER_TAG="bench-history-v2"

RUNS=10
JSON=0
ACCEPT=""
ACCEPT_SET=0

usage() {
  # Prints the header above, stopping before the WHY note (rationale, not usage).
  # Stops at the first non-comment line rather than a sentinel comment: the old
  # terminator was a `# WHY` block that a comment purge deleted, which would
  # have made --help print the entire script.
  sed -n '2,${/^#/!q; s/^# \{0,1\}//p;}' "$0"
}

# Every non-zero exit goes through die(), so a failing helper cannot leak its
# own status (--accept once exited 9 when a failed json encode escaped).
die() { # <exit-code> <reason>
  printf 'bench.sh: %s\n' "$2" >&2
  exit "$1"
}

while [ $# -gt 0 ]; do
  case "$1" in
    --runs)
      [ $# -ge 2 ] || die 2 "--runs requires a value"
      RUNS="$2"; shift 2 ;;
    --runs=*) RUNS="${1#*=}"; shift ;;
    --accept)
      [ $# -ge 2 ] || die 2 "--accept requires a note"
      ACCEPT="$2"; ACCEPT_SET=1; shift 2 ;;
    --accept=*) ACCEPT="${1#*=}"; ACCEPT_SET=1; shift ;;
    --json) JSON=1; shift ;;
    -h|--help) usage; exit 0 ;;
    *) printf 'unknown arg: %s\n' "$1" >&2; usage >&2; exit 2 ;;
  esac
done

case "$RUNS" in
  ''|*[!0-9]*) die 2 "--runs must be a positive integer" ;;
esac
# Leading zeros first, so the digit-count guard below measures the VALUE and not
# the spelling: `--runs 0010` is ten runs, not a four-digit monster.
while [ "${#RUNS}" -gt 1 ]; do
  case "$RUNS" in 0*) RUNS="${RUNS#0}" ;; *) break ;; esac
done
# Bound the DIGIT COUNT before any arithmetic: `[ 99999999999999999999999 -ge 2 ]`
# overflows bash's signed long and leaks a raw `[: integer expression expected`
# ahead of our own message. Three digits is already past the <= 50 bound below.
[ "${#RUNS}" -le 3 ] || die 2 "--runs must be <= 50 (a history row must stay one atomic write)"
[ "$RUNS" -ge 2 ] || die 2 "--runs must be >= 2 (one cold run is dropped)"
# Upper bound so the history row stays ONE write (see append_row): 50 samples of
# ~50 bytes plus the fixed fields measured 2873 bytes, comfortably inside the
# 4096 belt-and-braces bound the suite asserts.
[ "$RUNS" -le 50 ] || die 2 "--runs must be <= 50 (a history row must stay one atomic write)"

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/../.." && pwd)"
INIT="$REPO_ROOT/init.lua"
HISTORY="$SCRIPT_DIR/history.ndjson"
LOCK="$REPO_ROOT/nvim-pack-lock.json"

# One write() to an O_APPEND fd is atomic, so two concurrent runs cannot
# interleave halves of a row. PIPE_BUF governs pipes, not regular files;
# keeping a row under 4096 bytes is belt-and-braces, not the guarantee.
#
# The file is append-only and committed, so its last line can be truncated by
# a killed run or a merge. Appending onto that welds two rows into one
# invalid line and destroys BOTH, so the payload leads with a newline.
# A failed append is an environment error (exit 2), never the verdict: it used
# to exit 1, the REGRESS code, on a PASS run. stderr is redirected before the
# append so the shell's own error cannot leak past die() (bash applies
# redirections left to right).
append_row() { # <json-line>
  local lead=""
  if [ -s "$HISTORY" ] && [ "$(tail -c 1 "$HISTORY" | wc -l | tr -d ' ')" -eq 0 ]; then
    lead="
"
  fi
  printf '%s%s\n' "$lead" "$1" 2>/dev/null >> "$HISTORY" \
    || die 2 "could not append the row to $HISTORY (not writable?) — nothing was recorded, so this run is not a verdict"
}

# JSON string escaping via JSON::PP. The value arrives in the environment rather
# than in argv so a note starting with `-` cannot be read as a perl switch.
json_string() { # <raw-string>
  BENCH_JSON_STR="$1" perl -MJSON::PP -e '
    binmode(STDOUT);
    print JSON::PP->new->allow_nonref->encode($ENV{BENCH_JSON_STR});
  '
}

# Preflight the ONE interpreter this script depends on, and prove JSON::PP
# actually encodes rather than merely loading: every later perl call assumes it.
if [ "$(perl -MJSON::PP -e 'print JSON::PP->new->canonical->encode({a=>1})' 2>/dev/null || true)" != '{"a":1}' ]; then
  die 2 "perl with JSON::PP is required (core since perl 5.14) — history.ndjson must be read STRICTLY, and jq-lenient parsing would let a truncated row become the floor"
fi

ts="$(date -u '+%Y-%m-%dT%H:%M:%SZ')"

commit="null"
dirty="null"
if head_hash="$(git -C "$REPO_ROOT" rev-parse --short HEAD 2>/dev/null)"; then
  head_hash="$(printf '%s' "$head_hash" | tr -cd '0-9a-fA-F')"
  if [ -n "$head_hash" ]; then
    commit="\"$head_hash\""
    if [ -n "$(git -C "$REPO_ROOT" status --porcelain 2>/dev/null)" ]; then
      dirty=true
    else
      dirty=false
    fi
  fi
fi

# Machine identity. The floor is scoped by host+arch, so an unidentifiable
# machine is an environment error, not a reason to quietly compare against
# everybody's rows (or against none of them and call it FIRST).
host="$(hostname -s 2>/dev/null || true)"
[ -n "$host" ] || host="$(uname -n 2>/dev/null || true)"
host="$(printf '%s' "${host%%.*}" | tr -cd '0-9A-Za-z._-')"
os="$(uname -s 2>/dev/null | tr -cd '0-9A-Za-z._-' || true)"
arch="$(uname -m 2>/dev/null | tr -cd '0-9A-Za-z._-' || true)"
[ -n "$host" ] || die 2 "cannot determine this machine's hostname; the floor is machine-scoped and refuses to guess"
[ -n "$arch" ] || die 2 "cannot determine this machine's arch (uname -m); the floor is machine-scoped and refuses to guess"
os_json="null"
[ -n "$os" ] && os_json="\"$os\""

if [ "$ACCEPT_SET" -eq 1 ]; then
  [ -n "$ACCEPT" ] || die 2 "--accept requires a non-empty note"
# A marker line has the same one-write budget as a row: an unbounded note wrote
# ~5100 bytes. 500 chars is plenty, and worst-case escaping (6 bytes out per
# byte in) still fits.
  [ "${#ACCEPT}" -le 500 ] || die 2 "--accept note must be 500 characters or fewer (a history line must stay one atomic write)"
  note_json=""
  note_json="$(json_string "$ACCEPT")" || die 2 "could not encode the --accept note as JSON (perl/JSON::PP failed)"
  [ -n "$note_json" ] || die 2 "could not encode the --accept note as JSON (empty result)"
  # host AND arch: the marker resets the floor of the machine that wrote it and
  # of no other (see history_stats). A marker missing either field can never be
  # attributed, so it resets nothing — including this machine.
  marker="{\"marker\":\"floor-reset\",\"ts\":\"$ts\",\"note\":$note_json,\"commit\":$commit,\"host\":\"$host\",\"arch\":\"$arch\"}"
  append_row "$marker"
  if [ "$JSON" -eq 1 ]; then
    printf '%s\n' "$marker"
  else
    echo "floor reset: $ACCEPT"
    echo "  the next run seeds a new floor; earlier rows stay in $HISTORY as history."
  fi
  exit 0
fi

[ -f "$INIT" ] || die 2 "init.lua not found at $INIT"
command -v nvim >/dev/null 2>&1 || die 2 "nvim not on PATH"
# perl times each nvim process end-to-end; there is no portable sub-second clock
# in BSD date and bash 3.2 has no $EPOCHREALTIME.
command -v perl >/dev/null 2>&1 || die 2 "perl not on PATH (needed for wall_ms)"

TMP="$(mktemp -d)"
trap 'rm -rf "$TMP"' EXIT

# Bare fixed-point float, or "" if unparseable (JSON allows no leading zeros,
# bare dots, or inf). The character guard stops an embedded letter ("12x34")
# numifying to 12 -- dropped once already, restored 2026-07-24.
# x + 0 < 1e308 catches what the char guard cannot: a value of 400 nines is all
# digits, but overflows to inf in awk and prints the literal token, and
# {"ms":inf} is not JSON -- it destroys the row and every reader of it. THREE
# reviews missed this. Pinned at the sample path by bench_test.sh's 400-digit
# case; run that case before touching either guard.
num() { # <raw> <decimals>
  case "$1" in
    '' | *[!0-9.]* | *.*.* | '.') return 0 ;;
  esac
  awk -v x="$1" -v d="$2" 'BEGIN { if (x + 0 < 1e308) printf "%.*f\n", d, x }'
}

# num(), plus: a value that ROUNDS TO ZERO at this precision is not data. 1e-300
# and 0.0004 both normalize to "0.000", which then reached a division and printed
# a raw `awk: division by zero` — the m > 0 invariant every later step assumes
# was quietly false. Unrepresentable becomes null/skipped, never a number.
num_pos() { # <raw> <decimals>
  local v
  v="$(num "$1" "$2")"
  case "$v" in '' | -*) return 0 ;; esac
  awk -v x="$v" 'BEGIN { exit (x + 0 > 0 ? 0 : 1) }' || return 0
  printf '%s\n' "$v"
}

# Reads history.ndjson STRICTLY (JSON::PP, never jq -- a truncated line must
# fail to decode and be COUNTED, not half-parsed) and prints exactly one line:
#   bench-history-v2 <floor|-> <valid> <invalid> <foreign> <low> <markers_foreign>
#
# scoped to the rows after the last floor-reset marker THIS MACHINE wrote, and
# among those to the rows whose host+arch match this machine.
#
# Deliberately NOT scoped by commit or lock hash -- a plugin-driven slowdown IS
# a regression (see CLAUDE.md). Do not add lock filtering.
#
# Rows with no host/arch (pre-provenance) count as foreign, not mine:
# unattributable is not mine, and a foreign row that happened to be faster
# would manufacture a regression here.
#
# Markers are scoped the same way. Committed and shared means someone else's
# --accept lands in this file too, and unscoped it also launders a corrupt
# dataset into a false FIRST.
#
# A marker missing host or arch is foreign too, so it resets nothing: ignoring
# a marker that was mine costs a recoverable loud REGRESS, honouring one that
# was not hides a real regression. Loud-wrong beats silent-wrong. Counted and
# surfaced, so "my --accept did nothing" is never a mystery.
history_stats() {
  BENCH_HISTORY="$HISTORY" BENCH_HOST="$host" BENCH_ARCH="$arch" \
  BENCH_SANITY_MIN="$SANITY_MIN_MS" BENCH_TAG="$HISTORY_READER_TAG" \
  perl -e '
    use strict;
    use warnings;
    use JSON::PP;

    my $path   = $ENV{BENCH_HISTORY};
    my $host   = $ENV{BENCH_HOST};
    my $arch   = $ENV{BENCH_ARCH};
    my $sanity = $ENV{BENCH_SANITY_MIN} + 0;
    my $tag    = $ENV{BENCH_TAG};

    my $dec = JSON::PP->new;                    # strict: no relaxed, no allow_nonref
    my $enc = JSON::PP->new->allow_nonref;

    my @medians;
    my ($valid, $invalid, $foreign, $low, $mforeign) = (0, 0, 0, 0, 0);

    if (-e $path) {
      open(my $fh, "<", $path) or die "cannot read $path: $!\n";
      while (defined(my $line = <$fh>)) {
        $line =~ s/\A\s+//;
        $line =~ s/\s+\z//;
        next if $line eq "";
        my $row = eval { $dec->decode($line) };
        if (!defined($row) || ref($row) ne "HASH") { $invalid++; next; }
        my $mk = $row->{marker};
        if (defined($mk) && !ref($mk) && $mk eq "floor-reset") {
          # A marker speaks for one machine only; missing identity = not mine.
          my $mh = (defined($row->{host}) && !ref($row->{host})) ? $row->{host} : "";
          my $ma = (defined($row->{arch}) && !ref($row->{arch})) ? $row->{arch} : "";
          if ($mh ne $host || $ma ne $arch) { $mforeign++; next; }
          @medians = ();
          ($valid, $invalid, $foreign, $low, $mforeign) = (0, 0, 0, 0, 0);
          next;
        }
        my $m = $row->{median};
# Re-encoding IS the strict number test: a JSON string, bool, null, or literal
# too big for a double all come back quoted/true/Inf, and only a real JSON
# number comes back bare. So "12x34" can never numify to 12, and a 400-digit
# literal can never arrive as inf and pass a > 0 check.
        my $re = eval { $enc->encode($m) };
        if (!defined($re) || $re !~ /\A-?(?:0|[1-9][0-9]*)(?:\.[0-9]+)?(?:[eE][-+]?[0-9]+)?\z/) {
          $invalid++; next;
        }
# Unrepresentable at this precision is corrupt, not small: sprintf %.3f turns
# 1e-300 into "0.000", and a 0 floor divides. !($m < 1e308) is NOT redundant
# with the regex above -- 1e308 is a FINITE double that re-encodes as bare
# 1e+308 and passes it, so without this it becomes a floor no honest run can
# beat. Pinned by the 1e308 rows in bench_test.sh. (No apostrophes: this is
# inside a single-quoted perl -e.)
        if (!($m > 0) || !($m < 1e308) || sprintf("%.3f", $m) eq "0.000") { $invalid++; next; }
        my $rh = (defined($row->{host}) && !ref($row->{host})) ? $row->{host} : "";
        my $ra = (defined($row->{arch}) && !ref($row->{arch})) ? $row->{arch} : "";
        if ($rh ne $host || $ra ne $arch) { $foreign++; next; }
        if ($m <= $sanity) { $low++; next; }
        $valid++;
        push @medians, $m + 0;
      }
      close($fh);
    }

    my $floor = "-";
    if (@medians) {
      my $min = $medians[0];
      for my $v (@medians) { $min = $v if $v < $min; }
      $floor = sprintf("%.3f", $min);
    }
    print "$tag $floor $valid $invalid $foreign $low $mforeign\n";
  '
}

# The reader is a subprocess and its exit status is checked EXPLICITLY: a bare
# `read <<EOF $(history_stats)` swallows it, and a broken interpreter then
# reported FIRST / floor null / exit 0 over a real regression.
reader_err="$TMP/history-read.err"
stats_out=""
stats_rc=0
stats_out="$(history_stats 2>"$reader_err")" || stats_rc=$?
if [ "$stats_rc" -ne 0 ]; then
  reason="$(tr '\n' ' ' < "$reader_err" | cut -c1-200)"
  die 2 "could not read $HISTORY (reader exit $stats_rc): ${reason:-no diagnostic}. Refusing to report a verdict — a reader failure is not a first run"
fi
# Shape check: one line, the sentinel first, integer counts, nothing trailing.
# Garbage on the reader's stdout used to become a raw `awk: division by zero`.
if [ "$(printf '%s' "$stats_out" | wc -l | tr -d ' ')" -ne 0 ]; then
  die 2 "history reader printed more than one line; refusing to parse it as a floor"
fi
read -r stats_tag floor rows_valid rows_invalid rows_foreign rows_low markers_foreign stats_extra <<EOF
$stats_out
EOF
[ "$stats_tag" = "$HISTORY_READER_TAG" ] || die 2 "history reader produced unreadable output (no $HISTORY_READER_TAG sentinel): $(printf '%s' "$stats_out" | cut -c1-120)"
[ -z "$stats_extra" ] || die 2 "history reader produced unreadable output (trailing junk): $(printf '%s' "$stats_out" | cut -c1-120)"
case "${rows_valid}-${rows_invalid}-${rows_foreign}-${rows_low}-${markers_foreign}" in
  *[!0-9-]* | *--* | -* | *-) die 2 "history reader produced unreadable counts: $(printf '%s' "$stats_out" | cut -c1-120)" ;;
esac
if [ "$floor" = "-" ]; then
  floor=""
else
  floor="$(num_pos "$floor" 3)"
  [ -n "$floor" ] || die 2 "history reader returned a floor that is not a positive number: $(printf '%s' "$stats_out" | cut -c1-120)"
fi

# FIRST is legitimate only when there is genuinely nothing to compare against
# (no file, empty, markers only, or every row excluded) -- never when the rows
# exist but all failed to parse.
if [ -z "$floor" ] && [ "$rows_invalid" -gt 0 ]; then
  die 2 "$HISTORY has $rows_invalid unparseable row(s) since the last --accept and no usable row: the dataset is BROKEN, not empty. Repair the file, or start a fresh window with: $0 --accept \"why\""
fi

# BENCH_LOAD_OVERRIDE is read HERE and nowhere else, so bench_test.sh can drive
# the load verdict headlessly. Format: comma-separated, indexed by reading
# (0 = load_before, 1 = load_after, last element repeats); a single value
# behaves as before. Indexed rather than stateful because each call runs in
# its own $(...) subshell, where a walked cursor would be discarded.
load_avg() { # <nth reading: 0 = before the runs, 1 = after>
  local raw="" seq="${BENCH_LOAD_OVERRIDE:-}" i=0
  if [ -n "$seq" ]; then
    while [ "$i" -lt "$1" ]; do
      case "$seq" in *,*) seq="${seq#*,}" ;; esac
      i=$((i + 1))
    done
    raw="${seq%%,*}"
  elif [ -r /proc/loadavg ]; then
    raw="$(awk '{ print $1 }' /proc/loadavg)"
  else
    raw="$(sysctl -n vm.loadavg 2>/dev/null | awk '{ print $2 }')"
  fi
  num "$raw" 2
}

cpus=""
if command -v nproc >/dev/null 2>&1; then
  cpus="$(nproc 2>/dev/null || true)"
else
  cpus="$(sysctl -n hw.ncpu 2>/dev/null || true)"
fi
cpus="$(printf '%s' "$cpus" | tr -cd '0-9')"
# cpus=0 is not a cpu count (load / cpus leaked a raw awk division by zero).
# An unknown count means the load gate is INERT, and that must be said out
# loud: a silent PASS at load 99 is indistinguishable from a real one.
if [ -n "$cpus" ]; then
  [ "$cpus" -gt 0 ] || cpus=""
fi

nvim_raw="$(nvim --version 2>/dev/null || true)"
# awk, not head: head closing the pipe early would SIGPIPE the writer and trip
# `set -o pipefail`.
nvim_ver="$(printf '%s\n' "$nvim_raw" | awk 'NR == 1 { print $2 }' | tr -cd '0-9A-Za-z.+-')"
nvim_ver="${nvim_ver#v}"
nvim_json="null"
[ -n "$nvim_ver" ] && nvim_json="\"$nvim_ver\""

# The lock hash identifies the plugin set: a jump in median is only interesting
# next to which plugins were installed when it was measured. It is provenance
# for a human reading the dataset, NOT a floor filter (see history_stats).
lock_json="null"
if [ -f "$LOCK" ] && command -v shasum >/dev/null 2>&1; then
  lock_hash="$(shasum "$LOCK" | awk '{ print substr($1, 1, 12) }' | tr -cd '0-9a-f')"
  [ -n "$lock_hash" ] && lock_json="\"$lock_hash\""
fi

load_before="$(load_avg 0)"

samples_json=""
ms_kept=()
wall_kept=()
i=0
while [ "$i" -lt "$RUNS" ]; do
  log="$TMP/startup.$i.log"
  wall_file="$TMP/wall.$i"
  # perl times its own child, and writes the delta to a file so nvim's stdout
  # can be dropped wholesale. Bracketing the process from bash instead would
  # fold two perl spawns (~15ms) into every wall_ms.
  # +q makes a headless nvim exit once startup finishes so the log is flushed.
  perl -MTime::HiRes=time -e '
    my $out = shift @ARGV;
    my $t0 = time;
    system @ARGV;
    open my $fh, ">", $out or exit 0;
    printf {$fh} "%.3f\n", (time - $t0) * 1000;
  ' "$wall_file" nvim --headless -u "$INIT" --startuptime "$log" +q >/dev/null 2>&1 || true

  # Guard on the log existing: a crashed nvim may write no file, and the sample
  # then has to become null rather than abort the run.
  ms=""
  if [ -f "$log" ]; then
    ms="$(num_pos "$(awk '/NVIM STARTED/ { t = $1 } END { if (t != "") print t }' "$log")" 3)"
  fi
  wall=""
  if [ -f "$wall_file" ]; then
    wall="$(num_pos "$(tr -d '[:space:]' < "$wall_file")" 3)"
  fi

  if [ "$i" -eq 0 ]; then cold=true; else cold=false; fi
  samples_json="${samples_json:+$samples_json,}{\"run\":$i,\"cold\":$cold,\"ms\":${ms:-null},\"wall_ms\":${wall:-null}}"

  if [ "$i" -gt 0 ]; then
    if [ -n "$ms" ]; then ms_kept+=("$ms"); fi
    if [ -n "$wall" ]; then wall_kept+=("$wall"); fi
  fi
  i=$((i + 1))
done

load_after="$(load_avg 1)"

n=${#ms_kept[@]}
# An environment failure records NOTHING: a row with no samples would be a hole
# in the dataset, not a data point.
[ "$n" -ge 1 ] || die 2 "no valid startuptime samples parsed"

pct() { # <newline-separated values> <percentile>
  printf '%s\n' "$1" | sort -n | awk -v p="$2" '
    { a[NR] = $1 }
    END {
      idx = int((p / 100) * NR + 0.999999)   # nearest-rank (ceil)
      if (idx < 1) idx = 1
      if (idx > NR) idx = NR
      print a[idx]
    }'
}
ms_all="$(printf '%s\n' "${ms_kept[@]}")"
median="$(pct "$ms_all" 50)"
p90="$(pct "$ms_all" 90)"
wall_median=""
if [ "${#wall_kept[@]}" -ge 1 ]; then
  wall_median="$(pct "$(printf '%s\n' "${wall_kept[@]}")" 50)"
fi

# max(load_before, load_after): load that climbed mid-run poisons the reading
# just as much as load that was already there.
load_max=""
if [ -n "$load_before" ] || [ -n "$load_after" ]; then
  load_max="$(awk -v a="${load_before:-0}" -v b="${load_after:-0}" \
    'BEGIN { printf "%.2f\n", (a > b ? a : b) }')"
fi
load_ratio=""
if [ -n "$load_max" ] && [ -n "$cpus" ]; then
  load_ratio="$(awk -v l="$load_max" -v c="$cpus" 'BEGIN { printf "%.3f\n", l / c }')"
fi

verdict="PASS"
delta_pct=""
exit_code=0
if [ -z "$floor" ]; then
  verdict="FIRST"
else
  delta_pct="$(awk -v m="$median" -v f="$floor" 'BEGIN { printf "%.1f\n", (m - f) / f * 100 }')"
  if awk -v m="$median" -v f="$floor" 'BEGIN { exit (m > f * 1.10 ? 0 : 1) }'; then
    verdict="REGRESS"
    exit_code=1
  fi
fi
# Load pressure outranks the PASS/REGRESS call: a wall-clock reading from a busy
# machine is not evidence either way. The row is still recorded — an inflated
# median can never lower the floor, so it cannot poison the dataset.
inconclusive=0
if [ "$verdict" != "FIRST" ] && [ -n "$load_ratio" ] \
   && awk -v r="$load_ratio" 'BEGIN { exit (r > 0.5 ? 0 : 1) }'; then
  verdict="INCONCLUSIVE"
  exit_code=3
  inconclusive=1
fi

row="{\"ts\":\"$ts\",\"commit\":$commit,\"dirty\":$dirty,\"nvim\":$nvim_json,\"lock\":$lock_json"
row="$row,\"host\":\"$host\",\"os\":$os_json,\"arch\":\"$arch\",\"cpus\":${cpus:-null}"
row="$row,\"load_before\":${load_before:-null},\"load_after\":${load_after:-null},\"load_ratio\":${load_ratio:-null}"
row="$row,\"runs_kept\":$n,\"samples\":[$samples_json]"
row="$row,\"median\":$median,\"p90\":$p90,\"wall_median\":${wall_median:-null}"
row="$row,\"floor\":${floor:-null},\"delta_pct\":${delta_pct:-null}"
row="$row,\"rows_valid\":$rows_valid,\"rows_invalid\":$rows_invalid"
row="$row,\"rows_foreign\":$rows_foreign,\"rows_low\":$rows_low"
row="$row,\"markers_foreign\":$markers_foreign"
row="$row,\"verdict\":\"$verdict\"}"
append_row "$row"

if [ "$JSON" -eq 1 ]; then
  printf '%s\n' "$row"
else
  echo "nvim startup (headless, -u init.lua), $n runs kept (cold dropped):"
  printf '  median: %s ms  (--startuptime total)\n' "$median"
  printf '  p90:    %s ms\n' "$p90"
  printf '  wall:   %s ms  (median end-to-end, incl. spawn + deferred setup)\n' "${wall_median:-?}"
  printf '  machine: %s (%s/%s%s)\n' "$host" "${os:-?}" "$arch" "${cpus:+, $cpus cpus}"
  if [ -n "$load_before" ]; then
    printf '  load:   %s before, %s after (1-min avg%s)\n' \
      "$load_before" "${load_after:-?}" "${load_ratio:+, $load_ratio/cpu}"
  fi
  if [ -z "$load_ratio" ]; then
    if [ -z "$cpus" ]; then
      printf '  load check skipped (cpu count unknown) — the 0.5/cpu INCONCLUSIVE gate is INERT for this run\n'
    else
      printf '  load check skipped (no load reading) — the 0.5/cpu INCONCLUSIVE gate is INERT for this run\n'
    fi
  fi
  printf '  history: %s row(s) feed the floor since the last --accept (%s unparseable, %s from another machine, %s below the %sms sanity floor)\n' \
    "$rows_valid" "$rows_invalid" "$rows_foreign" "$rows_low" "$SANITY_MIN_MS"
  if [ "$markers_foreign" -gt 0 ]; then
    printf '  note:   %s floor-reset marker(s) IGNORED (another machine, or no host/arch to attribute them to) — a marker only resets the floor of the machine that wrote it; rerun %s --accept "why" here\n' \
      "$markers_foreign" "$0"
  fi
  if [ -n "$floor" ]; then
    printf '  floor:  %s ms  (min of those %s)  delta %+.1f%%  -> %s\n' \
      "$floor" "$rows_valid" "$delta_pct" "$verdict"
  else
    printf '  floor:  (none yet) -> FIRST, this run seeds %s\n' "$HISTORY"
  fi
  if [ "$inconclusive" -eq 1 ]; then
    printf '  INCONCLUSIVE: load %s on %s cpus is over 0.5/cpu — rerun quieter; the row was still recorded.\n' \
      "$load_max" "$cpus"
  fi
  if [ "$verdict" = "REGRESS" ]; then
    printf '  REGRESS: more than 10%% over the floor. If the slowdown is deliberate: %s --accept "why"\n' "$0"
  fi
fi

exit "$exit_code"
