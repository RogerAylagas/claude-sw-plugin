---
name: implement
description: Implement an approved plan from docs/plans/. Finds the plan for the request or current branch (and routes to planning when there is none), creates the Conventional Branch, writes unit tests from the acceptance criteria first, implements step by step with one Conventional Commit per step, adds integration tests when the plan requires them, and runs the same checks as CI until they pass. Use when the user asks to implement, build, code, develop or execute a feature, change or plan, or says "go ahead" after a plan was approved.
argument-hint: "[plan file or feature name]"
---

# Implement an approved plan

Shared rules: `${CLAUDE_PLUGIN_ROOT}/skills/conventions/SKILL.md` (branches, commits).
Design rules still apply while coding: `${CLAUDE_PLUGIN_ROOT}/skills/plan/reference/principles.md`.

## Step 1: Find the plan

1. If the user gave a plan path, use it.
2. Otherwise, on a working branch: use the plan in `docs/plans/` whose frontmatter `branch:` matches
   the current branch.
3. Otherwise: look for plans with `status: approved` or `status: in-progress`
   (`grep -lE '^status: (approved|in-progress)' docs/plans/*.md`) and match them to the request by
   title and context. If several match, ask which one with AskUserQuestion.

Then:

| Situation | Action |
|---|---|
| No plan, trivial change (typo, docs, one-line config) | Ask once whether to proceed without a plan. |
| No plan, a bug | Switch to the fix flow: `${CLAUDE_PLUGIN_ROOT}/skills/fix/SKILL.md`. |
| No plan, anything else | Say "No approved plan found; planning first." Follow `${CLAUDE_PLUGIN_ROOT}/skills/plan/SKILL.md` (it enters plan mode), then come back here after approval. |
| `status: draft` | Finish the plan's approval step (plan skill, Step 7) before coding. |
| `status: done` or `abandoned` | Tell the user. New work needs a new plan. |
| `status: approved` or `in-progress` | Continue. `in-progress` means resume at the first unchecked step. |

## Step 2: Check the plan still fits the code

Confirm that the files, functions and commands the plan names still exist and behave as it
assumes. Small drift (a renamed helper) → adapt and mention it in the commit body. Real drift
(the approach no longer works) → deviation protocol (Step 5) before writing code.

## Step 3: Prepare the branch

1. `git status --porcelain`: only the plan file may be uncommitted. Anything else → stop and ask
   the user what to do with it; never discard or stash their work silently.
2. Base branch: `main` for `type: hotfix`, otherwise `develop`.
3. `git fetch origin`. If the plan's branch exists (locally or on the remote), switch to it and
   update it. Otherwise `git switch -c <branch> origin/<base>` (use the local base when there is
   no remote).
4. Set `status: in-progress` in the plan and commit it alone:
   `docs(plans): add plan for <title>` (first time) or `docs(plans): resume <title>`.

## Step 4: Implement step by step

For each unchecked step, in order:

1. **Tests first.** Write the unit tests for the acceptance criteria this step covers, using the
   project's test layout and helpers. Run them and confirm they fail for the expected reason. When
   test-first is impractical (pure wiring or configuration), write the tests right after the code,
   in the same step.
2. **Minimum code** to make them pass. Follow the codebase's conventions. Change only what the step
   lists; no drive-by edits.
3. **Refactor** inside the step's scope while the tests stay green.
4. **Fast checks**: the tests and linters for what you touched (see AGENTS.md or the justfile, e.g.
   `just test`, `just lint`).
5. **Commit**: tick the step in the plan (`- [ ]` → `- [x]`) and commit code, tests and the plan
   update together, using the step's Conventional Commit message. If a pre-commit hook rewrites
   files, stage them and commit again. Never use `--no-verify`.

Unit tests must be fast and deterministic: no network, real clock or shared file system (inject
or fake them). Cover the happy path, edge cases and error paths of new and changed code.

## Step 5: Deviation protocol

Stop and ask before coding past any of these:

- the plan's approach doesn't work or an acceptance criterion can't be met;
- the change needs files, dependencies or behavior the plan doesn't list;
- you find a bug or design problem outside the plan's scope.

Explain in 2-3 lines, propose the plan change, and ask with AskUserQuestion. After the user
decides, update the plan (steps, Changes table, and a note under "Open questions") and commit it as
`docs(plans): <what changed>`. Out-of-scope problems become a note for a separate plan or fix,
not extra code in this branch.

## Step 6: Integration tests

Follow the plan's `integration_tests` value:

- `required`: implement them as planned (the plan names the boundary and location).
- `undecided`: ask now with AskUserQuestion: "Integration tests needed?" with your recommendation
  first (needed when the change crosses a database, network, file-system, third-party or process
  boundary). Record the answer in the plan's frontmatter and Test strategy.
- `not-needed`: skip.

## Step 7: Full quality gate

Run the same checks CI runs: `just check` if the repository has a justfile (without `just`
installed: `uvx --exclude-newer "14 days" --from rust-just just check`), otherwise the commands in
AGENTS.md, CONTRIBUTING.md or the CI workflow (build, linters and formatters, type checks, unit
and integration tests). Fix and re-run until everything passes.

Never make checks pass by deleting, skipping or weakening tests, by disabling lint or type rules,
by adding ignore comments, or by lowering coverage thresholds, unless the plan says so or the user
agrees. If a failure was already there before your change, report it instead of hiding it.

## Step 8: Finish

1. If behavior, commands or conventions changed, update README, AGENTS.md or CONTRIBUTING.md in a
   `docs:` commit.
2. Tick each acceptance criterion (`- [ ]` → `- [x]`) that a passing test covers. Leave a
   criterion unticked if no test covers it, and say why in the report. Then set the plan's
   `status: done` and commit both: `docs(plans): mark <title> done`.
3. Report: the commits made, tests added (with the criterion each covers), check results, any
   criterion left unticked, and any deviations from the plan.
4. Suggest the next step: `/sw:review-pr` to review the diff and open the pull request.
