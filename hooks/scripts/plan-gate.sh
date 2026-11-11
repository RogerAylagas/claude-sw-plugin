#!/bin/sh
# sw soft workflow gate, run on Edit|Write.
#
#   plan-gate.sh pre   (PreToolUse)  Ask the user, once per session and branch, before Claude edits
#                                    code on main/develop, on a branch that breaks Conventional
#                                    Branch, or on a branch without an approved plan in docs/plans/.
#   plan-gate.sh post  (PostToolUse) The edit ran, so the user allowed it: stop asking for this
#                                    session and branch.
#
# Soft by design: it never blocks (always exits 0, emits "ask" at most). Documentation edits are
# never gated. Only active in repositories that contain docs/plans/.
set -u

mode=${1:-pre}
here=$(CDPATH='' cd -- "$(dirname -- "$0")" && pwd)
# shellcheck source=hooks/scripts/lib.sh
. "$here/lib.sh"

input=$(cat)
file=$(sw_json_string file_path "$input")
[ -n "$file" ] || exit 0

dir=$(sw_existing_dir "$file")
root=$(sw_repo_root "$dir") || exit 0
sw_enabled "$root" || exit 0
sw_is_doc "$dir" "$file" && exit 0
branch=$(sw_branch "$root") || exit 0

reason=''
case "$branch" in
    main | master | develop)
        reason="sw: you are on '$branch', which only changes through pull requests. Create a working branch first (feature/, bugfix/ or chore/ from develop; hotfix/ from main), for example with /sw:implement or /sw:fix. Allow only if editing '$branch' directly is intentional."
        ;;
    *)
        if ! sw_valid_branch "$branch"; then
            reason="sw: branch '$branch' breaks Conventional Branch (feature|bugfix|hotfix|release|chore/<lowercase-hyphenated-description>; AI-agent prefixes such as claude/ are not allowed). Rename it with 'git branch -m <type>/<description>'. Allow to continue anyway."
        elif ! sw_active_plan "$root" "$branch" >/dev/null; then
            reason="sw: no approved plan in docs/plans/ for branch '$branch'. Plan first with /sw:plan (or use /sw:fix for a bug). Allow to continue without a plan, which is fine for trivial changes; you will not be asked again for this branch in this session."
        fi
        ;;
esac
[ -n "$reason" ] || exit 0

session=$(sw_json_string session_id "$input")
marker=$(sw_marker "$session" "$root" "$branch")

if [ "$mode" = post ]; then
    : >"$marker" 2>/dev/null
    exit 0
fi

[ -e "$marker" ] && exit 0
printf '{"hookSpecificOutput":{"hookEventName":"PreToolUse","permissionDecision":"ask","permissionDecisionReason":"%s"}}\n' \
    "$(sw_json_escape "$reason")"
exit 0
