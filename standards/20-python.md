# Python

## Tooling (mandated)

- **Env + dependencies: `uv`.** Not poetry, pipenv, pip-tools, or conda.
  - Project layout uses `pyproject.toml` and `uv.lock`. Both committed.
  - Install: `uv sync`. Add a dep: `uv add <pkg>`. Run: `uv run <cmd>`.
  - Never run bare `pip install` in a project — it bypasses the lockfile.
- **Lint + format: `ruff`** (covers Flake8, isort, pyupgrade, and formatting).
  - `ruff check` and `ruff format` in CI; both must pass.
- **Type check: `mypy`** in strict mode, or `pyright` (project's choice — pick one).
- **Test framework: `pytest`** (see [`50-testing.md`](50-testing.md)).
- **Python version: 3.11+**, pinned in `pyproject.toml` via `requires-python = ">=3.11"` and a `.python-version` file for `uv`.

## Type hints

- Required on all public function signatures (parameters and return type).
- Required on module-level variables whose type isn't obvious.
- Use built-in generics (`list[str]`, `dict[str, int]`), not `typing.List` / `typing.Dict`.
- Use `X | None`, not `Optional[X]`.
- `Any` is forbidden in committed code without a `# type: ignore[...]` comment that includes a ticket reference.
- Use `Protocol` for structural typing rather than abstract base classes when only a method signature matters.

## Naming

- `snake_case` for modules, functions, variables.
- `PascalCase` for classes.
- `UPPER_SNAKE_CASE` for module-level constants.
- Leading underscore (`_helper`) for module-private. Don't reach in.
- Don't shadow built-ins (`id`, `list`, `type`, `input`).

## Strings & data

- f-strings for formatting. Not `.format()`, not `%`.
- `pathlib.Path` for filesystem paths. Not `os.path` string concatenation.
- `datetime` always with timezone (`datetime.now(timezone.utc)`); naive datetimes are forbidden.
- Decimal for money (`from decimal import Decimal`); never floats.
- For structured data, in order of preference:
  1. `pydantic.BaseModel` for validated I/O at boundaries
  2. `@dataclass(frozen=True, slots=True)` for internal value objects
  3. `TypedDict` for plain dict shape annotation
  4. Dicts only for genuinely free-form data

## Errors

- Subclass `Exception` to define domain errors: `class BillingError(Exception)`.
- Never bare `except:` and never `except Exception: pass`. Catch the narrowest type you can handle.
- Re-raise with `raise` (preserves traceback) or `raise NewError() from original`.
- Never use exceptions for control flow on the hot path.

## Async

- `asyncio` for I/O concurrency; don't mix sync and async in one path.
- Run independent awaits in parallel: `asyncio.gather` / `asyncio.TaskGroup`.
- Don't block the event loop with sync I/O — wrap with `asyncio.to_thread` if you must.
- HTTP client: `httpx` (async-capable); not `requests` for new async code.

## Logging

- Use `logging`; never `print` in committed code.
- Configure once at startup. Modules call `logger = logging.getLogger(__name__)`.
- Structured logs preferred (`structlog` or JSON formatter) — `logger.info("login_succeeded", extra={"user_id": uid})`.
- No PII or secrets in log records.

## Project layout

```
project_root/
  pyproject.toml
  uv.lock
  .python-version
  src/
    myapp/
      __init__.py
      config.py          # env loading via pydantic-settings
      domain/            # pure logic, no I/O
      adapters/          # DB, HTTP, queue
      api/               # routes (FastAPI/Flask)
      cli.py             # entrypoints
  tests/
    unit/
    integration/
```

- `src/` layout (not flat) — prevents accidental imports of an uninstalled package during tests.
- Configuration via `pydantic-settings` reading from env. Loaded once, injected.
- Don't read `os.environ` deep in business logic.

## Don't do

- Mutable default arguments (`def f(x=[]):`). Use `None` and create inside.
- `from x import *`. Always explicit.
- `global` / `nonlocal` for state — pass it as an argument.
- `eval` / `exec` on any user-influenced input. Escalate if you think you need them.
- Catching `BaseException` (catches `KeyboardInterrupt`, `SystemExit`).
- `subprocess.shell=True` with interpolated input — pass an argv list.
