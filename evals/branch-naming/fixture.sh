#!/usr/bin/env bash
# An empty repository using the sw workflow, on develop.
set -euo pipefail

git init -q -b main
git config user.name "Eval"
git config user.email "eval@example.com"
mkdir -p docs/plans
printf '# Orders service\n\nWorkflow: main = production, develop = default branch.\n' >AGENTS.md
printf '# Plans\n' >docs/plans/README.md
git add -A
git commit -q -m "chore: initial commit"
git switch -q -c develop
