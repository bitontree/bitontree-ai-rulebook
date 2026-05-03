<!--
PR title must follow Conventional Commits:
  <type>(<scope>): <subject>
e.g. feat(auth): rotate refresh tokens on every use
-->

## What

<!-- 1–3 bullets describing the change at a high level. -->

-

## Why

<!-- The motivation. Link the ticket. -->

Refs: BIT-

## How to test

<!-- Steps a reviewer can run locally. Include commands, URLs, test data. -->

1.
2.

## Risk & rollback

<!--
- What could break?
- How would we notice?
- How do we roll back?
Skip this section only for trivial / docs-only changes.
-->

## Checklist

- [ ] PR title follows Conventional Commits
- [ ] Linked ticket in `Refs:` / `Closes:`
- [ ] Lint, types, and tests pass locally (`npm test` / `uv run pytest`)
- [ ] No new lint/type/test suppressions without ticket + reason
- [ ] No secrets, `.env`, or large binaries committed
- [ ] Updated docs (README / OpenAPI / type signatures) if behaviour changed
- [ ] No AI co-author trailers in commits
