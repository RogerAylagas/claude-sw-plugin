#!/usr/bin/env bash
# A small repository that uses the sw workflow (docs/plans/ exists) with no plan for the request.
set -euo pipefail

git init -q -b main
git config user.name "Eval"
git config user.email "eval@example.com"
mkdir -p docs/plans src tests

cat >AGENTS.md <<'EOF'
# AGENTS.md

A small command-line greeter. Run the tests with `python -m unittest discover -s tests`.
Workflow: main = production, develop = default branch. Plans live in docs/plans/.
EOF

cat >docs/plans/README.md <<'EOF'
# Plans

One plan per change, named after its branch.
EOF

cat >src/app.py <<'EOF'
import argparse


def main(argv=None):
    parser = argparse.ArgumentParser(prog="app")
    parser.add_argument("name")
    args = parser.parse_args(argv)
    print(f"Hello, {args.name}!")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
EOF

git add -A
git commit -q -m "chore: initial commit"
git switch -q -c develop
