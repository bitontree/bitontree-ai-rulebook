# Security

The OWASP Top 10 is the floor, not the ceiling. These are practical rules that prevent the bugs we keep seeing.

## Input validation

- Validate every input that crosses a trust boundary: HTTP request, queue message, file upload, subprocess output, third-party webhook.
- Whitelist > blacklist. Define what's *allowed* and reject the rest.
- Length limits on every string field. Number ranges on every numeric field.
- Reject unknown fields; don't silently drop them.
- Validate before any I/O — DB lookups, file reads, downstream calls.

## Output encoding

- HTML output: use the framework's escaping (React's default, Jinja's `autoescape=True`). Never build HTML by string concat.
- `dangerouslySetInnerHTML` / `|safe` requires sanitization with DOMPurify / `bleach` and an explanation.
- Use `Content-Type` and `X-Content-Type-Options: nosniff` headers.

## Injection

- **SQL:** parameterized queries only. ORM with bind parameters, or raw SQL with `?` / `$1` placeholders. Never string-format SQL with user input.
- **NoSQL:** same principle — pass user input as values, never as query operators or keys.
- **Shell:** no `shell=True` with interpolated input. Pass argv lists. Better: don't shell out at all.
- **Template:** never `eval` user input as a template (Jinja `from_string` on user input enables RCE).

## Secrets

- Env vars only. No hardcoded credentials, API keys, or connection strings.
- Loaded once at boot via `pydantic-settings` / a typed config module.
- Stored at rest in: 1Password / AWS Secrets Manager / Azure Key Vault / HashiCorp Vault — never in repos, never in chat, never in tickets.
- Rotated on a schedule and on every offboarding.
- A leaked secret is rotated *first*, history-cleaned *second*. Don't reverse the order.

## Authentication

- Don't roll your own auth. Use OAuth2/OIDC (Auth0, Clerk, Cognito, Keycloak) or your platform's identity service.
- Passwords: bcrypt / argon2 with a per-password salt. Never SHA-256, never plaintext.
- MFA available on every product that holds user data.
- Sessions: cookies with `HttpOnly`, `Secure`, `SameSite=Lax` (or `Strict` where the UX allows). Tokens for APIs, cookies for browsers.
- JWTs: short-lived (≤ 1h), refresh tokens with rotation. Revocation list for compromised tokens.

## Authorization

- Authorize on every request, server-side. Never trust client-side checks.
- Object-level: verify the requester owns / has access to the resource — not just that they're logged in. (IDOR is the most-shipped bug.)
- Default deny. Explicit allow.
- Admin actions are logged with actor + target + timestamp.

## Transport & headers

- HTTPS in all environments past local dev. HSTS in production.
- Security headers (set at the edge or in middleware):
  - `Strict-Transport-Security: max-age=31536000; includeSubDomains`
  - `X-Content-Type-Options: nosniff`
  - `X-Frame-Options: DENY` (or CSP `frame-ancestors`)
  - `Content-Security-Policy: ...` — start strict, relax with care
  - `Referrer-Policy: strict-origin-when-cross-origin`
- CORS allow-list, no `*` in production.

## Rate limiting

- Auth endpoints (login, signup, password reset) rate-limited per IP + per account.
- LLM-backed endpoints rate-limited per user (see [`30-langchain-langgraph.md`](30-langchain-langgraph.md)).
- Public APIs have a global limit; authenticated APIs have a per-key limit.
- Return `429 Too Many Requests` with `Retry-After`.

## Logging & PII

- Never log: passwords, tokens, full credit card numbers, API keys, full DOB, government IDs, raw OAuth codes.
- Mask user emails / phones in logs (`u****@example.com`).
- Logs are PII-grade — same retention and access controls as the database.

## Dependencies

- Audit on every PR (CI step): `npm audit`, `uv pip audit` / `pip-audit`, GitHub Dependabot.
- Critical / high severity blocks merge. Medium gets a ticket.
- New dependencies require justification. Prefer well-maintained, recently-updated packages with > 1 author.
- Lockfile is committed and respected. Don't update transitive deps without intent.
- Generated SBOMs for production artifacts.

## File uploads

- Validate type by content sniffing, not extension or `Content-Type` (both are spoofable).
- Cap size at the gateway, not in application code.
- Store outside the web root or behind a signed-URL mechanism. Never serve user uploads from the same origin as your app under the same path.
- Scan for malware on anything user-supplied that other users will receive.

## Deserialization

- No `pickle.loads` / `yaml.load` (use `yaml.safe_load`) on untrusted input.
- JSON only at the boundary; deserialize to a typed model, not free dicts.

## Don't do

- Disable certificate verification in HTTP clients (`verify=False`, `rejectUnauthorized: false`)
- Send secrets in URL query strings (they end up in logs and `Referer` headers)
- Use `Math.random()` / `random` for security tokens — use `crypto.randomBytes` / `secrets.token_urlsafe`
- Build SQL or shell strings with `+` or `f"..."` and user input
- Email or chat passwords in plain text — even one-time, even "internally"
