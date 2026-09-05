# Protocol: private-files

**When:** Uploads, PDFs, health documents, exports, sensitive images.

**Related:** `security.md`, `authorization.md`, `data-lifecycle.md`.

---

## 1. Inspect

- `saveUploadedFile()` usage and storage root
- Multer config (`memoryStorage`, MIME allowlist)
- Download/serve handlers and AuthZ on **bytes**
- Deletion paths (metadata + blob)

## 2. Invariants

- Health/sensitive files **private by default**
- Server-generated UUID `fileId` — never path from `originalname` or user params
- `saveUploadedFile()`: path containment, mode `0o600`
- **Opaque filename/URL is not authorization** — bytes require AuthZ check
- MIME sniffing / allowlist; size limits
- Extension vs content consistency
- Signed URL expiry if used
- Caching headers appropriate for sensitivity
- Content-Disposition for downloads

> Sensitive + permanently public retrievable URL = security failure unless explicit documented product decision.

## 3. Tests

- Owner can fetch; unrelated user cannot
- Revoked collaborator cannot
- Delete removes blob + metadata

## 4. Verification

Jest/integration for auth on file routes; grep for `originalname` in path construction.
