# Agatha care journey — BDD scenarios (expanded per phase; PR-01 stub)
@pet_care @agatha-care-journey
Feature: Agatha care journey profile facts
  Profile identification and neuter facts persist with merge-safe PUT semantics.

  @ACJ-PF-01
  Scenario: Neuter status survives profile reload
    Given a guardian owns a pet with neuter status "no"
    When the guardian updates the pet name without sending neuter status
    Then the pet detail still shows neuter status "no"

  @acj @pr-03 @smoke-uat
  Scenario: ACJ-IC-01 — Record neuter no from sheet on inset prompt
    Given a guardian owns a pet with unknown neuter status
    When the guardian records neuter status "no" from the profile inset sheet
    Then the pet detail shows neuter status "no"

  @acj @pr-03 @smoke-ci @authz
  Scenario: ACJ-IC-02 — View-only cannot record profile facts
    Given a shared carer views a pet with unknown profile facts
    Then the profile inset Record action is disabled

  @acj @pr-04 @smoke-uat
  Scenario: ACJ-AC-01 — Chip recorded hides completeness card
    Given a guardian owns a pet with unknown microchip status
    When the guardian records microchip identification from the Agatha completeness card
    Then the pet profile no longer shows the microchip completeness card

  @acj @pr-04
  Scenario: ACJ-AC-02 — Agatha chrome on completeness cards
    Given a guardian owns a pet with unknown neuter status
    Then the pet profile shows an Agatha completeness card with profile category

  @acj @pr-04 @smoke-ci
  Scenario: ACJ-GUARD-01 — Completeness actions do not create care rhythms
    Given a guardian owns a pet with unknown profile facts
    When the guardian dismisses the neuter completeness card
    Then no new care rhythm appears on the pet profile

  @acj @pr-05 @smoke-ci
  Scenario: ACJ-SP-01 — Safeguard hides rhythm suggestion
    Given a guardian owns a pet with an active weight safeguard and pending rhythm suggestion
    Then the pet profile shows the safeguard card and not the rhythm suggestion

  @acj @pr-11 @smoke-uat
  Scenario: ACJ-FB-01 — chip save clears welfare suggestion
    Given a guardian owns a pet with microchip welfare pending
    When the guardian saves a microchip id on the pet profile
    Then the pet profile no longer shows the microchip welfare suggestion

  @acj @pr-12 @smoke-uat
  Scenario: ACJ-CO-01 — same-day date header
    Given a guardian owns two care items due on the same future day
    When the guardian opens the care agenda due soon section
    Then the care agenda shows a same-day date header for that day

  @acj @pr-13 @smoke-ci
  Scenario: ACJ-CO-02 — coordination banner links only
    Given a guardian owns two pets with care due on the same future day
    When the guardian opens the care agenda due soon section
    Then the care agenda shows coordination links for each pet
