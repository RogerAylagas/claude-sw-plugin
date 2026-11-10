#!/bin/sh
# Tests for hooks/scripts (plan-gate.sh, session-context.sh).
# Usage: sh tests/hooks/run.sh   (POSIX sh; on Windows run from Git Bash)
set -u

top=$(CDPATH='' cd -- "$(dirname -- "$0")/../.." && pwd)
gate="$top/hooks/scripts/plan-gate.sh"
ctx="$top/hooks/scripts/session-context.sh"

work=$(mktemp -d 2>/dev/null || mktemp -d -t swhooks)
trap 'rm -rf "$work"' EXIT INT TERM
CLAUDE_PLUGIN_DATA="$work/state"
export CLAUDE_PLUGIN_DATA
unset CLAUDE_PROJECT_DIR

passed=0
failed=0

ok() {
    passed=$((passed + 1))
    printf 'ok   %s\n' "$1"
}

not_ok() {
    failed=$((failed + 1))
    printf 'FAIL %s\n     %s\n' "$1" "$2"
}

# Path as Claude Code sends it in hook JSON: native Windows path (escaped) on Windows.
json_path() {
    case "$(uname -s)" in
        MINGW* | MSYS* | CYGWIN*) cygpath -w "$1" | sed 's/\\/\\\\/g' ;;
        *) printf '%s' "$1" ;;
    esac
}

new_repo() { # NAME BRANCH [plans=yes|no]
    _r="$work/$1"
    mkdir -p "$_r"
    git -C "$_r" -c init.defaultBranch=main init -q
    git -C "$_r" symbolic-ref HEAD "refs/heads/$2"
    [ "${3:-yes}" = yes ] && mkdir -p "$_r/docs/plans"
    printf '%s' "$_r"
}

write_plan() { # REPO FILE BRANCH STATUS [crlf|quoted]
    _content=$(printf -- '---\ntitle: Test plan\ntype: feature\nbranch: %s\nstatus: %s   # comment\nintegration_tests: not-needed\n---\n\n# Plan\n\n## Steps\n- [x] add parser\n- [ ] wire CLI flag\n- [ ] document flag\n' "$3" "$4")
    case "${5:-}" in
        quoted) _content=$(printf '%s\n' "$_content" | sed "s|^branch: .*|branch: \"$3\"|") ;;
    esac
    case "${5:-}" in
        crlf) printf '%s\n' "$_content" | sed 's/$/\r/' >"$1/docs/plans/$2" ;;
        *) printf '%s\n' "$_content" >"$1/docs/plans/$2" ;;
    esac
}

gate() { # MODE SESSION FILE -> stdout of plan-gate.sh; fails the test run on non-zero exit
    printf '{"session_id":"%s","transcript_path":"x","cwd":"x","hook_event_name":"PreToolUse","tool_name":"Edit","tool_input":{"file_path":"%s","old_string":"say \\"file_path\\": \\"/etc/x\\"","new_string":"b"}}' \
        "$2" "$(json_path "$3")" | sh "$gate" "$1"
    _rc=$?
    [ "$_rc" -eq 0 ] || not_ok "plan-gate exit status" "expected 0, got $_rc for $3"
}

context() { # CWD
    printf '{"session_id":"s","hook_event_name":"SessionStart","source":"startup","cwd":"%s"}' "$(json_path "$1")" | sh "$ctx"
}

expect_ask() { # NAME OUTPUT [TEXT]
    case "$2" in
        *'"permissionDecision":"ask"'*"${3:-}"*) ok "$1" ;;
        *) not_ok "$1" "expected ask mentioning [${3:-}], got: ${2:-<nothing>}" ;;
    esac
}

expect_silent() { # NAME OUTPUT
    if [ -z "$2" ]; then ok "$1"; else not_ok "$1" "expected no output, got: $2"; fi
}

expect_contains() { # NAME OUTPUT TEXT
    case "$2" in
        *"$3"*) ok "$1" ;;
        *) not_ok "$1" "expected output to contain '$3', got: ${2:-<nothing>}" ;;
    esac
}

# --- plan-gate.sh -------------------------------------------------------------------------

mkdir -p "$work/plain"
expect_silent "outside a git repository: silent" "$(gate pre s1 "$work/plain/app.py")"

r=$(new_repo optout develop no)
expect_silent "repo without docs/plans (not using sw): silent" "$(gate pre s1 "$r/src/app.py")"

r=$(new_repo dev develop)
expect_ask "develop + code file: ask" "$(gate pre s1 "$r/src/app.py")" "develop"
expect_silent "develop + markdown file: silent" "$(gate pre s1 "$r/README.md")"
expect_silent "develop + file under docs/: silent" "$(gate pre s1 "$r/docs/diagram.svg")"
expect_silent "develop + plan in docs/plans/: silent" "$(gate pre s1 "$r/docs/plans/feature-x.md")"
gate post s1 "$r/README.md"
expect_ask "doc edit does not unlock code edits" "$(gate pre s1 "$r/src/app.py")"
gate post s1 "$r/src/app.py"
expect_silent "after an allowed edit: silent for the rest of the session" "$(gate pre s1 "$r/src/other.py")"
expect_ask "new session: ask again" "$(gate pre s2 "$r/src/app.py")"

r=$(new_repo mainrepo main)
expect_ask "main + code file: ask" "$(gate pre s1 "$r/app.py")" "main"

r=$(new_repo noplan feature/csv-export)
expect_ask "feature branch without plan: ask" "$(gate pre s1 "$r/src/app.py")" "no approved plan"
expect_ask "new file in new folder still resolves the repo" "$(gate pre s1 "$r/src/new/deep/mod.py")" "no approved plan"

r=$(new_repo draft feature/csv-export)
write_plan "$r" feature-csv-export.md feature/csv-export draft
expect_ask "plan in draft status: ask" "$(gate pre s1 "$r/src/app.py")" "no approved plan"

r=$(new_repo approved feature/csv-export)
write_plan "$r" feature-csv-export.md feature/csv-export approved
expect_silent "approved plan for branch: silent" "$(gate pre s1 "$r/src/app.py")"

r=$(new_repo progress bugfix/empty-cart)
write_plan "$r" bugfix-empty-cart.md bugfix/empty-cart in-progress
expect_silent "in-progress plan for branch: silent" "$(gate pre s1 "$r/src/app.py")"

r=$(new_repo other feature/csv-export)
write_plan "$r" feature-other.md feature/other approved
expect_ask "approved plan for a different branch: ask" "$(gate pre s1 "$r/src/app.py")" "no approved plan"

r=$(new_repo crlf feature/csv-export)
write_plan "$r" feature-csv-export.md feature/csv-export approved crlf
expect_silent "plan with CRLF line endings: silent" "$(gate pre s1 "$r/src/app.py")"

r=$(new_repo quoted release/v1.2.0)
write_plan "$r" release.md release/v1.2.0 approved quoted
expect_silent "quoted branch value and dotted release branch: silent" "$(gate pre s1 "$r/src/app.py")"

r=$(new_repo agent claude/csv-export)
write_plan "$r" claude.md claude/csv-export approved
expect_ask "AI-agent branch prefix: ask" "$(gate pre s1 "$r/src/app.py")" "Conventional Branch"

r=$(new_repo upper Feature/CSV)
expect_ask "uppercase branch: ask" "$(gate pre s1 "$r/src/app.py")" "Conventional Branch"

r=$(new_repo detached develop)
git -C "$r" -c user.name=t -c user.email=t@example.com commit -q --allow-empty -m "chore: init"
git -C "$r" checkout -q --detach
expect_silent "detached HEAD: silent" "$(gate pre s1 "$r/src/app.py")"

# --- session-context.sh -------------------------------------------------------------------

expect_silent "context outside a git repository: silent" "$(context "$work/plain")"
r=$(new_repo ctxoptout develop no)
expect_silent "context in repo without docs/plans: silent" "$(context "$r")"

r=$(new_repo ctxdev develop)
out=$(context "$r")
expect_contains "context on develop: explains protected branch" "$out" "protected"
expect_contains "context lists commands" "$out" "/sw:plan"

r=$(new_repo ctxplan feature/csv-export)
write_plan "$r" feature-csv-export.md feature/csv-export in-progress crlf
out=$(context "$r")
expect_contains "context shows plan path" "$out" "Plan: docs/plans/feature-csv-export.md"
expect_contains "context shows plan status" "$out" "status: in-progress"
expect_contains "context shows progress" "$out" "steps done: 1/3"
expect_contains "context shows next step" "$out" "Next plan step: wire CLI flag"

r=$(new_repo ctxnoplan feature/csv-export)
expect_contains "context without plan suggests /sw:plan" "$(context "$r")" "No plan in docs/plans/"

r=$(new_repo ctxagent codex/thing)
expect_contains "context warns about bad branch name" "$(context "$r")" "breaks Conventional Branch"

printf '\n%d passed, %d failed\n' "$passed" "$failed"
[ "$failed" -eq 0 ]
