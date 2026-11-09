#!/usr/bin/env bash
# A repository using the sw workflow, on develop, with a bug in average() and an existing test file.
set -euo pipefail

git init -q -b main
git config user.name "Eval"
git config user.email "eval@example.com"
mkdir -p docs/plans src tests

cat >AGENTS.md <<'EOF'
# AGENTS.md

Statistics helpers. Run the tests with `python -m unittest discover -s tests` (standard library
only, no dependencies to install).
Workflow: main = production, develop = default branch. Plans live in docs/plans/.
Branches follow Conventional Branch; commits follow Conventional Commits.
EOF

cat >docs/plans/README.md <<'EOF'
# Plans

One plan per change, named after its branch.
EOF

cat >src/stats.py <<'EOF'
def average(values):
    """Return the arithmetic mean of values."""
    return sum(values) / len(values)
EOF

cat >tests/test_stats.py <<'EOF'
import pathlib
import sys
import unittest

sys.path.insert(0, str(pathlib.Path(__file__).resolve().parents[1] / "src"))

from stats import average  # noqa: E402


class AverageTest(unittest.TestCase):
    def test_average_of_numbers(self):
        self.assertEqual(average([1, 2, 3]), 2)


if __name__ == "__main__":
    unittest.main()
EOF

git add -A
git commit -q -m "chore: initial commit"
git switch -q -c develop
