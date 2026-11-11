#!/bin/sh
# Initialise the dependency manager of a project rendered by render.sh, under the 14-day
# dependency rule (docs/adr/0002-dependency-cooldown.md in the sw plugin):
#   - dev tools are installed through the package manager, whose own setting (rendered into the
#     project) never picks a release younger than 14 days, and the lock file is created;
#   - toolchains (uv, just, Node, pnpm, Rust, the vcpkg baseline) are pinned to the newest
#     release at least 14 days old, found with aged-version.sh. Versions never come from memory.
# Safe on existing projects: it never rewrites a manifest it did not create, and prints what to
# merge by hand instead.
#
# Usage: init-project.sh --lang python|typescript|rust|cpp --dir DIR [--kind lib|app] [--pm PM]
#                        [--name NAME]
# Needs an authenticated GitHub CLI (gh) to look up release dates.
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
# True if any of the files exists and contains the literal text.
contains() { # TEXT FILE...
    _text=$1
    shift
    grep -qsF -- "$_text" "$@"
}
# True if dotted version A >= B. Only the leading numeric fields count ("1.99.1-beta" = 1.99.1).
version_at_least() { # A B
    awk -v a="$1" -v b="$2" 'BEGIN {
        sub(/[^0-9.].*/, "", a); sub(/[^0-9.].*/, "", b)
        na = split(a, x, "."); nb = split(b, y, ".")
        for (i = 1; i <= (na > nb ? na : nb); i++) {
            if (x[i] + 0 > y[i] + 0) exit 0
            if (x[i] + 0 < y[i] + 0) exit 1
        }
        exit 0
    }'
}
# Newest release (or commit) at least 14 days old; aged-version.sh explains any failure.
aged() {
    sh "$here/aged-version.sh" "$@"
}
# Pin a toolchain placeholder in every workflow that still contains it.
pin_workflows() { # PLACEHOLDER VALUE
    for _f in .github/workflows/*.yml; do
        if contains "$1" "$_f"; then
            replace "$_f" "$1" "$2"
        fi
    done
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

# 1. The tools that will install dependencies must enforce the rule. pnpm and npm silently
#    ignore settings they don't know, so check their versions before anything is installed.
case "$lang" in
    python) need uv ;;
    typescript)
        pm=${pm:-pnpm}
        need npm
        case "$pm" in
            pnpm)
                need pnpm
                v=$(pnpm --version)
                version_at_least "$v" 10.16 ||
                    die "pnpm $v ignores minimumReleaseAge (the 14-day rule); install pnpm 10.16 or newer and run again"
                ;;
            npm)
                v=$(npm --version)
                version_at_least "$v" 11.10 ||
                    die "npm $v ignores min-release-age (the 14-day rule); install npm 11.10 or newer and run again"
                ;;
            *) die "unsupported package manager '$pm' for typescript" ;;
        esac
        ;;
    rust) need cargo ;;
    cpp) ;;
    *) die "--lang must be python, typescript, rust or cpp" ;;
esac
need gh

# 2. Toolchains every generated CI workflow installs.
uv_version=''
if contains '{{UV_VERSION}}' .github/workflows/*.yml || contains '{{UV_BUILD_REQ}}' pyproject.toml; then
    uv_version=$(aged astral-sh/uv) || die "could not pin uv"
    pin_workflows '{{UV_VERSION}}' "$uv_version"
fi
if contains '{{JUST_VERSION}}' .github/workflows/*.yml; then
    just_version=$(aged casey/just) || die "could not pin just"
    pin_workflows '{{JUST_VERSION}}' "$just_version"
fi

# 3. The language's dependency manager.
case "$lang" in
    python)
        if contains '{{UV_BUILD_REQ}}' pyproject.toml; then
            # Same build-backend bounds `uv init` writes, for the pinned uv release.
            major=${uv_version%%.*}
            rest=${uv_version#*.}
            minor=${rest%%.*}
            replace pyproject.toml '{{UV_BUILD_REQ}}' "uv_build>=$uv_version,<$major.$((minor + 1))"
        fi
        uv add --dev ruff mypy pytest pytest-cov pre-commit
        ;;
    typescript)
        nvmrc=$(tr -d ' \r\nv' <.nvmrc 2>/dev/null || true)
        node_major=${nvmrc%%.*}
        case "$nvmrc" in
            '' | *.*) ;; # no .nvmrc, or already an exact version: leave it alone
            *)
                node_version=$(aged --prefix "v$node_major." nodejs/node) || die "could not pin Node $node_major"
                printf '%s\n' "$node_version" >.nvmrc
                ;;
        esac
        # TypeScript: the newest release typescript-eslint supports (its peer range), so a new
        # TypeScript major that the linter can't load yet is never installed.
        ts_range=$(npm view typescript-eslint peerDependencies.typescript 2>/dev/null || true)
        typescript="typescript${ts_range:+@$ts_range}"
        tools="@types/node${node_major:+@$node_major} vitest @vitest/coverage-v8 eslint @eslint/js typescript-eslint eslint-config-prettier prettier"
        case "$pm" in
            pnpm)
                # Same major as the installed pnpm: pnpm also publishes patches for older majors.
                pnpm_major=$(pnpm --version)
                pnpm_major=${pnpm_major%%.*}
                pnpm_version=$(aged --prefix "v$pnpm_major." pnpm/pnpm) || die "could not pin pnpm $pnpm_major"
                version_at_least "$pnpm_version" 10.16 ||
                    die "pnpm $pnpm_version would ignore minimumReleaseAge; install pnpm 10.16 or newer"
                npm pkg set "packageManager=pnpm@$pnpm_version"
                # shellcheck disable=SC2086 # word splitting of the tool list is intended
                pnpm add --save-dev "$typescript" $tools
                ;;
            npm)
                # shellcheck disable=SC2086
                npm install --save-dev "$typescript" $tools
                ;;
        esac
        ;;
    rust)
        if contains '{{RUST_VERSION}}' rust-toolchain.toml; then
            rust_version=$(aged rust-lang/rust) || die "could not pin Rust"
            replace rust-toolchain.toml '{{RUST_VERSION}}' "$rust_version"
        fi
        # Install the pinned toolchain (rustup 1.28+; older versions install it on `show`).
        if command -v rustup >/dev/null 2>&1; then
            rustup toolchain install >/dev/null 2>&1 || rustup show >/dev/null
        fi
        cargo_version=$(cargo --version | awk '{ print $2 }')
        if ! version_at_least "$cargo_version" 1.100; then
            printf '%s\n' "init-project.sh: warning: cargo $cargo_version ignores global-min-publish-age in" \
                "  .cargo/config.toml (respected from Cargo 1.100). Dependabot's 14-day cooldown still" \
                "  applies; move rust-toolchain.toml to 1.100 or newer once that release is 14 days old." >&2
        fi
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
        if contains '{{VCPKG_BASELINE}}' vcpkg.json; then
            baseline=$(aged --commit master microsoft/vcpkg) || die "could not pin the vcpkg baseline"
            replace vcpkg.json '{{VCPKG_BASELINE}}' "$baseline"
        fi
        ;;
esac
echo "init-project.sh: $lang project initialised in $(pwd)"
