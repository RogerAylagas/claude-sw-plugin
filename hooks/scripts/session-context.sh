#!/bin/sh
# sw SessionStart hook: tell Claude where this repository stands in the sw workflow.
# Plain stdout becomes session context. Prints nothing outside repositories with docs/plans/.
# Never fails the session: always exits 0.
set -u

here=$(CDPATH='' cd -- "$(dirname -- "$0")" && pwd)
# shellcheck source=hooks/scripts/lib.sh
. "$here/lib.sh"

input=$(cat 2>/dev/null || true)
cwd=$(sw_json_string cwd "$input")
if [ -z "$cwd" ] || [ ! -d "$cwd" ]; then
    cwd=${CLAUDE_PROJECT_DIR:-$PWD}
fi

root=$(sw_repo_root "$cwd") || exit 0
sw_enabled "$root" || exit 0
sw_cleanup_state

echo "[sw] This repository uses the sw workflow: main = production, develop = default branch and PR target. Branches follow Conventional Branch (no AI-agent prefixes); commits and PR titles follow Conventional Commits."

if ! branch=$(sw_branch "$root"); then
    echo "[sw] HEAD is detached. Switch to a branch before changing code."
    exit 0
fi

case "$branch" in
    main | master | develop)
        echo "[sw] Current branch: $branch (protected, changes only through PRs). Before changing code, plan with /sw:plan or start a bug fix with /sw:fix; both create the working branch."
        ;;
    *)
        plan=$(sw_active_plan "$root" "$branch") || plan=$(sw_plans "$root" "$branch" | head -n 1 | cut -f 1)
        if [ -n "$plan" ]; then
            status=$(sw_plans "$root" "$branch" | grep -F "$plan$SW_TAB" | head -n 1 | cut -f 2)
            progress=$(awk '/^[ \t]*- \[[xX]\] /{d++} /^[ \t]*- \[[ xX]\] /{t++} END{printf "%d/%d", d, t}' "$plan")
            next=$(awk '{ sub(/\r$/, "") } /^[ \t]*- \[ \] /{ sub(/^[ \t]*- \[ \] /, ""); print; exit }' "$plan")
            echo "[sw] Current branch: $branch. Plan: ${plan#"$root"/} (status: ${status:-unknown}, steps done: $progress)."
            [ -n "$next" ] && echo "[sw] Next plan step: $next"
        else
            echo "[sw] Current branch: $branch. No plan in docs/plans/ for this branch: use /sw:plan before implementing (or /sw:fix for a bug)."
        fi
        sw_valid_branch "$branch" ||
            echo "[sw] Warning: branch '$branch' breaks Conventional Branch. Rename it: git branch -m <feature|bugfix|hotfix|release|chore>/<description>."
        ;;
esac

echo "[sw] Commands: /sw:plan, /sw:implement, /sw:fix, /sw:review-pr, /sw:release, /sw:setup-repo."
exit 0
