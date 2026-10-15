#!/usr/bin/env bash
# test.sh - Tests for app.sh
set -u

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
APP="$ROOT/app/app.sh"

PASS=0
FAIL=0

pass() { echo "PASS: $1"; PASS=$((PASS+1)); }
fail() { echo "FAIL: $1"; FAIL=$((FAIL+1)); }

# assert_exit <name> <expected-exit-code> <command...>
assert_exit() {
    local name="$1" expected="$2"
    shift 2
    "$@" >/dev/null 2>&1
    local rc=$?
    if [[ $rc -eq $expected ]]; then
        pass "$name (exit $rc)"
    else
        fail "$name (expected exit $expected, got $rc)"
    fi
}

# assert_output <name> <pattern> <command...>
assert_output() {
    local name="$1" pattern="$2"
    shift 2
    local out
    out=$("$@" 2>&1)
    if echo "$out" | grep -qi "$pattern"; then
        pass "$name"
    else
        fail "$name (output missing '$pattern')"
    fi
}

echo "Running tests for app.sh"
echo

# 1-2: help
assert_exit   "help exits 0"                      0 "$APP" help
assert_output "help prints usage"                 "usage" "$APP" help

# 3-4: system-info
assert_exit   "system-info exits 0"               0 "$APP" system-info
assert_output "system-info shows kernel version"  "kernel" "$APP" system-info

# 5-6: invalid commands
assert_exit   "invalid command exits 2"           2 "$APP" not-a-command
assert_exit   "no command exits 2"                2 "$APP"

# 7: missing host
assert_exit   "check-host without host exits 2"   2 "$APP" check-host

# 8: valid host
assert_exit   "check-host localhost exits 0"      0 "$APP" check-host localhost

# 9: missing port
assert_exit   "check-port without port exits 2"   2 "$APP" check-port localhost

# 10-12: bad ports
assert_exit   "non-numeric port exits 2"          2 "$APP" check-port localhost abc
assert_exit   "port 0 exits 2"                    2 "$APP" check-port localhost 0
assert_exit   "port 65536 exits 2"                2 "$APP" check-port localhost 65536

echo
echo "Passed: $PASS  Failed: $FAIL"
[[ $FAIL -eq 0 ]]
