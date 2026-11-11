# sw plugin — design rationale & v1 build plan

> This is the design review and build plan approved on 2026-11-09, before any code was written.
> It explains *why* the plugin works the way it does. When the code and this document disagree,
> the code wins; update this document in the same PR.

## Context
The goal is one Claude Code plugin that covers the whole software lifecycle: repo setup → planning → implementation. It also covers bug fixes, review/PR, release, and retrofitting existing repos. The original proposal had three phases (setup, planning, implementation). Part 1 records what was missing from it and what was changed. Part 2 is the v1 build plan.

Decisions made by the project owner:
- Built-in templates for **Python, TypeScript/JS, Rust, C++**. Any other language: look up its tooling at setup time.
- Extra workflows: **Retrofit existing repo, Bug-fix path, Review & PR, Release** (all four).
- Plan enforcement: **soft reminder** (warn or ask, never hard-block).
- Branching: **`main` = production**, **`develop` = default branch and PR target**.
- **Conventional Commits v1.0.0**.
- **Conventional Branch v1.1.0** naming **without** the AI-agent prefixes (`ai/ claude/ codex/ copilot/ cursor/`).

---

## Part 1 — Feedback on the proposed phases

### Cross-cutting (the biggest gaps)
1. **The handoff between planning and implementation isn't defined.** Implementation step 1 ("check if there is a plan") only works if plans live somewhere predictable. By default, Claude Code's plan mode saves plans to `~/.claude/plans/` with random names. Those files are outside the repo and can't be matched to a feature. → Store plans in the repo at `docs/plans/<slug>.md`, with frontmatter (`branch`, `type`, `status: draft|approved|in-progress|done`). Setup sets `"plansDirectory": "docs/plans"` in the project's `.claude/settings.json` so plan mode writes there. The plan skill renames the file and adds the frontmatter once the plan is approved.
2. **Define each check command once.** AGENTS.md, CONTRIBUTING.md, pre-commit, CI and Claude should all run the same commands. → A task runner (`justfile`, which works on Windows too) with `setup / fmt / lint / build / test / test-integration / check`. CI calls `just check`, so local runs and CI can't drift apart.
3. **Skills are advisory; hooks are deterministic.** Use hooks for the few rules that matter (branch guard, plan reminder). Skill text handles everything else.
4. **Your planning rules can conflict.** "Use design patterns" and "best architecture" pull against "change as little code as possible". → Write an explicit precedence order into the plan skill: **correctness → consistency with the existing codebase → minimal change → simplicity (KISS/YAGNI) → pattern or architecture purity**. Use a pattern only when it solves a problem that exists today. Name it in the plan and say why a simpler option wasn't enough.
5. **"Read the standards at creation time" needs a limit.** Researching every language from scratch on every run is slow, costs tokens, and gives different results each time. → Ship a short, curated reference per language (tool choices, rationale, last-reviewed date). At setup time, get the **latest versions from the tools themselves** (`pre-commit autoupdate`, `uv add --dev`, `pnpm add -D`, `cargo add`), never from model memory. Search the web only for uncovered languages or stale references. *(Superseded in part by [ADR 0002](adr/0002-dependency-cooldown.md): versions now come from the newest release at least 14 days old, and `pre-commit autoupdate` is no longer used.)*
6. **Scale the process to the task.** A typo shouldn't need a full plan. Small bug fixes take the shorter `fix` route.

### Repo setup (bootstrap)
| Your item | Change / addition |
|---|---|
| (1) AGENTS.md | Keep it, and add a `CLAUDE.md` that holds just `@AGENTS.md`. Claude Code only reads AGENTS.md when there is no CLAUDE.md. The import is the documented portable approach and the one the docs advise on Windows. Keep AGENTS.md short: commands, conventions, architecture map, testing rules, "never do" list. |
| (2) Dependency manager | Ask, with a recommendation per language: Python → **uv**; TS/JS → **pnpm** (npm or bun as alternatives); Rust → **cargo** (no question needed); C++ → **CMake + vcpkg manifest mode** (Conan 2 as the alternative). Also pin the toolchain: `.python-version`, `engines`/`.nvmrc`, `rust-toolchain.toml`, CMake minimum version. |
| (3) develop default | Order matters: the initial commit goes on `main`, then push, then create and push `develop`, then `gh repo edit --default-branch develop`. **Add branch protection** for `main` and `develop`: PR required, CI must pass, no force-push. This needs admin rights, and private repos need GitHub Pro/Team for this. Rename the local `master` to `main`. |
| (4) pre-commit | **pre-commit works for every language**, so use it for all four. That means one tool and one CI step. Common hooks: whitespace/EOF, YAML/TOML/JSON checks, merge-conflict markers, large files, mixed line endings, **gitleaks** (secrets), `no-commit-to-branch [main, develop]`, **commit-message + branch-name checks** (commit-check, or a local regex hook as fallback). Per language: Python ruff check+format + type checker; TS ESLint+Prettier or Biome + `tsc --noEmit`; Rust rustfmt + clippy `-D warnings`; C++ clang-format (clang-tidy runs in CI because it needs `compile_commands.json`). |
| (5) CI | GitHub Actions. Jobs: `lint` (pre-commit, cached) → `build` (real for C++/Rust/TS, placeholder when there's nothing to build) → `unit` → `integration`. Add: PR checks on commit messages and branch name (hooks can be skipped locally), least-privilege `permissions`, `concurrency` cancel-in-progress, dependency caching, version matrix, coverage report. C++ gets a sanitizer job (ASan/UBSan). **Dependabot** targets `develop`. |
| (6) CONTRIBUTING.md | Cover setup, branch and commit rules (with examples), the PR flow (`feature/* → develop`, `release/* → main`, hotfix), how to run `just check`, and what tests are expected. |
| **Missing** | `.gitignore`, **`.gitattributes` (`* text=auto eol=lf`, which matters on Windows)**, `.editorconfig`, README, LICENSE (ask), `.env.example` · `tests/unit` + `tests/integration` with a **smoke test so CI is green from the first push** · PR template (links the plan and has a checklist), issue templates · `.claude/settings.json` (plansDirectory, permission allowlist for `just *`) · `docs/plans/`, `docs/adr/` · `cliff.toml` (changelog) · first conventional commit, push, and confirm CI is green. |
| **Idempotent** | Setup never overwrites an existing file without showing a diff and asking. This is what lets **retrofit and setup be one skill**: setup is just retrofit on an empty repo. |

### Planning
| Your item | Change / addition |
|---|---|
| (1) Ask questions | **Read the code first**, then ask only what the code can't answer. Ask in batches with AskUserQuestion, with a recommended option for each. Always cover **non-functional requirements**: scale and load, latency, budget, security, compatibility. Without those, rules (3) and (4) are guesswork. |
| (2) Patterns, (3) Architecture | Keep them, but apply the precedence order above. **Reuse comes first**: list the existing functions and modules the plan will use. Significant architecture decisions get an **ADR** (`docs/adr/`, MADR format). |
| (4) Cost | Optimize hot paths, not everything. State the complexity of hot paths and flag the real cost drivers: N+1 queries, external API or LLM calls, cloud egress, cold starts. Measure before optimizing. |
| (5) Minimal changes | Keep. The plan lists every file it touches and explains why. The plan reviewer flags anything not traceable to a requirement. |
| **Missing** | **Testable acceptance criteria** (Given/When/Then), which feed straight into the unit tests · **out of scope** · risks, breaking changes, migration, rollback · **test strategy, including whether integration tests are needed, decided here** · ordered steps, **each one a single conventional commit** · branch name (Conventional Branch) · **user approval gate** · for medium or large plans, an independent `plan-critic` subagent checks for over-engineering, missed reuse, and changes beyond the minimum before the user sees the plan. |

### Implementation
| Your item | Change / addition |
|---|---|
| (1) Check for a plan | Look for a plan in `docs/plans/` with `status: approved` that matches the branch or request. If none exists, route to planning: Claude can switch to plan mode with user approval; otherwise ask the user to press Shift+Tab or use `/plan`. |
| (2) Implement | **Before coding:** clean tree, `develop` up to date, create the branch named in the plan. **During:** follow the steps in order, tick them off in the plan file, one Conventional Commit per step. **If the plan turns out wrong:** stop, explain, update the plan, and get approval again. Don't drift silently. |
| (3) Unit tests | Write them **from the acceptance criteria, test-first where practical**, not at the end. Cover edge cases and error paths. Never weaken a test or disable a lint rule to get green. |
| (4) Ask about integration tests | **Move this question to planning** (the test strategy), so the work is planned and sized instead of being a surprise at the end. Implementation then does what the plan says. |
| **Missing** | Run **`just check`** (the same gate as CI) and iterate until it's green before calling the work done · update docs (README, AGENTS.md if conventions changed) · hand off to Review & PR. |

### Extra workflows (all selected)
- **fix**: reproduce → **failing test first** → root cause → minimal fix → regression test. The plan is a mini plan file (`type: bugfix`), so the same gate applies to every change. Branch `bugfix/*` from `develop`, or `hotfix/*` from `main` for production.
- **review-pr**: a `code-reviewer` subagent with fresh context checks the **diff against the plan**: conformance, unrequested changes, test quality, security. Then push, open a PR to `develop` from the template with the plan linked, run `gh pr checks --watch`, and fix any failures.
- **release**: from `develop`, compute the next semver from the commits since the last tag (git-cliff `--bumped-version`), create `release/vX.Y.Z`, bump version files (`uv version`, `pnpm version --no-git-tag-version`, `cargo set-version`, CMake `project(VERSION)`), generate CHANGELOG, open a PR to `main`. After it merges: tag, create a GitHub release, and open a merge-back PR `main → develop`. Hotfixes finish the same way.
- **retrofit**: the same skill as setup (`setup-repo`). It audits first, shows what's missing or outdated, and adds only what the user picks.

### Branch & commit rules (encode once, in the `conventions` skill + validators)
- Allowed branches: `main`, `develop`, or `(feature|feat|bugfix|fix|hotfix|release|chore)/<desc>`.
- `<desc>` regex: `[a-z0-9]+(\.[a-z0-9]+)*(-[a-z0-9]+(\.[a-z0-9]+)*)*`
- Not allowed: `master` and the AI prefixes.
- Claude uses the canonical prefixes `feature/ bugfix/ hotfix/ release/vX.Y.Z chore/`. It must name branches itself, because Claude Code can default to `claude/*`.
- Commits: `type(scope)!: description` with types `feat fix build chore ci docs style refactor perf test revert`. Breaking changes use `!` or a `BREAKING CHANGE:` footer.

---

## Part 2 — v1 build plan

### Plugin layout
```
.claude-plugin/plugin.json        name (short, e.g. "sw" → /sw:plan), version, description
.claude-plugin/marketplace.json   repo is its own marketplace (entry name == plugin name)
skills/
  setup-repo/   SKILL.md (+ disable-model-invocation: true: changes remote repo settings)
                reference/{python,typescript,rust,cpp,generic}.md
                templates/ AGENTS.md CLAUDE.md CONTRIBUTING.md justfile.* pre-commit.*.yaml
                           ci.*.yml dependabot.yml cliff.toml gitattributes editorconfig PR/issue templates
  plan/         SKILL.md + reference/{plan-template.md, principles.md, adr-template.md}
  implement/    SKILL.md
  fix/          SKILL.md
  review-pr/    SKILL.md
  release/      SKILL.md (disable-model-invocation: true: tags and releases)
  conventions/  SKILL.md (user-invocable: false; shared branch and commit rules)
agents/  plan-critic.md, code-reviewer.md   (read-only tools)
hooks/   hooks.json + scripts/{session-context.sh, plan-gate.sh}
evals/   one or more cases per skill
AGENTS.md  CLAUDE.md  CONTRIBUTING.md  README.md  .github/workflows/ci.yml
```
Conventions: each SKILL.md stays under 500 lines and puts details in `reference/` (progressive disclosure). Trigger phrases go first in `description`. Bundled files are referenced with `${CLAUDE_PLUGIN_ROOT}`, which is substituted inline in skill text and is not an environment variable inside the Bash tool. Per-session state goes in `${CLAUDE_PLUGIN_DATA}`.

### Hooks (soft, per user choice)
- **SessionStart**: prints the current branch, the matching plan with its status and next unchecked step, or "no plan for this branch". Kept to 10 lines or fewer.
- **PreToolUse `Edit|Write`**: never blocks with exit 2.
  - On `main`/`develop` → `permissionDecision: "ask"` ("protected branch; create feature/… first").
  - On a feature branch with no approved plan, editing a non-doc file → `ask` **once per session**, tracked with a marker file in `${CLAUDE_PLUGIN_DATA}`.
  - Otherwise → allow silently.
- Scripts are POSIX sh (Claude Code on Windows uses Git Bash). They handle backslash paths, which is how `tool_input.file_path` arrives on Windows.

### Plan file contract (`docs/plans/<slug>.md`)
Frontmatter: `title, type (feature|bugfix|hotfix|chore), branch, status, integration_tests (required|not-needed)`.
Sections: Context · Acceptance criteria · Out of scope · Design (reuse, files touched, patterns used and why) · Cost/performance · Risks/migration/rollback · Test strategy · Steps (checklist, one commit each) · Open questions.

### Build order (each milestone is a PR to `develop`, using the plugin's own conventions)
0. **Set up this repo by hand.** Rename `master` → `main`; add AGENTS.md/CLAUDE.md, plugin.json, marketplace.json, `.gitattributes`, pre-commit; CI running `claude plugin validate . --strict` and shellcheck; create `develop` and make it the default; add protections.
1. `conventions` skill + both hooks + hook tests.
2. `plan` skill + plan template/principles + `plan-critic` agent. Confirm how `plansDirectory` behaves (relative paths) here.
3. `implement` skill, connected to the plan contract and hooks.
4. `setup-repo`: generic + Python first, then TS/JS, Rust, C++ references and templates. Retrofit/audit mode included.
5. `fix` + `review-pr` + `code-reviewer` agent.
6. `release` (git-cliff, version bump per language, merge-back).
7. Eval suite for every skill. Tag v1.0.0 using the plugin's own `release` skill.

## Verification
- **Structure:** `claude plugin validate . --strict` in CI on every PR.
- **Hooks:** feed sample JSON into the scripts and assert the decision. Run on **ubuntu + windows** runners, plus shellcheck.
- **Behavior:** `claude plugin eval .` cases. Examples: "implement X" with no plan → routes to planning (`tool_used`/`regex`); setup-repo on an empty fixture → `file_exists` for AGENTS.md, CLAUDE.md, `.pre-commit-config.yaml`, `.github/workflows/ci.yml`, CONTRIBUTING.md, justfile; fix → test written before the fix (`tool_order`); branch named `claude/...` → rejected. Evals cost real model calls, so run them on `workflow_dispatch` or before releases with `--max-cost-usd`, not on every PR.
- **End to end, by hand:** install locally (`/plugin marketplace add ./`). Then, for each of the four languages, run setup-repo on a throwaway GitHub repo and confirm: CI green on the first push, `develop` is the default, protections are active. Then run plan → implement → review-pr → release on a toy feature, and fix on a seeded bug.
