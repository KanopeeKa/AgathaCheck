# tz-repair-followup-e76a

## Goal

Close gaps from the post-merge ops audit (#1602 / host runbook): repair script timezone and spec coverage (D3–D5), Paris CI breadth (AC-TZ2), and remaining DATE pool hygiene.

**Prerequisite:** #1602 on `main`; ops `.env` + D2 reopen fixes land in `cursor/tz-repair-ops-fix-e76a` first.

## Phases

### Phase 1 — Repair `todayIso` from pet home TZ

- `repairTzShift` / CLI: default “today” from pet `home_timezone` (or explicit `--as-of-date`), not UTC `toISOString`.
- Tests: Paris boundary fixture (00:30 Europe/Paris).

### Phase 2 — DC-4 D3/D4/D5 repair scope

- D3: delete off-series `schedule` rows (flag person-acted).
- D4: flag suspect `schedule_anchor_date`; recompute `next_due_date` where safe.
- D5: `--report-d5` listing user-edited DATE rows since deploy.
- Integration fixtures per AC-DC6 / spec §9.2.

### Phase 3 — AC-TZ2 Paris CI matrix

- Run backend Jest + care DB integration under `TZ=Europe/Paris` in CI (not only pgTypes + tick smoke).

### Phase 4 — Pool bootstrap hygiene + TZ-4 inventory doc

- Extend `check_pg_pool_bootstrap` (or sibling) to `scripts/care/audit_care_families.js`.
- Document DATE-column inventory (TZ-4) in ops/architecture doc.

## Autonomy

Pending `approve-autonomous tz-repair-followup-e76a` on control issue (bootstrap via `init-control-issue`).
