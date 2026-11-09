## TypeScript

- Package manager: `{{PM}}` (Node {{NODE_VERSION}}, see `.nvmrc`). Add dependencies with
  `{{PM}} add <package>` (dev tools: `{{PM}} add -D <tool>`); commit the lock file.
- ES modules with `"module": "nodenext"`: relative imports end in `.js`
  (`import { greet } from "./index.js"`), even from `.ts` files.
- Code in `src/`; unit tests in `tests/unit/`, integration tests in `tests/integration/`
  (Vitest, files named `*.test.ts`).
- Style: Prettier formats; ESLint uses typescript-eslint's strict, type-checked rules;
  `tsc` runs in strict mode. Avoid `any`; validate untrusted data at the edges.
