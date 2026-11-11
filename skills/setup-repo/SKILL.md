---
name: setup-repo
description: Set up a new repository, or retrofit an existing one, for the sw workflow - AGENTS.md and CLAUDE.md, the dependency manager (uv recommended for Python), main + develop branches with develop as default, pre-commit with the language's standard formatters and linters, a CI pipeline (conventions, lint, build, unit and integration tests), CONTRIBUTING.md, PR templates, Dependabot and branch protection. Built-in templates for Python, TypeScript/JavaScript, Rust and C++; other languages are set up from their official tooling. Use when the user asks to set up, bootstrap, initialise or scaffold a repository, or to add the sw workflow to an existing one.
argument-hint: "[language] [project-name]"
disable-model-invocation: true
---

# Set up or retrofit a repository

Paths below are relative to `${CLAUDE_PLUGIN_ROOT}/skills/setup-repo/`. Read
`reference/generic.md` now, and `reference/<language>.md` once the language is known
(`python`, `typescript`, `rust`, `cpp`). Branch and commit rules:
`${CLAUDE_PLUGIN_ROOT}/skills/conventions/SKILL.md`.

Principles: ask before choosing anything the user would care about; never overwrite their files
without showing a diff; never write tool versions from memory, and never use a release younger
than 14 days (the 14-day rule, "Versions" in `reference/generic.md`); confirm before anything
that leaves the machine.

## Step 1: Inspect

Run read-only checks and summarise the findings in a short table:

- Is this a git repository? Any commits? Current branch? Is there a remote (`git remote -v`)?
- Languages present (`pyproject.toml`, `package.json`, `Cargo.toml`, `CMakeLists.txt`, ...).
- Which items from the checklist in `reference/generic.md` already exist.
- Tools available: `git`, `gh` (`gh auth status`; `init-project.sh` needs it to look up release
  dates), `uv`, `just`, and the language's tools (`node`/`pnpm`, `cargo`, `cmake`/`VCPKG_ROOT`).
  Note what's missing and how to install it; don't install system tools without asking. Versions
  that enforce the 14-day rule: uv 0.9.17+, pnpm 10.16+, npm 11.10+, Cargo 1.100+.
- Outdated uv: compare `uv --version` with the newest uv release at least 14 days old
  (`sh "${CLAUDE_PLUGIN_ROOT}/skills/setup-repo/scripts/aged-version.sh" astral-sh/uv`). An older
  uv offers fewer Python versions. Offer `uv self update <that version>`; never a plain
  `uv self update`, which installs the newest release, however young. If uv came from a package
  manager (Homebrew, pip, winget, ...), `uv self update` refuses: offer to update it there, to a
  release at least 14 days old.
- Missing `just`: offer `uv tool install --exclude-newer "14 days" rust-just`. Until it's
  installed, run recipes with `uvx --exclude-newer "14 days" --from rust-just just <recipe>`.
- With a GitHub remote: default branch, whether `develop` exists, branch protection
  (`gh api repos/<o>/<r>/branches/<b>/protection`, 404 = none).

Empty or new directory → **new setup**. Existing code → **retrofit**: same steps, but only add
what's missing, and work on a `chore/sw-setup` branch.

## Step 2: Ask

Use AskUserQuestion (at most 4 questions per call, recommended option first with
"(Recommended)"). Skip anything already known from Step 1.

1. Language (if not detected) and project kind: library or application.
2. Dependency manager, with the recommendation from the language reference (Python: **uv**;
   TypeScript: **pnpm**; Rust: cargo, no question; C++: **vcpkg**).
3. The language-specific choices listed under "Questions to ask" in the language reference
   (version, type checker, lint stack, standard, ...).
4. License (MIT, Apache-2.0, a proprietary "All rights reserved", or none yet). Never pick one
   silently. Get the text with `gh api /licenses/<spdx-id> --jq .body` and fill in year and holder.
5. Project name (lowercase-hyphenated) and one-sentence description, defaulting to the directory
   name. The user can type their own through "Other".
6. GitHub: create the repository if there is no remote (public or private?), and whether to apply
   branch protection (recommended), with how many required approvals (0 for solo projects).
   The private option must say that branch protection on private repositories needs a paid
   GitHub plan (Pro, Team or Enterprise). Name the owner's plan if GitHub returns it:
   `gh api user --jq .plan.name` for a personal account, `gh api orgs/<org> --jq .plan.name` for
   an organisation. It is often `null` (GitHub only reports it to tokens with the `user` scope,
   or to organisation owners), so never rely on it.

For a language without templates, research its current official tooling (formatter, linter,
type checker or analyzer, test runner, package manager) before asking, and follow
"Languages without templates" in `reference/generic.md`.

## Step 3: Render into a staging directory

```sh
sh "${CLAUDE_PLUGIN_ROOT}/skills/setup-repo/scripts/render.sh" \
  --lang <lang> --kind <lib|app> --pm <pm> --name <name> --description "<sentence>" \
  --license "<license name>" [--python-version X.Y | --node-version N | --cxx-standard N] \
  --dest <scratchpad>/sw-staging
```

The script prints every file it rendered. Template conventions: `templates/README.md`.

## Step 4: Merge into the repository

Follow "Rendering and merging" in `reference/generic.md`. Show the user a table first: file,
status (new / identical / differs), proposed action. In a retrofit, let the user choose which
areas to apply (docs, quality hooks, CI, Dependabot, Claude settings) with a multi-select question.

If writing `.claude/settings.json` is refused by the permission system, show the user its content
and ask them to create the file.

## Step 5: Initialise dependencies

```sh
sh "${CLAUDE_PLUGIN_ROOT}/skills/setup-repo/scripts/init-project.sh" \
  --lang <lang> --dir <repo> --kind <lib|app> --pm <pm> --name <name>
```

It installs the dev tools through the package manager, whose rendered setting skips releases
younger than 14 days, creates the lock file, and pins the toolchains (uv and just in CI, Node,
pnpm, Rust, the vcpkg baseline) to the newest releases at least 14 days old. It stops if pnpm or
npm is too old to enforce the rule. If it reports an existing manifest, merge the printed
fragment by hand.

## Step 6: Check the version pins

Don't run `pre-commit autoupdate` and don't move actions to their latest release: both ignore
the 14-day rule. The templates ship hook revs and exact action releases at least 14 days old, and
Dependabot updates them after its cooldown. Note the pins `init-project.sh` chose for the report,
and pass on any warning it printed (for example, Cargo older than 1.100 ignoring the rule).

## Step 7: Verify locally

```sh
git add -A
just fmt            # line breaks depend on the project name
git add -A
SKIP=no-commit-to-branch just check   # SKIP only while still on main/develop before the first commit
```

If `just` isn't installed, use `uvx --exclude-newer "14 days" --from rust-just just`. Fix failures in the generated files
until `just check` passes; never by disabling a check.

Then fill in project-specific details: the layout notes in AGENTS.md and the README description.

## Step 8: Git and GitHub

List every remote-changing action and ask for one confirmation before starting. Then follow
"Git and GitHub, new repository" or "Git and GitHub, existing repository (retrofit)" in
`reference/generic.md`:

- New repository: initial commit on `main` (`chore: initial project setup`), push, create and
  push `develop`, make it the default branch, set merge options, protect `main` and `develop`
  (required check `CI OK`), run `just setup` to install the hooks, and watch the first CI run.
- Retrofit: one commit per area on `chore/sw-setup`, push, and open a PR into `develop` (or the
  default branch). Repository settings only with explicit approval.

If protection fails with HTTP 403 ("Upgrade to GitHub Pro or make this repository public"), the
repository is private on a free plan. Carry on with the other steps, and say in the report that
the local pre-commit hooks still block commits to `main` and `develop`, but nothing on GitHub
does. To get protection: make the repository public or upgrade the plan, then re-run the
protection step.

## Step 9: Report

Summarise what was created or changed, the choices made, the CI status, anything skipped (and
why), and the next step: "Plan your first change with `/sw:plan`."
