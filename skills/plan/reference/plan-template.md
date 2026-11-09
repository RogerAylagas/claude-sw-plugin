# Plan template

Copy everything below the line into the plan file and fill it in. Rules:

- Keep the frontmatter keys and allowed values exactly as shown: the sw hooks and skills read them.
  - `type`: `feature` | `bugfix` | `hotfix` | `chore`
  - `status`: `draft` | `approved` | `in-progress` | `done` | `abandoned`
  - `integration_tests`: `required` | `not-needed` | `undecided`
- Delete guidance comments (`<!-- -->`) once a section is filled in. Write "None" rather than
  deleting a section.
- Be concrete: file paths, function names, commands. No "etc.", no "as needed".
- Aim for a plan you can read in five minutes.

---

```markdown
---
title: <Short imperative title, e.g. Add CSV export to the orders report>
type: feature
branch: feature/<lowercase-hyphenated-description>
status: draft
integration_tests: not-needed
---

# <Title>

## Context
<!-- Why this change: the problem, who has it, what prompted it. 2-5 sentences. -->

## Acceptance criteria
<!-- Testable statements. Each becomes at least one test. -->
- [ ] Given <state>, when <action>, then <observable result>.
- [ ] Given <error condition>, when <action>, then <error behavior>.

## Out of scope
<!-- What this change deliberately does not do. -->
-

## Design
### Reused
<!-- Existing code this plan builds on, with paths. -->
- `path/to/module.py` `existing_function()`: <what we use it for>

### Changes
<!-- Every file touched and why. New files need a stronger reason than edits to existing ones. -->
| File | Change | Why |
|---|---|---|
| `path/to/file` | <edit / new> | <reason tied to an acceptance criterion> |

### Patterns and decisions
<!-- Only if a pattern or new abstraction is used: name it, and say why the simpler option isn't
enough. Link an ADR if one is needed. Write "None" for straightforward changes. -->

## Cost and performance
<!-- Hot paths and their complexity; I/O and network calls; paid APIs, LLM tokens, cloud
resources; expected load. What you measure before optimizing. "No hot paths affected" is fine. -->

## Risks, compatibility and rollback
<!-- Breaking changes, data migrations, security and privacy, feature flags, how to roll back. -->

## Test strategy
- Unit: <what is tested, where (test file paths), which acceptance criteria>
- Integration: <required: what boundary, where; or: not needed, because ...>

## Steps
<!-- Ordered. One Conventional Commit each. Name the files and tests per step. -->
- [ ] `docs(plans): add plan for <title>`: commit this plan
- [ ] `<type>(<scope>): <description>`: <files>, tests: <test files>
- [ ] `<type>(<scope>): <description>`: <files>, tests: <test files>

## Open questions
<!-- Anything still unresolved, including rejected plan-critic findings with reasons. -->
None.
```
