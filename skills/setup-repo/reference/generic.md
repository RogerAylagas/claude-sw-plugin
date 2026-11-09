# Repository setup: language-independent reference

Last reviewed: 2026-11-09. Re-check tool recommendations against official docs if this is more
than six months old.

## What every repository gets

| Item | File(s) | Why |
|---|---|---|
| Agent instructions | `AGENTS.md`, `CLAUDE.md` (`@AGENTS.md`) | One source of truth for every coding agent; Claude Code reads CLAUDE.md, which imports AGENTS.md. |
| Contributor guide | `CONTRIBUTING.md` | Setup, branch and commit rules, PR flow, test expectations. |
| README, license | `README.md`, `LICENSE` | Ask for the license; never pick one silently. |
| Task runner | `justfile` | One definition of setup/fmt/lint/analyze/build/test/test-integration/check, used by humans, agents and CI. |
| Quality hooks | `.pre-commit-config.yaml` | Formatting, linting, file hygiene, secret scan (gitleaks), CI-config validation, Conventional Commits (commit-msg), Conventional Branch + no direct commits to main/develop. |
| CI | `.github/workflows/ci.yml` | Conventions (PRs), lint, build, unit and integration tests; a single `CI OK` job for branch protection. |
| Dependency updates | `.github/dependabot.yml` | Weekly, into `develop`, Conventional Commit messages (`chore(deps): ...`). |
| PR and issue templates | `.github/pull_request_template.md`, `.github/ISSUE_TEMPLATE/` | PRs link their plan; bug reports capture severity (hotfix or not). |
| Line endings, editor | `.gitattributes` (LF), `.editorconfig` | Identical bytes on Windows, macOS, Linux. |
| Ignore rules | `.gitignore` | Language artifacts, secrets (`.env`), OS/editor files. |
| Claude Code project settings | `.claude/settings.json` | `plansDirectory: docs/plans` so plan mode writes into the repo; allow `just *`. |
| Plans and ADRs | `docs/plans/README.md`, `docs/adr/0001-record-architecture-decisions.md` | The plan contract used by `/sw:plan` and `/sw:implement`; decision records. |
| Changelog config | `cliff.toml` | git-cliff turns Conventional Commits into CHANGELOG.md and the next version. |
| Smoke tests | `tests/unit/`, `tests/integration/` | CI is green from the first push; real tests replace them. |

Optional, ask when relevant: `.env.example` (applications that read configuration from the
environment), `CODEOWNERS` (teams), CodeQL (`github/codeql-action`) for public or security-sensitive
projects.

## Rendering and merging

1. Render into a staging directory in the scratchpad, never into the repository:
   `sh "${CLAUDE_PLUGIN_ROOT}/skills/setup-repo/scripts/render.sh" --lang <lang> --dest <staging> --name <name> ...`
2. For every rendered file compare with the repository:
   - missing → copy it;
   - identical → nothing to do;
   - different → show a short diff and ask: keep theirs, take ours, or merge (merge by hand,
     keeping their content and adding what's missing).
   Never overwrite a file the user has without asking.
3. Run `init-project.sh` in the repository **after** copying (it needs the manifest templates in
   place). When a manifest already existed, it only adds the dev tools and prints what to merge.
4. Fill in project-specific text: AGENTS.md layout notes, README description.
5. Format once (`just fmt`), because line breaks depend on the project name; then run
   `just check` until it passes.

## Versions: never from memory

- pre-commit hooks: `uvx pre-commit autoupdate` after rendering.
- Dev dependencies: added by the package manager (`init-project.sh`), so they resolve to the
  latest release and are pinned in the lock file.
- GitHub Actions: for each `uses: owner/repo@vN` in `.github/workflows/`, check the latest release
  (`gh api repos/owner/repo/releases/latest --jq .tag_name`) and update the major version. Use a
  full tag when the action has no floating major tag (`gh api repos/owner/repo/git/ref/tags/vN`
  returns 404). Dependabot keeps them current afterwards.
- Language version: see the language reference.

## Git and GitHub, new repository

Confirm with the user before anything that leaves the machine (creating a repo, pushing, changing
settings), listing exactly what will happen.

```sh
git init -b main                     # or: git branch -m master main
git add -A
SKIP=no-commit-to-branch git commit -m "chore: initial project setup"   # the only direct commit to main
gh repo create <owner>/<name> --private --source . --remote origin      # if there is no remote; ask public/private
git push -u origin main
git switch -c develop && git push -u origin develop
gh repo edit --default-branch develop --enable-squash-merge --enable-merge-commit \
  --enable-rebase-merge=false --delete-branch-on-merge
gh api -X PATCH repos/<owner>/<name> -f squash_merge_commit_title=PR_TITLE \
  -f squash_merge_commit_message=COMMIT_MESSAGES
just setup                           # installs the git hooks
```

Branch protection for `main` and `develop` (requires admin rights; private repositories need a
paid GitHub plan; ask whether to require approvals, 0 for solo projects):

```sh
for branch in main develop; do
gh api -X PUT "repos/<owner>/<name>/branches/$branch/protection" --input - <<'JSON'
{
  "required_status_checks": { "strict": true, "contexts": ["CI OK"] },
  "enforce_admins": false,
  "required_pull_request_reviews": { "required_approving_review_count": 0 },
  "restrictions": null,
  "allow_force_pushes": false,
  "allow_deletions": false
}
JSON
done
```

Then watch the first CI run on `develop` (`gh run list --branch develop`, `gh run watch`).
GitHub occasionally fails a brand-new repository's first run without creating any jobs; if the
run shows zero jobs, re-run it once (`gh run rerun <id>`) before investigating.

## Git and GitHub, existing repository (retrofit)

- Work on a branch, `chore/sw-setup`, created from `develop` (or from the default branch if
  `develop` doesn't exist yet), and open a PR. Group the changes into one commit per area:
  `docs: add AGENTS.md and contributing guide`, `build: add pre-commit hooks and justfile`,
  `ci: add CI workflow and dependabot`, `chore: add Claude Code project settings`.
- Creating `develop`, changing the default branch, merge settings and branch protection change how
  the whole team works: list them and ask before doing any of them.
- If `main` is called `master`, propose renaming it (`gh api -X POST repos/<o>/<r>/branches/master/rename -f new_name=main`)
  but don't do it without explicit approval.

## Squash vs merge commits

Feature, bugfix and chore PRs are squash-merged, so `develop` gets one Conventional Commit per PR
(the PR title). Release and hotfix PRs into `main`, and the merge-back from `main` into `develop`,
use merge commits so the branches keep a shared history. That is why the repository allows both
methods and disables rebase merging.

## Languages without templates

Follow the same structure by hand: same files, same justfile recipe names, same CI shape (the
`conventions` job and `CI OK` job are language-independent: copy them from any rendered CI file).
Choose the tools from the language's official documentation at setup time: its standard
formatter, linter, type checker or static analyzer, test runner, package manager and lock file.
Prefer pre-commit hooks published by the tools themselves, or `language: system` hooks calling
the project's own tools.
