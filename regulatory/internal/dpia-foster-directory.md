# DPIA — Organisation People Directory & Foster Contact Data

**Document classification:** Internal — Confidential  
**Last updated:** 5 July 2026  
**Owner:** SAS McCauley Conseils (Agatha Track)

## 1. Description of processing

Agatha Track allows charity/rescue organisations to maintain a **people directory** including:
- Registered members (Super Admin, Admin, Foster roles)
- External foster contacts without app accounts

Per-organisation **foster contact fields** (phone, foster contact address, admin notes) and foster placement history are stored to coordinate fostering operations.

External contacts receive an **Art. 14 informational email** when added, after admin attestation of lawful basis.

## 2. Necessity and proportionality

| Data | Purpose | Proportionality |
|------|---------|-----------------|
| Name, email | Identity, invites, linking accounts | Minimum necessary |
| Foster phone / address | Operational contact for placements | Org-scoped; required for foster role before placement |
| Admin notes | Operational coordination | Org-scoped; free-text limited; operational-only guidance in UI |
| Placement history | Audit trail, current/past foster status | Core service feature |

Data is **not** shared across organisations. External foster data is never visible outside the creating organisation.

## 3. Risks and mitigations

| Risk | Likelihood | Impact | Mitigation |
|------|------------|--------|------------|
| Cross-org data leakage | Low | High | Strict `organization_id` filters on all APIs; no global notes |
| Unauthorised access | Medium | High | Admin-only endpoints; JWT auth; role checks |
| Art. 14 failure for external fosters | Medium | Medium | Mandatory checkbox + auto email with privacy link |
| Sensitive data in free-text notes | Medium | Medium | UI helper text; DPA special-category prohibition; admin training |
| Inaccurate contact data | Medium | Low | Admin edit + user view of linked profiles on registration |
| Breach of contact/address data | Low | High | HTTPS, EU hosting, breach notification procedure |

## 4. Data subject rights

- Registered users: profile edit, export, erasure via account deletion (cascade)
- External fosters: rights via organisation or contact@agathatrack.com; informational email explains rights
- Platform assists organisations as processor under DPA

## 5. Residual risk

Residual risk is **acceptable** for launch at current scale, subject to:
- Annual review of this DPIA
- Monitoring for special-category data in notes (no automated scanning at launch)
- Re-assessment if analytics, profiling, or large-scale processing is introduced

## 6. Consultation

No supervisory authority consultation required at current processing scale and risk profile. Review if processing exceeds 10,000 data subjects or systematic monitoring is added.
