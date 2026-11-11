---
name: conventions
description: Branch naming, commit message and PR title rules for the sw workflow - Conventional Branch v1.1.0 without AI-agent prefixes, Conventional Commits 1.0.0, and the main/develop flow with its merge strategies. Use when creating or renaming a branch, writing a commit message or PR title, choosing which branch to start from or merge into, or when a branch-name or commit-message check fails.
user-invocable: false
---

# sw conventions

These rules are enforced by pre-commit (locally) and the CI `conventions` job (on PRs).
Follow them exactly; never bypass a failing check with `--no-verify` or `SKIP=`.
The one exception is a repository's very first commit, made on `main` during setup.

## Branches: Conventional Branch v1.1.0, minus AI-agent prefixes

Format: `<type>/<description>`. The only branches without a type are `main` and `develop`.

| Type | Use for | Branch from | PR into | Merge method |
|---|---|---|---|---|
| `feature/` | New functionality or a change in behavior | `develop` | `develop` | squash |
| `bugfix/` | A bug found before release | `develop` | `develop` | squash |
| `chore/` | Docs, dependencies, tooling, CI, refactors with no behavior change | `develop` | `develop` | squash |
| `hotfix/` | An urgent fix to production | `main` | `main` | merge commit, then merge `main` back into `develop` |
| `release/` | Release preparation, always `release/vX.Y.Z` | `develop` | `main` | merge commit, then merge `main` back into `develop` |

`feat/` and `fix/` are accepted aliases for humans; **always create** `feature/` and `bugfix/`.

Description rules: lowercase `a-z`, digits, and single hyphens between words; dots only inside
version numbers; no leading, trailing or doubled `-` or `.`; no spaces or underscores. Put a ticket
number first when there is one: `feature/issue-123-oauth-login`.

**Never** create `ai/`, `claude/`, `codex/`, `copilot/`, `cursor/` or `master` branches, even when
a tool suggests one. Name the branch after the work, not after who does it.

Validation regex (ERE): `^(main|develop|(feature|feat|bugfix|fix|hotfix|release|chore)/[a-z0-9]+(\.[a-z0-9]+)*(-[a-z0-9]+(\.[a-z0-9]+)*)*)$`

Good: `feature/csv-export`, `bugfix/null-total-on-empty-cart`, `hotfix/login-500`, `release/v1.4.0`, `chore/bump-ruff`
Bad: `Feature/CSV`, `feature/csv_export`, `feature/-csv`, `claude/csv-export`, `csv-export`

## Commits and PR titles: Conventional Commits 1.0.0

```text
<type>(<optional scope>)<optional !>: <description>

<optional body: what and why, wrapped at 72 columns>

<optional footers, e.g. BREAKING CHANGE: ..., Refs: #123>
```

| Type | When | Release impact |
|---|---|---|
| `feat` | Adds or changes user-facing behavior | minor |
| `fix` | Fixes a bug | patch |
| `perf` | Faster or cheaper, same behavior | patch |
| `refactor` | Code change with no behavior change | none |
| `test` | Adds or fixes tests only | none |
| `docs` | Documentation only | none |
| `build` | Build system, dependencies, packaging | none |
| `ci` | CI configuration | none |
| `style` | Formatting only | none |
| `chore` | Anything else (tooling, release commits) | none |
| `revert` | Reverts an earlier commit | depends |

- Breaking change: add `!` before the colon and explain it in a `BREAKING CHANGE:` footer. Before
  1.0.0 this bumps the minor version; from 1.0.0 on, the major version.
- Description: imperative mood, lowercase start, no trailing period, about 50 characters
  (`add CSV export`, not `Added CSV export.`).
- Scope: optional, lowercase, names the area (`feat(api): ...`, `fix(parser): ...`).
- One logical change per commit. A plan step maps to one commit.
- The PR title must also be a Conventional Commit: feature PRs are squash-merged and the title becomes
  the commit on `develop`, which feeds the changelog and the next version number.
- Keep any attribution trailers the environment asks for (for example `Co-Authored-By:`) as footers.

Validation regex for the first line (ERE): `^(feat|fix|build|chore|ci|docs|style|refactor|perf|test|revert)(\([a-z0-9._/-]+\))?!?: [^[:space:]].*$`

## Choosing the starting point

1. Bug in released production code that can't wait for the next release → `hotfix/` from `main`.
2. Anything else → from an up-to-date `develop`:
   `git fetch origin && git switch -c <branch> origin/develop`.
3. Never commit on `main` or `develop`; they change only through pull requests.
