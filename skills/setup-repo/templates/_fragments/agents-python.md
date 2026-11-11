## Python

- Dependencies are managed with [uv](https://docs.astral.sh/uv/): `uv add <package>`,
  `uv add --dev <tool>`, `uv run <command>`. Commit `uv.lock`. Never use pip directly.
- 14-day rule: `[tool.uv] exclude-newer = "14 days"` in `pyproject.toml` (needs uv 0.9.17+).
  Exemption: `exclude-newer-package = { <package> = false }` in the same table. The Python
  version is `.python-version`; CI's pinned uv only offers Python builds it already knew about.
- Code lives in `src/{{PACKAGE_NAME}}/`; unit tests in `tests/unit/`, integration tests in
  `tests/integration/` (pytest).
- Style: ruff formats and lints (`pyproject.toml` has the rule set); mypy runs in strict mode, so
  every function has type annotations.
- Tests are plain pytest functions; use fixtures and `tmp_path` instead of real shared state.
