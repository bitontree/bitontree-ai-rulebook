# Hard Rules — full text

These are non-negotiable. If you find yourself wanting to break one, escalate first; do not act.

## 1. No AI co-authorship

Never add lines like:

```
Co-Authored-By: Claude <noreply@anthropic.com>
Co-Authored-By: GitHub Copilot <noreply@github.com>
Co-Authored-By: Codex <noreply@openai.com>
```

**Why.** Commits represent human responsibility. Author and co-author fields belong to the people who reviewed and shipped the change. AI assistants are tools, not contributors. Attribution to an AI muddles ownership, complicates audit trails, and exposes internal tooling to public history.

**How to apply.** Configure your AI agent to omit these trailers. The `commit-msg` hook in [`templates/commit-msg-hook`](../templates/commit-msg-hook) blocks them automatically — install it via `scripts/install-global.sh`.

## 2. No secrets in commits

Never commit `.env*`, API keys, tokens, OAuth secrets, private keys, certificates, keystores, database URLs with credentials, customer data, PII, or production samples.

**Why.** Once a secret is in git history it is leaked, even after deletion. Rotation across multiple systems is expensive and sometimes impossible (third-party tokens cannot always be revoked).

**How to apply.**
- Use the org `.gitignore` from [`templates/.gitignore`](../templates/.gitignore)
- Add a pre-commit secret scanner (`gitleaks`, `trufflehog`, or GitHub native secret scanning)
- If a secret leaks: rotate it immediately, then remove from history with `git-filter-repo` and force-push (this is the **only** sanctioned force-push case, and only with team coordination)

## 3. No force-push to protected branches

No `git push --force` or `--force-with-lease` to `main`, `master`, `develop`, `staging`, `production`, or any release branch.

**Why.** Force-push silently destroys work that other engineers have based on. Recovering from it costs hours and sometimes loses data.

**How to apply.** Configure server-side branch protection. Use feature branches for everything; never reset history on a branch others have pulled.

## 4. No bypassing git hooks

No `--no-verify`, `--no-gpg-sign`, or any flag that skips pre-commit, commit-msg, or pre-push hooks.

**Why.** Hooks enforce checks that prevent broken builds and policy violations. Bypassing them defeats the purpose of having them.

**How to apply.** If a hook fails, fix the cause. If the hook itself is wrong, fix the hook in a separate PR.

## 5. No direct pushes to protected branches

Every change is a PR with at least one reviewer approval and green CI.

**Why.** Code review catches bugs, shares context, and creates an audit trail.

**How to apply.** Branch protection enforces this server-side. If you have permission to push directly, you still don't.

## 6. No silencing of lint, type, or test failures

Do not add to make CI green:

- `eslint-disable` / `eslint-disable-next-line`
- `// @ts-ignore` / `// @ts-expect-error`
- `# type: ignore` / `# noqa`
- `it.skip` / `xit` / `xdescribe` / `pytest.skip`

**Why.** These tools find real problems. Silencing them either hides a bug or normalizes ignoring tooling, which compounds.

**How to apply.** Fix the underlying issue. If a suppression is genuinely needed, it must include a ticket and a reason on the same line:

```ts
// eslint-disable-next-line no-explicit-any -- BIT-1234: blocked on third-party type defs, remove when @vendor/sdk@2 ships
```

```py
result = unsafe_call()  # type: ignore[arg-type]  # BIT-5678: SDK stubs missing, remove on next release
```

PRs that contain bare suppressions without ticket + reason will be rejected in review.

## 7. No rewriting of shared git history

Do not `git reset --hard`, `git rebase`, or `git push --force` on commits already pushed to a shared branch — even your own feature branch — without coordinating with anyone who may have based work on it.

**Why.** Rewritten history breaks others' clones; recovery is painful and sometimes lossy.

**How to apply.** Use `git revert` instead of `reset` for pushed commits. If you must rewrite, announce it in the team channel first.
