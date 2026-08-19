## Problem

PR #649 (UX Overhaul integration) merged to `main` and deployed to UAT, but **most planned work from phases 1–3 never landed in Flutter**. Phase PRs #647–#648 closed with only root-level Python helper scripts (`fix_*.py`, `replace_strings.py`) that were never executed against source files.

UAT correctly reflects `main`: drawer still shows **Guardian / Organisation**, chooser FTUE unchanged, form polish missing, etc.

## Root cause (audit 2026-08-19)

| Phase | Branch | Intended work | Actually on `main` |
|-------|--------|---------------|-------------------|
| **1** | `cursor/ux-overhaul-phase2-13e3` commits `b9019f1b`…`57b62f3a` | Strings, landing rules, notification deep-links, snackbar removal, ChoiceChips remind field, delete-pet name, org form hint | **None** of the 7 Flutter commits |
| **2** | `be859576` | Action-oriented FTUE, invite bypass, empty-state cross-link | **Never implemented** (scripts only) |
| **3** | `22b0920b` via #649 | Remove legacy `AppExperience` state | **Partial** (`activeExperienceProvider` removed; other diffs remain) |

Reference plan: `.agents/plans/ux-overhaul-plan.md`

## Delivery

- **Blocked on:** PR #654 (`pr/guardian-operations-mobile-completion`) — overlaps `app_en.arb`, `app_fr.arb`, guardian home/events widgets.
- **Implementation PR:** #655 (`cursor/ux-drawer-labels-my-pets-shelters-8e8e`) — rebase onto `main` after #654 merges; expand to full recovery.

## Checklist — Phase 1 (Routing, Navigation & Form Polish)

- [ ] Navigation l10n: `drawerGuardian` → **My Pets**, `drawerOrganisation` → **Shelters** (+ related dashboard/account toggle copy; EN+FR; avoid blind global replace)
- [ ] Deterministic landing rules in `experience_resolve_screen.dart` (pets >0 → `/g/home`; 0 pets + orgs → `/o/home`; else `/g/home`)
- [ ] Notification bell deep-links into Shelter views (`notification_navigation.dart`, panel/screen)
- [ ] Remove redundant validation Snackbars from form screens (inline borders instead)
- [ ] `HealthEntryRemindField` → ChoiceChips
- [ ] `confirmDeletePet` dialog shows pet name (remove `deletePetConfirm('')` hack)
- [ ] `OrganizationFormScreen`: remove empty-string id hack; add `hintText`
- [ ] Update E2E locators + widget tests
- [ ] Delete root-level `fix_*.py` / `replace_*.py` / `update_*.py` scaffolding scripts

## Checklist — Phase 2 (Onboarding & Empty States)

- [ ] Replace `ExperienceChooserScreen` with action-oriented FTUE (3 choices per plan)
- [ ] "I'm fostering a pet" dialog with optional code entry
- [ ] Auth: invite-link signups bypass FTUE
- [ ] My Pets empty state cross-links to Shelters
- [ ] Shelter settings accessible from Shelter dashboard
- [ ] BDD/E2E updates for changed onboarding flows

## Checklist — Phase 3 (Architecture cleanup — reconcile)

- [ ] Reconcile remaining diffs vs `origin/cursor/ux-overhaul-phase3-13e3` (`experience_section_drawer`, `pet_detail_viewer_context_provider`, `resolve_post_login_path` tests)
- [ ] Confirm no resurrection of `activeExperienceProvider` / `lastAppSectionProvider`

## Verification

- [ ] `./scripts/pre-push-changed.sh` during iteration; `./scripts/pre-push.sh` before merge
- [ ] `flutter test` for touched areas
- [ ] Manual: hamburger drawer shows **My Pets** / **Shelters**; landing rules; FTUE; delete-pet dialog shows name
- [ ] UAT deploy shows changes after merge

## References

- Integration merge: #649 (`5288f9a6`)
- Phase branches: `origin/cursor/ux-overhaul-phase2-13e3`, `origin/cursor/ux-overhaul-phase3-13e3`
- Recovery PR: #655
