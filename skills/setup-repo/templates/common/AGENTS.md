# AGENTS.md

Guidance for AI coding agents (Claude Code, Codex, Copilot, …) and humans working on
**{{PROJECT_NAME}}**: {{DESCRIPTION}}

## Commands

Everything runs through the `justfile`, and CI runs the same recipes: a green `just check` locally
means a green CI. Install just from https://just.systems (or `uv tool install rust-just`).

| Command | What it does |
|---|---|
| `just setup` | Install dependencies and git hooks. Run once after cloning. |
| `just fmt` | Format all code. |
| `just lint` | All pre-commit hooks on all files: formatting, linting, file checks, secret scan. |
| `just analyze` | Static analysis (type checker or equivalent). |
| `just build` | Build the project. |
| `just test` | Unit tests. |
| `just test-integration` | Integration tests. |
| `just check` | Everything CI runs. Must pass before opening a pull request. |

<!-- sw:include agents-{{LANG}}.md -->

## Repository layout

| Path | Contents |
|---|---|
| `docs/plans/` | One plan per change (format in `docs/plans/README.md`). Plan mode writes here. |
| `docs/adr/` | Architecture decision records. |
| `.github/workflows/ci.yml` | CI: conventions, lint, build, unit and integration tests. |

## Workflow

- `main` is production; `develop` is the default branch and the target of every PR.
  Never commit to either directly.
- Branches follow [Conventional Branch](https://conventionalbranch.org) without AI-agent prefixes:
  `feature/`, `bugfix/`, `chore/` from `develop`; `hotfix/` from `main`; `release/vX.Y.Z`.
- Commits and PR titles follow [Conventional Commits 1.0.0](https://www.conventionalcommits.org/en/v1.0.0/).
  Feature PRs are squash-merged; release and hotfix PRs use merge commits.
- Non-trivial changes start with a plan in `docs/plans/`; significant decisions get an ADR.

## Rules for agents

- Read the relevant code and tests before changing anything; reuse existing helpers.
- Make the smallest change that meets the plan; no drive-by refactors.
- Write unit tests for new and changed behavior; add integration tests when a change crosses a
  boundary (database, network, file system, external service, another process).
- Never weaken or skip tests, disable lint or type rules, add ignore comments or use
  `--no-verify` to get a green build.
- Never commit secrets; configuration comes from the environment (see `.env.example` if present).
