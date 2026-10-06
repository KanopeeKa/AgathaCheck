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

- **Product behaviour change (any surface):** run `/canonical-docs sync` — `.cursor/skills/canonical-docs/SKILL.md` Mode A; policy in `docs/domains/documentation/standards.md`.
- **Deeper architecture / ADR:** this protocol plus `docs/architecture/` when Router assigns `documentation` for significant architecture (see ROUTER §4).
- **Agent workflow change:** `docs/agent-efficiency/` or skill docs — not domain `features/` unless product behaviour changed.
- **Intentional deferral:** GitHub issue with `tech-debt` / `review-follow-up`

## 4. Do not

- Duplicate entire protocols in prose docs
- Document formatter/lint rules (tooling owns those)
