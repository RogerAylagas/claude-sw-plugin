# Contributing to {{PROJECT_NAME}}

## Setup

<!-- sw:include contributing-{{LANG}}.md -->

Then run `just setup` once: it installs the dependencies and the git hooks (pre-commit and
commit-msg). On Windows the justfile runs its recipes in PowerShell.

## Workflow

1. Start from an up-to-date `develop` (`git switch develop && git pull`).
2. For anything non-trivial, write a plan in `docs/plans/` first (see `docs/plans/README.md`).
3. Create a branch following [Conventional Branch](https://conventionalbranch.org) (AI-agent
   prefixes such as `claude/` or `codex/` are not allowed):

   | Prefix | Use for | Branch from | PR into |
   |---|---|---|---|
   | `feature/` | New functionality | `develop` | `develop` |
   | `bugfix/` | Bug fixes | `develop` | `develop` |
   | `chore/` | Docs, dependencies, tooling | `develop` | `develop` |
   | `hotfix/` | Urgent production fixes | `main` | `main`, then merged back into `develop` |
   | `release/vX.Y.Z` | Release preparation | `develop` | `main`, then merged back into `develop` |

   Descriptions use lowercase letters, digits and hyphens: `feature/csv-export`,
   `bugfix/issue-42-empty-cart`.
4. Commit with [Conventional Commits](https://www.conventionalcommits.org/en/v1.0.0/):

   ```text
   feat(export): add CSV export to the orders report
   fix(cart): return zero total for an empty cart
   docs: describe the release process
   feat(api)!: remove the v1 orders endpoint
   ```

   Types: `feat fix perf refactor test docs build ci style chore revert`. Mark breaking changes
   with `!` and a `BREAKING CHANGE:` footer.
5. Run `just check` until it passes.
6. Open a pull request into `develop` (`main` for `hotfix/` and `release/`). The PR title must be a
   Conventional Commit: feature PRs are squash-merged and the title becomes the commit message.

## Tests

- New and changed behavior needs unit tests (`just test`): fast, deterministic, no network.
- Changes that cross a boundary (database, network, file system, external services) also need
  integration tests (`just test-integration`).
- Never skip, weaken or delete tests to get a green build.

## Releases

Maintainers cut releases from `develop`: a `release/vX.Y.Z` branch bumps the version and updates
`CHANGELOG.md` (generated with [git-cliff](https://git-cliff.org) from the commit history), is
merged into `main` and tagged `vX.Y.Z`, then `main` is merged back into `develop`.
