# sw — software lifecycle workflows for Claude Code

`sw` is a Claude Code plugin that makes Claude work like a disciplined engineer, from an empty
repository to a tagged release:

| Command | What it does |
|---|---|
| `/sw:setup-repo` | Sets up a new repo, or adds what's missing to an existing one: `AGENTS.md` + `CLAUDE.md`, dependency manager (uv recommended for Python), `main` + `develop` branches, pre-commit, CI, `CONTRIBUTING.md`, PR templates, branch protection. |
| `/sw:plan` | Asks the questions needed to pin down a change, then writes a plan in `docs/plans/`: acceptance criteria, minimal design that reuses existing code, cost notes, test strategy, and one commit per step. |
| `/sw:implement` | Finds the approved plan (or routes to planning), creates the branch, writes tests from the acceptance criteria, implements step by step, and runs the same checks as CI. |
| `/sw:fix` | Bug-fix path: reproduce with a failing test, find the root cause, make the smallest fix. |
| `/sw:review-pr` | Independent review of the diff against the plan, then opens the PR and watches CI. |
| `/sw:release` | Computes the next version from Conventional Commits, prepares the release branch and changelog, tags, and merges back. |

Conventions used everywhere: [Conventional Commits 1.0.0](https://www.conventionalcommits.org/en/v1.0.0/)
and [Conventional Branch](https://conventionalbranch.org) (without AI-agent prefixes).
`main` is production; `develop` is the default branch and PR target.

## Install

In Claude Code:

```text
/plugin marketplace add RogerAylagas/claude-sw-plugin
/plugin install sw@claude-sw-plugin
```

## Status

Under active development; see [docs/design.md](docs/design.md) for the design and build plan.

## Contributing

See [CONTRIBUTING.md](CONTRIBUTING.md) and [AGENTS.md](AGENTS.md).
