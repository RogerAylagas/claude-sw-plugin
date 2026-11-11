#!/usr/bin/env bash
# A small repository that uses the sw workflow, with an approved plan (two acceptance criteria)
# that has not been implemented yet. The plan file is not committed, as after /sw:plan.
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

cat >tests/test_app.py <<'EOF'
import io
import sys
import unittest
from contextlib import redirect_stdout

sys.path.insert(0, "src")
import app  # noqa: E402


class GreetTest(unittest.TestCase):
    def test_greets_by_name(self):
        out = io.StringIO()
        with redirect_stdout(out):
            app.main(["Alice"])
        self.assertEqual(out.getvalue().strip(), "Hello, Alice!")


if __name__ == "__main__":
    unittest.main()
EOF

git add -A
git commit -q -m "chore: initial commit"
git switch -q -c develop

cat >docs/plans/feature-shout-flag.md <<'EOF'
---
title: Add a --shout flag
type: feature
branch: feature/shout-flag
status: approved
integration_tests: not-needed
---

# Add a --shout flag

## Context
Users want an uppercase greeting for announcements.

## Acceptance criteria
- [ ] Given `--shout`, when the app greets Alice, then it prints `HELLO, ALICE!`.
- [ ] Given no `--shout`, when the app greets Alice, then it still prints `Hello, Alice!`.

## Out of scope
- Other casing options.

## Design
### Reused
- `src/app.py` `main()`: add one argparse flag.

### Changes
| File | Change | Why |
|---|---|---|
| `src/app.py` | edit: `--shout` flag | AC 1-2 |
| `tests/test_app.py` | edit: tests for both criteria | AC 1-2 |

### Patterns and decisions
None.

## Cost and performance
No hot paths affected.

## Risks, compatibility and rollback
None: the default output is unchanged.

## Test strategy
- Unit: `tests/test_app.py`, AC 1-2.
- Integration: not needed (no boundary crossed).

## Steps
- [ ] `docs(plans): add plan for the --shout flag`: commit this plan
- [ ] `feat(app): add --shout flag`: `src/app.py`, tests: `tests/test_app.py`

## Open questions
None.
EOF
