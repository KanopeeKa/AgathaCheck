# Agatha care journey — BDD traceability (Playwright: e2e/bdd mirror)
@pet_care @agatha-care-journey
Feature: Agatha care journey welfare feedback

  @acj @pr-11 @smoke-uat
  @P1
  Scenario: ACJ-FB-01 — chip save clears welfare suggestion
    Given a guardian owns a pet with microchip welfare pending
    When the guardian saves a microchip id on the pet profile
    Then the pet profile no longer shows the microchip welfare suggestion

  @acj @pr-12 @smoke-uat
  @P1
  Scenario: ACJ-CO-01 — same-day date header
    Given a guardian owns two care items due on the same future day
    When the guardian opens the care agenda due soon section
    Then the care agenda shows a same-day date header for that day

  @acj @pr-13 @smoke-ci @smoke-uat
  Scenario: ACJ-CO-02 — coordination banner links only
    Given a guardian owns two pets with care due on the same future day
    When the guardian opens the care agenda due soon section
    Then the care agenda shows coordination links for each pet
