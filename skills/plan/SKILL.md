---
name: plan
description: Plan a feature or change before any code is written. Asks the questions needed to pin down requirements, explores the codebase for code to reuse, applies design principles (minimal change, patterns only when they pay off, computational and economic cost), and writes an approved plan to docs/plans/ with acceptance criteria, a test strategy and one-commit-per-step tasks. Use when the user asks to plan, design or scope a feature, change or refactor, asks "how should we build X", or wants something non-trivial built and no approved plan exists for it.
argument-hint: "[what to build or change]"
---

# Plan a change

Goal: an approved plan in `docs/plans/` that a different engineer could implement without asking
anything, and that changes as little code as possible. **Do not write or change code here.**

Shared rules: `${CLAUDE_PLUGIN_ROOT}/skills/conventions/SKILL.md` (branch names, commit format).
Design rules: `${CLAUDE_PLUGIN_ROOT}/skills/plan/reference/principles.md`. Read it before Step 4.
Plan format: `${CLAUDE_PLUGIN_ROOT}/skills/plan/reference/plan-template.md`. Read it before Step 5.

## Step 0: Size the request

- **Trivial** (typo, comment, one-line config, docs only): say no plan is needed and stop.
- **Bug** (something that worked, or should work, is broken): suggest `/sw:fix`, which has a
  lighter flow (reproduce → failing test → fix). Continue here only if the user wants a full plan.
- **Feature, change, refactor**: continue.

Check `docs/plans/` for an existing plan for the same work. If one exists, update it instead of
starting a new one.

## Step 1: Work read-only

If you are not in plan mode, enter it with the EnterPlanMode tool so that exploration can't change
files (the user approves the switch). If that tool isn't available, ask the user to switch with
Shift+Tab or `/plan`, or continue under the same rule: no edits except the plan file.

## Step 2: Understand before asking

1. Read `AGENTS.md` (or `CLAUDE.md`), `CONTRIBUTING.md`, related plans in `docs/plans/` and ADRs in
   `docs/adr/`.
2. Explore the code the change touches. For broad searches use the Explore subagent and keep only
   its conclusions. Find:
   - existing functions, modules, types and patterns that already do part of the job (reuse beats
     new code);
   - the conventions to follow (naming, error handling, layering, test layout, test helpers);
   - the entry points and callers affected (the blast radius).
3. Note what the code cannot tell you. Only that becomes a question.

## Step 3: Ask until nothing important is ambiguous

Use AskUserQuestion, at most 4 questions per call, each with 2-4 concrete options; put your
recommendation first and add "(Recommended)" to its label. Never ask what the code or the user
already answered. Cover, when relevant:

- **Outcome**: who uses this, what problem it solves, what "done" looks like.
- **Scope**: what is explicitly out of scope.
- **Behavior**: inputs, outputs, edge cases, error handling, defaults.
- **Non-functional requirements**: expected scale and load, latency targets, cost budget (compute,
  storage, paid APIs or LLM tokens), security and privacy, backward compatibility, data migration.
- **Integration tests**: needed or not (recommend one: needed when the change crosses a process,
  network, database, file-system or third-party boundary). Recording this here means
  implementation never stops to ask.
- **Rollout**: feature flag, migration order, deprecation.

Repeat until the acceptance criteria can be written as checks that pass or fail.

## Step 4: Design

Apply `reference/principles.md`. When principles conflict, this order wins:

1. Correctness: meets the acceptance criteria, secure, no data loss.
2. Consistency with the existing codebase and its conventions.
3. Minimal change: fewest files, lines and new concepts; reuse before writing.
4. Simplicity (KISS, YAGNI).
5. Pattern and architecture purity.

For every design pattern or new abstraction in the plan, name it and say in one line why the simpler
option isn't enough. Note the cost of hot paths (complexity, I/O, paid calls). If the change alters
architecture, a public contract, or a default technology, draft an ADR from
`reference/adr-template.md` and list it as a plan step.

## Step 5: Write the plan

Follow `reference/plan-template.md` exactly. The frontmatter keys are a contract read by the sw
hooks and `/sw:implement`.

- Branch: choose it now, following the conventions skill (`feature/`, `bugfix/`, `chore/`;
  `hotfix/` only for urgent production fixes). Never an AI-agent prefix.
- File: in plan mode, write to the plan file the harness gives you. Otherwise write
  `docs/plans/<branch with "/" replaced by "-">.md`, e.g. `docs/plans/feature-csv-export.md`.
- `status: draft` until the user approves.
- Steps: ordered, each one small enough to be one Conventional Commit, each naming the files it
  touches and the tests it adds. Tests come from the acceptance criteria.

## Step 6: Get an independent critique (medium and large plans)

If the plan touches 4 or more files, adds a module, dependency, public API, schema or migration, or
needs an ADR, launch the `plan-critic` subagent (`subagent_type: "sw:plan-critic"`) with the plan's
path. Fix the findings you agree with; list the ones you reject, with the reason, under
"Open questions" for the user to see. Skip this step for small plans.

## Step 7: Approval

- In plan mode: call ExitPlanMode. The user approves or asks for changes.
- Otherwise: show a short summary and ask with AskUserQuestion (Approve / Revise).

After approval:

1. Make sure the plan is at `docs/plans/<branch-slug>.md`. Plan mode may have used a random file
   name; rename it.
2. Set `status: approved`.
3. Leave the file uncommitted. `/sw:implement` creates the branch and commits the plan as its
   first commit.
4. Tell the user: "Plan approved: `docs/plans/<file>`. Run `/sw:implement` to build it."
