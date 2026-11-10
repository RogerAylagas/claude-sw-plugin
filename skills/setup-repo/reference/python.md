# Python reference

Last reviewed: 2026-11-09.

| Concern | Default | Alternatives (ask) | Notes |
|---|---|---|---|
| Dependency manager | **uv** | Poetry, PDM, pip-tools | uv is fast, manages Python versions, lock file `uv.lock`, standard `pyproject.toml`. Templates exist only for uv; for another choice, render with uv and translate the commands. |
| Build backend | `uv_build` | hatchling, setuptools | Bounds set from the installed uv version, like `uv init` does. |
| Layout | `src/<package>/` | flat layout | src layout keeps tests honest (they import the installed package). |
| Formatter + linter | **ruff** (`ruff format`, `ruff check`) | — | Replaces black, isort, flake8, pyupgrade, bandit subsets. |
| Type checker | **mypy --strict** | pyright / basedpyright, ty | Ask; for pyright, replace the `analyze` recipe and the `[tool.mypy]` table. |
| Tests | **pytest** + pytest-cov | — | `tests/unit/`, `tests/integration/`, `--import-mode=importlib`. |
| Python version | latest stable CPython that the project's key dependencies support | | Check https://devguide.python.org/versions/ (latest "bugfix" status). |

## Questions to ask

- Library or application (app gets `[project.scripts]` and `__main__.py`).
- Python version (recommend the latest stable release with bugfix support).
- Type checker: mypy (recommended, most widely used) or pyright.
- For applications: does it read configuration from the environment? → add `.env.example`.

## Commands

| Task | Command |
|---|---|
| Add a dependency | `uv add <package>` |
| Add a dev tool | `uv add --dev <tool>` |
| Run anything in the env | `uv run <command>` |
| Sync after pulling | `uv sync` |

## Retrofit notes

- Existing `requirements.txt` / `setup.py` projects: propose migrating to `pyproject.toml` with
  `uv add -r requirements.txt`, as its own commit; ask first.
- Existing black/isort/flake8 config: propose replacing it with ruff (`ruff` can read most of the
  same settings); don't silently delete their config.
- Merge the `[tool.ruff]`, `[tool.mypy]`, `[tool.pytest.ini_options]` and `[tool.coverage.*]`
  tables from the rendered `pyproject.toml` into theirs, keeping their existing values.
