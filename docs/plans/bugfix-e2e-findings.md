---
title: Fix the findings of the first end-to-end trial
type: bugfix
branch: bugfix/e2e-findings
status: in-progress
integration_tests: not-needed
---

# Fix the findings of the first end-to-end trial

## Context
On 2026-11-10 the plugin was run end to end in headless Claude Code sessions on a throwaway
repository (`RogerAylagas/sw-e2e-python`): setup-repo, plan, implement, review-pr and fix. All
worked, with four findings:

1. Branch protection failed with HTTP 403: private repositories on a free GitHub plan can't have
   it. The setup skill only found out at the end, when the user could no longer choose differently.
2. The local uv (0.12.15) was months old. Python 3.15 was offered only as a release candidate, and
   the `uv_build` bound was stale. The bound is fixed since #9: it now comes from the newest uv
   release at least 14 days old. The skill still never offers to update uv.
3. `just` was not installed. Every later session tried `just`, failed, and ran the recipe commands
   by hand, because the generated AGENTS.md doesn't mention the `uvx` fallback.
4. `/sw:implement` ticked the plan's steps but not its acceptance criteria; `/sw:review-pr` had to
   tick them in an extra commit.

## Root cause
The skills' instructions don't cover these situations. There's no code defect: setup-repo Step 1
inspects tools but doesn't act on outdated or missing ones, Step 2 asks public/private without the
plan limitation, the generated AGENTS.md only says how to install `just`, and implement Step 8
doesn't mention acceptance criteria.

## Acceptance criteria
- [ ] Given setup-repo asks whether the new repository is public or private, then the private
      option says that branch protection on private repositories needs a paid GitHub plan (Pro,
      Team or Enterprise), naming the account's plan when `gh api user --jq .plan.name` returns one
      (it is `null` for tokens without the `user` scope, so it can't be relied on). If protection
      then fails with HTTP 403, the report says why and what would enable it.
- [ ] Given a local uv older than the newest uv release at least 14 days old, when setup-repo
      inspects the tools, then it offers `uv self update <that version>`, never a plain
      `uv self update` (which would install a release younger than 14 days).
- [ ] Given `just` is missing, then setup-repo offers `uv tool install --exclude-newer "14 days"
      rust-just`, and the generated AGENTS.md tells later sessions to run recipes with
      `uvx --exclude-newer "14 days" --from rust-just just <recipe>`; implement Step 7 says the same.
- [ ] Given an implementation whose tests pass, when implement finishes, then every acceptance
      criterion with a passing test is ticked in the plan, naming the test; any criterion left
      unticked is reported with the reason.

## Out of scope
- Installing anything without the user's approval.
- Detecting the plan reliably: `plan` is only returned to tokens with the `user` scope.

## Changes
| File | Change |
|---|---|
| `skills/setup-repo/SKILL.md` | Step 1: outdated uv and missing `just` (AC 2-3); Step 2: free plan + private (AC 1) |
| `skills/setup-repo/templates/common/AGENTS.md` | `uvx` fallback for `just` (AC 3) |
| `skills/implement/SKILL.md` | Step 7 fallback (AC 3); Step 8 ticks acceptance criteria (AC 4) |
| `evals/implement-ticks-acceptance-criteria/` | New eval case for AC 4 |

## Test strategy
- Unit: none; these are skill instructions.
- Eval: `evals/implement-ticks-acceptance-criteria/` (an approved plan with two criteria; graded on
  whether implement ticks them). Like the other evals, it costs model calls and runs on demand
  (Linux, macOS, WSL2 or the Evals workflow).
- `just check` (lint, validate, hook and script tests) and the template smoke tests in CI.

## Steps
- [x] `docs(plans): add plan for the end-to-end trial findings`
- [x] `test(evals): check that implement ticks acceptance criteria`: the eval case
- [ ] `fix(implement): tick verified acceptance criteria and know the just fallback`
- [ ] `fix(setup-repo): warn about protection on free private repos, offer uv and just`

## Open questions
None.
