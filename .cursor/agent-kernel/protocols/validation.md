# Protocol: validation

**When:** External input: bodies, query params, path IDs, uploads metadata, enums, dates.

---

## 1. Inspect

- Existing validation patterns in the domain route
- Shared validators in `server/lib/`
- Client-side validation (must not be sole enforcement)

## 2. Requirements

- Declarative, consistent validation per field
- IDs: format + existence where required
- Enums: reject unknown values
- Text: bounds (min/max length)
- Numbers: range; **invalid input must not silently become 0 or default**
- Dates: `YYYY-MM-DD` calendar dates vs instants (`date-time.md`)
- Arrays: max length, element validation
- Cross-field rules (e.g. end after start)
- Foreign resource relationships verified server-side
- Unknown-field policy: strip or reject consistently

## 3. Invariants

- Malformed values → 4xx with stable error shape, not 500
- No SQL string concatenation — parameterized queries only

## 4. Tests

- Happy path valid payload
- Each invalid rule: missing required, out of range, wrong type, unknown enum
- Authorization separate (`authorization.md`)

## 5. Verification

Jest route tests with invalid payloads; `./scripts/pre-push-changed.sh`.
