# Plans

Every non-trivial change starts with a plan in this folder. Claude Code's plan mode writes here
because `.claude/settings.json` sets `"plansDirectory": "docs/plans"`.

- One file per change, named after its branch: `feature/plan-gate-hook` → `feature-plan-gate-hook.md`.
- The frontmatter is a contract read by the `sw` hooks and skills; keep the keys and values exact:

```yaml
---
title: Ask once per session when no approved plan exists
type: feature            # feature | bugfix | hotfix | chore
branch: feature/plan-gate-hook
status: approved         # draft | approved | in-progress | done | abandoned
integration_tests: not-needed   # required | not-needed | undecided
---
```

- Steps are a Markdown checklist (`- [ ]` / `- [x]`), one Conventional Commit per step.
- Plans are committed on their branch, so the PR shows what was planned next to what was built.
