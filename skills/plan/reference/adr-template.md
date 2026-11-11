# ADR template

Architecture Decision Records live in `docs/adr/NNNN-<short-title>.md`, numbered sequentially
(look at the highest existing number). Write one when a change alters architecture, a public
contract (API, schema, file format, CLI), or a default technology choice. Never rewrite an
accepted ADR: supersede it with a new one and update the old one's status line.

---

```markdown
# <NNNN>. <Decision title in a few words>

- Status: proposed | accepted | superseded by [NNNN](NNNN-title.md)
- Date: <YYYY-MM-DD>
- Plan: [docs/plans/<file>.md](../plans/<file>.md)

## Context and problem statement
<!-- The forces at play: requirements, constraints, what triggered the decision. -->

## Options considered
1. <Option A>: <one-line summary>
2. <Option B>: <one-line summary>

## Decision
Chosen: <option>, because <reasons tied to the context>.

## Consequences
- Good: <...>
- Bad / accepted trade-offs: <...>
- Follow-ups: <...>
```
