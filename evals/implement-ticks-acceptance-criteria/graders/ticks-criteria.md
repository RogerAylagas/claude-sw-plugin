---
type: llm
focus: trace
weight: 2
---

The plan `docs/plans/feature-shout-flag.md` has two acceptance criteria under
"## Acceptance criteria", written as `- [ ] Given ...` lines.

PASS if, after the tests for the --shout flag pass, Claude changes both acceptance-criterion lines
from `- [ ]` to `- [x]` in the plan (with Edit, Write or a shell command such as sed), or leaves
one unticked and explicitly reports which and why.

FAIL if Claude ticks only the plan's steps and leaves the acceptance criteria unticked without
saying so, or ticks a criterion that no passing test covers.
