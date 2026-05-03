# Git workflow

## Branches

- `main` is always deployable. No exceptions.
- Feature work happens on a branch off `main` (or off the active release branch).
- Branch naming: `<type>/<ticket>-<short-desc>`
  - `feat/BIT-123-refresh-token-rotation`
  - `fix/BIT-456-null-pointer-on-logout`
  - `chore/BIT-789-bump-node-22`
  - Types match the Conventional Commits set: `feat`, `fix`, `chore`, `docs`, `refactor`, `test`, `perf`, `build`, `ci`, `revert`.
- One branch per ticket. Don't combine unrelated work.
- Delete the branch after merge. Long-lived branches drift.

## Commits

- **Conventional Commits** format, required:

  ```
  <type>(<scope>): <subject>

  <body>

  Refs: BIT-1234
  ```

- Subject: imperative, lowercase, no trailing period, ≤ 72 chars.
- Body: explain *why*. The *what* is in the diff. Wrap at 72 chars.
- Reference the ticket in the footer: `Refs: BIT-1234` or `Closes: BIT-1234`.
- One logical change per commit. If you can't summarize it in one line, it's two commits.
- **No AI co-author trailers.** See [Hard Rule §1](00-hard-rules.md).

## Pull requests

- One feature / fix per PR. PRs above ~400 lines of diff need an explicit reason.
- PR title = the merge commit's subject. Use Conventional Commits format there too.
- PR description (use [`templates/pull_request_template.md`](../templates/pull_request_template.md)) covers:
  - **What** changed (1–3 bullets, high level)
  - **Why** (link the ticket, summarize the motivation)
  - **How to test** (steps a reviewer can run)
  - **Risk** / rollback plan, if non-obvious
- Self-review before requesting review. Read your own diff with fresh eyes.
- Mark PRs `draft` while in progress; ready-for-review only when CI is green.

## Reviews

- At least **one approval** required. Risky areas (auth, billing, data migrations, infra) require a domain owner approval.
- Reviewers respond within one business day. If you can't, say so or reassign.
- Comments are constructive and specific. "This is bad" is not a review comment.
- Use suggestion blocks for small, accept-as-is changes.
- Author addresses every comment — fix, push back with reasoning, or open a follow-up ticket. Don't silently ignore.
- "LGTM" without inspection is dishonest. If you didn't read it, don't approve.

## Merging

- **Squash-merge** by default. Keeps `main` history one-commit-per-feature.
- Merge commit message uses the PR title (Conventional Commits) and the PR description body.
- Rebase-merge is allowed for sequences of small, well-separated commits the author wants preserved.
- Plain merge commits are not used — they clutter history.
- All required CI checks must be green at merge time. Never override.

## Keeping branches current

- Rebase your branch onto `main` periodically: `git fetch && git rebase origin/main`.
- Resolve conflicts locally, with full editor + tests. Don't resolve via the GitHub UI for non-trivial conflicts.
- After rebase, force-push to *your own* feature branch with `--force-with-lease`. Never force-push to a shared branch (see [Hard Rule §3](00-hard-rules.md)).

## Hotfixes

- Branch off the affected release branch (`release/x.y` or `main` if that's what's deployed).
- Same PR + review process. Hotfixes are not an excuse for skipping review — they're an excuse for *fast* review.
- After merging the hotfix to the release branch, also merge / cherry-pick into `main`.

## Tags & releases

- Tags are immutable. Never re-tag. Cut a new patch version instead.
- Semantic versioning: `MAJOR.MINOR.PATCH`.
- Release notes are generated from Conventional Commits — that's why the format matters.

## Things that look helpful but aren't

- `git commit -am "wip"` then squashing later — you lose the granularity that helps reviewers
- "I'll clean up the commits before merge" — clean as you go; rebases get harder, not easier
- Pulling with merge instead of rebase — creates noisy merge commits in feature branches
- `git checkout .` / `git reset --hard` to "start fresh" — you lose work that wasn't yet committed; `git stash` first
