---
title: Organization roles and permissions
owner: Documentation Team
audience: both
status: active
last_updated: 2026-08-22
tags: [domain,organization,specs,permissions]
---

# Organization roles and permissions

Extracted from [/docs/org-fostering-strategy.md](/docs/org-fostering-strategy.md) (org-identity sections). Foster **placement lifecycle** and transfer workflows belong in the [fostering domain](/docs/domains/fostering/README.md).

## Glossary (org roles)

| Term | Meaning |
|------|---------|
| **Super admin** | Full control including edit/delete org. Multiple allowed. |
| **Admin** | Manage members, pets, foster placements; cannot edit/delete org. |
| **Foster** | Sees only pets they are fostering + org contact details. |
| **Owner** | `pets.user_id` — legal owner in the system. |
| **Shared** | `pet_access.role = shared` — collaborator via share link. |
| **Foster access** | `pet_access.role = foster` — day-to-day care during an active placement. |

### DB role values

| DB value | UI label | Notes |
|----------|----------|-------|
| `super_admin` | Super admin | Edit/delete org; assign any role |
| `admin` | Admin | Manage members, pets; cannot edit/delete org or assign super_admin |
| `foster` | Foster | Org contact only until placements assign pets |
| `pending_*` | Invited | Awaiting accept |

## Permission matrix (target)

| Action | Super admin | Admin | Foster |
|--------|:-----------:|:-----:|:------:|
| Edit / delete org | ✓ | ✗ | ✗ |
| Invite / remove members | ✓ | ✓ | ✗ |
| Promote to super admin | ✓ | ✗ | ✗ |
| See all org pets | ✓ | ✓ | ✗ |
| See org contact | ✓ | ✓ | ✓ |
| Foster parent directory | ✓ | ✓ | ✗ |
| Start / manage placements | ✓ | ✓ | ✗ |
| Day-to-day pet care (fostered pet) | ✓ | ✓ | ✓ |
| Transfer ownership | ✓ | ✓ | ✗ |
| Share pet (as foster) | — | — | ✓ |

**Validation lesson:** [.agents/memory/body-supplied-org-id-validation.md](/.agents/memory/body-supplied-org-id-validation.md)

---

**Custody data model:** [org-custody-model.md](org-custody-model.md) · **Member privacy:** [org-member-privacy.md](org-member-privacy.md)
