#!/bin/sh
# Initialise the dependency manager of a project rendered by render.sh: install the dev tools at
# their latest versions (resolved by the package manager, never from memory) and create the lock
# file. Safe on existing projects: it never rewrites a manifest it did not create, and prints what
# to merge by hand instead.
#
# Usage: init-project.sh --lang python|typescript|rust|cpp --dir DIR [--kind lib|app] [--pm PM]
#                        [--name NAME]
set -eu

here=$(CDPATH='' cd -- "$(dirname -- "$0")" && pwd)
fragments=$(CDPATH='' cd -- "$here/../templates/_fragments" && pwd)

die() {
    printf 'init-project.sh: %s\n' "$1" >&2
    exit 1
}
need() {
    command -v "$1" >/dev/null 2>&1 || die "'$1' is not installed; install it and run again"
}
# Replace a literal string in a file (portable alternative to sed -i).
replace() { # FILE FROM TO
    awk -v from="$2" -v to="$3" '
        function rep(s, from, to,    i, out) {
            out = ""
            while ((i = index(s, from)) > 0) {
                out = out substr(s, 1, i - 1) to
                s = substr(s, i + length(from))
            }
            return out s
        }
        { print rep($0, from, to) }' "$1" >"$1.sw-tmp"
    mv "$1.sw-tmp" "$1"
}

lang='' dir='' kind=app pm='' name=''
while [ $# -gt 0 ]; do
    [ $# -ge 2 ] || die "missing value for $1"
    case "$1" in
        --lang) lang=$2 ;;
        --dir) dir=$2 ;;
        --kind) kind=$2 ;;
        --pm) pm=$2 ;;
        --name) name=$2 ;;
        *) die "unknown option $1" ;;
    esac
    shift 2
done
[ -d "$dir" ] || die "--dir must be an existing directory"
cd "$dir"
[ -n "$name" ] || name=$(basename -- "$(pwd)")

case "$lang" in
    python)
        need uv
        if grep -q '{{UV_BUILD_REQ}}' pyproject.toml 2>/dev/null; then
            # Same build-backend bounds `uv init` writes for the installed uv version.
            version=$(uv --version | awk '{ print $2 }')
            major=${version%%.*}
            rest=${version#*.}
            minor=${rest%%.*}
            replace pyproject.toml '{{UV_BUILD_REQ}}' "uv_build>=$version,<$major.$((minor + 1))"
        fi
        uv add --dev ruff mypy pytest pytest-cov pre-commit
        ;;
    typescript)
        pm=${pm:-pnpm}
        need npm
        node_major=$(tr -d ' \r\nv' <.nvmrc 2>/dev/null || true)
        # TypeScript: the newest release typescript-eslint supports (its peer range), so a new
        # TypeScript major that the linter can't load yet is never installed.
        ts_range=$(npm view typescript-eslint peerDependencies.typescript 2>/dev/null || true)
        typescript="typescript${ts_range:+@$ts_range}"
        tools="@types/node${node_major:+@$node_major} vitest @vitest/coverage-v8 eslint @eslint/js typescript-eslint eslint-config-prettier prettier"
        case "$pm" in
            pnpm)
                need pnpm
                npm pkg set "packageManager=pnpm@$(pnpm --version)"
                # shellcheck disable=SC2086 # word splitting of the tool list is intended
                pnpm add --save-dev "$typescript" $tools
                ;;
            npm)
                # shellcheck disable=SC2086
                npm install --save-dev "$typescript" $tools
                ;;
            *) die "unsupported package manager '$pm' for typescript" ;;
        esac
        ;;
    rust)
        need cargo
        if [ ! -f Cargo.toml ]; then
            if [ "$kind" = lib ]; then target=--lib; else target=--bin; fi
            cargo init --vcs none --name "$name" "$target" .
            cat "$fragments/cargo-lints.toml" >>Cargo.toml
        else
            echo "Cargo.toml already exists: merge $fragments/cargo-lints.toml into it by hand if its lints are missing."
        fi
        cargo generate-lockfile
        ;;
    cpp)
        if grep -q '{{VCPKG_BASELINE}}' vcpkg.json 2>/dev/null; then
            need git
            baseline=$(git ls-remote https://github.com/microsoft/vcpkg refs/heads/master | cut -f 1)
            [ -n "$baseline" ] || die "could not read the latest vcpkg commit"
            replace vcpkg.json '{{VCPKG_BASELINE}}' "$baseline"
        fi
        ;;
    *) die "--lang must be python, typescript, rust or cpp" ;;
esac
echo "init-project.sh: $lang project initialised in $(pwd)"
