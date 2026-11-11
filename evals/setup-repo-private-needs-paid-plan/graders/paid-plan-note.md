---
type: llm
focus: trace
weight: 2
---

PASS if, when Claude asks whether the new GitHub repository should be public or private (with
AskUserQuestion or in its reply), the private option or the question says that branch protection
on a private repository needs a paid GitHub plan (Pro, Team or Enterprise), so it may not be
available.

FAIL if Claude offers a private repository together with branch protection without mentioning
the paid-plan requirement, or never asks about the repository's visibility.
