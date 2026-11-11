# Changelog

All notable changes to this project are documented in this file.
The format follows [Keep a Changelog](https://keepachangelog.com/en/1.1.0/) and the project
uses [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [1.0.0] - 2026-11-11

### Features

- **conventions:** Add branch and commit rules skill
- **hooks:** Add session context and soft plan gate
- **plan:** Add planning skill with plan template and design principles
- **agents:** Add read-only plan-critic subagent
- **implement:** Add plan-driven implementation skill
- **setup-repo:** Add template renderer and project initialiser
- **setup-repo:** Add common and per-language templates
- **setup-repo:** Add setup and retrofit skill with tooling references
- **fix:** Add bug-fix skill that reproduces with a failing test first
- **agents:** Add read-only code-reviewer subagent
- **review-pr:** Add review and pull request skill
- **release:** Add release and hotfix skill
- **setup-repo:** Find releases at least 14 days old
- **setup-repo:** Enforce the 14-day rule in generated projects
- **setup-repo:** Add Dependabot cooldown and pre-commit updates

### Bug fixes

- **setup-repo:** Install the newest TypeScript that typescript-eslint supports
- **setup-repo:** Skip generated lock files in YAML and file-size checks
- **setup-repo:** Close gaps in the 14-day rule found in review
- **implement:** Tick verified acceptance criteria and know the just fallback
- **setup-repo:** Warn about protection on free private repos, offer uv and just
- **setup-repo:** Close review gaps in the end-to-end trial fixes
- **release:** Separate changelog releases with blank lines

### Documentation

- Describe the workflow, hooks and development commands
- **plans:** Add plan for the 14-day dependency rule
- **adr:** Record the 14-day dependency rule
- **setup-repo:** Document the 14-day rule and exemptions
- **plans:** Add plan for the end-to-end trial findings

### Dependencies

- **deps:** Bump astral-sh/setup-uv

### Maintenance

- Initial repository setup
- **hooks:** Cover plan gate and session context on all platforms
- **setup-repo:** Smoke-test every template variant in CI
- **evals:** Add behavior evals for plan, implement, fix and branch naming
- Add on-demand evals workflow and just recipe
- License the plugin under MIT and the setup templates under MIT-0
- Apply the 14-day rule to this repository
- **evals:** Check that implement ticks acceptance criteria
