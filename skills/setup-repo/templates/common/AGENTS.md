# AGENTS.md

Guidance for AI coding agents (Claude Code, Codex, Copilot, …) and humans working on
**{{PROJECT_NAME}}**: {{DESCRIPTION}}

## Commands

Everything runs through the `justfile`, and CI runs the same recipes: a green `just check` locally
means a green CI. Install just from https://just.systems (or `uv tool install --exclude-newer "14 days" rust-just`).

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

## Dependencies: the 14-day rule

Never add or update to a dependency, tool, hook or action version released less than 14 days ago.
Malicious releases are usually found and pulled within days.

- The package manager enforces it (see the language section above), and Dependabot waits 14 days
  before proposing an update (`.github/dependabot.yml`). Never weaken or remove these settings.
- Toolchains are pinned to releases at least 14 days old: uv and just in `.github/workflows/`,
  plus the language toolchain above. To update one, pick the newest release that is at least
  14 days old. Actions are pinned to exact releases, never to a floating `@vN` tag.
- Don't run `pre-commit autoupdate`: it ignores release age. Dependabot updates the hooks.
- Urgent security fix for a release younger than 14 days: exempt only that package (syntax above),
  with a comment giving the reason and the date it can be removed, and only with the
  maintainers' approval. Remove the exemption once the release is 14 days old.

## Rules for agents

- Read the relevant code and tests before changing anything; reuse existing helpers.
- Make the smallest change that meets the plan; no drive-by refactors.
- Write unit tests for new and changed behavior; add integration tests when a change crosses a
  boundary (database, network, file system, external service, another process).
- Never weaken or skip tests, disable lint or type rules, add ignore comments or use
  `--no-verify` to get a green build.
- Never commit secrets; configuration comes from the environment (see `.env.example` if present).
