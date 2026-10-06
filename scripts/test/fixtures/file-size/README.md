# File size gate fixtures

Used by `scripts/check_file_size.test.js` (synthetic temp dirs) and manual repro.

Violations exercised:

- New 501-line `server/lib` file without allowlist entry (blocking D7).
- Allowlisted file growing past `maxLines`.
- Expired `review_date` warning on allowlist entries.
