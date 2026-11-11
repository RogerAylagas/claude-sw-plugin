# 2. Never use a dependency or tool released less than 14 days ago

- Status: accepted
- Date: 2026-11-11
- Plan: [docs/plans/feature-dependency-cooldown.md](../plans/feature-dependency-cooldown.md)

## Context and problem statement

Supply-chain attacks often ship as a new release of a popular package: a hijacked maintainer
account, a poisoned build or a typosquat. Most are found and yanked within days. Until now the
plugin did the opposite of waiting: setup installed the newest versions of everything,
`pre-commit autoupdate` pinned the newest hooks, and CI installed the newest uv, just, Node and pnpm.

The user asked for a rule: never use a dependency released less than 14 days ago. It covers
generated projects, this repository and toolchains. Urgent security fixes may bypass it only
through an explicit per-package exemption.

## Options considered

1. **Each package manager's own setting, plus Dependabot's cooldown and pinned toolchains.**
   Native gates cover `add`, `install`, lock files and transitive dependencies.
2. **A custom checker in CI** that reads lock files and rejects young versions. It would duplicate
   every package manager's resolver, catch problems only after resolution, and miss `uv add`
   and `pnpm add` on developer machines.
3. **Renovate instead of Dependabot**, using `minimumReleaseAge`. It needs a GitHub App or a
   self-hosted bot. Dependabot is built in and now has `cooldown`.

## Decision

Chosen: option 1. Each mechanism below was verified on 2026-11-10/11.

| Tool | Mechanism | Minimum version | Per-package exemption |
|---|---|---|---|
| uv | `[tool.uv] exclude-newer = "14 days"` ([docs](https://docs.astral.sh/uv/reference/settings/#exclude-newer)); `uvx --exclude-newer "14 days"` for tools | uv 0.9.17 | `exclude-newer-package = { <pkg> = false }` |
| pnpm | `minimumReleaseAge: 20160` (minutes) in `pnpm-workspace.yaml` ([docs](https://pnpm.io/settings/dependency-resolution)) | pnpm 10.16 | `minimumReleaseAgeExclude: [<pkg>]` |
| npm | `min-release-age=14` (days) in `.npmrc` ([docs](https://docs.npmjs.com/cli/v11/using-npm/config#min-release-age)) | npm 11.10 | `min-release-age-exclude` (npm 11.17) |
| Cargo | `[registry] global-min-publish-age = "14 days"` in `.cargo/config.toml` ([docs](https://doc.rust-lang.org/cargo/reference/config.html#registryglobal-min-publish-age)) | Cargo 1.100 | `CARGO_RESOLVER_INCOMPATIBLE_PUBLISH_AGE=allow cargo update -p <crate> --precise <version>` (the lock file keeps it) |
| vcpkg | `builtin-baseline` set to a `microsoft/vcpkg` commit at least 14 days old | — | `overrides` in `vcpkg.json` |
| Dependabot | `cooldown: default-days: 14` on every ecosystem, including `pre-commit` and `vcpkg` ([docs](https://docs.github.com/en/code-security/dependabot/working-with-dependabot/dependabot-options-reference#cooldown)) | — | `cooldown.exclude`. Security updates bypass the cooldown. |
| Toolchains | uv, just, Node, pnpm and Rust are pinned to the newest release at least 14 days old, found by `skills/setup-repo/scripts/aged-version.sh` | — | Pin an older or newer version by hand. |

Pre-commit hooks and GitHub Actions have no native gate. Setup keeps the versions shipped in the
templates, and Dependabot proposes updates after the cooldown. Setup no longer runs
`pre-commit autoupdate`, which ignores release age.

Exemptions are only for urgent security fixes. Each one names a single package, carries a
comment with the reason and the date it can be removed (14 days after the release), and is
removed in a later PR.

## Consequences

- Good: new projects and this repository never pick up a release younger than 14 days through
  their package managers, Dependabot or CI toolchains.
- Good: the gates live in ordinary config files that are easy to read and to remove.
- Bad / accepted trade-offs:
  - Fixes and features arrive 14 days late.
  - pnpm fails to install a dependency that has no release at least 14 days old.
  - A Dependabot security PR for a young version needs a manual exemption.
  - Cargo older than 1.100 silently ignores its setting. Rust projects get a warning until their
    pinned toolchain reaches 1.100, which happens on 2026-11-26, 14 days after its release.
  - Toolchain pins don't update automatically. Dependabot can't update them, so they are
    refreshed by hand with `aged-version.sh`.
- Not covered: runner images and OS packages; Python interpreter patch versions, which are bounded
  only because the pinned uv knows nothing newer than itself; and packages pre-commit installs
  into hook environments with pip.
- Follow-ups: drop the Cargo warning once 1.100 is the oldest toolchain the templates can pin.
  Consider an automated refresh of the toolchain pins.
