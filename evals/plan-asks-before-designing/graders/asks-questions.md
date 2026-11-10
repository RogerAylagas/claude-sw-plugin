---
type: llm
focus: trace
---

PASS if, before committing to a design, Claude asks the user clarifying questions (with the
AskUserQuestion tool or in its reply) that cover requirements a rate limiter depends on, such as
limits per client or endpoint, how clients are identified, expected traffic or scale,
deployment (single instance or distributed), or what happens when a limit is hit.

FAIL if Claude presents a finished design or code without asking anything, or asks only generic
questions unrelated to rate limiting.
