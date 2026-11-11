# Contributing to sw

Thanks for helping! This plugin follows the same workflow it teaches.

## Setup

1. Install [uv](https://docs.astral.sh/uv/) and the [GitHub CLI](https://cli.github.com/).
   Optional: [just](https://just.systems) (otherwise use `uvx --exclude-newer "14 days" --from rust-just just`).
2. Install the git hooks: `uvx --exclude-newer "14 days" pre-commit install` (installs both the
   `pre-commit` and `commit-msg` hooks).
3. Try the plugin locally from a Claude Code session:
   `/plugin marketplace add ./` then `/plugin install sw@claude-sw-plugin`.

On Windows, run `just` recipes from Git Bash.

## Workflow

1. Start from an up-to-date `develop`.
2. Plan non-trivial changes first (`/sw:plan`); the plan lives in `docs/plans/`.
3. Create a branch named with [Conventional Branch](https://conventionalbranch.org) rules
   (AI-agent prefixes are not allowed):

   | Prefix | Use for | Branch from | PR into |
   |---|---|---|---|
   | `feature/` (`feat/`) | New functionality | `develop` | `develop` |
   | `bugfix/` (`fix/`) | Bug fixes | `develop` | `develop` |
   | `chore/` | Docs, deps, tooling | `develop` | `develop` |
   | `hotfix/` | Urgent production fix | `main` | `main`, then merge back |
   | `release/vX.Y.Z` | Release preparation | `develop` | `main`, then merge back |

   Description: lowercase letters, digits, hyphens; dots only for versions. Example: `feature/plan-gate-hook`.
4. Commit with [Conventional Commits](https://www.conventionalcommits.org/en/v1.0.0/):

   ```text
   feat(hooks): ask once per session when no approved plan exists
   fix(setup-repo): keep existing .gitignore entries
   docs: explain the plan file contract
   feat(plan)!: rename plan status "ready" to "approved"
   ```

   Types: `feat fix build chore ci docs style refactor perf test revert`.
   Breaking changes use `!` or a `BREAKING CHANGE:` footer.
5. Run `just check` until it passes.
6. Open a PR against `develop` (or `main` for `release/*` and `hotfix/*`). The PR title must be a
   Conventional Commit, because feature PRs are squash-merged and the title becomes the commit.

## Testing expectations

- Hook scripts and helper scripts: add or update a case in `tests/`.
- Skills: add or update an eval case in `evals/` and run it (`just evals`, costs real model calls;
  cases that use Bash need Claude Code's sandbox, so run them on Linux, macOS or WSL2, or with
  the manual **Evals** workflow, which needs an `ANTHROPIC_API_KEY` repository secret).
- Templates: `just test-templates <language>` renders the templates into a temporary project and
  runs its full check.

## Adding a language to `setup-repo`

1. Add `skills/setup-repo/reference/<language>.md` (tools, rationale, last-reviewed date).
2. Add templates under `skills/setup-repo/templates/<language>/`.
3. Extend `tests/templates/smoke.sh` and the CI template matrix.
