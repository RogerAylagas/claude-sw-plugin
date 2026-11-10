# setup-repo templates

`scripts/render.sh` turns these files into a project. Nothing here is copied verbatim.

## Layout

| Path | Contents |
|---|---|
| `common/` | Files every project gets (AGENTS.md, CONTRIBUTING.md, GitHub templates, docs/, ...). |
| `<lang>/` | Language files (`python`, `typescript`, `rust`, `cpp`). They override `common/` files with the same path. |
| `_fragments/` | Snippets included by other templates. Never copied on their own. |

This README and `LICENSE` are not rendered (only `common/` and `<lang>/` are).

Everything in this folder is licensed under [MIT No Attribution](LICENSE), so generated projects
owe nothing to this one. The project's own license comes from the user's choice during setup.

## Markers

| Marker | Effect |
|---|---|
| `{{PROJECT_NAME}}` `{{PACKAGE_NAME}}` `{{PACKAGE_UPPER}}` `{{DESCRIPTION}}` `{{LANG}}` `{{KIND}}` `{{PM}}` `{{PYTHON_VERSION}}` `{{NODE_VERSION}}` `{{CXX_STANDARD}}` `{{LICENSE}}` `{{AUTHOR}}` `{{YEAR}}` `{{DATE}}` | Replaced in contents and in paths. `PACKAGE_NAME` is the project name with `_` instead of `-`. |
| `{{UV_BUILD_REQ}}`, `{{VCPKG_BASELINE}}` | Left for `init-project.sh`, which resolves them from the installed tools. |
| A line containing `sw:include FILE` | Replaced by `_fragments/FILE` (`{{LANG}}` in FILE is expanded). |
| A line ending in a comment `sw:if KEY=VALUE` (`#`, `//` or `<!-- -->`) | Kept only when KEY (`kind`, `pm`, `lang`) equals VALUE; the marker is removed. A line that is only the marker becomes a blank line. |
| A file named `NAME.sw-if-KEY-VALUE` | Rendered as `NAME` only when KEY equals VALUE. |

Other `{{ ... }}` text (GitHub Actions expressions, just interpolation, git-cliff templates) is left
alone because only the names above are replaced.

## Rules

- Never write tool or action versions from memory: look them up (see `../reference/generic.md`).
- Keep every language's justfile recipe names identical: `setup fmt lint analyze build test
  test-integration check`.
- The branch and commit regexes in `_fragments/precommit-common.yaml` and
  `_fragments/ci-conventions.yml` must match `skills/conventions/SKILL.md`.
- After any change, run `just test-templates <lang> <kind> [pm]` from the repository root; CI runs
  every variant.
