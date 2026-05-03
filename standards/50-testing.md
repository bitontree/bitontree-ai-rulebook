# Testing

## Mandated frameworks

- **JavaScript/TypeScript: Jest.** Not Vitest, Mocha, AVA, Jasmine.
  - React: Jest + React Testing Library.
  - Don't ship Enzyme. It's deprecated.
- **Python: pytest.** Not unittest, nose.
  - Async: `pytest-asyncio`.

## Coverage

- New code: ≥ 70% line coverage. Higher for domain logic; lower for thin glue is acceptable.
- Coverage measured per PR. A drop > 2% requires justification in the PR description.
- Coverage is a floor, not a target. 100% coverage with no assertions is worthless.

## Test structure

- **Arrange — Act — Assert**, in that order, with a blank line between sections for readability.
- One *behavior* per test. Multiple assertions are fine if they describe the same behavior.
- Test name describes behavior, not implementation:
  - Bad: `test_returns_true`
  - Good: `test_login_succeeds_with_valid_credentials`
  - JS: `it('rejects login when password is wrong', ...)`

## Test pyramid

- **Unit:** fast (< 50ms each), no I/O, no network. Run on every save.
- **Integration:** real DB, real queue, real cache where reasonable. Run on every PR.
- **E2E:** full stack via Playwright (web) or HTTP client (API). Run on every PR for the critical path; nightly for the long tail.

Keep tiers separate: `tests/unit/`, `tests/integration/`, `tests/e2e/`. CI runs them in stages so a unit failure short-circuits integration.

## Mocks

- Mock at boundaries — outbound HTTP, third-party SDKs, system clock, randomness.
- **Do not mock the database in integration tests.** Use a real DB (Docker, testcontainers, ephemeral test DB). Mocks lie about migrations.
- Don't mock the system under test. If you need to mock it, the design is wrong.
- Prefer dependency injection over monkey-patching. Test seams should exist by design.

## Determinism

- Tests do not depend on external networks. CI must pass with no internet.
- Tests do not depend on wall-clock time. Inject a clock; freeze it.
- Tests do not share state. Use isolated DB schemas / fresh in-memory state per test.
- Random values get a seed. Flaky tests are bugs — fix or delete, never retry-loop.

## Snapshots

- Use sparingly. Snapshots are useful for serializers, schema dumps, generated artifacts.
- Don't snapshot whole React component trees — they break on every prop addition and devs blindly accept the diff.
- Every snapshot has a comment explaining what it's protecting against.

## What to test

- Public behavior, not private implementation. If you have to expose internals to test, redesign.
- Edge cases: empty input, single element, max input, boundary values, unicode, timezones.
- Error paths, not just happy paths.
- Regression tests when fixing a bug — the test that would have caught it.

## What not to test

- Library code (the libraries have their own tests).
- Trivial getters/setters / pass-throughs.
- Type-only assertions in TS — let the compiler do that.
- The framework. Don't test that React renders. Test your component.

## Forbidden

- `it.skip`, `xit`, `xdescribe`, `pytest.skip`, `@pytest.mark.skip` without a ticket reference and reason on the same line.
- Catching an assertion error and continuing — let it fail.
- `setTimeout` / `time.sleep` in tests as a substitute for awaiting a condition. Use `waitFor`, polling helpers, or proper async.
- Tests that pass when run alone but fail in a suite (or vice versa) — that's shared state, fix it.
- Commented-out tests.

## CI

- All tests run on every PR. PRs cannot merge with failing tests.
- Required checks include: lint, type, unit, integration, coverage report.
- Test execution is parallelized where it doesn't cause shared-state issues.
- Test artifacts (coverage reports, failure screenshots, traces) are uploaded for at least 7 days.
