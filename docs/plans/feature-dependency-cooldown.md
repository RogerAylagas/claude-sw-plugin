---
title: Never use a dependency or tool released less than 14 days ago
type: feature
branch: feature/dependency-cooldown
status: in-progress
integration_tests: required
---

# Never use a dependency or tool released less than 14 days ago

## Context
Malicious releases (hijacked maintainer accounts, typosquats, poisoned updates) are usually found
and yanked within days. A 14-day cooldown on every dependency avoids almost all of them at little
cost. Today `setup-repo` does the opposite: `init-project.sh` installs the newest versions,
Step 6 runs `pre-commit autoupdate` and bumps actions to their latest release, and CI installs
the latest uv, just, Node and pnpm. The user asked for the rule in generated projects, in this
repository and for toolchains, with per-package exemptions only for urgent security fixes.

Verified on 2026-11-10/11 (sources in ADR 0002): uv `exclude-newer = "14 days"` (uv 0.9.17+;
`uvx --exclude-newer "14 days"` works too), pnpm `minimumReleaseAge` (10.16+), npm
`min-release-age` (11.10+; Node 24.22.1 bundles npm 11.19.1), Cargo `global-min-publish-age`
(respected from 1.100, which ships 2026-11-12, so it becomes usable here on 2026-11-26),
Dependabot `cooldown` (security updates bypass it; `pre-commit` and `vcpkg` ecosystems exist, and
the schema in check-jsonschema 0.39.0 accepts all three). vcpkg, pre-commit and GitHub Actions
have no native setting.

## Acceptance criteria
- [ ] Given `aged-version.sh OWNER/REPO`, when it runs, then it prints the newest non-draft,
      non-prerelease release published at least 14 days ago, without a leading `v`; `--prefix P`
      keeps only tags starting with `P`; `--commit BRANCH` prints the newest commit on `BRANCH`
      at least 14 days old; `--days N` changes the age; `SW_NOW=<epoch seconds>` replaces the
      current time (for reproducible tests).
- [ ] Given no matching release or a failing `gh` call, when `aged-version.sh` runs, then it exits
      non-zero with a message naming the repository.
- [ ] Given a generated Python project, then `pyproject.toml` has `[tool.uv] exclude-newer =
      "14 days"`, `uv.lock` records the 14-day span, and the `uv_build` lower bound is a uv
      release at least 14 days old.
- [ ] Given a generated TypeScript project, then with pnpm `pnpm-workspace.yaml` sets
      `minimumReleaseAge: 20160` and `packageManager` names the newest release of the installed
      pnpm major that is at least 14 days old; with npm `.npmrc` sets `min-release-age=14`; and
      `.nvmrc` holds the newest release of the chosen Node major that is at least 14 days old
      (`@types/node` still uses the major).
- [ ] Given a `pnpm` older than 10.16 or an `npm` older than 11.10 on `PATH`, when
      `init-project.sh` runs, then it stops before any install with a message naming the version
      needed (both tools silently ignore the setting otherwise).
- [ ] Given a generated Rust project, then `.cargo/config.toml` sets `global-min-publish-age =
      "14 days"` and `rust-toolchain.toml` pins the newest Rust release at least 14 days old; when
      the `cargo` that runs in the project reports a version older than 1.100, `init-project.sh`
      prints a warning that Cargo ignores the setting.
- [ ] Given a generated C++ project, then `builtin-baseline` is the newest `microsoft/vcpkg`
      `master` commit at least 14 days old.
- [ ] Given any generated project, then its CI installs uv and just at pinned versions at least
      14 days old, `just` recipes run `uvx --exclude-newer "14 days"`, and `dependabot.yml` sets
      `cooldown: default-days: 14` on every ecosystem, including `pre-commit` (and `vcpkg` for C++).
- [ ] Given `/sw:setup-repo`, then it no longer runs `pre-commit autoupdate` or picks the latest
      action releases, and the generated AGENTS.md states the rule and how to add a per-package
      exemption for an urgent security fix.
- [ ] Given this repository, then Dependabot has a 14-day cooldown and a `pre-commit` entry; CI
      pins uv, just, Node and pnpm to releases at least 14 days old and installs Claude Code with
      `npm install --before`; `just update-hooks` is gone; every hook rev and action version in
      this repo **and in `skills/setup-repo/templates/`** is at least 14 days old; and the rules in
      `AGENTS.md`, `skills/setup-repo/reference/generic.md` and `docs/design.md` say how to pick
      versions under the rule (`aged-version.sh`), with `--exclude-newer` on every `uvx` fallback.

## Out of scope
- Runner images and OS packages (compilers, CMake, clang-tidy from apt, git, gh): not ours to pin.
- Python interpreter patch versions: not pinned separately. CI's uv is pinned to a release at
  least 14 days old, and uv only offers the Python builds it knew when it was released.
- Packages that pre-commit installs into hook environments with pip at hook-install time
  (for example `check-jsonschema`'s own dependencies): pre-commit has no age option.
- Automatic updates of toolchain pins (Dependabot can't update `setup-uv`'s `version`, `.nvmrc` or
  `rust-toolchain.toml`): documented manual procedure only.
- Changing already generated repositories: they get the rule through `/sw:setup-repo` (retrofit).
- Making the 14 days configurable.
- The four end-to-end findings from 2026-11-10 (separate bugfix PR).

## Design
### Reused
- `skills/setup-repo/scripts/init-project.sh` `replace()`, `need()`, `die()`: version pins are
  resolved where `{{UV_BUILD_REQ}}` and `{{VCPKG_BASELINE}}` already are; the Node major is
  already read from `.nvmrc` for `@types/node`.
- `skills/setup-repo/scripts/render.sh`: unknown `{{...}}` markers are left for `init-project.sh`;
  `.sw-if-pm-<pm>` files make the pnpm and npm config files conditional.
- `templates/_fragments/dependabot-actions.yml`: shared Dependabot entry, included by every language.
- `tests/templates/smoke.sh` and the CI `templates` matrix: render + init + `just check` for all
  seven variants exercise every native setting end to end.
- `tests/hooks/run.sh`: test runner style (stub inputs, `ok`/`FAIL` lines, counts) for the new tests.
- `gh` (already required by setup) and its built-in jq: release dates without `jq`, `date` or `curl`.

### Changes
| File | Change | Why |
|---|---|---|
| `skills/setup-repo/scripts/aged-version.sh` | new | One place that finds "newest release at least N days old" for uv, just, pnpm, Node, Rust and vcpkg (AC 1-2) |
| `skills/setup-repo/scripts/init-project.sh` | edit | One `version_at_least` helper checks the real `pnpm`, `npm` and `cargo` first (AC 5-6); then resolve `{{UV_VERSION}}`, `{{JUST_VERSION}}`, `{{UV_BUILD_REQ}}`, `packageManager` (prefix = installed pnpm major), exact `.nvmrc`, `{{RUST_VERSION}}`, vcpkg baseline with `aged-version.sh` (AC 3-8) |
| `templates/python/pyproject.toml` | edit | `[tool.uv] exclude-newer = "14 days"` (AC 3) |
| `templates/typescript/pnpm-workspace.yaml.sw-if-pm-pnpm`, `.npmrc.sw-if-pm-npm` | new | pnpm and npm age settings (AC 4) |
| `templates/rust/.cargo/config.toml`, `rust-toolchain.toml` | new / edit | Cargo age setting; `channel = "{{RUST_VERSION}}"` (AC 6) |
| `templates/*/.github/workflows/ci.yml` | edit | `setup-uv` `version`, `setup-just` `just-version`; Rust installs the pinned toolchain with `rustup` instead of `dtolnay/rust-toolchain@stable` (AC 8) |
| `templates/{cpp,rust,typescript}/justfile` | edit | `uvx --exclude-newer "14 days" pre-commit` (AC 8) |
| `templates/*/.github/dependabot.yml`, `_fragments/dependabot-actions.yml`, `_fragments/dependabot-precommit.yml` (new) | edit / new | `cooldown`, `pre-commit` entry, `vcpkg` entry for C++ (AC 8) |
| `templates/**` and `_fragments/**` hook revs and action tags | edit | Downgrade any version younger than 14 days (AC 10) |
| `templates/*/.pre-commit-config.yaml` | edit | Header comment: Dependabot updates the revs, don't run `autoupdate` (AC 9) |
| `templates/common/AGENTS.md`, `_fragments/agents-*.md`, `_fragments/contributing-*.md` | edit | State the rule, the exemption syntax per tool and how to update toolchain pins (AC 9) |
| `skills/setup-repo/SKILL.md`, `reference/{generic,python,typescript,rust,cpp}.md`, `templates/README.md` | edit | Step 6 becomes "check the pins"; versions section explains the rule, the pins and exemptions; `uvx` fallback gets `--exclude-newer` (AC 9-10) |
| `tests/scripts/run.sh` | new | Offline tests with stub `gh`/`pnpm`/`npm`/`cargo` on `PATH`, plus live `aged-version.sh` tests at a fixed `SW_NOW` (AC 1-2, 5-6) |
| `justfile`, `.github/workflows/ci.yml` | edit | `test-scripts` recipe and CI job (with `GH_TOKEN`, added to `CI OK`) in step 3; `GH_TOKEN` for the templates job in step 4 |
| `.github/workflows/evals.yml`, `.github/dependabot.yml`, `.pre-commit-config.yaml` | edit | This repo's own tools (AC 10) |
| `AGENTS.md`, `README.md`, `CONTRIBUTING.md`, `docs/design.md` | edit | Rule text, how to update toolchain pins, `uvx` fallbacks; design.md gets a note where it says "latest versions" (AC 10) |
| `docs/adr/0002-dependency-cooldown.md` | new | Record the policy, the per-tool mechanisms and the known gaps |

### Patterns and decisions
- Prefer each package manager's own gate over our own checks: they also cover `uv add`,
  `pnpm add` and transitive dependencies, which a script could not.
- Toolchain pins are resolved at setup time by `aged-version.sh` instead of hard-coding versions
  in templates: templates stay version-free for toolchains, and every new project starts from the
  newest eligible release.
- Release lines: "newest" means newest by publish date within a tag prefix. pnpm uses the
  installed major as the prefix (pnpm ships patches for older majors), Node the chosen major;
  uv, just and Rust publish a single line.
- Version checks look at the binaries that will actually run (`cargo --version` inside the project,
  so rustup's `rust-toolchain.toml` and non-rustup installs are both covered), not at the pins.
- No new abstraction beyond the one script and one helper. ADR 0002 records the decision.

## Cost and performance
No hot paths. `init-project.sh` makes 2-5 extra GitHub API calls per setup (authenticated limit:
5,000 per hour). CI: the templates job makes the same calls per variant. Waiting 14 days for new
releases is the intended cost; security fixes skip it through Dependabot or an explicit exemption.

## Risks, compatibility and rollback
- Until Rust 1.100 is 14 days old (2026-11-26), Rust projects pin 1.99.x, where Cargo ignores the
  setting: `init-project.sh` warns, and Dependabot's cooldown still applies.
- pnpm's explicit `minimumReleaseAge` is strict: a dependency with no release older than 14 days
  fails to install. Intended; the exemption procedure covers it.
- A Dependabot security PR for a version younger than 14 days fails the package manager's gate.
  The documented fix is a commented per-package exemption in that PR, removed after 14 days.
- Toolchain pins age without automatic updates; the procedure is in the generated AGENTS.md.
- GitHub release dates can differ by minutes from registry publish dates; irrelevant at 14 days.
- The live `aged-version.sh` tests depend on GitHub keeping old releases; a deleted release would
  need the expected value updated.
- Rollback: revert the PR. Projects generated in the meantime keep their settings, which are
  ordinary config entries that can be deleted.

## Test strategy
- Unit (offline, `tests/scripts/run.sh`): stub `gh`, `pnpm`, `npm` and `cargo` scripts on `PATH`.
  `aged-version.sh` failure paths (`gh` fails, empty result) exit non-zero with the repository in
  the message (AC 2); `init-project.sh` stops on pnpm 10.15 and npm 11.9 before installing
  anything (AC 5) and warns on cargo 1.99 (AC 6).
- Integration (required):
  - `tests/scripts/run.sh` live part: `aged-version.sh` with a fixed past `SW_NOW` returns known
    exact versions for `casey/just`, `nodejs/node --prefix v24.`, `pnpm/pnpm --prefix v10.` and
    `microsoft/vcpkg --commit master` (AC 1). Runs in CI with `GH_TOKEN`.
  - CI `templates` matrix (7 variants) renders, initialises and runs each generated project's
    `just check` with the new settings active; `smoke.sh` also checks the generated files for the
    settings and pins in AC 3-8. `just lint` validates every `dependabot.yml` against its schema.

## Steps
- [x] `docs(plans): add plan for the 14-day dependency rule`: this plan
- [x] `docs(adr): record the 14-day dependency rule`: `docs/adr/0002-dependency-cooldown.md`
- [ ] `feat(setup-repo): find releases at least 14 days old`: `scripts/aged-version.sh`,
      `tests/scripts/run.sh`, `justfile` (`test-scripts`), CI `test-scripts` job with `GH_TOKEN`
      added to `CI OK`; tests: `tests/scripts/run.sh`
- [ ] `feat(setup-repo): enforce the 14-day rule in generated projects`: templates (pyproject,
      pnpm/npm config, Cargo config, `rust-toolchain.toml`, CI, justfiles), `init-project.sh`,
      `GH_TOKEN` for the CI templates job; tests: `tests/scripts/run.sh` (version checks),
      `tests/templates/smoke.sh` checks
- [ ] `feat(setup-repo): add Dependabot cooldown and pre-commit updates`: Dependabot templates and
      fragments, pre-commit config comments, downgrade template revs and action tags younger than
      14 days; tests: `just lint` schema check, smoke
- [ ] `docs(setup-repo): document the 14-day rule and exemptions`: `SKILL.md`, references,
      `templates/README.md`, AGENTS and CONTRIBUTING fragments
- [ ] `ci: apply the 14-day rule to this repository`: `.github/`, `justfile`,
      `.pre-commit-config.yaml`, `AGENTS.md`, `README.md`, `CONTRIBUTING.md`, `docs/design.md`

## Open questions
- No eval for the `setup-repo` text change (Step 6 no longer runs `autoupdate`). The skill is
  user-invoked only and its behavior lives in the scripts, which the tests above cover; an eval
  would have to create real GitHub repositories. Plan-critic finding accepted as a known gap.
- Plan-critic (2026-11-11): REVISE with 9 findings; all applied above. npm in CI and the
  Dependabot schema were checked and are fine (see Context).
