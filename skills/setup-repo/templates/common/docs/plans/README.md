# Plans

Every non-trivial change starts with a plan in this folder. Claude Code's plan mode writes here
because `.claude/settings.json` sets `"plansDirectory": "docs/plans"`.

- One file per change, named after its branch: `feature/csv-export` → `feature-csv-export.md`.
- The frontmatter is a contract read by tools; keep the keys and values exact:

```yaml
---
title: Add CSV export to the orders report
type: feature                   # feature | bugfix | hotfix | chore
branch: feature/csv-export
status: approved                # draft | approved | in-progress | done | abandoned
integration_tests: not-needed   # required | not-needed | undecided
---
```

- Sections: Context, Acceptance criteria, Out of scope, Design, Cost and performance, Risks,
  Test strategy, Steps (a `- [ ]` checklist, one Conventional Commit per step), Open questions.
- Plans are committed on their branch, so each pull request shows what was planned next to what
  was built.
