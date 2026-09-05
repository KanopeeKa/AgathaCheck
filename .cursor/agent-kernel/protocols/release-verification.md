# Protocol: release-verification

**When:** Major user journeys, final execute-plan phases, ui-design-deep multi-step flows, pre-release assessment. **Not** the same as `/babysit-uat` CI pre-UAT watch.

**CI pre-UAT:** `/babysit-uat` + `pre-uat-e2e.yml` — keep separate.

---

## 1. Journey-first

Start from user goal → trace UI → state → API → AuthZ → persistence.

## 2. Actors (select applicable)

Owner · collaborator · foster · revoked foster · org member/admin · unrelated user · anonymous

## 3. States (select applicable)

Happy · loading · empty · partial data · validation error · server error · slow network · offline · session expired · unauthorized · repeat action · realistic volume

## 4. Security-negative UAT examples

| Area | Don't only test |
|------|-----------------|
| Sharing | Owner can share → also revoked/expired fail, scope doesn't leak |
| Health | Owner sees record → unrelated user denied, attachment bytes protected |

## 5. Root cause classification (defects found)

UI · state · domain · API · AuthZ · data integrity · storage · environment/test-data

Fix at the actual layer — not symptom-only patches.

## 6. Verification

- Manual/computer-use walkthrough for major UI
- BDD/Playwright for automated journey coverage
- Lower-level tests per `testing.md` for defects found

Optional future: `/release-gate` skill with GO / NO-GO — deferred.
