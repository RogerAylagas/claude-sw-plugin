# AGENTS.md

Guidance for AI coding agents (Claude Code, Codex, Copilot, …) and humans working on **sw**,
a Claude Code plugin that guides the software lifecycle: repo setup → planning → implementation
→ review & PR → release. Design rationale: [docs/design.md](docs/design.md).

## Repository map

| Path | What lives there |
|---|---|
| `.claude-plugin/plugin.json` | Plugin manifest (name `sw`, so skills are `/sw:<skill>`). |
| `.claude-plugin/marketplace.json` | This repo is its own marketplace (`claude-sw-plugin`). |
| `skills/<name>/SKILL.md` | One skill per workflow. Details go in `reference/`, files to copy in `templates/`, deterministic helpers in `scripts/`. |
| `agents/*.md` | Subagents (`plan-critic`, `code-reviewer`). |
| `hooks/hooks.json`, `hooks/scripts/` | Soft workflow gate and session context (POSIX sh). |
| `tests/` | Hook tests and template smoke tests. |
| `evals/` | `claude plugin eval` cases. They cost real model calls: run on demand only. |
| `docs/plans/`, `docs/adr/` | Plans for changes to this repo, and architecture decision records. |

There is deliberately no `CLAUDE.md` here: a `CLAUDE.md` at a plugin root is never loaded as context
(the validator warns about it), and Claude Code reads `AGENTS.md` directly when no `CLAUDE.md` exists.

## Commands

Use the `justfile`; CI runs the same recipes. On Windows run them from Git Bash.
If `just` is not installed, use `uvx --from rust-just just <recipe>` (needs [uv](https://docs.astral.sh/uv/)).

| Command | What it does |
|---|---|
| `just check` | Lint + validate + hook tests. Must pass before a PR. |
| `just lint` | `pre-commit run --all-files` (formatting, YAML/JSON checks, shellcheck, secrets). |
| `just validate` | `claude plugin validate . --strict`. |
| `just test-hooks` | Tests for `hooks/scripts/` (CI runs them on Linux, macOS and Windows). |
| `just test-templates <lang> [lib\|app] [pm]` | Renders a setup-repo template, initialises it and runs its own `just check`. Needs that language's toolchain; CI runs every variant. |
| `just evals` | Behavior evals with `claude plugin eval`. Real model calls, billed: run before releases, not on every change. Cases that use Bash need Claude Code's sandbox (Linux, macOS, WSL2). |

## Conventions (enforced by pre-commit and CI)

- **Branches** — [Conventional Branch](https://conventionalbranch.org) without AI-agent prefixes:
  `main`, `develop`, or `feature|feat|bugfix|fix|hotfix|release|chore/<lowercase-hyphenated-description>`.
  Never `claude/…`, `ai/…`, `codex/…`, `copilot/…`, `cursor/…`, or `master`.
- **Commits and PR titles** — [Conventional Commits 1.0.0](https://www.conventionalcommits.org/en/v1.0.0/):
  `type(scope)!: description`, types `feat fix build chore ci docs style refactor perf test revert`.
- **Flow** — `main` is production, `develop` is the default branch and PR target.
  `feature/*`, `bugfix/*`, `chore/*` → PR to `develop` (squash merge, PR title becomes the commit).
  `release/vX.Y.Z` and `hotfix/*` → PR to `main` (merge commit), then merge `main` back into `develop`.
- Never commit directly to `main` or `develop`; never use `--no-verify`.

## Rules for changing the plugin

- Keep each `SKILL.md` under 500 lines; move detail into `reference/` files and link them.
  Put trigger phrases first in `description` (`description` + `when_to_use` are cut at 1,536 chars).
- Reference bundled files as `${CLAUDE_PLUGIN_ROOT}/...` in skill text. It is substituted inline,
  it is **not** an environment variable inside Bash commands. Never write state there; use
  `${CLAUDE_PLUGIN_DATA}`.
- Hook scripts: POSIX `sh` + `git`, `sed`, `awk`, `grep` only (no `jq`, Python or Node). They must
  work in Git Bash on Windows, Linux and macOS. The gate is **soft**: never exit 2; use
  `permissionDecision: "ask"` at most.
- The branch and commit rules are defined in `skills/conventions/SKILL.md`. If you change them,
  update every copy in the same PR: `hooks/scripts/`, the setup templates (pre-commit config and CI
  `conventions` job), and this repo's `.pre-commit-config.yaml` and `.github/workflows/ci.yml`.
- Never write tool or action versions from memory into templates: look them up
  (`gh api repos/<owner>/<repo>/releases/latest`, `pre-commit autoupdate`).
- Every behavior change needs a test (hooks, scripts) or an eval case (skills).
