# Engineering Standards

How we build things. One page. Read the universal rules, then jump to your project type.

## Who this is for

| You're building... | Jump to |
|---|---|
| HTTP API in Python (FastAPI or Flask) | [Python API](#python-api) |
| HTTP API in Node (Express or NestJS) | [Node API](#node-api) |
| LLM app, agent, or RAG pipeline | [AI project](#ai-project) |
| Background worker, mail sender, cron job | [Worker / mail / job](#worker--mail--job) |

In your project's README, write one line:

```
> Standards: Python API   (v1.0)
```

That tells humans, AI assistants, and CI which section binds this repo.

---

## Universal rules

Apply to every repo, no matter what.

- **Secrets never go in the repo.** Not in source, not in tests, not in `.env`. Use a secrets manager. Document required env vars in `.env.example`.
- **Lockfile is committed.** `uv.lock`, `pnpm-lock.yaml`, etc.
- **README explains setup, run, test, owner.** And declares which section above applies.
- **Tests for new features and bug fixes.** No exceptions.
- **CI runs lint + types + tests.** Failure blocks merge.
- **PRs are small, ticket-linked, reviewed once, squash-merged.** No force-push to `main`.
- **Logs are structured JSON.** No PII (emails, names, tokens, payment data).
- **Errors don't leak stack traces to clients.**
- **No empty `catch` / bare `except`.** If you caught it, do something with it.
- **Material decisions get a one-page ADR.** Template at the bottom.

That's it. Ten rules.

---

## Python API

### Stack

| Concern | Choice |
|---|---|
| Runtime | Python 3.11+ (pin in `pyproject.toml`) |
| Package manager | `uv` |
| Lint + format | `ruff` |
| Types | `mypy --strict` or `pyright` |
| Tests | `pytest` |
| HTTP framework | **FastAPI** (preferred) or **Flask** |
| Validation | Pydantic |
| ORM | SQLAlchemy 2.0 + Alembic |
| Logger | `structlog` |

### Layout

```
src/<service_name>/
  api/v1/        ← routes, no business logic
  services/      ← business logic
  repositories/  ← all DB access
  models/        ← SQLAlchemy
  schemas/       ← Pydantic
  core/          ← config, errors, logger
tests/{unit, integration, e2e}/
migrations/
.env.example
pyproject.toml
README.md
```

### Patterns

- ✅ Routes call services. Services call repositories. **No DB queries in routes or services.**
- ✅ Config: `pydantic-settings` (FastAPI) or a `Config` class loaded from `os.environ` (Flask). Validate at startup, exit on bad config.
- ✅ Errors: subclass `AppError`. One global handler translates to HTTP.
- ✅ Pagination is mandatory. No unbounded lists.
- ✅ JSON keys are `snake_case`. Timestamps are ISO 8601 UTC.
- ✅ Auth: OAuth 2.0 / OIDC / JWT only. Passwords with `argon2` or `bcrypt` (cost ≥ 12).
- ❌ No `print()` for logging.
- ❌ No `except Exception:` except at the top boundary.
- ❌ No sequential int IDs externally — use UUID/ULID.
- ❌ No `*` for CORS in production.
- ❌ No SQL built with f-strings or `+`.

### Naming

| Thing | Style | Example |
|---|---|---|
| File | `snake_case` | `user_service.py` |
| Class | `PascalCase` | `UserService` |
| Function / variable | `snake_case` | `get_user_by_id` |
| Constant | `UPPER_SNAKE_CASE` | `MAX_RETRIES` |

### Error response shape

```json
{ "error": { "code": "USER_NOT_FOUND", "message": "...", "trace_id": "..." } }
```

### HTTP status codes

| Code | Use for |
|---|---|
| 200 / 201 / 204 | Success / created / no content |
| 400 / 401 / 403 / 404 | Bad request / unauthn / unauthz / not found |
| 409 / 422 / 429 | Conflict / validation failed / rate limit |
| 500 / 503 | Server error / dependency down |

---

## Node API

### Stack

| Concern | Choice |
|---|---|
| Runtime | Node 20+ (pin in `engines` and `.nvmrc`) |
| Language | TypeScript with `"strict": true` |
| Package manager | `pnpm` |
| Linter | `eslint` (`@typescript-eslint`) |
| Formatter | `prettier` |
| Tests | `vitest` |
| HTTP framework | **NestJS** (preferred) or **Express** |
| Validation | Zod (Express) or `class-validator` + `ValidationPipe` (NestJS) |
| ORM | Prisma (preferred) or TypeORM |
| Logger | `pino` |

### Layout — NestJS

```
src/
  main.ts
  app.module.ts
  modules/<feature>/
    <feature>.module.ts
    <feature>.controller.ts
    <feature>.service.ts
    <feature>.repository.ts
    dto/
  common/    ← filters, guards, interceptors
  config/
test/{unit, integration, e2e}/
prisma/
README.md
```

### Layout — Express

```
src/
  index.ts        ← starts server
  app.ts          ← builds Express app
  routes/v1/
  controllers/
  services/
  repositories/
  schemas/        ← Zod
  middleware/
  core/           ← config, logger, errors
test/
README.md
```

### Patterns

- ✅ Controllers call services. Services call repositories.
- ✅ Validate at the boundary — Zod (Express) or `ValidationPipe` (NestJS, with `whitelist: true, forbidNonWhitelisted: true`).
- ✅ Errors: domain class hierarchy + global filter (NestJS) or error middleware (Express).
- ✅ JSON keys are `camelCase`. Timestamps ISO 8601 UTC.
- ✅ `helmet` enabled. CORS allow-list. Rate limiter on auth + writes.
- ✅ Auth: OAuth 2.0 / OIDC / JWT. Passwords with `argon2` or `bcrypt` (cost ≥ 12).
- ❌ No `console.log` in production code.
- ❌ No floating promises (`@typescript-eslint/no-floating-promises = error`).
- ❌ No `process.env` access outside the config module.
- ❌ No plain `.js` for new code.

### Naming

| Thing | Style | Example |
|---|---|---|
| File | `kebab-case` | `user-service.ts` |
| Class | `PascalCase` | `UserService` |
| Function / variable | `camelCase` | `getUserById` |
| Interface / type | `PascalCase`, no `I` prefix | `User` |
| Constant | `UPPER_SNAKE_CASE` | `MAX_RETRIES` |

Error response shape and HTTP codes: same as the [Python API](#python-api) section. For cross-service contracts, the producer's casing wins — document it in the OpenAPI spec.

---

## AI project

LLM apps, agents, RAG pipelines, evaluators.

> The framework choice (LangChain, LlamaIndex, DSPy, raw SDK) is **not** standardized. It changes too fast. The patterns below don't.

### Patterns that don't change

- ✅ **Prompts live in files under `prompts/`,** version-controlled. Header comment per file: purpose, inputs, output shape, last-known-good model.
- ✅ **Every LLM call has a timeout, exponential-backoff retry, and a documented fallback.** Treat the model like flaky HTTP.
- ✅ **Model name, temperature, max_tokens come from config** — never hardcoded scattered through the code.
- ✅ **Output that drives a code path gets parsed and validated** (Pydantic / Zod). Never `eval` model output. Never pass it raw into shell, SQL, or file paths.
- ✅ **Agent loops have a max iteration count.** Always.
- ✅ **Per-call logging:** prompt id, model, input/output token counts, latency, trace_id. PII redacted.
- ✅ **Cost tracked per call,** aggregable per request / user / feature.
- ✅ **Eval set in `evals/` for every prompt + model combo in production.** Prompt change = re-eval before merge.
- ✅ **PII redacted before sending to a third-party API.** If sensitive data must go, write an ADR.
- ✅ **Deterministic tasks: `temperature = 0` and explicit format constraints.** Creative tasks: temperature set explicitly with a justification comment. The default is not a value.

### Framework switches happen via ADR

When you want to add or replace a framework, write a one-page ADR (template at bottom): what we're using now, what's not working, what we're moving to, what we give up. The patterns above don't change.

---

## Worker / mail / job

Background workers, queue consumers, cron jobs, mail senders, batch processors.

### Universal worker patterns

- ✅ **Idempotent.** Running twice with the same input = no duplicate side effect. For mail, payments, or third-party calls: persist an idempotency key *before* the side effect, check on retry.
- ✅ **Retry with exponential backoff. Bounded max attempts.**
- ✅ **Failures go to a dead-letter queue or "failed jobs" table.** Observable — alert or weekly review. Not silent.
- ✅ **Transient errors retry. Permanent errors (4xx, bad input) go straight to DLQ.**
- ✅ **Every job has a max execution time.** Exceeding = killed and failed.
- ✅ **`SIGTERM` handled gracefully:** stop accepting, finish in-flight, exit clean.
- ✅ **Cron jobs that mustn't overlap use a distributed lock** (Redis, DB row, filesystem lock for VM-only).
- ✅ **Logs include start, end, duration, status, trace_id.**
- ✅ **Workers heartbeat or expose a liveness endpoint.**

### Mail-specific

- ✅ **Templates in `templates/`, never inline strings.**
- ✅ **Rate-limit sends.** Respect provider limits and sender reputation.
- ✅ **Bounce + complaint handling.** Hard bounces and complaints suppress future sends.
- ✅ **Unsubscribe link + `List-Unsubscribe` header on non-transactional mail.**

### Cron-specific

- ✅ **Cron expressions in version control,** not configured by hand on a VM.
- ✅ **Each scheduled job has documented purpose, owner, and expected runtime.**

---

## For AI coding assistants

When generating or modifying code in a repo that links here:

- Read this whole file before you write anything.
- The **Universal rules** + the section named in the project's README are binding.
- When a request would break a rule (any ✅ or ❌ above), surface the conflict and ask before proceeding.
- Don't introduce libraries or patterns that aren't here. Propose an ADR instead.
- Cite the section heading when justifying a decision (e.g., *"per Python API > Patterns, services call repositories, not the ORM directly"*).

---

## ADR template

Use for: framework changes, deviations from a hard rule, anything material an engineer 6 months from now would want to understand. One page.

```markdown
# ADR NNNN: <title>

Status: Proposed | Accepted | Superseded by ADR-NNNN
Date: YYYY-MM-DD

## Context
What's the situation, what's pushing the decision now. 2–3 sentences.

## Decision
What we're doing. One paragraph. Specific.

## Alternatives
- Option A — why we didn't pick it.
- Option B — why we didn't pick it.

## Consequences
- What gets better.
- What gets worse / what we give up.
- Migration or revisit notes.
```

---

*v1.0 · Maintained by Platform · Edits via PR with an ADR*
