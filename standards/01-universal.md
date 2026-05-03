# Universal principles

Apply across every language and stack.

## Naming

- Names must answer "what is this for?" without requiring a comment.
- Avoid abbreviations except universally understood ones (`id`, `url`, `ctx`).
- Boolean variables and functions read as predicates: `isReady`, `hasAccess`, `canRetry`.
- Collections are plural: `users`, `failedJobs`. Avoid `userList`, `userArray`.
- Constants are `UPPER_SNAKE_CASE` in JS/Python. Group related constants in an enum or object.
- Don't encode types in names (`strName`, `arrUsers`). Modern editors show types.

## Comments

Default to writing none. Add one only when the *why* is non-obvious — a hidden constraint, a surprising invariant, a workaround for a specific bug.

Do not write:

- Comments that restate the code (`// increment counter` above `counter++`)
- Comments referencing the current task or PR (`// added for BIT-1234`) — that belongs in the commit message
- Multi-paragraph block comments — if you need that much, write a doc and link it
- Banner comments (`// ===== HELPERS =====`) — use sections via files or modules instead

Do write:

- A one-line note above a workaround that would otherwise look wrong
- A docstring on a public function whose contract isn't obvious from signature
- A `// TODO(BIT-1234): reason` with a ticket reference for known gaps

## Functions

- One job per function. If the name has "and" in it, split it.
- Aim for ≤ 50 lines. Hard ceiling 100 lines without a code-review exception.
- ≤ 4 positional parameters. Beyond that, take an options object / dataclass.
- Pure functions where possible; side effects at the edges.
- Return early to avoid deep nesting. Guard clauses over `else` ladders.

## Files and modules

- Aim for ≤ 300 lines per file. Files over 500 are a refactor target.
- Group by feature, not by type. `users/` containing `users.routes.ts`, `users.service.ts`, `users.test.ts` beats `routes/`, `services/`, `tests/`.
- One default export per file *or* named exports — pick one per project and stick with it.
- No circular imports. If two modules need each other, extract the shared part into a third.

## Error handling

- Validate at the boundary — HTTP request, queue message, file load, subprocess output. Trust internal calls.
- Throw / raise typed errors, not strings. Subclass a base error per domain.
- Don't catch what you can't handle. `try` blocks should be small and intentional.
- Never swallow errors. `except: pass` and `catch (e) {}` are forbidden (see Hard Rule §6).
- Log with structured fields (`{userId, requestId}`), not interpolated strings.
- Errors crossing a service boundary get a stable error code; clients should not parse messages.

## Data and state

- Prefer immutable data structures and pure transformations.
- Avoid global mutable state. If you need it, hide it behind a module with a clear API.
- Date/time: store and pass UTC; convert at display only. Never store local time.
- Money: use a dedicated decimal type or integer cents. Never floats.
- IDs: opaque strings. Don't expose autoincrement integers in URLs.

## Performance

- Don't optimize what you haven't measured.
- The big wins are usually algorithmic (N+1 queries, repeated work, missing indexes), not micro-syntax.
- Prefer streaming / pagination over loading whole datasets.
- For LLM and API calls: cache, batch, and parallelize in that order.

## Documentation

- README per project, with: what it is, how to run, how to test, who owns it.
- Public APIs (HTTP, library exports) are documented at the type/schema level (OpenAPI, JSDoc, docstrings) — not in prose elsewhere.
- ADRs (architecture decision records) for non-obvious choices that future engineers will question.
- Don't write docs that duplicate code. Link to source where appropriate.
