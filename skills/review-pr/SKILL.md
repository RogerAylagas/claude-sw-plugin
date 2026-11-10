---
name: review-pr
description: Review the current branch and open its pull request. An independent code-reviewer subagent checks the diff against the plan (correctness, plan conformance, unrequested changes, tests, security, cost), findings get fixed, the branch is pushed, a PR is opened against the right base with a Conventional Commit title and the plan linked, and CI is watched until it passes. Use when the user asks to review changes, open or create a PR, submit or ship work, or after /sw:implement or /sw:fix finishes.
argument-hint: "[base branch]"
---

# Review and open a pull request

Shared rules: `${CLAUDE_PLUGIN_ROOT}/skills/conventions/SKILL.md`.

## Step 1: Preconditions

1. Current branch: not `main` or `develop`, and named per the conventions. If not, stop and
   propose a rename.
2. Working tree clean. Uncommitted changes → ask whether they belong in this PR (then commit them
   with a Conventional Commit) or not.
3. Base branch: the argument if given; `main` for `hotfix/*` and `release/*`; otherwise `develop`.
4. Plan: the file in `docs/plans/` whose `branch:` matches. A trivial change may have none.
5. `git fetch origin`. If the base has moved ahead: if the branch was never pushed, rebase onto
   `origin/<base>`; if it was pushed, merge `origin/<base>` into it instead (no force-push).
   Re-run the checks afterwards.

## Step 2: Local gate

Run `just check` (or the commands in AGENTS.md / CI). It must pass before review.

## Step 3: Independent review

Launch the `code-reviewer` subagent (`subagent_type: "sw:code-reviewer"`) with only: the base ref
(`origin/<base>`), the plan path, and the repository root. Don't pass your own explanation of the
change: the reviewer has to judge the code, not your account of it.

Handle its findings:

- **blocker / major**: fix them, each fix as a Conventional Commit, and re-run the gate. If any
  blocker was fixed, run the reviewer once more (two rounds at most).
- **minor**: fix if cheap and in scope; otherwise list under "Follow-ups" in the PR.
- If you disagree with a finding, explain why in the PR description; don't silently ignore it.

## Step 4: Push

`git push -u origin <branch>`. Never force-push a branch others may use. Use
`--force-with-lease` only on your own unshared branch after a rebase, and say so.

## Step 5: Open or update the PR

- Existing PR (`gh pr view`): update its body if needed.
- New PR: `gh pr create --base <base> --title "<title>" --body-file <file>`.
- Title: a Conventional Commit summarising the whole change, because feature PRs are
  squash-merged and the title becomes the commit on `develop` (release PRs:
  `chore(release): vX.Y.Z`).
- Body: follow `.github/pull_request_template.md` if the repository has one. Include a summary,
  the plan link, the main changes, the checks you ran and their results, the review outcome and
  any follow-ups, and `Closes #<issue>` when there is one. End with any attribution line the
  environment requires for PRs.

## Step 6: Watch CI

`gh pr checks <number> --watch`. On failure: read the failed logs (`gh run view <run-id>
--log-failed`), fix locally, re-run the gate, push. Stop after three attempts and report what's
failing. If a run ended with no jobs at all (an occasional GitHub glitch), re-run it once
(`gh run rerun <run-id>`) before investigating.

## Step 7: Report, don't merge

The PR is where a human reviews the work, so don't merge it unless the user explicitly asks.
Report the PR URL, the CI status and a summary of the review.

If the user asks you to merge: `gh pr merge --squash` for feature, bugfix and chore PRs;
`gh pr merge --merge` for release and hotfix PRs into `main`, followed by `/sw:release` to tag and
merge back.
