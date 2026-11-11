#!/bin/sh
# Smoke test for the setup-repo templates: render a project the way setup-repo does, initialise
# its dependency manager, and run its full `just check` (lint, analysis, build, unit and
# integration tests).
#
# Usage: sh tests/templates/smoke.sh <python|typescript|rust|cpp> <lib|app> [package-manager]
# Env:   JUST       just command (default: just; e.g. "uvx --exclude-newer '14 days' --from rust-just just")
#        SMOKE_PYTHON  Python version for python projects (default: 3.13)
#        KEEP=1     keep the generated project and print its path
set -eu

lang=${1:?usage: smoke.sh <lang> <lib|app> [pm]}
kind=${2:?usage: smoke.sh <lang> <lib|app> [pm]}
pm=${3:-}
just_cmd=${JUST:-just}

top=$(CDPATH='' cd -- "$(dirname -- "$0")/../.." && pwd)
scripts="$top/skills/setup-repo/scripts"
work=$(mktemp -d 2>/dev/null || mktemp -d -t swsmoke)
if [ "${KEEP:-}" = 1 ]; then
    trap 'echo "kept: $work/demo-project"' EXIT
else
    trap 'rm -rf "$work"' EXIT
fi
dest="$work/demo-project"

set -- --lang "$lang" --kind "$kind" --dest "$dest" --name demo-project \
    --description "Smoke-test project rendered by the sw plugin." --license "MIT"
[ -n "$pm" ] && set -- "$@" --pm "$pm"
case "$lang" in
    python) set -- "$@" --python-version "${SMOKE_PYTHON:-3.13}" ;;
    typescript) set -- "$@" --node-version "$(node -p 'process.versions.node.split(".")[0]')" ;;
esac

echo "== render ($lang, $kind${pm:+, $pm})"
sh "$scripts/render.sh" "$@"

cd "$dest"
git -c init.defaultBranch=main init -q
git switch -q -c feature/smoke-test

echo "== init-project"
sh "$scripts/init-project.sh" --lang "$lang" --dir "$dest" --kind "$kind" ${pm:+--pm "$pm"} --name demo-project

echo "== unresolved placeholders"
if grep -rIl --exclude-dir=.git --exclude-dir=node_modules --exclude-dir=.venv --exclude-dir=target \
    -e '{{[A-Z_]*}}' -e 'sw:include' -e 'sw:if' . ; then
    echo "FAIL: the files above still contain template markers" >&2
    exit 1
fi

echo "== 14-day dependency rule"
fail() {
    echo "FAIL: $1" >&2
    exit 1
}
has() { # FILE TEXT
    grep -qF -- "$2" "$1" 2>/dev/null || fail "$1 does not contain: $2"
}
semver='[0-9][0-9]*\.[0-9][0-9]*\.[0-9][0-9]*'
# Anchored, so `just-version:` doesn't count as setup-uv's `version:`.
grep -qE '^[[:space:]]+version: "[0-9]+\.[0-9]+\.[0-9]+"' .github/workflows/ci.yml ||
    fail "CI does not pin uv to an exact version"
grep -q "just-version: \"$semver\"" .github/workflows/ci.yml || fail "CI does not pin just to an exact version"
[ "$lang" = python ] || has justfile 'uvx --exclude-newer "14 days" pre-commit'
# Sessions without `just` installed must find the fallback (end-to-end trial, 2026-11-10).
has AGENTS.md 'uvx --exclude-newer "14 days" --from rust-just just <recipe>'
ecosystems=$(grep -c 'package-ecosystem:' .github/dependabot.yml)
cooldowns=$(grep -c 'default-days: 14' .github/dependabot.yml)
[ "$ecosystems" -eq "$cooldowns" ] ||
    fail "only $cooldowns of $ecosystems Dependabot ecosystems have a 14-day cooldown"
has .github/dependabot.yml 'package-ecosystem: pre-commit'
[ "$lang" != cpp ] || has .github/dependabot.yml 'package-ecosystem: vcpkg'
if grep -rnE 'uses: [^ ]+@v[0-9]+( |$)' .github/workflows; then
    fail "the actions above float on a major version tag; pin an exact release at least 14 days old"
fi
case "$lang" in
    python)
        has pyproject.toml 'exclude-newer = "14 days"'
        has uv.lock 'exclude-newer-span = "P14D"'
        ;;
    typescript)
        grep -q "^$semver\$" .nvmrc || fail ".nvmrc does not hold an exact Node version"
        case "${pm:-pnpm}" in
            pnpm)
                has pnpm-workspace.yaml 'minimumReleaseAge: 20160'
                grep -q "\"packageManager\": \"pnpm@$semver\"" package.json || fail "packageManager does not pin pnpm"
                ;;
            npm) has .npmrc 'min-release-age=14' ;;
        esac
        ;;
    rust)
        has .cargo/config.toml 'global-min-publish-age = "14 days"'
        grep -q "^channel = \"$semver\"" rust-toolchain.toml || fail "rust-toolchain.toml does not pin a Rust release"
        ;;
    cpp)
        grep -q '"builtin-baseline": "[0-9a-f]\{40\}"' vcpkg.json || fail "vcpkg.json has no baseline commit"
        ;;
esac

if [ "$lang" = cpp ] && [ -z "${VCPKG_ROOT:-}" ]; then
    echo "== vcpkg at the manifest baseline (as the generated CI does)"
    baseline=$(sed -n 's/.*"builtin-baseline": *"\([0-9a-f]*\)".*/\1/p' vcpkg.json)
    git init --quiet "$work/vcpkg"
    git -C "$work/vcpkg" fetch --quiet --depth 1 https://github.com/microsoft/vcpkg "$baseline"
    git -C "$work/vcpkg" checkout --quiet FETCH_HEAD
    "$work/vcpkg/bootstrap-vcpkg.sh" -disableMetrics
    VCPKG_ROOT="$work/vcpkg"
    export VCPKG_ROOT
fi

# Formatting depends on the project name's length, so setup-repo formats once after rendering.
git add -A
echo "== just fmt"
# shellcheck disable=SC2086 # JUST may be a multi-word command
$just_cmd fmt || true
git add -A

echo "== just check"
# shellcheck disable=SC2086 # JUST may be a multi-word command
$just_cmd check
echo "== OK: $lang $kind${pm:+ ($pm)}"
