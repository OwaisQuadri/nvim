#!/usr/bin/env bash
# Headless smoke test for this config.
#
# Boots `nvim --headless -u init.lua` the same way a real session boots, then
# asserts that the pieces this repo wires up actually landed. Every check prints
# one JSON object per line (ndjson) with a fixed key order, so a run is
# greppable, diffable against the previous run, and readable by a tool without
# parsing prose:
#
#   ./test.sh
#   ./test.sh | jq -c 'select(.ok == false)'
#
# Exits non-zero if any check fails, so it works as a pre-merge gate.
#
# The bar for a check: deleting the code it covers must turn it red. Asserting
# that a config table has the right contents does not clear that bar when the
# thing that consumes the table is what's likely to break -- so where a feature
# has an observable effect, drive the effect.
set -uo pipefail
cd "$(cd "$(dirname "$0")" && pwd)" || exit 1

# Every check reports, then the run exits non-zero if any of them failed. An
# early `exit 1` would leave the rest of the suite unreported and break the
# `./test.sh | jq -c 'select(.ok == false)'` workflow the README documents.
failures=0
report() { # name, ok, [detail]
  if [ "$2" = true ]; then
    printf '{"ts":"%s","check":"%s","ok":true}\n' "$(date -u +%Y-%m-%dT%H:%M:%SZ)" "$1"
  else
    failures=$((failures + 1))
    printf '{"ts":"%s","check":"%s","ok":false%s}\n' "$(date -u +%Y-%m-%dT%H:%M:%SZ)" "$1" \
      "${3:+,\"detail\":$(printf '%s' "$3" | head -20 | jq -Rs . 2>/dev/null || echo '"see stderr"')}"
  fi
}

# Before asserting anything about what the config wired up, assert that it
# loaded without complaint. A runtime error in a section none of the checks
# below happen to cover still prints on every single launch, and the checks
# alone would report a clean green over it.
#
# Matched against error signatures rather than "any output at all": a first
# launch legitimately narrates plugin installs and treesitter parser compiles,
# and a gate that goes red on those is a gate people learn to ignore. `Error
# in`/`Error detected` are what catch the ones that don't surface as an `E123:`
# at the top level -- an error thrown inside an autocmd or a deferred callback,
# which is exactly where a config error hides from `+qa`.
#
# A `FileType` pass over the languages this config claims to support is folded
# in for the same reason: several sections do their real work in a FileType
# autocmd, and `+qa` alone never fires one.
startup_probe="$(nvim --headless -u init.lua \
  -c 'lua for _, ft in ipairs { "swift", "dart", "lua", "typescriptreact", "yaml" } do vim.bo.filetype = ft end' \
  +qa 2>&1)"
startup_status=$?
# `setup failed` is in the alternation because this config reports its own
# degraded states through `vim.notify(..., WARN)`, and nvim does NOT prefix a
# WARN with anything the patterns above match — so a debugger that fails to load
# on every single launch would otherwise sail past this gate entirely.
startup_noise="$(printf '%s' "$startup_probe" | grep -E '^E[0-9]+:|^Error in |Error detected|stack traceback|attempt to (index|call|perform|concatenate|compare)|module .* not found|setup failed')"
if [ -n "$startup_noise" ] || [ "$startup_status" -ne 0 ]; then
  report config.loads_without_errors false "${startup_noise:-nvim exited $startup_status with no output}"
else
  report config.loads_without_errors true
fi

# Needs its own process: the Swift debug adapter registers lazily, and the checks
# below open a Swift buffer, which registers it. This covers the other entry
# point -- reaching for a Swift debug key before ever opening a Swift file. The
# generic F-key steps deliberately do NOT do this; they belong to whichever
# adapter a lane already registered, so `<leader>db` is the contract under test.
if nvim --headless -u init.lua -l /dev/stdin >/dev/null 2>&1 <<'PROBE'
vim.o.verbose = 0
-- nvim-dap is no longer even loaded at startup (both lanes defer it to the
-- first Swift/Dart buffer), so asserting on `require('dap')` here would load it
-- and destroy what's under test. Assert the stronger thing: nothing pulled it in.
assert(package.loaded['dap'] == nil, 'nvim-dap was loaded during startup')
vim.fn.maparg('<leader>db', 'n', false, true).callback()
assert(require('dap').configurations.swift ~= nil, 'debug key did not register the adapter')
PROBE
then
  report dap.debug_key_registers_adapter_without_a_swift_buffer true
else
  report dap.debug_key_registers_adapter_without_a_swift_buffer false
fi

# Also needs its own process, and for the same reason: the buffer under test has
# to be the session's FIRST Swift buffer. That is the one the debugger's own
# breakpoint-restoring hook cannot see, because the lazy setup that registers it
# happens during the very BufReadPost it would have to run on. A miss here is
# destructive, not just empty -- the next toggle rewrites the file's saved
# breakpoints from what's in memory, i.e. nothing.
if nvim --headless -u init.lua -l /dev/stdin >/dev/null 2>&1 <<'PROBE'
vim.o.verbose = 0
local root, contents = vim.fn.tempname(), 'struct Saved {\n    let a = 1\n}\n'
vim.fn.mkdir(vim.fs.joinpath(root, '.nvim', 'xcodebuild'), 'p')
-- Breakpoints are keyed by buffer name, and on macOS `/var/...` resolves to
-- `/private/var/...` the moment the buffer opens -- so the fixture has to be
-- written under the resolved path or the key silently never matches.
root = vim.uv.fs_realpath(root)
local file = vim.fs.joinpath(root, 'Saved.swift')
vim.fn.writefile(vim.split(contents, '\n'), file)
vim.fn.writefile({ ('{"%s":[{"line":2}]}'):format(file) }, vim.fs.joinpath(root, '.nvim', 'xcodebuild', 'breakpoints.json'))
vim.cmd.cd(root)
require('xcodebuild').update_cwd()
vim.cmd.edit(file)
-- `get(buf)` answers with `{ [buf] = {...} }`, so it is one entry long whether
-- or not that buffer has any breakpoints. Count the inner list.
local buf = vim.api.nvim_get_current_buf()
assert(#(require('dap.breakpoints').get(buf)[buf] or {}) > 0, 'saved breakpoint not restored on the first Swift buffer')
PROBE
then
  report dap.restores_saved_breakpoints_on_the_first_swift_buffer true
else
  report dap.restores_saved_breakpoints_on_the_first_swift_buffer false
fi

# Its own process too, and for the same reason as the two above: this asserts
# that something is NOT set up yet, so any earlier check that happens to touch a
# Flutter project would make it pass or fail for the wrong reason.
# flutter-tools registers its `:Flutter*` commands on entering a Dart buffer
# rather than at setup, so the mobile lane has to nudge that trigger -- without
# it, every Flutter verb dies with E492 in a project you haven't opened a .dart
# file in yet.
if nvim --headless -u init.lua -l /dev/stdin >/dev/null 2>&1 <<'PROBE'
vim.o.verbose = 0
assert(vim.fn.exists ':FlutterRun' ~= 2, 'Flutter commands registered before any Flutter project was touched')
local root = vim.uv.fs_realpath(vim.fn.tempname()) or vim.fn.tempname()
vim.fn.mkdir(root, 'p')
vim.fn.writefile({ 'name: demo' }, vim.fs.joinpath(root, 'pubspec.yaml'))
vim.cmd.cd(root)
pcall(vim.fn.maparg('<leader>ms', 'n', false, true).callback)
assert(vim.fn.exists ':FlutterRun' == 2, 'the mobile lane did not make the Flutter commands reachable')
assert(vim.fn.exists ':FlutterDevices' == 2, ':FlutterDevices still missing')
PROBE
then
  report flutter.commands_reachable_from_the_mobile_lane true
else
  report flutter.commands_reachable_from_the_mobile_lane false
fi

# This one has to let the REAL `vim.cmd` run, so it can't live in the inline
# block: that block stubs vim.cmd to observe dispatch, which is exactly the
# layer where the bug lives. Ex commands expand `%` to the current file name
# AFTER any shellescape, so a project path containing `%` splices the open
# buffer's name into an already-quoted shell argument -- with a hostile filename
# open, that is arbitrary command execution. The assertion is that the terminal
# is handed the path literally.
if nvim --headless -u init.lua -l /dev/stdin >/dev/null 2>&1 <<'PROBE'
vim.o.verbose = 0
local root = vim.uv.fs_realpath(vim.fn.tempname()) or vim.fn.tempname()
vim.fn.mkdir(root, 'p')
-- an open buffer whose name gets spliced in if `%` is still expanded
vim.fn.writefile({ 'x' }, vim.fs.joinpath(root, 'INJECTED.txt'))
vim.cmd.edit(vim.fs.joinpath(root, 'INJECTED.txt'))
vim.cmd { cmd = 'cd', args = { root }, magic = { file = false } }

-- `<leader>mn` with a project name containing `%`: shellescape quotes it, then
-- the Ex command expands `%` INSIDE those quotes unless magic is off.
vim.ui.select = function(items, _, on_choice) on_choice(items[1]) end
vim.ui.input = function(_, on_confirm) on_confirm 'demo%app' end
vim.fn.maparg('<leader>mn', 'n', false, true).callback()

local terminal
for _, buf in ipairs(vim.api.nvim_list_bufs()) do
  local name = vim.api.nvim_buf_get_name(buf)
  if name:match '^term://' then terminal = name end
end
assert(terminal, 'no terminal was opened')
assert(not terminal:match 'INJECTED', 'the open buffer name was spliced into the command: ' .. terminal)
assert(terminal:match "demo%%app'$", 'the project name was not passed literally: ' .. terminal)
PROBE
then
  report mobile.does_not_expand_ex_magic_into_shell_commands true
else
  report mobile.does_not_expand_ex_magic_into_shell_commands false
fi

# The Lua checks below stub `vim.cmd` to observe WHICH command a mobile verb
# would dispatch. That proves routing, but it mocks away the exact surface a
# missing toolchain breaks -- so this one runs the real dispatch, in its own
# process, with `flutter` genuinely off PATH. That is the state of any machine
# that hasn't installed it, and behaviourally the state of an asdf shim with no
# pinned version (executable, resolves to nothing). Unguarded, flutter-tools
# dies inside executable.lua with a raw E5108 traceback naming none of that.
suite_dir="$PWD"
flutter_absent_probe() { # lhs
  local root
  root="$(mktemp -d)"
  mkdir -p "$root/bin"
  ln -sf "$(command -v nvim)" "$root/bin/nvim"
  printf 'name: demo\n' > "$root/pubspec.yaml"
  ( cd "$root" && env PATH="$root/bin:/usr/bin:/bin" nvim --headless -u "$suite_dir/init.lua" \
      -c "lua local seen; local n = vim.notify; vim.notify = function(m) seen = tostring(m) end; local ok = pcall(vim.fn.maparg('$1', 'n', false, true).callback); vim.notify = n; print((ok and 'OK ' or 'CRASH ') .. tostring(seen))" \
      -c 'qa!' 2>&1 )
  rm -rf "$root"
}

flutter_absent_ok=true
flutter_absent_detail=""
for key in '<leader>mr' '<leader>md' '<leader>ms'; do
  probe_out="$(flutter_absent_probe "$key")"
  # Must not throw, AND must name the real problem rather than failing silently.
  if ! printf '%s' "$probe_out" | grep -q "OK .*not on PATH"; then
    flutter_absent_ok=false
    flutter_absent_detail="$flutter_absent_detail $key:[$(printf '%s' "$probe_out" | tr '\n' ' ' | cut -c1-80)]"
  fi
done
if [ "$flutter_absent_ok" = true ]; then
  report mobile.flutter_verbs_survive_a_missing_sdk true
else
  report mobile.flutter_verbs_survive_a_missing_sdk false "$flutter_absent_detail"
fi

# Its own process, with the host faked to Linux BEFORE init.lua is sourced.
# SECTION 22 (Xcode) never loads on a non-mac, so any lane that still resolves an
# Xcode project there dispatches a command that does not exist -- E492, after
# having already tcd'd you into the package. The upward walk gates this; the
# DOWNWARD monorepo scan is a separate code path and had no gate at all.
if nvim --headless \
  --cmd 'lua local real = vim.uv.os_uname(); vim.uv.os_uname = function() return { sysname = "Linux", machine = "x86_64", release = real.release, version = real.version } end' \
  -u init.lua -l /dev/stdin >/dev/null 2>&1 <<'PROBE'
vim.o.verbose = 0
local root = vim.fn.tempname()
vim.fn.mkdir(vim.fs.joinpath(root, 'pkgs/mylib'), 'p')
-- realpath only AFTER mkdir: on macOS /var is a symlink to /private/var, so
-- resolving a path that doesn't exist yet returns nil and the cwd comparison
-- below then fails for a reason that has nothing to do with the host gate.
root = vim.uv.fs_realpath(root) or root
vim.fn.writefile({ '// swift-tools-version:5.9' }, vim.fs.joinpath(root, 'pkgs/mylib/Package.swift'))
vim.cmd { cmd = 'cd', args = { root }, magic = { file = false } }

local notified
local n = vim.notify
vim.notify = function(m) notified = tostring(m) end
local ok, err = pcall(vim.fn.maparg('<leader>ms', 'n', false, true).callback)

assert(ok, 'mobile lane threw on a non-mac host: ' .. tostring(err))
assert((notified or ''):match 'No mobile project', 'a Swift package was offered on a host where SECTION 22 never loaded: ' .. tostring(notified))
assert(vim.fn.getcwd() == root, 'cwd was moved into an unusable project: ' .. vim.fn.getcwd())

-- The case above only covers stack DETECTION. The doctor is a separate path and
-- the one that actually crashed: a Flutter repo commits its `ios/` folder, so on
-- Linux `<leader>m?` reached a `kind:"xcode"` buildServer.json and shelled out to
-- `md5` -- a BSD-only binary. `vim.system` on a missing binary throws ENOENT
-- straight out of the keymap rather than failing soft.
local flutter_root = vim.fn.tempname()
vim.fn.mkdir(vim.fs.joinpath(flutter_root, 'ios/Runner.xcodeproj'), 'p')
flutter_root = vim.uv.fs_realpath(flutter_root) or flutter_root
vim.fn.writefile({ 'name: demo' }, vim.fs.joinpath(flutter_root, 'pubspec.yaml'))
vim.fn.writefile(
  { '{"kind":"xcode","build_root":"/some/build/root","scheme":"Runner"}' },
  vim.fs.joinpath(flutter_root, 'ios/buildServer.json')
)
vim.cmd { cmd = 'cd', args = { flutter_root }, magic = { file = false } }

notified = nil
local doctor_ok, doctor_err = pcall(vim.fn.maparg('<leader>m?', 'n', false, true).callback)
vim.notify = n

assert(doctor_ok, 'the doctor threw on a non-mac host with a committed ios/: ' .. tostring(doctor_err))
-- Not "didn't mention brew" -- ANY ios/ verdict is wrong here. On a host with no
-- sourcekit-lsp there is no phantom error to report, and on the mac that runs
-- this suite `md5` exists, so a laxer assertion passes even with the gate gone.
assert(
  not (notified or ''):match 'ios/',
  'the doctor produced an ios/ verdict on a host that cannot build or lint Swift: ' .. tostring(notified)
)
PROBE
then
  report mobile.non_mac_host_never_reaches_the_xcode_toolchain true
else
  report mobile.non_mac_host_never_reaches_the_xcode_toolchain false
fi

# Its own process: nvim-dap is loaded lazily and several later checks pull it
# in, so this must run before any of them or it proves nothing. flutter-tools
# decides ONCE, inside `use_debugger_runner()`, whether to use the DAP runner or
# the plain job runner — if nvim-dap isn't loadable at that moment it silently
# falls back to running the app UNDEBUGGED and only notifies. `debugger.enabled`
# stays true either way, which is why a config-table read cannot catch this.
# The regression that motivated it: deferring dap to a `FileType dart` hook,
# which `<leader>mr` never triggers (its nudge is a BufEnter on pubspec.yaml).
if nvim --headless -u init.lua -l /dev/stdin >/dev/null 2>&1 <<'PROBE'
vim.o.verbose = 0
assert(package.loaded['dap'] == nil, 'nvim-dap was already loaded before any mobile verb')
local root = vim.fn.tempname()
vim.fn.mkdir(root, 'p')
root = vim.uv.fs_realpath(root) or root
vim.fn.writefile({ 'name: demo' }, vim.fs.joinpath(root, 'pubspec.yaml'))
vim.cmd { cmd = 'cd', args = { root }, magic = { file = false } }
-- No .dart buffer is ever opened: that is the whole point.
pcall(vim.fn.maparg('<leader>ms', 'n', false, true).callback)
assert(package.loaded['dap'] ~= nil, 'a Flutter verb ran without loading nvim-dap first -- the app would start undebugged')
PROBE
then
  report flutter.verb_loads_the_debugger_before_starting_the_app true
else
  report flutter.verb_loads_the_debugger_before_starting_the_app false
fi

# Its own process, because it stubs xcodebuild.nvim's internals.
# `<leader>mr`/`<leader>mb` on an unconfigured Xcode project must run setup and
# then actually DO the thing. The wizard signals completion by no signal at all:
# every `XcodebuildProjectSettingsUpdated` emitter sits inside `select_testplan`,
# while the fields `is_app_configured()` needs (bundleId/appPath/productName) are
# written afterwards by `update_settings`, which takes no callback and emits
# nothing. So an event-driven implementation walks the whole wizard and then
# silently does nothing on exactly the common case: an app project.
# The stub reproduces that shape -- configured flips to true LATE, with no event.
if nvim --headless -u init.lua -l /dev/stdin >/dev/null 2>&1 <<'PROBE'
vim.o.verbose = 0
local root = vim.fn.tempname()
vim.fn.mkdir(root, 'p')
root = vim.uv.fs_realpath(root) or root
vim.fn.mkdir(vim.fs.joinpath(root, 'App.xcodeproj'), 'p')
vim.cmd { cmd = 'cd', args = { root }, magic = { file = false } }

local config = require 'xcodebuild.project.config'
local actions = require 'xcodebuild.actions'

local configured = false
config.is_configured = function() return configured end
config.settings = config.settings or {}
-- `is_configured()` alone can't say WHICH project it means. Point the recorded
-- project at a DIFFERENT directory, the way it's left after switching projects
-- (the wizard's project picker doesn't clear scheme/destination/bundleId), and
-- the fast path must not treat this project as ready.
config.settings.projectFile = '/somewhere/else/Other.xcodeproj'

-- The wizard: completes asynchronously, emits NOTHING when it finishes.
config.configure_project = function() vim.defer_fn(function() configured = true end, 250) end
actions.configure_project = config.configure_project

local built = 0
actions.build_and_run = function() built = built + 1 end

configured = true -- "configured", but for a different project
vim.fn.maparg('<leader>mr', 'n', false, true).callback()
assert(built == 0, 'built immediately using another project\'s leftover scheme/destination')
configured = false

-- Now the honest case: settings that do belong here, arriving late and silently.
config.settings.projectFile = vim.fs.joinpath(root, 'App.xcodeproj')
vim.fn.maparg('<leader>mr', 'n', false, true).callback()
assert(built == 0, 'built before setup finished')

-- Long enough for the poll to notice, and deliberately silent: no autocmd is
-- ever fired, so anything waiting on the event stays asleep forever.
vim.wait(6000, function() return built > 0 end, 100)
assert(built == 1, 'setup completed but the queued run never fired (waited 6s, no event was ever emitted)')
PROBE
then
  report mobile.xcode_run_resumes_after_setup_without_an_event true
else
  report mobile.xcode_run_resumes_after_setup_without_an_event false
fi

# `md5` lives in /sbin, which is not on every login PATH, and `vim.system` on a
# missing binary throws ENOENT rather than failing soft. Run the doctor with it
# genuinely unreachable: the guard must degrade to "can't verify", never take the
# keymap down. Separate from the non-mac check above, which cannot cover this --
# the host running this suite always has md5.
md5_probe_bin="$(mktemp -d)"
ln -sf "$(command -v nvim)" "$md5_probe_bin/nvim"
if env PATH="$md5_probe_bin:/usr/bin:/bin" nvim --headless -u init.lua -l /dev/stdin >/dev/null 2>&1 <<'PROBE'
vim.o.verbose = 0
assert(vim.fn.executable 'md5' == 0, 'fixture is void: md5 is still reachable on this PATH')
local root = vim.fn.tempname()
vim.fn.mkdir(vim.fs.joinpath(root, 'ios/Runner.xcodeproj'), 'p')
root = vim.uv.fs_realpath(root) or root
vim.fn.writefile({ 'name: demo' }, vim.fs.joinpath(root, 'pubspec.yaml'))
vim.fn.writefile(
  { '{"kind":"xcode","build_root":"/some/build/root","scheme":"Runner"}' },
  vim.fs.joinpath(root, 'ios/buildServer.json')
)
vim.cmd { cmd = 'cd', args = { root }, magic = { file = false } }

local n = vim.notify
vim.notify = function() end
local ok, err = pcall(vim.fn.maparg('<leader>m?', 'n', false, true).callback)
vim.notify = n
assert(ok, 'the doctor threw when md5 was off PATH: ' .. tostring(err))
PROBE
then
  report mobile.doctor_survives_a_missing_md5 true
else
  report mobile.doctor_survives_a_missing_md5 false
fi
rm -rf "$md5_probe_bin"

# A throw inside the poll callback must still stop the timer, and a second press
# must still be able to replace a pending one. Unguarded, the cleanup is skipped,
# the 400ms timer spins for the rest of the session emitting one error per tick,
# and because the same call throws again on the next keypress the
# replace-and-close branch is unreachable -- only restarting nvim recovers it.
if nvim --headless -u init.lua -l /dev/stdin >/dev/null 2>&1 <<'PROBE'
vim.o.verbose = 0
local root = vim.fn.tempname()
vim.fn.mkdir(root, 'p')
root = vim.uv.fs_realpath(root) or root
vim.fn.mkdir(vim.fs.joinpath(root, 'App.xcodeproj'), 'p')
vim.cmd { cmd = 'cd', args = { root }, magic = { file = false } }

local config = require 'xcodebuild.project.config'
local actions = require 'xcodebuild.actions'
actions.configure_project = function() end -- no picker in a headless run

-- Exactly what a settings.json holding `null` produces: `settings` is not a
-- table, so every `is_configured()` raises.
config.is_configured = function() error('settings is a userdata value', 0) end

local n = vim.notify
vim.notify = function() end
local first = pcall(vim.fn.maparg('<leader>mr', 'n', false, true).callback)
vim.wait(1500, function() return false end, 100) -- let the poll tick and fail

-- The contract: the lane is still usable. A stranded timer also strands this.
local second = pcall(vim.fn.maparg('<leader>mr', 'n', false, true).callback)
vim.notify = n
assert(first, 'first press threw out of the keymap')
assert(second, 'the mobile key became unusable after a poll error -- the timer was never stopped')
PROBE
then
  report mobile.poll_stops_itself_when_the_project_state_is_corrupt true
else
  report mobile.poll_stops_itself_when_the_project_state_is_corrupt false
fi

# Needs its own process, for a reason none of the ones above share: this is the
# only check that types. nvim-ts-autotag hooks insert-mode `>` with a
# buffer-local keymap, so the only honest way to cover it is to actually press
# the keys -- asserting the module loaded or that `setup` ran would stay green
# with the feature broken. But `nvim_feedkeys` leaves typeahead that drains
# whenever the event loop next runs, which in the shared block below (25 checks,
# one nvim) is at a moment no check controls: the line under test decayed to
# `> ` and the corruption could just as easily have landed in a neighbour.
# Escaping does not fix that -- folding `<Esc>` into the same feedkeys via
# `nvim_replace_termcodes` was tried and still decayed. Isolation does.
#
# Load-bearing inside the probe, do not tidy: assert IMMEDIATELY after feedkeys,
# with no `stopinsert` and no `vim.wait` following it, because any event-loop
# pumping after the keys is what corrupts the line; and keep the wait on the
# highlighter BEFORE typing, because close_tag() parses the tree synchronously
# and needs the tsx parser already resolved.
if nvim --headless -u init.lua -l /dev/stdin >/dev/null 2>&1 <<'PROBE'
vim.o.verbose = 0
local path = vim.fs.joinpath(vim.fn.tempname(), 'AutoTag.tsx')
vim.fn.mkdir(vim.fs.dirname(path), 'p')
vim.fn.writefile({ 'const a = ' }, path)
vim.cmd.edit(path)
local buf = vim.api.nvim_get_current_buf()
vim.wait(20000, function() return vim.treesitter.highlighter.active[buf] ~= nil end, 100)
vim.api.nvim_feedkeys('A<View>', 'x', false)
local line = vim.api.nvim_get_current_line()
assert(line == 'const a = <View></View>', 'auto-close did not fire, got: ' .. line)
PROBE
then
  report treesitter.nvim_ts_autotag_auto_closes_jsx_tags true
else
  report treesitter.nvim_ts_autotag_auto_closes_jsx_tags false
fi

nvim --headless -u init.lua -l /dev/stdin <<'LUA'
-- `nvim -l` bumps 'verbose' to 1, which makes guess-indent narrate every buffer
-- this script opens straight into the middle of the ndjson stream.
vim.o.verbose = 0

local failures = 0

-- Only a literal `true` passes. `ok and detail ~= false` would let a check that
-- forgets to return anything report green forever.
local function check(name, fn)
  local ok, detail = pcall(fn)
  local passed = ok and detail == true
  if not passed then failures = failures + 1 end
  -- Hand-assembled rather than `vim.json.encode`d: that orders keys by hash, so
  -- two runs with identical outcomes still differ textually on every line.
  local line = ('{"ts":%s,"check":%s,"ok":%s'):format(
    vim.json.encode(os.date '!%Y-%m-%dT%H:%M:%SZ'),
    vim.json.encode(name),
    tostring(passed)
  )
  if not ok then line = line .. ',"detail":' .. vim.json.encode(tostring(detail)) end
  io.stdout:write(line .. '}\n')
end

local commands = vim.api.nvim_get_commands {}
local function has_command(name) return commands[name] ~= nil end

-- `maparg` rather than a scan of `nvim_get_keymap`: the latter reports `<F5>`
-- verbatim but `<leader>x` already expanded to the leader key, so no single
-- normalization of the wanted lhs matches both.
local function has_keymap(mode, lhs) return not vim.tbl_isempty(vim.fn.maparg(lhs, mode, false, true)) end

---Writes `contents` to a scratch file and opens it, the way a user would.
---@return integer buffer
local function open_scratch(name, contents)
  local path = vim.fs.joinpath(vim.fn.tempname(), name)
  vim.fn.mkdir(vim.fs.dirname(path), 'p')
  vim.fn.writefile(vim.split(contents, '\n'), path)
  vim.cmd.edit(path)
  return vim.api.nvim_get_current_buf()
end

-- A Swift file that swiftlint has opinions about (force cast, one-letter names)
-- and swiftformat has opinions about (the space before the colon).
local MESSY_SWIFT = [[
struct Fixture {
    let name : String
    func f(x: Any) -> String {
        return x as! String
    }
}
]]

-- hardtime configures itself on a ~500ms timer, so this waits on the thing that
-- timer actually produces. `package.loaded.hardtime` would be true the instant
-- `require` returned, and stay true with the `setup{}` call deleted.
check('hardtime.enabled_and_toggleable', function()
  vim.wait(3000, function() return require('hardtime').is_plugin_enabled end, 50)
  if not require('hardtime').is_plugin_enabled then return false end
  vim.cmd 'Hardtime toggle' -- what <leader>tH invokes; errors if the command never registered
  return require('hardtime').is_plugin_enabled == false
end)

check('xcodebuild.commands', function() return has_command 'XcodebuildBuild' and has_command 'XcodebuildSetup' and has_command 'XcodebuildPicker' end)
-- Asserts what each key DOES, not merely that the lhs is bound to something --
-- otherwise rebinding the whole namespace to no-ops reads as green.
check('xcodebuild.keymaps', function()
  local wanted = { ['<leader>xb'] = 'XcodebuildBuild', ['<leader>xr'] = 'XcodebuildBuildRun', ['<leader>X'] = 'XcodebuildPicker', ['<leader>xs'] = 'XcodebuildSetup' }
  for lhs, command in pairs(wanted) do
    local rhs = vim.fn.maparg(lhs, 'n', false, true).rhs
    if rhs ~= ('<cmd>%s<CR>'):format(command) then return false end
  end
  return has_keymap('v', '<leader>xt') and has_keymap('n', '<leader>xL')
end)
check('xcodebuild.reloads_on_cd', function()
  for _, autocmd in ipairs(vim.api.nvim_get_autocmds { event = 'DirChanged' }) do
    if (autocmd.group_name or ''):match 'xcodebuild' then return true end
  end
  return false
end)
-- Settings live at the project root, so opening a file in a subdirectory has to
-- keep resolving to the same place -- otherwise every nested file is its own
-- half-configured "project".
check('xcodebuild.finds_config_from_a_subdirectory', function()
  local root = vim.fn.tempname()
  vim.fn.mkdir(vim.fs.joinpath(root, 'Sources', 'Deep'), 'p')
  vim.fn.mkdir(vim.fs.joinpath(root, '.nvim', 'xcodebuild'), 'p')
  vim.fn.writefile({ '{"scheme":"Fixture"}' }, vim.fs.joinpath(root, '.nvim', 'xcodebuild', 'settings.json'))
  vim.cmd.cd(vim.fs.joinpath(root, 'Sources', 'Deep'))
  require('xcodebuild').update_cwd()
  return require('xcodebuild.project.config').settings.scheme == 'Fixture'
end)

-- The Swift debug adapter registers lazily, so this also covers the trigger:
-- nothing but opening a Swift buffer should be needed to make debugging work.
-- `unregistered` is sampled at load rather than inside the check, so adding
-- another Swift-buffer check above this one can't turn it red on its own.
local dap_unregistered_at_startup = package.loaded['dap'] == nil
check('dap.swift_configuration_registers_on_swift_buffer', function()
  if not dap_unregistered_at_startup then return false end -- must NOT be paid up front
  open_scratch('Trigger.swift', MESSY_SWIFT)
  local configurations = require('dap').configurations.swift
  return configurations ~= nil and #configurations > 0
end)
-- Each debug key must reach a real function, not just be bound. A no-op lambda
-- or a typo'd action name would otherwise read as green until pressed.
check('dap.keymaps', function()
  for _, lhs in ipairs { '<leader>dd', '<leader>db', '<leader>dx', '<F5>', '<F10>' } do
    if type(vim.fn.maparg(lhs, 'n', false, true).callback) ~= 'function' then return false end
  end
  local integration = require 'xcodebuild.integrations.dap'
  for _, action in ipairs { 'build_and_debug', 'debug_without_build', 'debug_tests', 'debug_class_tests', 'toggle_breakpoint', 'toggle_message_breakpoint', 'terminate_session' } do
    if type(integration[action]) ~= 'function' then return false end
  end
  return true
end)

-- Drive the formatter and the linter for real. Asserting `formatters_by_ft` and
-- `linters_by_ft` alone would stay green with the autocmd that fires them, or
-- the tool itself, entirely gone.
check('conform.swiftformat_reformats_a_swift_buffer', function()
  local buf = open_scratch('Format.swift', MESSY_SWIFT)
  local before = vim.api.nvim_buf_get_lines(buf, 0, -1, false)
  require('conform').format { bufnr = buf, async = false, timeout_ms = 15000 }
  local after = vim.api.nvim_buf_get_lines(buf, 0, -1, false)
  return not vim.deep_equal(before, after) and vim.tbl_contains(after, '    let name: String')
end)
check('lint.swiftlint_reports_on_opening_a_swift_file', function()
  local buf = open_scratch('Lint.swift', MESSY_SWIFT) -- opening alone must trigger it
  vim.wait(20000, function() return #vim.diagnostic.get(buf) > 0 end, 100)
  for _, diagnostic in ipairs(vim.diagnostic.get(buf)) do
    if diagnostic.source == 'swiftlint' then return true end
  end
  return false
end)

-- [[ The mobile lane ]]
-- Detection decides which stack every `<leader>m*` key talks to, so it gets
-- driven against real directory shapes rather than asserted about. The nested
-- case is the one that matters: an Expo app has an `ios/` folder with an
-- xcodeproj in it, and reading that as an Xcode project would send every verb
-- to the wrong stack.
local function scaffold(files)
  local root = vim.uv.fs_realpath(vim.fn.tempname()) or vim.fn.tempname()
  vim.fn.mkdir(root, 'p')
  root = vim.uv.fs_realpath(root)
  for name, contents in pairs(files) do
    local path = vim.fs.joinpath(root, name)
    vim.fn.mkdir(vim.fs.dirname(path), 'p')
    vim.fn.writefile(vim.split(contents, '\n'), path)
  end
  return root
end

---Presses a mobile key in `root` and reports what it dispatched to, by standing
---in for `vim.cmd` and recording the Ex command or shell command it reached for.
---Covers both call shapes the lane uses: `vim.cmd 'FlutterDevices'` and the
---table form `vim.cmd { cmd = 'terminal', args = { 'npm install' } }`.
---@return {command: string|nil, notified: string|nil, error: string|nil}
local function dispatch_target(lhs, root)
  vim.cmd 'silent! %bwipeout!'
  -- Magic off here for the same reason the lane itself does it: a fixture path
  -- containing `%` would otherwise blow up the harness before the code under
  -- test ever runs.
  vim.cmd { cmd = 'cd', args = { root }, magic = { file = false } }
  local seen = {}
  local notify, cmd = vim.notify, vim.cmd
  vim.notify = function(message) seen.notified = message end
  ---@diagnostic disable-next-line: duplicate-set-field
  vim.cmd = setmetatable({}, {
    __call = function(_, c)
      if type(c) == 'string' then
        seen.command = c
      elseif type(c) == 'table' and c.cmd == 'terminal' then
        seen.command = (c.args or {})[1]
      elseif type(c) == 'table' and c.cmd == 'tcd' then
        -- Must really run: entering the project directory IS the behaviour
        -- under test for a monorepo. The lane calls `tcd` in TABLE form (it
        -- needs `magic = { file = false }` so a `%` in a path isn't expanded),
        -- so swallowing table-form commands wholesale would silently stop
        -- testing the thing and turn both `enters_*` checks green-for-nothing.
        cmd(c)
      end
    end,
    __index = function(_, key)
      -- `tcd` is the one command that must really happen: getting into the
      -- project directory IS the behaviour under test for a monorepo, and a
      -- stub that swallows it would let the regression back in silently.
      if key == 'tcd' then return function(...) return cmd[key](...) end end
      return function(...)
        if key == 'terminal' then seen.command = select(1, ...) end
      end
    end,
  })
  local ok, err = pcall(vim.fn.maparg(lhs, 'n', false, true).callback)
  vim.notify, vim.cmd = notify, cmd
  if not ok then seen.error = tostring(err) end
  return seen
end

check('mobile.detects_each_stack', function()
  local flutter = scaffold { ['pubspec.yaml'] = 'name: demo\n' }
  local expo = scaffold { ['package.json'] = '{"dependencies":{"expo":"~52.0.0"}}' }
  local none = scaffold { ['README.md'] = 'nothing to see' }

  -- react-native is a real arm of `detect()` and of three dispatch tables, so
  -- it belongs here: without it, deleting the whole branch stayed green.
  -- Dispatched from a SUBDIRECTORY so only the upward `detect()` walk can find
  -- it. From the root, `find_projects_below` has its own react-native arm and
  -- would rescue a deleted `detect()` branch, leaving this green for nothing.
  local rn_root = scaffold {
    ['package.json'] = '{"dependencies":{"react-native":"0.76.0"}}',
    ['src/components/Button.tsx'] = '',
  }
  local bare_rn = vim.fs.joinpath(rn_root, 'src/components')
  return dispatch_target('<leader>ms', flutter).command == 'FlutterDevices'
    and dispatch_target('<leader>ms', expo).command == 'npm install'
    and dispatch_target('<leader>mr', bare_rn).command == 'npx react-native start'
    and (dispatch_target('<leader>ms', none).notified or ''):match 'No mobile project here' ~= nil
end)

-- Detection is nearest-marker-wins, and both directions have to hold. An `ios/`
-- xcodeproj inside an Expo app must not drag you to Xcode, and an app in a JS
-- monorepo must not be dragged up to the monorepo's package.json. A fixed
-- "Expo beats Xcode" rule passes the first and fails the second.
check('mobile.nearest_project_marker_wins', function()
  local expo_with_native = scaffold {
    ['package.json'] = '{"dependencies":{"expo":"~52.0.0"}}',
    ['ios/App.xcodeproj/project.pbxproj'] = '',
  }
  local native_in_monorepo = scaffold {
    ['package.json'] = '{"dependencies":{"expo":"~52.0.0"}}',
    ['native/App.xcodeproj/project.pbxproj'] = '',
  }
  -- from the Expo root, the nested ios/ project must not win
  if dispatch_target('<leader>ms', expo_with_native).command ~= 'npm install' then return false end
  -- from inside the native app, the monorepo's package.json must not win
  local from_native = dispatch_target('<leader>ms', vim.fs.joinpath(native_in_monorepo, 'native'))
  return from_native.command == 'XcodebuildSetup'
end)

-- Opening nvim in a subdirectory of an app has to resolve to the app, not to
-- "no mobile project here" -- for every stack, not just the ones whose marker
-- is a plain file.
-- A monorepo root is not "inside" any of its apps, so walking up finds nothing
-- there. Searching down is what makes `<leader>m*` work from the top without
-- cd-ing first, and the generated native shells (a Flutter app's `ios/` and
-- `macos/`, its `.dart_tool/flutter_gen/pubspec.yaml`) must not show up as
-- extra projects alongside the one real one.
check('mobile.finds_a_project_below_in_a_monorepo', function()
  local root = scaffold {
    ['README.md'] = 'monorepo',
    ['apps/mobile/pubspec.yaml'] = 'name: demo\n',
    ['apps/mobile/ios/Runner.xcodeproj/project.pbxproj'] = '',
    ['apps/mobile/macos/Runner.xcworkspace/contents'] = '',
    ['apps/mobile/.dart_tool/flutter_gen/pubspec.yaml'] = 'name: generated\n',
    ['apps/server/main.py'] = 'pass',
  }
  local seen = dispatch_target('<leader>ms', root)
  -- exactly one project, so no picker: it should act immediately
  return seen.command == 'FlutterDevices' and not seen.error
end)

-- Finding the project is only half of it. Every one of these tools re-derives
-- its own root from wherever Neovim is sitting, so dispatching from a monorepo
-- root without moving there first gets you `flutter run` in the repo root and
-- "No pubspec.yaml file found" -- which is exactly what happened in practice.
check('mobile.enters_the_project_directory_it_picked', function()
  local root = scaffold {
    ['.git/HEAD'] = 'ref: refs/heads/main\n', -- the decoy: a repo root above the app
    ['apps/mobile/pubspec.yaml'] = 'name: demo\n',
  }
  local app = vim.fs.joinpath(root, 'apps/mobile')
  local seen = dispatch_target('<leader>ms', root)
  return seen.command == 'FlutterDevices' and vim.fn.getcwd() == app
end)

-- The same guarantee from the other direction: found by walking UP, from a
-- subfolder of the app. Both paths have to land you in the project root, or the
-- tools disagree about which project this is depending on how you got here.
check('mobile.enters_the_project_root_from_a_subdirectory', function()
  local root = scaffold {
    ['pubspec.yaml'] = 'name: demo\n',
    ['lib/src/widgets/button.dart'] = '',
  }
  local seen = dispatch_target('<leader>ms', vim.fs.joinpath(root, 'lib/src/widgets'))
  return seen.command == 'FlutterDevices' and vim.fn.getcwd() == root
end)

-- A bare `flutter run` with a phone, a Mac and Chrome all attached exits(1)
-- with "More than one device connected". So the first run has to ASK (via
-- `:FlutterDevices`, which runs on select), the next has to reuse that answer
-- without asking, and `:MobileForget` has to put it back to asking.
check('mobile.flutter_asks_for_a_device_once_then_reuses_it', function()
  local root = scaffold { ['pubspec.yaml'] = 'name: demo\n' }

  local first = dispatch_target('<leader>mr', root)

  -- Stand in for flutter-tools starting the app on the device you picked.
  require('flutter-tools.commands').current_device = function()
    return { id = 'DEVICE-ID', name = 'Owais (mobile)', platform = 'ios' }
  end
  vim.api.nvim_exec_autocmds('User', { pattern = 'FlutterToolsAppStarted' })

  local second = dispatch_target('<leader>mr', root)
  vim.cmd 'MobileForget'
  local third = dispatch_target('<leader>mr', root)

  -- NOT quoted: flutter-tools splits the ex-command args on spaces and spawns
  -- via libuv with no shell, so shell quoting would land inside the device id
  -- and match nothing. This assertion previously pinned the quoted (broken)
  -- form as the contract.
  return first.command == 'FlutterDevices'
    and second.command == 'FlutterRun -d DEVICE-ID'
    and (second.notified or ''):match 'Owais %(mobile%)' ~= nil -- says which one
    and third.command == 'FlutterDevices'
end)

-- Opening a Flutter app's `ios/Runner/AppDelegate.swift` gets you a red
-- "No such module 'Flutter'" from sourcekit-lsp on a file that compiles fine --
-- it has no framework search paths without a buildServer.json. The Xcode doctor
-- names that, but `<leader>m?` in a Flutter project never reaches the Xcode
-- doctor, so the Flutter one has to check the native halves itself.
check('mobile.doctor_flags_a_flutter_native_shell_without_compile_flags', function()
  local root = scaffold {
    ['pubspec.yaml'] = 'name: demo\n',
    -- ios: bound to the build server, flags not harvested yet. `kind` is absent,
    -- i.e. the "manual" layout, so the flags would live at `ios/.compile`.
    ['ios/Runner.xcodeproj/project.pbxproj'] = '',
    ['ios/buildServer.json'] = '{"build_root":"x","scheme":"Runner"}',
    -- macos: same layout, flags present. Genuinely healthy.
    ['macos/Runner.xcodeproj/project.pbxproj'] = '',
    ['macos/buildServer.json'] = '{"build_root":"y","scheme":"Runner"}',
    ['macos/.compile'] = '[]',
  }
  local notified = dispatch_target('<leader>m?', root).notified or ''
  -- Bound-but-unharvested must read as broken, and must say WHICH of the two
  -- steps is missing -- "run config" and "run a clean build" are different jobs.
  return notified:match 'ios/ build server is bound but has no flags yet' ~= nil
    and notified:match 'ok macos/ has compile flags' ~= nil
end)

-- The other storage layout, and the one the recommended `xcode-build-server
-- config` actually produces: kind="xcode" keeps flags in a hashed file under
-- ~/Library/Caches, never in `.compile`. Checking `.compile` unconditionally
-- reports a perfectly working project as broken.
check('mobile.doctor_understands_the_xcode_kind_flag_cache', function()
  local build_root = '/fixture/build/root'
  local root = scaffold {
    ['pubspec.yaml'] = 'name: demo\n',
    ['ios/Runner.xcodeproj/project.pbxproj'] = '',
    ['ios/buildServer.json'] = ('{"kind":"xcode","build_root":"%s","scheme":"Runner"}'):format(build_root),
  }
  local ios = vim.fs.joinpath(root, 'ios')

  -- The expected path is computed by the REAL build server, not by restating
  -- the formula under test. An earlier version of this check built its fixture
  -- with the same (wrong) formula init.lua used, so the two agreed with each
  -- other and disagreed with reality -- it could not have failed no matter how
  -- wrong the implementation was. Ask python for the answer the server itself
  -- would compute, and skip rather than fake it if that isn't available.
  local server = '/opt/homebrew/Cellar/xcode-build-server/1.3.0/libexec/server.py'
  if not vim.uv.fs_stat(server) then return true end
  local script = ([[
import hashlib, os
root_path = os.path.abspath(%q)
cache = os.path.join(os.path.expanduser("~/Library/Caches/xcode-build-server"), root_path.replace("/", "-"))
h = hashlib.md5(%q.encode("utf-8")).hexdigest()
print(os.path.join(cache, "-".join(["compile_file", "Runner", h])))
]]):format(ios, build_root)
  local out = vim.system({ 'python3', '-c', script }):wait()
  local flags = vim.trim(out.stdout or '')
  if flags == '' then return false end

  -- Sandboxed HOME: unsandboxed, this wrote into the user's real
  -- ~/Library/Caches, two concurrent suite runs clobbered each other's fixture,
  -- and an error before the delete leaked a directory there.
  local real_home = vim.env.HOME
  local fake_home = vim.fn.tempname()
  vim.fn.mkdir(fake_home, 'p')
  flags = flags:gsub(vim.pesc(real_home), fake_home, 1)
  vim.env.HOME = fake_home

  vim.fn.mkdir(vim.fs.dirname(flags), 'p')
  vim.fn.writefile({ '[]' }, flags)
  local ok_run, notified = pcall(function() return dispatch_target('<leader>m?', root).notified or '' end)
  vim.env.HOME = real_home
  vim.fn.delete(fake_home, 'rf')
  if not ok_run then return false end

  -- No `.compile` anywhere in the fixture, yet this project is healthy.
  return (notified or ''):match 'ok ios/ has compile flags' ~= nil
end)

-- The JUNK prune list had no real coverage: the fixture that claimed to pin it
-- put `.dart_tool/flutter_gen/pubspec.yaml` five levels down, where SEARCH_DEPTH
-- already excluded it, so emptying JUNK stayed green. Keep the generated pubspec
-- INSIDE the depth bound so only the prune list can exclude it.
check('mobile.ignores_generated_projects_inside_the_depth_bound', function()
  local root = scaffold {
    ['apps/app/pubspec.yaml'] = 'name: real\n',
    ['apps/app/.dart_tool/pubspec.yaml'] = 'name: generated\n', -- depth 4, prune-only
    ['node_modules/pkg/package.json'] = '{"dependencies":{"expo":"1.0.0"}}',
  }
  -- Exactly one project must be found, so it dispatches without a picker.
  local seen = dispatch_target('<leader>ms', root)
  return seen.command == 'FlutterDevices' and not seen.error
end)

-- `:tcd` expands its argument, so a project path containing `%` (or a backtick,
-- which executes) must not be handed to it raw. The existing ex-magic check
-- can't catch this: it cds INTO the fixture first, so `enter()` takes its
-- getcwd-equals-root early return and never calls tcd at all. Dispatching from
-- the parent is what forces the directory move.
check('mobile.enters_a_project_whose_path_contains_ex_magic', function()
  local root = scaffold {
    ['app%pct/pubspec.yaml'] = 'name: demo\n',
    ['README.md'] = 'monorepo',
  }
  local app = vim.fs.joinpath(root, 'app%pct')
  local seen = dispatch_target('<leader>ms', root)
  return seen.command == 'FlutterDevices' and vim.fn.getcwd() == app and not seen.error
end)

-- A remembered project can vanish underneath the memo: a branch switch, a moved
-- folder, `flutter clean`. Without dropping the entry on a failed enter, every
-- mobile key stays wedged on the dead path and any new project below is
-- unreachable until `:MobileForget`.
check('mobile.forgets_a_remembered_project_that_disappeared', function()
  local root = scaffold {
    ['README.md'] = 'monorepo',
    ['apps/gone/pubspec.yaml'] = 'name: doomed\n',
  }
  -- First press remembers apps/gone and moves there.
  if dispatch_target('<leader>ms', root).command ~= 'FlutterDevices' then return false end

  vim.fn.delete(vim.fs.joinpath(root, 'apps/gone'), 'rf')
  vim.fn.mkdir(vim.fs.joinpath(root, 'apps/other'), 'p')
  vim.fn.writefile({ 'name: replacement' }, vim.fs.joinpath(root, 'apps/other/pubspec.yaml'))

  -- Second press: the memo is stale, so it must say so rather than throw.
  local stale = dispatch_target('<leader>ms', root)
  if stale.error or not (stale.notified or ''):match 'pick another' then return false end

  -- Third press must recover on its own, without :MobileForget. The cwd is the
  -- half that matters: a wedged lane ALSO dispatches `:FlutterDevices`, just
  -- from the monorepo root, which is the "No pubspec.yaml file found" failure
  -- `enter` exists to prevent. Asserting only the command cannot tell them apart.
  local third = dispatch_target('<leader>ms', root)
  return third.command == 'FlutterDevices' and vim.fn.getcwd() == vim.fs.joinpath(root, 'apps/other')
end)

-- Build WITHOUT launching. The distinction is sharpest on Xcode (a real
-- build-only action) and needs a target platform on Flutter, which is taken from
-- the device already chosen rather than asked for again.
-- Parsed from REAL `flutter devices` text by flutter-tools' own parser, not a
-- hand-written device shape. The hand-written one hid two bugs at once: the
-- platform column is arch-suffixed (`darwin-arm64`, not `darwin`), and `macos`
-- is the device ID in the previous column, so an exact-match table matched
-- almost nothing while looking correct.
check('mobile.build_targets_match_real_flutter_device_platforms', function()
  local devices = require 'flutter-tools.devices'
  local lines = {
    'macOS (desktop)             • macos                                • darwin-arm64   • macOS 27.0 26A5378j darwin-arm64',
    'Chrome (web)                • chrome                               • web-javascript • Google Chrome 150.0',
    'Owais (mobile)              • 00008140-000445EA02FA801C            • ios            • iOS 27.0 24A5380h',
    'Pixel 7 (mobile)            • 1B2C3D4E                             • android-arm64  • Android 15 (API 35)',
  }
  local expected = { ['darwin-arm64'] = 'flutter build macos', ['web-javascript'] = 'flutter build web', ios = 'flutter build ios', ['android-arm64'] = 'flutter build apk' }

  for _, line in ipairs(lines) do
    local device = devices.parse(line, 1) -- 1 == DEVICE in flutter-tools
    if not (device and device.platform) then return false end

    local root = scaffold { ['pubspec.yaml'] = 'name: demo\n' }
    require('flutter-tools.commands').current_device = function() return device end
    vim.cmd { cmd = 'cd', args = { root }, magic = { file = false } }
    vim.api.nvim_exec_autocmds('User', { pattern = 'FlutterToolsAppStarted' })

    if dispatch_target('<leader>mb', root).command ~= expected[device.platform] then return false end
  end
  return true
end)

-- The reuse path hands flutter-tools `FlutterRun -d <id>`, which it parses back
-- into literally `{ id = ... }`. If the memo takes that at face value it erases
-- the platform and name learned from the picker, so the SECOND build loses its
-- target and the run notice degrades to a raw UUID.
check('mobile.a_reuse_run_does_not_erase_the_remembered_device', function()
  local root = scaffold { ['pubspec.yaml'] = 'name: demo\n' }
  local commands = require 'flutter-tools.commands'

  commands.current_device = function() return { id = 'UDID-1', name = 'Owais (mobile)', platform = 'ios' } end
  vim.cmd { cmd = 'cd', args = { root }, magic = { file = false } }
  vim.api.nvim_exec_autocmds('User', { pattern = 'FlutterToolsAppStarted' })

  -- Exactly what the plugin reports back on a `-d <id>` re-entry.
  commands.current_device = function() return { id = 'UDID-1' } end
  vim.api.nvim_exec_autocmds('User', { pattern = 'FlutterToolsAppStarted' })

  local build = dispatch_target('<leader>mb', root)
  local run = dispatch_target('<leader>mr', root)
  return build.command == 'flutter build ios' and (run.notified or ''):match 'Owais' ~= nil
end)

-- The picker is async, so the chosen root can vanish while it is open -- a
-- branch switch, a moved folder. Remembering it before the move is known to
-- have worked poisons the memo with a root already known to be dead, and burns
-- the next press re-discovering that.
check('mobile.does_not_remember_a_project_that_died_in_the_picker', function()
  local root = scaffold {
    ['README.md'] = 'monorepo',
    ['apps/a/pubspec.yaml'] = 'name: a\n',
    ['apps/b/package.json'] = '{"dependencies":{"expo":"~52.0.0"}}',
  }
  local doomed = vim.fs.joinpath(root, 'apps/a')

  local select = vim.ui.select
  ---@diagnostic disable-next-line: duplicate-set-field
  vim.ui.select = function(items, _, on_choice)
    for _, project in ipairs(items) do
      if project.root == doomed then
        vim.fn.delete(doomed, 'rf') -- vanishes while the picker is open
        return on_choice(project)
      end
    end
    on_choice(nil)
  end
  local first = dispatch_target('<leader>ms', root)

  -- Second press must re-discover from scratch. Only `apps/b` still exists, so
  -- it resolves straight to it -- no picker, and crucially no attempt to reuse
  -- the dead root. A poisoned memo instead reports `apps/a` is gone, again.
  local second = dispatch_target('<leader>ms', root)
  vim.ui.select = select

  return not first.error
    and second.command == 'npm install'
    and not (second.notified or ''):match 'is gone'
    and vim.fn.getcwd() == vim.fs.joinpath(root, 'apps/b')
end)

check('mobile.builds_without_launching', function()
  local flutter_root = scaffold { ['pubspec.yaml'] = 'name: demo\n' }
  local expo_root = scaffold { ['package.json'] = '{"dependencies":{"expo":"~52.0.0"}}' }

  -- With a remembered iOS device, the target is inferred, so no picker.
  require('flutter-tools.commands').current_device = function()
    return { id = 'DEV', name = 'Phone', platform = 'ios' }
  end
  vim.cmd { cmd = 'cd', args = { flutter_root }, magic = { file = false } }
  vim.api.nvim_exec_autocmds('User', { pattern = 'FlutterToolsAppStarted' })

  local flutter_build = dispatch_target('<leader>mb', flutter_root)
  local expo_build = dispatch_target('<leader>mb', expo_root)

  -- An unknown platform must fall through to the picker rather than silently
  -- doing nothing. Drive `vim.ui.select` by answering it.
  local android_root = scaffold { ['pubspec.yaml'] = 'name: demo\n' }
  require('flutter-tools.commands').current_device = function()
    return { id = 'DEV2', name = 'Pixel', platform = 'android' }
  end
  vim.cmd { cmd = 'cd', args = { android_root }, magic = { file = false } }
  vim.api.nvim_exec_autocmds('User', { pattern = 'FlutterToolsAppStarted' })
  local android_build = dispatch_target('<leader>mb', android_root)

  local unknown_root = scaffold { ['pubspec.yaml'] = 'name: demo\n' }
  require('flutter-tools.commands').current_device = function()
    return { id = 'DEV3', name = 'Fridge', platform = 'tizen-arm' }
  end
  vim.cmd { cmd = 'cd', args = { unknown_root }, magic = { file = false } }
  vim.api.nvim_exec_autocmds('User', { pattern = 'FlutterToolsAppStarted' })

  local asked
  local select = vim.ui.select
  ---@diagnostic disable-next-line: duplicate-set-field
  vim.ui.select = function(items, _, on_choice)
    asked = items
    on_choice('macos')
  end
  local fallback = dispatch_target('<leader>mb', unknown_root)
  vim.ui.select = select

  return flutter_build.command == 'flutter build ios'
    and android_build.command == 'flutter build apk' -- a second row of the table
    and expo_build.command == 'npx expo export'
    and asked ~= nil -- the picker really opened
    and fallback.command == 'flutter build macos'
    and not flutter_build.error
end)

check('mobile.detects_from_a_subdirectory', function()
  local flutter = scaffold { ['pubspec.yaml'] = 'name: demo\n', ['lib/src/keep'] = '' }
  local xcode = scaffold { ['App.xcodeproj/project.pbxproj'] = '', ['App/Sources/keep'] = '' }
  return dispatch_target('<leader>ms', vim.fs.joinpath(flutter, 'lib', 'src')).command == 'FlutterDevices'
    and dispatch_target('<leader>ms', vim.fs.joinpath(xcode, 'App', 'Sources')).command == 'XcodebuildSetup'
end)

-- A manifest we can't read identifies nothing; it must not make every mobile
-- key throw. Both shapes bit this before: no read permission, and a directory
-- that happens to be named package.json.
check('mobile.survives_an_unreadable_manifest', function()
  local unreadable = scaffold { ['package.json'] = '{"dependencies":{"expo":"~52.0.0"}}' }
  vim.fn.setfperm(vim.fs.joinpath(unreadable, 'package.json'), '---------')
  local a_directory = scaffold { ['package.json/inside'] = '' }
  for _, root in ipairs { unreadable, a_directory } do
    local seen = dispatch_target('<leader>ms', root)
    if seen.error or not (seen.notified or ''):match 'No mobile project here' then return false end
  end
  return true
end)

check('mobile.detects_a_project_whose_path_contains_ex_magic', function()
  local root = scaffold { ['package.json'] = '{"dependencies":{"expo":"~52.0.0"}}' }
  local awkward = vim.fs.joinpath(root, 'a%b#c')
  vim.fn.mkdir(awkward, 'p')
  vim.fn.writefile({ '{"dependencies":{"expo":"~52.0.0"}}' }, vim.fs.joinpath(awkward, 'package.json'))
  local seen = dispatch_target('<leader>ms', awkward)
  return seen.command == 'npm install' and not seen.error
end)

-- The question this whole lane exists to answer: when a stack is installed but
-- unusable, say which part is missing instead of failing at the build.
check('mobile.doctor_names_an_unpinned_flutter_sdk', function()
  if vim.fn.executable 'asdf' == 0 then return true end -- nothing to detect without a version manager
  local root = scaffold { ['pubspec.yaml'] = 'name: demo\n' } -- deliberately no .tool-versions
  local seen = dispatch_target('<leader>m?', root)
  return (seen.notified or ''):match 'asdf has no flutter version set' ~= nil
end)

check('mobile.keymaps', function()
  for _, lhs in ipairs { '<leader>mr', '<leader>mb', '<leader>mR', '<leader>md', '<leader>mt', '<leader>ms', '<leader>m?', '<leader>mn' } do
    if type(vim.fn.maparg(lhs, 'n', false, true).callback) ~= 'function' then return false end
  end
  return true
end)

-- Asserting `formatters_by_ft.dart` alone stays green while the formatter is
-- unrunnable -- which it is whenever the Dart SDK isn't resolvable, the exact
-- failure `<leader>m?` exists to report. `get_formatter_info().available` is
-- conform's own answer to "could I actually run this right now".
check('conform.dart_formatter_is_available', function()
  if not vim.deep_equal(require('conform').formatters_by_ft.dart, { 'dart_format' }) then return false end
  local info = require('conform').get_formatter_info('dart_format', vim.api.nvim_get_current_buf())
  if info.available then return true end
  -- A resolvable `dart` is environment, not config: say so rather than
  -- reporting a config defect, and rather than reporting a silent pass.
  error(('dart_format is configured but not runnable: %s. `<leader>m?` in a Flutter project explains this.'):format(info.available_msg or 'unknown'))
end)
-- `is_enabled`, not `vim.lsp.config.eslint ~= nil`: nvim-lspconfig ships a
-- default config for every server it knows about, so the latter is true whether
-- or not this config ever asked for eslint.
check('lsp.eslint_enabled', function() return vim.lsp.is_enabled 'eslint' end)

-- flutter-tools populates `dap.configurations.dart` immediately BEFORE calling
-- `register_configurations`, so the widely-copied snippet for that hook (reset
-- the table, then load launch.json) deletes the configuration it was about to
-- run and every `:FlutterRun` dies with "No launch configuration for DAP found".
-- Reading the plugin's resolved config rather than our literal table, because
-- what matters is what flutter-tools ended up holding.
check('flutter.debugger_does_not_clear_its_own_dap_configuration', function()
  local debugger = require('flutter-tools.config').debugger
  if not (debugger.enabled == true and debugger.register_configurations == nil) then return false end

  -- Whether the debugger actually ENGAGES is asserted in its own process
  -- (`flutter.verb_loads_the_debugger_before_starting_the_app`) -- by the time
  -- this check runs, an earlier Swift check has already loaded nvim-dap, so a
  -- `package.loaded['dap']` assertion here would be true no matter what.
  return true
end)

-- Highlighting, rather than `get_installed('parsers')`: the installed list is
-- disk state, so it stays true on this machine even if the parser is dropped
-- from the config. Driving the buffer at least proves the parser resolves and
-- attaches. (It still can't fail on a machine where the parser is already
-- installed by something else -- there is no accessor for "what did the config
-- ask for", so that gap is real and known.)
local function highlights(filename, contents)
  local path = vim.fs.joinpath(vim.fn.tempname(), filename)
  vim.fn.mkdir(vim.fs.dirname(path), 'p')
  vim.fn.writefile(vim.split(contents, '\n'), path)
  vim.cmd.edit(path)
  local buf = vim.api.nvim_get_current_buf()
  vim.wait(20000, function() return vim.treesitter.highlighter.active[buf] ~= nil end, 100)
  return vim.treesitter.highlighter.active[buf] ~= nil
end

check('treesitter.highlights_swift', function() return highlights('Fixture.swift', MESSY_SWIFT) end)
check('treesitter.highlights_dart', function() return highlights('fixture.dart', 'void main() {\n  var x = 1;\n}\n') end)
check('lsp.sourcekit_attaches_to_a_swift_buffer', function()
  local buf = open_scratch('Lsp.swift', MESSY_SWIFT)
  vim.wait(30000, function() return #vim.lsp.get_clients { bufnr = buf } > 0 end, 200)
  return vim.tbl_contains(vim.tbl_map(function(c) return c.name end, vim.lsp.get_clients { bufnr = buf }), 'sourcekit')
end)

os.exit(failures == 0 and 0 or 1)
LUA
inline_status=$?
[ "$inline_status" -eq 0 ] || failures=$((failures + 1))

exit $([ "$failures" -eq 0 ] && echo 0 || echo 1)
