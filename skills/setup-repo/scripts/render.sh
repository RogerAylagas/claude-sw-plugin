#!/bin/sh
# Render the sw setup templates for one language into DEST, normally an empty staging directory.
# Claude then compares DEST with the real repository and copies, diffs or merges each file, so
# rendering never overwrites anything in a repository.
#
# Usage:
#   render.sh --lang python|typescript|rust|cpp --dest DIR --name NAME [options]
#
# Options:
#   --description TEXT    One sentence; no double quotes or backslashes.
#   --kind lib|app        Library or application (default: app).
#   --pm PM               python: uv | typescript: pnpm, npm | rust: cargo | cpp: vcpkg
#                         (default: the first one).
#   --python-version X.Y  Required for python.
#   --node-version N      Required for typescript (major version, e.g. 24).
#   --cxx-standard N      cpp only (default: 20).
#   --license TEXT        License name for the README (default: "No license chosen yet").
#   --author NAME         Author for package metadata (default: git config user.name).
#   --year YYYY           Default: current year.
#
# Template rules (see skills/setup-repo/templates/README.md):
#   common/ then <lang>/ are copied; files in <lang>/ override common/ ones.
#   A line containing "sw:include FILE" is replaced by templates/_fragments/FILE
#   ("{{LANG}}" in FILE is expanded first).
#   A line ending in a comment "sw:if KEY=VALUE" is kept only when KEY (kind, pm, lang) has
#   VALUE; the marker is removed. A file named "NAME.sw-if-KEY-VALUE" works the same way.
#   {{PLACEHOLDER}} tokens listed below are replaced in file contents and paths. Unknown
#   tokens are left alone (init-project.sh fills {{UV_BUILD_REQ}} and {{VCPKG_BASELINE}}).
set -eu

here=$(CDPATH='' cd -- "$(dirname -- "$0")" && pwd)
templates=$(CDPATH='' cd -- "$here/../templates" && pwd)

die() {
    printf 'render.sh: %s\n' "$1" >&2
    # The file loop runs in a subshell: leave a flag so the main script fails too.
    [ -z "${work:-}" ] || : >"$work/failed"
    exit 1
}

lang='' dest='' name='' description='' kind=app pm='' python_version='' node_version=''
cxx_standard=20 license='No license chosen yet' author='' year=''
while [ $# -gt 0 ]; do
    [ $# -ge 2 ] || die "missing value for $1"
    case "$1" in
        --lang) lang=$2 ;;
        --dest) dest=$2 ;;
        --name) name=$2 ;;
        --description) description=$2 ;;
        --kind) kind=$2 ;;
        --pm) pm=$2 ;;
        --python-version) python_version=$2 ;;
        --node-version) node_version=$2 ;;
        --cxx-standard) cxx_standard=$2 ;;
        --license) license=$2 ;;
        --author) author=$2 ;;
        --year) year=$2 ;;
        *) die "unknown option $1" ;;
    esac
    shift 2
done

[ -n "$dest" ] || die "--dest is required"
printf '%s\n' "$name" | grep -Eq '^[a-z][a-z0-9]*(-[a-z0-9]+)*$' ||
    die "--name must be lowercase-hyphenated (e.g. my-project), got '$name'"
case "$kind" in lib | app) ;; *) die "--kind must be lib or app" ;; esac
case "$lang" in
    python)
        pm=${pm:-uv}
        [ -n "$python_version" ] || die "--python-version is required for python"
        ;;
    typescript)
        pm=${pm:-pnpm}
        [ -n "$node_version" ] || die "--node-version is required for typescript"
        ;;
    rust) pm=${pm:-cargo} ;;
    cpp) pm=${pm:-vcpkg} ;;
    *) die "--lang must be python, typescript, rust or cpp" ;;
esac
case "$lang:$pm" in
    python:uv | typescript:pnpm | typescript:npm | rust:cargo | cpp:vcpkg) ;;
    *) die "no templates for package manager '$pm' with $lang; render the default and adapt" ;;
esac
case "$description" in
    *'"'* | *\\*) die "--description must not contain double quotes or backslashes" ;;
esac
[ -n "$description" ] || description="TODO: describe $name in one sentence."
[ -n "$author" ] || author=$(git config user.name 2>/dev/null || true)
[ -n "$author" ] || author="TODO: author"
[ -n "$year" ] || year=$(date +%Y)

package=$(printf '%s' "$name" | tr '-' '_')
package_upper=$(printf '%s' "$package" | tr '[:lower:]' '[:upper:]')

work=$(mktemp -d 2>/dev/null || mktemp -d -t swrender)
trap 'rm -rf "$work"' EXIT INT TERM

# Placeholder substitutions as a sed script ("|" delimiter; escape \ | & in values).
script="$work/placeholders.sed"
: >"$script"
add() {
    printf 's|{{%s}}|%s|g\n' "$1" "$(printf '%s' "$2" | sed -e 's/[\\|&]/\\&/g')" >>"$script"
}
add PROJECT_NAME "$name"
add PACKAGE_NAME "$package"
add PACKAGE_UPPER "$package_upper"
add DESCRIPTION "$description"
add LANG "$lang"
add KIND "$kind"
add PM "$pm"
add PYTHON_VERSION "$python_version"
add NODE_VERSION "$node_version"
add CXX_STANDARD "$cxx_standard"
add LICENSE "$license"
add AUTHOR "$author"
add YEAR "$year"
add DATE "$(date +%Y-%m-%d)"

# The awk programs below are single-quoted on purpose: $0 belongs to awk, not to the shell.
# shellcheck disable=SC2016
include_awk='
function rep(s, from, to,    i, out) {
    out = ""
    while ((i = index(s, from)) > 0) {
        out = out substr(s, 1, i - 1) to
        s = substr(s, i + length(from))
    }
    return out s
}
{
    if (match($0, /sw:include[ \t]+[^ \t]+/)) {
        spec = substr($0, RSTART, RLENGTH)
        sub(/^sw:include[ \t]+/, "", spec)
        file = frag "/" rep(spec, "{{LANG}}", lang)
        n = 0
        while ((getline line < file) > 0) { print line; n++ }
        close(file)
        if (n == 0) { printf "render.sh: missing or empty fragment %s\n", file > "/dev/stderr"; exit 2 }
        next
    }
    print
}'

# shellcheck disable=SC2016
cond_awk='
{
    if (match($0, /sw:if[ \t]+[a-z]+=[A-Za-z0-9.+_-]+/)) {
        cond = substr($0, RSTART + 5, RLENGTH - 5)
        sub(/^[ \t]+/, "", cond)
        split(cond, kv, "=")
        val = (kv[1] == "kind") ? kind : (kv[1] == "pm") ? pm : (kv[1] == "lang") ? lang : ""
        if (val != kv[2]) next
        line = $0
        sub(/[ \t]*(#|\/\/|<!--)[ \t]*sw:if[ \t]+[^ \t]+([ \t]*-->)?[ \t]*$/, "", line)
        print line
        next
    }
    print
}'

render_file() { # SRC DST
    awk -v frag="$templates/_fragments" -v lang="$lang" "$include_awk" "$1" >"$work/a" ||
        die "include failed in $1"
    awk -v kind="$kind" -v pm="$pm" -v lang="$lang" "$cond_awk" "$work/a" >"$work/b" ||
        die "conditionals failed in $1"
    mkdir -p "$(dirname -- "$2")"
    sed -f "$script" "$work/b" >"$2" || die "placeholders failed in $1"
}

mkdir -p "$dest"
for layer in common "$lang"; do
    base="$templates/$layer"
    find "$base" -type f | sort | while IFS= read -r src; do
        rel=${src#"$base"/}
        case "$rel" in
            *.sw-if-*)
                cond=${rel##*.sw-if-}
                rel=${rel%.sw-if-*}
                key=${cond%%-*}
                want=${cond#*-}
                case "$key" in
                    kind) have=$kind ;;
                    pm) have=$pm ;;
                    lang) have=$lang ;;
                    *) die "unknown condition key '$key' in $src" ;;
                esac
                [ "$have" = "$want" ] || continue
                ;;
        esac
        rel=$(printf '%s\n' "$rel" | sed -f "$script")
        render_file "$src" "$dest/$rel"
        printf '%s\n' "$rel"
    done
done | sort -u
[ ! -e "$work/failed" ] || exit 1
