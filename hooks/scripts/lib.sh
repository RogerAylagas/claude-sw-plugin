# shellcheck shell=sh
# Shared helpers for the sw hook scripts.
# Portability contract: POSIX sh plus git, sed, awk, grep, cksum. No jq, Python or Node.
# Must work in Git Bash (Windows), Linux and macOS.

# Conventional Branch v1.1.0 without AI-agent prefixes. Keep in sync with skills/conventions/SKILL.md.
SW_BRANCH_RE='^(main|develop|(feature|feat|bugfix|fix|hotfix|release|chore)/[a-z0-9]+(\.[a-z0-9]+)*(-[a-z0-9]+(\.[a-z0-9]+)*)*)$'
# shellcheck disable=SC2034 # used by the scripts that source this file
SW_TAB=$(printf '\t')

# sw_json_string KEY JSON: print the first string value of "KEY" in JSON.
# Unescapes \" and turns JSON-escaped backslashes into "/" so Windows paths work in Git Bash.
sw_json_string() {
    printf '%s\n' "$2" \
        | sed -nE 's/.*"'"$1"'"[[:space:]]*:[[:space:]]*"(([^"\\]|\\.)*)".*/\1/p' \
        | head -n 1 \
        | sed -e 's/\\\\/\//g' -e 's/\\"/"/g' -e 's/\\\//\//g'
}

# sw_json_escape TEXT: escape TEXT for use inside a JSON string (single-line text).
sw_json_escape() {
    printf '%s' "$1" | sed -e 's/\\/\\\\/g' -e 's/"/\\"/g' | tr -d '\r\n'
}

# sw_existing_dir PATH: nearest existing directory containing PATH (PATH may not exist yet).
sw_existing_dir() {
    _d=$(dirname -- "$1")
    while [ ! -d "$_d" ]; do
        _p=$(dirname -- "$_d")
        [ "$_p" = "$_d" ] && break
        _d=$_p
    done
    printf '%s\n' "$_d"
}

# sw_repo_root DIR: top-level directory of the git repository containing DIR.
sw_repo_root() {
    git -C "$1" rev-parse --show-toplevel 2>/dev/null
}

# sw_branch ROOT: current branch name; fails on a detached HEAD.
sw_branch() {
    git -C "$1" symbolic-ref --quiet --short HEAD 2>/dev/null
}

# sw_enabled ROOT: the workflow applies only to repositories that have docs/plans/.
sw_enabled() {
    [ -d "$1/docs/plans" ]
}

# sw_valid_branch NAME
sw_valid_branch() {
    printf '%s\n' "$1" | grep -Eq "$SW_BRANCH_RE"
}

# sw_plans ROOT BRANCH: print "FILE<TAB>STATUS" for each plan whose frontmatter branch is BRANCH.
sw_plans() {
    for _f in "$1"/docs/plans/*.md; do
        [ -f "$_f" ] || continue
        awk -v want="$2" '
            { sub(/\r$/, "") }
            NR == 1 { if ($0 !~ /^---[ \t]*$/) exit; infm = 1; next }
            infm && /^---[ \t]*$/ { exit }
            infm && match($0, /^[A-Za-z_]+:/) {
                key = substr($0, 1, RLENGTH - 1)
                val = substr($0, RLENGTH + 1)
                sub(/[ \t]+#.*$/, "", val)
                gsub(/^[ \t]+|[ \t]+$/, "", val)
                gsub(/^["\047]|["\047]$/, "", val)
                v[key] = val
            }
            END { if (v["branch"] == want) printf "%s\t%s\n", FILENAME, v["status"] }
        ' "$_f"
    done
}

# sw_active_plan ROOT BRANCH: print the FILE of an approved or in-progress plan for BRANCH.
sw_active_plan() {
    sw_plans "$1" "$2" | awk -F '\t' '$2 == "approved" || $2 == "in-progress" { print $1; found = 1; exit } END { exit !found }'
}

# sw_is_doc DIR FILE: documentation (by extension, or anything under docs/) never needs a plan.
# DIR is the nearest existing directory of FILE; git gives its path relative to the repo root,
# which avoids comparing absolute paths that differ in form on Windows (C:/ vs /c/, 8.3 names).
sw_is_doc() {
    case "$2" in
        *.md | *.mdx | *.rst | *.adoc | *.txt) return 0 ;;
    esac
    case "$(git -C "$1" rev-parse --show-prefix 2>/dev/null)" in
        docs/*) return 0 ;;
    esac
    return 1
}

# sw_state_dir: per-user state (plugin data dir when Claude Code provides one).
sw_state_dir() {
    _s="${CLAUDE_PLUGIN_DATA:-${TMPDIR:-/tmp}/sw-plugin}/gate"
    mkdir -p "$_s" 2>/dev/null
    printf '%s\n' "$_s"
}

# sw_marker SESSION ROOT BRANCH: marker file meaning "the user allowed an ungated edit here".
sw_marker() {
    _sid=$(printf '%s' "$1" | tr -cd 'A-Za-z0-9-')
    _sum=$(printf '%s|%s' "$2" "$3" | cksum | awk '{ print $1 }')
    printf '%s/%s-%s\n' "$(sw_state_dir)" "${_sid:-nosession}" "$_sum"
}

# sw_cleanup_state: drop markers older than a week.
sw_cleanup_state() {
    find "$(sw_state_dir)" -type f -mtime +7 -exec rm -f {} + 2>/dev/null || true
}
