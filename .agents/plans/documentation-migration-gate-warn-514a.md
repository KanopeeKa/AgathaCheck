# Documentation migration — integration docs gate warn (`documentation-migration-gate-warn-514a`)

**Outcome:** PR merged to `cursor/documentation-migration-integration-514a` sets `DOCS_GATE_MODE: warn` for consolidation Phase A.

**docs_targets:** N/A — CI workflow only; handover §4.

## Phase 1 — Advisory docs gate on integration

**branch:** `cursor/documentation-migration-gate-warn-514a`

Change `.github/workflows/docs-gate.yml` env `DOCS_GATE_MODE` from `block` to `warn`. PR body documents temporary Phase A per migration handover.
