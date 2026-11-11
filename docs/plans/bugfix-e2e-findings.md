---
title: Fix the findings of the first end-to-end trial
type: bugfix
branch: bugfix/e2e-findings
status: done
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
      Team or Enterprise), naming the owner's plan when GitHub returns it (user or organisation;
      it is often `null`, so it can't be relied on). If protection then fails with HTTP 403, the
      report says why and what would enable it.
- [ ] Given a local uv older than the newest uv release at least 14 days old, when setup-repo
      inspects the tools, then it offers `uv self update <that version>` (or an update through the
      package manager that installed uv), never a plain `uv self update`, which would install a
      release younger than 14 days. `init-project.sh`'s "uv too old" message says the same.
- [ ] Given `just` is missing, then setup-repo offers `uv tool install --exclude-newer "14 days"
      rust-just`, and the generated AGENTS.md tells later sessions to run recipes with
      `uvx --exclude-newer "14 days" --from rust-just just <recipe>`; implement Step 7 says the same.
- [x] Given an implementation whose tests pass, when implement finishes, then every acceptance
      criterion with a passing test is ticked in the plan, and the report names the test covering
      each; any criterion left unticked is reported with the reason.

## Out of scope
- Installing anything without the user's approval.
- Detecting the plan reliably: `plan` is only returned to tokens with the `user` scope.

## Changes
| File | Change |
|---|---|
| `skills/setup-repo/SKILL.md` | Step 1: outdated uv and missing `just` (AC 2-3); Step 2: free plan + private (AC 1) |
| `skills/setup-repo/templates/common/AGENTS.md` | `uvx` fallback for `just` (AC 3) |
| `skills/implement/SKILL.md` | Step 7 fallback (AC 3); Step 8 ticks acceptance criteria (AC 4) |
| `skills/fix/SKILL.md`, `skills/review-pr/SKILL.md` | Same `just` fallback where they run the gate (AC 3; added during implementation, both hit it in the trial) |
| `evals/implement-ticks-acceptance-criteria/` | New eval case for AC 4 |
| `evals/setup-repo-private-needs-paid-plan/` | New eval case for AC 1 (added after code review) |
| `skills/setup-repo/scripts/init-project.sh` | "uv too old" message suggests the aged uv release (AC 2; added after code review) |
| `tests/templates/smoke.sh` | Checks that the generated AGENTS.md has the `just` fallback (AC 3; added after code review) |

## Test strategy
- Unit: none; these are skill instructions. The "uv too old" message keeps its existing script
  test.
- Evals (they cost model calls and run on demand: Linux, macOS, WSL2 or the Evals workflow):
  `evals/implement-ticks-acceptance-criteria/` (AC 4) and `evals/setup-repo-private-needs-paid-plan/`
  (AC 1).
- Template smoke tests: every generated AGENTS.md contains the `uvx` fallback for `just` (AC 3).
- Exception, AC 2: no eval. It needs an outdated `uv` on the session's `PATH`, which a scaffold
  script can't arrange for the session it scaffolds. Covered by review.
- `just check` (lint, validate, hook and script tests) and the template smoke tests in CI.

## Steps
- [x] `docs(plans): add plan for the end-to-end trial findings`
- [x] `test(evals): check that implement ticks acceptance criteria`: the eval case
- [x] `fix(implement): tick verified acceptance criteria and know the just fallback`
- [x] `fix(setup-repo): warn about protection on free private repos, offer uv and just`

## Open questions
- AC 4 was verified on 2026-11-11 with a headless `claude -p` run on the new eval's fixture: both
  criteria were ticked in the `docs(plans): mark ... done` commit, and the report named the test
  covering each.
- AC 1-3 are left unticked: they change setup-repo's instructions, which only an interactive
  `/sw:setup-repo` run (or the AC 1 eval, run on demand) exercises. The generated-AGENTS.md part
  of AC 3 is checked by the smoke tests.
- Code review (2026-11-11): REQUEST CHANGES with 5 findings (missing tests for AC 1-3, organisation
  plans, a plain `uv self update` in a message, package-manager installs of uv, AC 4 wording);
  all addressed, with AC 2's eval recorded as an exception above.
