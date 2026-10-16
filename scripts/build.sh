#!/usr/bin/env bash
# build.sh - Build the Docker image and run smoke tests
set -u

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$ROOT" || exit 1

IMAGE="${IMAGE_NAME:-devops-tool}"
PASS=0
FAIL=0

pass() { echo "PASS: $1"; PASS=$((PASS+1)); }
fail() { echo "FAIL: $1"; FAIL=$((FAIL+1)); }

echo "== Building image: $IMAGE =="
if ! docker build -t "$IMAGE" .; then
    echo "Docker build failed" >&2
    exit 1
fi

smoke_test() {
    local name="$1" expected="$2"
    shift 2
    docker run --rm "$IMAGE" "$@" >/dev/null 2>&1
    local rc=$?
    if [[ $rc -eq $expected ]]; then
        pass "$name (exit $rc)"
    else
        fail "$name (expected exit $expected, got $rc)"
    fi
}

echo
echo "== Smoke tests =="
smoke_test "help exits 0"                 0 help
smoke_test "system-info exits 0"          0 system-info
smoke_test "invalid command exits 2"      2 invalid-command
smoke_test "non-numeric port exits 2"     2 check-port localhost abc

echo
echo "Passed: $PASS  Failed: $FAIL"
[[ $FAIL -eq 0 ]]
