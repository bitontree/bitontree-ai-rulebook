# JavaScript & Node.js

## Tooling (mandated)

- **Package manager: npm.** Not pnpm, yarn, or bun. Commit `package-lock.json`. Never commit `node_modules/`.
- **Test framework: Jest.** Not Vitest, Mocha, AVA. See [`50-testing.md`](50-testing.md).
- **Node version: current LTS.** Pin via `engines` in `package.json` and a `.nvmrc` / `.node-version` file.
- **Lint: ESLint** with the org-shared config (or, if absent, `@typescript-eslint/recommended` + `eslint-config-prettier`).
- **Format: Prettier.** No bikeshedding on style — Prettier wins.

## TypeScript

- New code is TypeScript. JS is acceptable only for legacy projects already on JS.
- `tsconfig.json` must enable: `strict`, `noUncheckedIndexedAccess`, `noImplicitOverride`, `noFallthroughCasesInSwitch`.
- No `any`. If you absolutely need it, use `unknown` and narrow, or escalate.
- No `as` casts to widen types. `as` is for narrowing the compiler can't prove on its own; document the *why* on the same line.
- Don't use `enum` — use union string literals or `as const` objects.
- Public exports have explicit return types.

## Modules

- ESM (`"type": "module"` in `package.json`) for new projects. CommonJS only for legacy.
- Use absolute or aliased imports for cross-feature paths (`@/users/service`), relative imports (`./util`) within a feature folder.
- No deep relative paths (`../../../../`). If you need them, the structure is wrong.
- One default export *or* named exports per file — pick a project-wide convention.

## Async

- `async`/`await` over `.then()` chains.
- Always handle rejections — every `await` is implicitly inside a `try` or wrapped by a top-level handler.
- Run independent awaits in parallel: `Promise.all` / `Promise.allSettled`. Sequential awaits in a loop is almost always a bug.
- No floating promises. Configure `@typescript-eslint/no-floating-promises` to error.
- Don't mix callbacks and promises. Wrap callback APIs with `util.promisify`.

## Errors

- Throw `Error` subclasses, not strings or plain objects.
- Define a per-domain base error: `class BillingError extends Error`.
- HTTP layer translates domain errors to status codes; domain layer never knows about HTTP.

## Logging

- Use `pino` or the project's standard logger. Never `console.log` in committed code.
- Structured logging only: `logger.info({ userId, action }, 'login succeeded')`.
- No PII or secrets in logs.

## Dependencies

- Justify every new dependency. Adding `lodash` for `_.isEmpty` is not justified.
- Prefer the standard library. `node:` prefix on Node built-ins (`import { readFile } from 'node:fs/promises'`).
- Audit weekly: `npm audit`. Fix high/critical before release.
- Pin minor versions in `package.json` (`^1.2.3`, not `*`). Lockfile is committed.

## Project layout

```
src/
  features/
    users/
      users.controller.ts
      users.service.ts
      users.repository.ts
      users.types.ts
      users.test.ts
  lib/                # cross-feature utilities
  config/             # env loading and validation
  index.ts            # entrypoint
```

- Configuration is loaded once at boot, validated with `zod` (or equivalent), and injected — not re-read from `process.env` deep in the code.
- Don't ship a `.env.example` with real values; ship it with placeholders.

## Don't do

- `var`. Use `const`; `let` only for genuine reassignment.
- `==` / `!=`. Always strict.
- `Array.prototype.forEach` for side effects when `for...of` reads cleaner with `await` inside.
- `JSON.parse(JSON.stringify(x))` for deep clone — use `structuredClone`.
- `new Date()` for "now" inside business logic — inject a clock for testability.
