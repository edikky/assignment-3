#!/usr/bin/env bash
# lint.sh - Check required files exist and run bash -n on all scripts
set -u

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$ROOT" || exit 1

status=0

required=(
    README.md
    app/app.sh
    scripts/lint.sh
    scripts/build.sh
    tests/test.sh
    Dockerfile
    compose.yaml
    .dockerignore
    .github/workflows/ci.yml
)

echo "== Checking required files =="
for f in "${required[@]}"; do
    if [[ -f "$f" ]]; then
        echo "OK:      $f"
    else
        echo "MISSING: $f" >&2
        status=1
    fi
done

echo
echo "== Checking Bash syntax (bash -n) =="
for f in app/*.sh scripts/*.sh tests/*.sh; do
    [[ -f "$f" ]] || continue
    if bash -n "$f"; then
        echo "OK:           $f"
    else
        echo "SYNTAX ERROR: $f" >&2
        status=1
    fi
done

echo
echo "== ShellCheck (optional extra) =="
if command -v shellcheck >/dev/null 2>&1; then
    if shellcheck app/*.sh scripts/*.sh tests/*.sh; then
        echo "ShellCheck: no issues"
    else
        echo "ShellCheck: warnings found (not blocking)"
    fi
else
    echo "ShellCheck not installed, skipping"
fi

echo
if [[ $status -eq 0 ]]; then
    echo "Lint passed"
else
    echo "Lint FAILED" >&2
fi
exit $status