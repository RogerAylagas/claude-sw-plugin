---
name: fix
description: Fix a bug the disciplined way. Gathers the symptoms, reproduces the bug with a failing test first, finds the root cause, makes the smallest fix, and keeps the test as a regression guard. Uses a short plan file and a bugfix/ branch from develop, or hotfix/ from main for urgent production issues. Use when the user reports a bug, error, crash, regression or wrong output, or asks to fix, debug or troubleshoot something that should already work.
argument-hint: "[bug description or issue number]"
---

# Fix a bug

Shared rules: `${CLAUDE_PLUGIN_ROOT}/skills/conventions/SKILL.md` (branches, commits).
Plan format: `${CLAUDE_PLUGIN_ROOT}/skills/plan/reference/plan-template.md`.

Never change code before the bug is reproduced by a failing test, and never "fix" by guessing.

## Step 1: Gather the facts

From the user's message, or the issue (`gh issue view <number>`), collect: what happens, what
should happen, steps to reproduce, error messages or logs, environment and version, and when it
started. Ask only for what's missing and essential, with AskUserQuestion.

Decide the kind of work:

- Behavior that never existed, or a change of intended behavior → it's a feature: suggest
  `/sw:plan` and stop.
- Broken in production and can't wait for the next release → **hotfix**: `hotfix/<slug>` from
  `main`. Confirm this with the user; hotfixes skip the normal release train.
- Anything else → **bugfix**: `bugfix/<slug>` from `develop`.

## Step 2: Branch and mini plan

1. `git status --porcelain` must be clean; otherwise ask what to do with the user's changes.
2. `git fetch origin && git switch -c <branch> origin/<develop|main>`.
3. Write `docs/plans/<branch with "/" replaced by "-">.md` with `type: bugfix` (or `hotfix`),
   `status: in-progress` (the user asked for the fix, so investigation is approved), and
   `integration_tests` set to `required` if the bug lives at a boundary (database, network, files,
   another service), otherwise `not-needed`. Sections: Context (symptoms, expected vs actual),
   Reproduction, Root cause (to be filled in), Fix, Test strategy, Steps.
4. Commit it alone: `docs(plans): add plan for fixing <short description>`.

## Step 3: Reproduce with a failing test

Write the smallest automated test that shows the bug, at the lowest level that can show it
(a unit test if possible, an integration test if the bug is in the interaction with a boundary).
Run it and confirm it fails **for the reported reason**, not because of a setup mistake.

If you can't reproduce it: report what you tried and what you observed, and ask for more
information. Don't change code on a guess.

## Step 4: Find the root cause

Trace from the failing test to the cause. Write it in the plan in 1-3 sentences: what is wrong,
where (`file:line`), and why it produces the symptom. Search for the same mistake elsewhere
(`grep`); list other occurrences in the plan, but fix them here only if they're part of the same
bug.

If the right fix isn't obvious (it touches more than two files, changes a public contract, or has
alternatives with trade-offs), present the options with a recommendation via AskUserQuestion
before writing it.

## Step 5: Minimal fix

Change the least code that removes the root cause (not just the symptom). No refactors, no
unrelated cleanups. The reproduction test now passes; add tests for edge cases the root cause
reveals.

## Step 6: Verify

Run the full gate: `just check` (or the commands in AGENTS.md / CI). Never skip, weaken or delete
tests or checks to get it green.

## Step 7: Commit

Fill in the plan (root cause, fix, ticked steps, `status: done`), then make **one** commit with
the test, the fix and the plan update:

```text
fix(<scope>): <what is fixed, imperative>

Root cause: <one or two sentences>.
Reproduced by <test name>, which failed before this change.

Fixes #<issue>
```

## Step 8: Hand off

Report the root cause, the fix, the test and the check results. Next: `/sw:review-pr`.
For a hotfix the PR goes into `main`; after it merges, `/sw:release` tags the patch version and
merges `main` back into `develop`.
