---
name: Frozen domains code removal (2026-11)
description: Shelter/Fostering product code deleted; boundary CI kept; data APIs pending retirement.
---

Execute-plan `frozen-domains-removal-3f9c` removed frozen Flutter roots, unused server modules, frozen E2E, and active UI that described organisation/fostering workspaces. **MVP is Pet Care only.**

**Engineering record:** [docs/engineering/frozen-domains/README.md](/docs/engineering/frozen-domains/README.md) (date, tag `pre-frozen-domains-removal-2026-11`, kept server modules, data decision pending).

**Still in repo until a separate owner PR:** `check_frozen_domain_boundaries.sh`, `manifest.json`, pre-push frozen exclusions (protected CI paths).

**Agent lesson:** Do not reintroduce Shelter/Fostering screens, workspace toggles, or org-workspace copy — terminology rule in [terminology.md](/docs/design/terminology.md). Server modules `fosterPlacements`, `adoptionJourneys`, etc. may remain for migrations/GDPR only.
