## TypeScript

- Package manager: `{{PM}}` (Node {{NODE_VERSION}}, see `.nvmrc`). Add dependencies with
  `{{PM}} add <package>` (dev tools: `{{PM}} add -D <tool>`); commit the lock file.
- 14-day rule: `minimumReleaseAge: 20160` in `pnpm-workspace.yaml` (needs pnpm 10.16+). <!-- sw:if pm=pnpm -->
  Exemption: `minimumReleaseAgeExclude: [<package>]` in the same file. Toolchains: `.nvmrc` <!-- sw:if pm=pnpm -->
  (exact Node release) and `packageManager` in `package.json` (pnpm). <!-- sw:if pm=pnpm -->
- 14-day rule: `min-release-age=14` in `.npmrc` (needs npm 11.10+). Exemption (npm 11.17+): <!-- sw:if pm=npm -->
  `min-release-age-exclude[]=<package>` in the same file. Toolchain: `.nvmrc` (exact Node release). <!-- sw:if pm=npm -->
- ES modules with `"module": "nodenext"`: relative imports end in `.js`
  (`import { greet } from "./index.js"`), even from `.ts` files.
- Code in `src/`; unit tests in `tests/unit/`, integration tests in `tests/integration/`
  (Vitest, files named `*.test.ts`).
- Style: Prettier formats; ESLint uses typescript-eslint's strict, type-checked rules;
  `tsc` runs in strict mode. Avoid `any`; validate untrusted data at the edges.
