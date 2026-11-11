#!/bin/sh
# Tests for skills/setup-repo/scripts (aged-version.sh, init-project.sh version checks).
# Usage: sh tests/scripts/run.sh   (POSIX sh; on Windows run from Git Bash)
#
# Offline tests put stub `gh`, `pnpm`, `npm` and `cargo` commands first on PATH. Live tests query
# the GitHub API at a fixed past date, so their answers never change; they need an authenticated
# `gh` (GH_TOKEN in CI) and are skipped locally without one.
set -u

top=$(CDPATH='' cd -- "$(dirname -- "$0")/../.." && pwd)
aged="$top/skills/setup-repo/scripts/aged-version.sh"

work=$(mktemp -d 2>/dev/null || mktemp -d -t swscripts)
trap 'rm -rf "$work"' EXIT INT TERM
real_path=$PATH

passed=0
failed=0
skipped=0

ok() {
    passed=$((passed + 1))
    printf 'ok   %s\n' "$1"
}

not_ok() {
    failed=$((failed + 1))
    printf 'FAIL %s\n     %s\n' "$1" "$2"
}

# Run a command, capturing stdout+stderr in $out and the exit code in $rc.
run() {
    out=$("$@" 2>&1)
    rc=$?
}

expect() { # NAME EXPECTED_RC PATTERN  (after `run`)
    if [ "$rc" -ne "$2" ]; then
        not_ok "$1" "exit $rc, expected $2; output: $out"
    elif ! printf '%s' "$out" | grep -q -- "$3"; then
        not_ok "$1" "output does not match '$3': $out"
    else
        ok "$1"
    fi
}

# Stub commands: STUB_<NAME>_OUT is printed, STUB_<NAME>_RC is the exit code.
mkdir -p "$work/bin"
for cmd in gh pnpm npm cargo; do
    upper=$(printf '%s' "$cmd" | tr '[:lower:]' '[:upper:]')
    cat >"$work/bin/$cmd" <<EOF
#!/bin/sh
printf '%s\n' "\$*" >>"$work/$cmd.calls"
[ -n "\${STUB_${upper}_OUT:-}" ] && printf '%s\n' "\$STUB_${upper}_OUT"
exit "\${STUB_${upper}_RC:-0}"
EOF
    chmod +x "$work/bin/$cmd"
done
stub_path="$work/bin:$real_path"

# --- aged-version.sh, offline -------------------------------------------------------------

run sh "$aged"
expect "aged-version: no repository prints usage" 1 "usage: aged-version.sh"
run sh "$aged" just
expect "aged-version: repository without owner is rejected" 1 "must be OWNER/REPO"
run sh "$aged" 'casey/just;rm'
expect "aged-version: unsafe characters are rejected" 1 "must be OWNER/REPO"
run sh "$aged" --days two casey/just
expect "aged-version: --days must be a number" 1 "whole number"
run sh "$aged" --prefix 'v"' casey/just
expect "aged-version: unsafe prefix is rejected" 1 "may only contain"
run sh "$aged" --frobnicate casey/just
expect "aged-version: unknown option is rejected" 1 "unknown option"
run env SW_NOW=yesterday sh "$aged" casey/just
expect "aged-version: SW_NOW must be epoch seconds" 1 "epoch seconds"

run env PATH="$stub_path" STUB_GH_OUT='2026-01-02T00:00:00Z v1.2.0
2026-03-01T00:00:00Z v1.10.0
2026-02-01T00:00:00Z v1.9.0' sh "$aged" owner/repo
expect "aged-version: newest by publish date wins, leading v is dropped" 0 "^1\.10\.0$"

run env PATH="$stub_path" STUB_GH_RC=1 sh "$aged" owner/repo
expect "aged-version: failing gh exits non-zero and names the repository" 1 "owner/repo: could not list releases"

rm -f "$work/gh.calls"
run env PATH="$stub_path" sh "$aged" --prefix v24. owner/repo
expect "aged-version: no eligible release exits non-zero" 1 "owner/repo: no release with a tag starting with 'v24.' at least 14 days old"
if grep -q -- '--paginate' "$work/gh.calls" 2>/dev/null; then
    ok "aged-version: pages through older releases when the first page has none"
else
    not_ok "aged-version: pages through older releases when the first page has none" "calls: $(cat "$work/gh.calls" 2>/dev/null)"
fi

run env PATH="$stub_path" STUB_GH_OUT=0123456789abcdef sh "$aged" --commit master owner/repo
expect "aged-version: --commit prints the commit" 0 "^0123456789abcdef$"

# --- aged-version.sh, live at a fixed date ------------------------------------------------

# 2026-10-01T00:00:00Z: the cutoff is 2026-09-17. Expected values were checked by hand against
# each repository's release list.
fixed_now=1790812800
if gh auth status >/dev/null 2>&1; then
    live() { # NAME EXPECTED ARGS...
        _name=$1 _expected=$2
        shift 2
        run env SW_NOW=$fixed_now sh "$aged" "$@"
        expect "$_name" 0 "^$_expected\$"
    }
    live "aged-version (live): single release line (casey/just)" 1.58.0 casey/just
    live "aged-version (live): --prefix keeps one major (nodejs/node v24)" 24.21.0 --prefix v24. nodejs/node
    live "aged-version (live): maintenance line of an older major (pnpm v10)" 10.34.5 --prefix v10. pnpm/pnpm
    live "aged-version (live): --commit (microsoft/vcpkg master)" a97c98d785fc0b1710bc711acf47767b756e6b7c --commit master microsoft/vcpkg
    run env SW_NOW=$fixed_now sh "$aged" --prefix v1. --days 30000 casey/just
    expect "aged-version (live): nothing old enough exits non-zero" 1 "casey/just: no release"
elif [ -n "${CI:-}" ]; then
    not_ok "aged-version (live)" "gh is not authenticated in CI: set GH_TOKEN for this job"
else
    skipped=$((skipped + 1))
    printf 'skip aged-version (live): gh is not authenticated\n'
fi

printf '\n%s passed, %s failed, %s skipped\n' "$passed" "$failed" "$skipped"
[ "$failed" -eq 0 ]
