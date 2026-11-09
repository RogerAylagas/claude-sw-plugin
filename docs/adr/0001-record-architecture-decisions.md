# 1. Record architecture decisions

- Status: accepted
- Date: 2026-11-09

## Context and problem statement

Decisions about how the plugin works (where plans live, how strict the workflow gate is, which
tools the templates use) need to be traceable, so later changes can see why things are the way
they are.

## Decision

Record significant decisions as Architecture Decision Records in `docs/adr/`, using a short
[MADR](https://adr.github.io/madr/)-style format: context, decision, consequences. Number them
sequentially and never rewrite an accepted ADR; supersede it with a new one.

The initial design decisions are recorded in [docs/design.md](../design.md).

## Consequences

- A decision that changes architecture, a public contract (plan frontmatter, hook behavior,
  command names) or a default tool choice gets an ADR in the same PR.
- Small implementation choices do not need one.
