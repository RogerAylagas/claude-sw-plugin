# Development tasks for the sw plugin. CI runs these same recipes.
# On Windows, run from Git Bash. Without just installed: `uvx --from rust-just just <recipe>`.

# List recipes
default:
    @just --list

# Everything CI runs. Must pass before opening a PR.
check: lint validate

# Formatting, file checks, shellcheck, secret scan
lint:
    uvx pre-commit run --all-files --show-diff-on-failure

# Validate the plugin and marketplace manifests, skills, agents and hooks
validate:
    claude plugin validate . --strict

# Update pre-commit hook versions to their latest releases
update-hooks:
    uvx pre-commit autoupdate
