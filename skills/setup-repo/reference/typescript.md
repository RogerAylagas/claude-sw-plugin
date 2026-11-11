# TypeScript / JavaScript reference

Last reviewed: 2026-11-11.

| Concern | Default | Alternatives (ask) | Notes |
|---|---|---|---|
| Package manager | **pnpm** | npm (templates exist), bun, yarn | pnpm: fast, strict dependency isolation, `pnpm-lock.yaml`; pinned through `packageManager` in package.json to the newest release of the installed major at least 14 days old. |
| Node version | current Active LTS | | Check https://nodejs.org/en/about/previous-releases. The major goes into `engines`; `.nvmrc` gets the newest release of that major at least 14 days old. |
| 14-day rule | pnpm `minimumReleaseAge: 20160` (`pnpm-workspace.yaml`), npm `min-release-age=14` (`.npmrc`) | — | Needs pnpm 10.16+ / npm 11.10+, which `init-project.sh` checks: older versions ignore the setting silently. See "Versions" in `generic.md`. |
| Module system | ESM, `"module": "nodenext"` | | Relative imports end in `.js`. |
| Type checker | **tsc --noEmit**, `strict` + `noUncheckedIndexedAccess` | | Build uses `tsconfig.build.json` (src only). |
| Linter | **ESLint** flat config + typescript-eslint `strictTypeChecked` | Biome | Ask. For Biome: drop eslint/prettier, add `@biomejs/biome`, a `biome.json`, and point the pre-commit hook and scripts at `biome check`. |
| Formatter | **Prettier** (code only; see `.prettierignore`) | Biome | Prettier ignores Markdown/YAML/JSON so docs and package-manager-written files are not reformatted. |
| Tests | **Vitest** + `@vitest/coverage-v8` | Jest, node:test | `tests/unit/`, `tests/integration/`. |

## Questions to ask

- Library or application (library gets `exports` and `files`; application gets `start`).
- Package manager: pnpm (recommended) or npm.
- Lint/format stack: ESLint + Prettier (recommended, most widely adopted) or Biome (single fast tool).
- Runtime target: Node only (templates), or a browser/framework app (then start from the
  framework's official scaffolder, e.g. Vite, Next.js, and add the sw files on top as a retrofit).

## Notes

- The pre-commit hooks call `node node_modules/<tool>/...` directly, which works on Windows,
  macOS and Linux and with any package manager; run `just setup` before the first commit.
- `@types/node` is pinned to the Node major in `.nvmrc`.
- TypeScript is installed at the newest version inside typescript-eslint's supported peer range
  (`npm view typescript-eslint peerDependencies.typescript`). In November 2026 that excludes
  TypeScript 7 (the native compiler), which typescript-eslint can't load yet; when it can, the
  range widens and nothing in the templates changes. If the user wants TypeScript 7 now, use it
  for `tsc` only, side by side with TypeScript 6 for linting, as the TypeScript 7 release notes
  describe.

## Retrofit notes

- Keep existing ESLint/Prettier configs if they already exist; add only missing pieces (type-aware
  rules, `--max-warnings=0`) after asking.
- Map the existing `package.json` scripts to the justfile recipes instead of renaming them.
