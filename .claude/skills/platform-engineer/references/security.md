# Security Pass Checklist

## Authentication & Authorization

- **Hardcoded credentials**: grep for `password =`, `secret =`, `api_key =` in source (not .env)
- **JWT secrets**: must come from env vars, minimum 32-char entropy; never committed
- **Weak hashing**: MD5/SHA1 for passwords → must be bcrypt/argon2/scrypt
- **Missing auth guards**: every protected route/controller must have a guard/middleware; verify OPTIONS/HEAD verbs too
- **Role checks**: privilege escalation paths — can a user-role endpoint access admin data?
- **Session fixation**: session ID regenerated after login?
- **Password reset tokens**: single-use, time-limited (≤15 min), invalidated after use?

## Injection

- **SQL injection**: `$queryRaw` / `db.execute` with string concatenation → parameterized queries required
  ```typescript
  // BAD
  prisma.$queryRaw(`SELECT * FROM users WHERE id = ${userId}`)
  // GOOD
  prisma.$queryRaw`SELECT * FROM users WHERE id = ${userId}`
  ```
- **NoSQL injection**: MongoDB `$where`, `$regex` with user input → sanitize with allowlist
- **XSS**: `dangerouslySetInnerHTML`, `innerHTML =`, `.html()` with user data → encode or use textContent
- **Command injection**: `exec()`/`spawn()` with user input → use allowlists + argument arrays, never shell interpolation
- **Path traversal**: file operations with user-supplied paths → `path.resolve` + check starts with allowed base

## Secrets Exposure

- **Committed secrets**: check `git log` for .env files, API keys, tokens in history
- **Secrets in logs**: `console.log(user)`, `logger.info(req.body)` — PII/tokens must never be logged
- **Secrets in error responses**: stack traces, DB errors exposed to client → sanitize in production
- **Hardcoded in frontend**: API keys in React/Swift source compiled into the binary

## Rate Limiting & DoS

- **Auth endpoints** (`/login`, `/register`, `/reset-password`): must have rate limiting (e.g., 5 req/min/IP)
- **AI/agent endpoints**: token-expensive routes need throttling
- **Resource-intensive endpoints**: file uploads, image processing, search — limit frequency and payload size
- **Missing pagination**: list endpoints returning unbounded results → add `limit`/`offset` or cursor

## Prompt Injection (AI/Agent code)

- **User input in system prompt**: never interpolate untrusted user data directly into system prompts
- **Tool call validation**: validate all arguments returned by the model before executing
- **Indirect injection**: fetched web content / user files used in prompts → sanitize or sandbox
- **Privilege escalation via prompt**: model asked to "ignore previous instructions" — use separate system + user turns

## CORS & Transport

- **CORS `*` with credentials**: `Access-Control-Allow-Origin: *` combined with `credentials: include` → browsers will reject; must echo specific origin
- **HTTPS enforcement**: HTTP responses missing `Strict-Transport-Security` header in production
- **Cookie flags**: session/auth cookies missing `HttpOnly`, `Secure`, `SameSite=Strict`

## Dependency Security

- **Known CVEs**: run `npm audit` / `bundle audit` / `pip audit`; flag any High/Critical unpatched deps
- **Outdated auth libraries**: passport.js, next-auth, better-auth — check for known bypass vulnerabilities

## Severity Classification

| Finding | Severity |
|---|---|
| SQL/NoSQL injection | 🔴 Critical |
| Hardcoded secrets in source | 🔴 Critical |
| Missing auth on protected route | 🔴 Critical |
| Prompt injection with tool execution | 🔴 Critical |
| XSS with stored/reflected data | 🟠 High |
| Missing rate limiting on auth | 🟠 High |
| Weak password hashing | 🟠 High |
| Secrets in logs | 🟠 High |
| CORS misconfiguration | 🟡 Medium |
| Missing HSTS | 🟡 Medium |
| Missing cookie flags | 🟡 Medium |
| Outdated deps (no active CVE) | 🟢 Low |
