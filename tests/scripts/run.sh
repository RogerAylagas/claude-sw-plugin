#!/bin/sh
# Tests for skills/setup-repo/scripts (aged-version.sh, init-project.sh version checks) and for
# the changelog layout of both cliff.toml files.
# Usage: sh tests/scripts/run.sh   (POSIX sh; on Windows run from Git Bash)
#
# Offline tests put stub `gh`, `pnpm`, `npm` and `cargo` commands first on PATH. Live tests query
# the GitHub API at a fixed past date, so their answers never change; they need an authenticated
# `gh` (GH_TOKEN in CI) and are skipped locally without one. The changelog tests run git-cliff
# with `uvx` and are skipped locally without it.
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
for cmd in gh pnpm npm cargo rustup uv; do
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

# --- init-project.sh: tool versions and pins, offline -------------------------------------

init="$top/skills/setup-repo/scripts/init-project.sh"
project() { # NAME -> empty project directory
    mkdir -p "$work/$1"
    printf '%s' "$work/$1"
}
calls() { # COMMAND -> its recorded calls, then forget them
    cat "$work/$1.calls" 2>/dev/null
    rm -f "$work/$1.calls"
}
refute() { # NAME PATTERN  (after `run`): exit 0 and output must not match
    if [ "$rc" -ne 0 ]; then
        not_ok "$1" "exit $rc; output: $out"
    elif printf '%s' "$out" | grep -q -- "$2"; then
        not_ok "$1" "output matches '$2': $out"
    else
        ok "$1"
    fi
}
rm -f "$work"/*.calls

dir=$(project pnpm-old)
run env PATH="$stub_path" STUB_PNPM_OUT=10.15.0 sh "$init" --lang typescript --pm pnpm --dir "$dir"
expect "init-project: pnpm older than 10.16 stops before installing" 1 "pnpm 10.15.0 ignores minimumReleaseAge"
case "$(calls pnpm)" in
    *add*) not_ok "init-project: pnpm older than 10.16 installs nothing" "pnpm add was called" ;;
    *) ok "init-project: pnpm older than 10.16 installs nothing" ;;
esac

dir=$(project npm-old)
run env PATH="$stub_path" STUB_NPM_OUT=11.9.0 sh "$init" --lang typescript --pm npm --dir "$dir"
expect "init-project: npm older than 11.10 stops before installing" 1 "npm 11.9.0 ignores min-release-age"

dir=$(project pnpm-pin)
printf '24\n' >"$dir/.nvmrc"
calls gh >/dev/null
calls npm >/dev/null
run env PATH="$stub_path" STUB_PNPM_OUT=10.16.0 STUB_GH_OUT='2026-01-01T00:00:00Z v10.20.0' \
    sh "$init" --lang typescript --pm pnpm --dir "$dir"
expect "init-project: pnpm 10.16 is accepted" 0 "typescript project initialised"
gh_calls=$(calls gh)
case "$gh_calls" in
    *'startswith("v10.")'*) ok "init-project: pnpm is pinned within the installed major" ;;
    *) not_ok "init-project: pnpm is pinned within the installed major" "gh calls: $gh_calls" ;;
esac
case "$gh_calls" in
    *'startswith("v24.")'*'nodejs/node'* | *'nodejs/node'*'startswith("v24.")'*)
        ok "init-project: Node is pinned within the .nvmrc major" ;;
    *) not_ok "init-project: Node is pinned within the .nvmrc major" "gh calls: $gh_calls" ;;
esac
case "$(calls npm)" in
    *'pkg set packageManager=pnpm@10.20.0'*) ok "init-project: packageManager names the aged pnpm release" ;;
    *) not_ok "init-project: packageManager names the aged pnpm release" "npm was not asked to set packageManager=pnpm@10.20.0" ;;
esac
if [ "$(cat "$dir/.nvmrc")" = 10.20.0 ]; then
    ok "init-project: a major-only .nvmrc becomes the aged exact version"
else
    not_ok "init-project: a major-only .nvmrc becomes the aged exact version" ".nvmrc: $(cat "$dir/.nvmrc")"
fi

dir=$(project uv-old)
run env PATH="$stub_path" STUB_UV_OUT='uv 0.9.16 (abc123 2025-12-01)' sh "$init" --lang python --dir "$dir"
expect "init-project: uv older than 0.9.17 stops before installing" 1 "uv 0.9.16 can't read exclude-newer"

dir=$(project rust-old)
printf '[toolchain]\nchannel = "{{RUST_VERSION}}"\n' >"$dir/rust-toolchain.toml"
run env PATH="$stub_path" STUB_GH_OUT='2026-10-16T00:00:00Z 1.99.1' STUB_CARGO_OUT='cargo 1.99.1 (abc123 2026-10-16)' \
    sh "$init" --lang rust --dir "$dir" --name demo
expect "init-project: cargo older than 1.100 gets a warning" 0 "cargo 1.99.1 ignores global-min-publish-age"
if grep -q 'channel = "1.99.1"' "$dir/rust-toolchain.toml"; then
    ok "init-project: rust-toolchain.toml is pinned to the aged release"
else
    not_ok "init-project: rust-toolchain.toml is pinned to the aged release" "$(cat "$dir/rust-toolchain.toml")"
fi

dir=$(project rust-new)
run env PATH="$stub_path" STUB_GH_OUT='2026-11-26T00:00:00Z 1.100.0' STUB_CARGO_OUT='cargo 1.100.0 (def456 2026-11-12)' \
    sh "$init" --lang rust --dir "$dir" --name demo
refute "init-project: cargo 1.100 gets no warning" "ignores global-min-publish-age"

dir=$(project cpp)
printf '{ "builtin-baseline": "{{VCPKG_BASELINE}}" }\n' >"$dir/vcpkg.json"
run env PATH="$stub_path" STUB_GH_OUT=0123456789abcdef sh "$init" --lang cpp --dir "$dir"
if [ "$rc" -eq 0 ] && grep -q '"builtin-baseline": "0123456789abcdef"' "$dir/vcpkg.json"; then
    ok "init-project: the vcpkg baseline is the aged commit"
else
    not_ok "init-project: the vcpkg baseline is the aged commit" "exit $rc; $(cat "$dir/vcpkg.json"); $out"
fi

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

# --- cliff.toml: changelog layout (this repository's and the setup template's) -------------

# git-cliff must write one header, a blank line before every release heading and one newline at
# the end (pre-commit's end-of-file fixer rejects more), for a new changelog and when the
# release flow prepends a release to an existing one.
changelog_layout() { # NAME FILE
    _bad=$(awk '
        /^# Changelog$/ { headers++ }
        /^## \[/ { releases++; if (prev != "") print "no blank line before line " NR ": " $0 }
        { prev = $0 }
        END {
            if (headers != 1) print headers + 0 " \"# Changelog\" headers, expected 1"
            if (releases != 2) print releases + 0 " releases, expected 2"
            if (prev == "") print "blank line at the end of the file"
        }' "$2")
    [ -n "$(tail -c 1 "$2")" ] && _bad="$_bad no newline at the end of the file"
    if [ -n "$_bad" ]; then
        not_ok "$1" "$_bad"
    else
        ok "$1"
    fi
}
if command -v uvx >/dev/null 2>&1; then
    repo=$(project changelog)
    g() {
        git -C "$repo" -c init.defaultBranch=main -c user.name=test -c user.email=test@example.invalid \
            -c core.hooksPath="$work/no-hooks" "$@"
    }
    if ! { g init -q && g commit -q --allow-empty -m "feat: first feature" && g tag v0.1.0 &&
        g commit -q --allow-empty -m "fix: first fix"; }; then
        not_ok "changelog: test repository" "git failed"
    fi
    for config in "$top/cliff.toml" "$top/skills/setup-repo/templates/common/cliff.toml"; do
        name=${config#"$top/"}
        cliff() { # ARGS... (in the test repository, with this config)
            (cd "$repo" && uvx --exclude-newer "14 days" git-cliff --config "$config" "$@") \
                >"$work/cliff.log" 2>&1 || {
                not_ok "$name: git-cliff $*" "$(cat "$work/cliff.log")"
                return 1
            }
        }
        rm -f "$repo/CHANGELOG.md"
        cliff --tag v0.2.0 --output CHANGELOG.md &&
            changelog_layout "$name: new changelog" "$repo/CHANGELOG.md"
        rm -f "$repo/CHANGELOG.md"
        cliff --latest --output CHANGELOG.md && cliff --unreleased --tag v0.2.0 --prepend CHANGELOG.md &&
            changelog_layout "$name: release prepended to a changelog" "$repo/CHANGELOG.md"
    done
elif [ -n "${CI:-}" ]; then
    not_ok "changelog" "uvx is not installed in CI: add astral-sh/setup-uv to this job"
else
    skipped=$((skipped + 1))
    printf 'skip changelog: uvx is not installed\n'
fi

printf '\n%s passed, %s failed, %s skipped\n' "$passed" "$failed" "$skipped"
[ "$failed" -eq 0 ]
