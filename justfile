# Development tasks for the sw plugin. CI runs these same recipes.
# On Windows, run from Git Bash. Without just installed: `uvx --exclude-newer "14 days" --from rust-just just <recipe>`.

# List recipes
default:
    @just --list

# Everything CI runs. Must pass before opening a PR.
check: lint validate test-hooks test-scripts

# Formatting, file checks, shellcheck, secret scan
lint:
    uvx --exclude-newer "14 days" pre-commit run --all-files --show-diff-on-failure

# Validate the plugin and marketplace manifests, skills, agents and hooks
validate:
    claude plugin validate . --strict

# Hook script tests (plan gate and session context)
test-hooks:
    sh tests/hooks/run.sh

# setup-repo script tests (live GitHub API checks need an authenticated gh)
test-scripts:
    sh tests/scripts/run.sh

# Render a setup-repo template, initialise it and run its `just check` (lang: python, typescript, rust, cpp)
test-templates lang kind="app" pm="":
    sh tests/templates/smoke.sh {{lang}} {{kind}} {{pm}}

# Behavior evals: real model calls billed to your account. Run before releases, not on every change.
# Cases that use Bash need Claude Code's sandbox (Linux, macOS or WSL2; not native Windows).
evals threshold="0.7" max_cost="10":
    claude plugin eval . --trust-plugin --scaffold --allow-tools Bash Write Edit --threshold {{threshold}} --max-cost-usd {{max_cost}} --no-publish
