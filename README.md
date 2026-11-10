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

## How it fits together

```text
/sw:setup-repo ──▶ /sw:plan ──▶ /sw:implement ──▶ /sw:review-pr ──▶ /sw:release
                       ▲              │
        /sw:fix ───────┘ (bugs: failing test first, smallest fix)
```

- **Plans live in the repository** (`docs/plans/<branch>.md`); their frontmatter (`branch`,
  `status`, `integration_tests`) is the contract between planning and implementation.
- **Two hooks keep Claude on the workflow without blocking it.** At session start Claude is told
  the current branch, its plan and the next step. Before editing code on `main`/`develop`, on a
  badly named branch, or without an approved plan, Claude asks you once per session and branch.
  Documentation edits are never gated, and repositories without `docs/plans/` are not affected.
- **Versions are never written from memory.** Setup lets the package managers resolve the latest
  tools, and `pre-commit autoupdate` pins the hooks.

Setup templates: Python (uv, ruff, mypy, pytest), TypeScript/JavaScript (pnpm or npm, ESLint,
Prettier, Vitest), Rust (cargo, rustfmt, clippy) and C++ (CMake presets, vcpkg, GoogleTest,
clang-format, clang-tidy, sanitizers). Other languages are set up the same way from their
official tooling.

Requirements: `git`; `gh` for GitHub steps; [uv](https://docs.astral.sh/uv/) and
[just](https://just.systems) in generated projects. On Windows, Claude Code runs the hooks with
Git Bash.

The design rationale is in [docs/design.md](docs/design.md).

## Contributing

See [CONTRIBUTING.md](CONTRIBUTING.md) and [AGENTS.md](AGENTS.md).

## License

The plugin is licensed under the [MIT License](LICENSE). The setup templates in
[`skills/setup-repo/templates/`](skills/setup-repo/templates/) are licensed under
[MIT No Attribution](skills/setup-repo/templates/LICENSE), so projects created or updated with
`/sw:setup-repo` don't need to carry this project's copyright notice.
