# FastAPI & Flask

Reads on top of [`20-python.md`](20-python.md). Pick one framework per service and stick with it; do not mix.

## Choosing between them

- **FastAPI** is the default for new services. Async-native, Pydantic-integrated, OpenAPI auto-generated.
- **Flask** only for legacy projects or when a sync-only library makes async painful.

## Shared rules (both frameworks)

### Architecture

Layered:

```
api/         # routes / view functions — translate HTTP <-> domain
services/    # business logic, framework-agnostic
repositories/  # DB / external I/O
schemas/     # Pydantic / Marshmallow models for I/O
domain/      # pure types and rules — no framework imports
```

- Routes know about HTTP. Services don't. Domain doesn't know about anything except itself.
- A route is ~20 lines: parse, call service, format response.
- Don't access the DB from a route. Don't import a route from a service.

### Validation

- Validate every request body, query param, and path param at the route boundary using Pydantic (FastAPI) or Marshmallow / Pydantic (Flask).
- Reject unknown fields by default. Don't silently drop them.
- Response models are *separate* from DB models — never return ORM objects directly.

### Errors

- Define a per-domain exception hierarchy in `services/`.
- Centralize translation to HTTP status codes in one place (FastAPI exception handlers, Flask error handlers).
- Error response shape is consistent across the API:

```json
{ "error": { "code": "BILLING_INSUFFICIENT_FUNDS", "message": "human-readable", "request_id": "..." } }
```

- Never leak stack traces or internal paths to clients in production.

### Auth

- Auth is a dependency / middleware, never inline in route bodies.
- Authenticate, *then* authorize — keep them separate.
- Tokens read from `Authorization: Bearer ...`, not query strings or cookies (cookies for browser apps with CSRF protection).
- Roles/permissions checked declaratively (`@requires_role`, `Depends(require_admin)`).

### Configuration

- `pydantic-settings` (or `dynaconf` for Flask if preferred) reading from env vars.
- Loaded once at startup. Injected via DI / app context.
- Validate at boot — fail fast if a required env var is missing.

### Observability

- Every request gets a `request_id` (generate if not provided in `X-Request-Id`). Propagate to logs and downstream calls.
- Structured JSON logs with `request_id`, `user_id` (when authed), `route`, `status`, `duration_ms`.
- `/healthz` (liveness) and `/readyz` (readiness) endpoints required. Readiness checks DB and critical deps.
- Metrics: at minimum request count, latency histogram, error rate, by route.

### CORS

- Explicit allow-list of origins. No `*` in production.
- Configure once at app level, not per-route.

### Pagination & limits

- All list endpoints paginate. Default page size 50, max 200.
- All endpoints have a request body / query size limit.
- Long-running work goes to a queue, not a synchronous request.

## FastAPI specifics

- **Async everywhere** unless a dep forces sync. Don't mix async and sync route handlers in the same router.
- Use `Depends` for: auth, DB sessions, request-scoped services. Don't import services as singletons.
- Pydantic v2 only. v1 is unsupported.
- Use `response_model=` on every route that returns data — enforces the response contract.
- Tag and document routes; the OpenAPI spec is the API contract.
- Background work: `BackgroundTasks` for fire-and-forget within a request; a real queue (Celery, RQ, Arq) for anything important.
- Use `lifespan` context manager for startup/shutdown, not the deprecated `@app.on_event`.

## Flask specifics

- Application factory pattern (`create_app()`), not a module-level `app = Flask(__name__)`.
- Blueprints per feature. One blueprint, one URL prefix.
- Use `flask-smorest` or `flask-restful` for API projects — get OpenAPI and validation.
- DB sessions via `flask-sqlalchemy`'s scoped session, scoped to request via `app.teardown_appcontext`.
- Don't use `g` for non-request-scoped state. Don't use `current_app.config` deep in services — inject config.
- For async needs, run async work in a worker (Celery/RQ); don't try to mix `asyncio` into Flask request handlers.

## Don't do

- ORM models as request/response bodies (couples API to DB)
- Business logic in route handlers
- `time.sleep` in an async route — `asyncio.sleep`
- Catching `Exception` in a route to "make it not crash" — let the framework's error handler deal with it
- Long-running synchronous work in a request — push to a queue
- Returning `200 OK` for errors — use the right status code
