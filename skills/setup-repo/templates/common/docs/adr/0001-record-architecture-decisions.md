# 1. Record architecture decisions

- Status: accepted
- Date: {{DATE}}

## Context and problem statement

Decisions about architecture, public contracts and technology choices need to stay traceable,
so later changes can see why things are the way they are.

## Decision

Record significant decisions as Architecture Decision Records in `docs/adr/`, in a short
[MADR](https://adr.github.io/madr/)-style format: context, options, decision, consequences.
Number them sequentially. Never rewrite an accepted ADR; supersede it with a new one.

## Consequences

- A change to architecture, a public contract (API, schema, file format, CLI) or a default
  technology gets an ADR in the same pull request.
- Small implementation choices don't need one.
