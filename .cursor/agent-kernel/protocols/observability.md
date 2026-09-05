# Protocol: observability

**When:** Meaningful backend/infrastructure behaviour change — not R0 copy edits.

---

## 1. Consider proportionally

- Structured logs for new failure modes
- Request/correlation IDs where pipeline supports
- Security-relevant events (auth failure, grant denied) without sensitive payloads
- Error classification (client vs server)
- Health/readiness if deploy surface changes

## 2. Invariants

- No secrets, tokens, passwords, or health payloads in logs
- No raw stack traces to clients (see `security.md`)

## 3. Skip for

- Pure Flutter presentation with no server change
- Comment-only or doc typo changes
