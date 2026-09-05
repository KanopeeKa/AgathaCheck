# Protocol: documentation

**When:** Architecture, API, security model, AuthZ, data lifecycle, migration, operational behaviour changes.

---

## 1. Prefer executable truth

| Concern | Source of truth |
|---------|-----------------|
| API shape | Route tests + OpenAPI when maintained |
| Schema | Migrations |
| Invariants | Tests |

## 2. Docs explain why

- Intent and reasoning
- Policy and operational consequence
- ADR for major security/architecture decisions (R3)

## 3. Update when

- New public API or behaviour change → `docs/architecture/api-reference.md` or domain README
- Workflow change → `docs/agent-efficiency/` or `docs/engineering/`
- Intentional deferral → GitHub issue with `tech-debt` / `review-follow-up`

## 4. Do not

- Duplicate entire protocols in prose docs
- Document formatter/lint rules (tooling owns those)
