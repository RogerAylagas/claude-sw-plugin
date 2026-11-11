---
name: release
description: Cut a release or finish a hotfix with the main/develop flow. Computes the next semantic version from Conventional Commits (git-cliff), prepares a release/vX.Y.Z branch with the version bump and CHANGELOG, and opens the PR into main. After it merges, tags the release, publishes GitHub release notes, and merges main back into develop. Use when the user asks to release, cut, tag or publish a version, or to finish a hotfix.
argument-hint: "[prepare|finish|hotfix] [version]"
disable-model-invocation: true
---

# Release

Shared rules: `${CLAUDE_PLUGIN_ROOT}/skills/conventions/SKILL.md`.
Changelog and version come from git-cliff with the repository's `cliff.toml`. Run it as
`uvx --exclude-newer "14 days" git-cliff` (or an installed `git-cliff`), so a release younger than
14 days is never used.

Pick the mode from the argument, or from the situation:

| Situation | Mode |
|---|---|
| On `develop`, or no release PR is open | **prepare** |
| A `release/*` or `hotfix/*` PR into `main` was just merged | **finish** |
| On a `hotfix/*` branch whose fix is committed | **hotfix** (bump, then PR into `main`) |

Tags and GitHub releases are public and hard to take back: confirm the version with the user
before creating them.

## Mode: prepare

1. Clean working tree; `git fetch --tags origin`; `git switch develop && git pull --ff-only`.
2. Check that the latest CI run on `develop` passed (`gh run list --branch develop --limit 1`)
   and that no release PR is already open (`gh pr list --base main`).
3. Last version: `git describe --tags --abbrev=0 --match 'v[0-9]*'`. No tag means a first release.
4. Next version: `git cliff --bumped-version`. Show the user the last version, the proposed one
   and the changes (`git cliff --unreleased --bump`), then confirm with AskUserQuestion (the
   proposed version first, marked "(Recommended)"; alternatives: the other semver bumps). For a
   first release, ask between `v0.1.0` and `v1.0.0`.
   Without git-cliff: apply the rules by hand. A breaking change bumps the major version (minor
   before 1.0.0), `feat` bumps the minor, `fix` and `perf` bump the patch.
5. `git switch -c release/vX.Y.Z`.
6. Bump every version field (see the table below); search the manifests for the old version so
   none is missed.
7. Changelog: if `CHANGELOG.md` exists, `git cliff --unreleased --tag vX.Y.Z --prepend CHANGELOG.md`;
   otherwise `git cliff --tag vX.Y.Z --output CHANGELOG.md`.
8. Run `just check`.
9. Commit `chore(release): vX.Y.Z`, push, and open the PR into `main` with the title
   `chore(release): vX.Y.Z`, the new changelog section as the body, and a note that it must be
   merged with a **merge commit**, not squashed. Watch CI (`gh pr checks --watch`).
10. Stop: a human merges the PR. Then run `/sw:release finish`.

## Mode: hotfix

On `hotfix/<slug>`, after the fix is committed (see `/sw:fix`):

1. `git fetch --tags origin`. The version is the last tag on `main` with the patch number
   increased (for example `v1.4.2` → `v1.4.3`).
2. Bump the version fields and update the changelog as in prepare steps 6-7.
3. Commit `chore(release): vX.Y.Z`, then open the PR into `main` with `/sw:review-pr`
   (merge commit, not squash).
4. After it merges, run `/sw:release finish`.

## Mode: finish

1. `git fetch --tags origin`. Find the release or hotfix PR that was just merged into `main`
   (`gh pr list --base main --state merged --limit 3`) and its merge commit. The version is in the
   release branch name or in the `chore(release): vX.Y.Z` commit.
2. Confirm with the user, then tag the merge commit and push the tag:
   `git tag -a vX.Y.Z -m "vX.Y.Z" <merge-commit>` and `git push origin vX.Y.Z`.
3. Release notes: `git cliff --latest --strip header > <scratchpad>/notes.md`, then
   `gh release create vX.Y.Z --title "vX.Y.Z" --notes-file <scratchpad>/notes.md`.
4. Merge back into `develop` through a dedicated branch. Never open a PR from `main` itself:
   with "delete branch on merge" enabled, GitHub would delete `main` if it isn't protected.
   ```sh
   git switch -c chore/merge-back-vX.Y.Z origin/main
   git push -u origin chore/merge-back-vX.Y.Z
   gh pr create --base develop --title "chore(release): merge vX.Y.Z back into develop" \
     --body "Brings the vX.Y.Z release commit (and any hotfix) back into develop. Merge with a merge commit."
   ```
   If it conflicts with `develop`, merge `origin/develop` into the merge-back branch, resolve the
   conflicts keeping develop's newer work, run `just check`, and push.
5. Report the tag, the release URL and the merge-back PR. A human merges the merge-back PR with
   a merge commit.

## Version fields

| Ecosystem | Where | How |
|---|---|---|
| Python (uv) | `pyproject.toml` `[project] version` | `uv version X.Y.Z` (updates `uv.lock`) |
| Node | `package.json` `version` | `npm version X.Y.Z --no-git-tag-version` (or `pnpm version`) |
| Rust | `Cargo.toml` `[package] version` | `cargo set-version X.Y.Z` (cargo-edit), or edit it and run `cargo update --workspace` |
| C++ | `CMakeLists.txt` `project(... VERSION X.Y.Z)`, `vcpkg.json` `version` | edit both |
| Claude Code plugin | `.claude-plugin/plugin.json` `version` | edit |
| Others | `git grep -n "<old version>"` in manifests | edit |

Tags are always `vX.Y.Z`; version fields hold `X.Y.Z`.
