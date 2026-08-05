# Public access gate — agent traps

Canonical ops: [`docs/ops/public-access.md`](../../docs/ops/public-access.md). Plan: `public-access-gate-a35f`.

## Traps

1. **FTP excludes `.htaccess`** — cPanel Directory Privacy can vanish after a web FTP sync. Anonymous 401 disappearing after deploy often means the privacy file was not uploaded, not that Basic Auth was “turned off in the app”.

2. **401 ≠ WAF** — HTTP Basic Auth returns **401**. Tiger Protect WAF challenges return HTML (often 503) with challenge markers. Never classify anonymous 401 as WAF; smoke kind is `basic_auth`.

3. **`isLiveUatTarget` vs `isLiveProdTarget`** — UAT-only behavior (WAF warmup, E2E bypass token, `prepareLiveApiAccess`, live stealth, Basic Auth credentials) must gate on **`isLiveUatTarget`**. Use **`isLiveProdTarget`** for prod-only checks. Keep **`isLiveHostingTarget`** only for “any live `*.agathatrack.com`” concerns (e.g. longer timeouts).

4. **Smoke mode contracts** — Teaser mode: body must include `data-site-mode="coming-soon"`; Flutter `main.dart.js` must **not** be served. API `coming_soon`: health **200**, auth **403** `public_access_closed`. UAT Basic Auth on: anonymous **401** proof before credentialed checks.
