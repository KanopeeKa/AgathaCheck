# Agatha care journey — BDD traceability (Playwright: e2e/bdd mirror)
@pet_care @agatha-care-journey
Feature: Agatha care journey welfare feedback

  @acj @pr-11 @smoke-uat @P1
  Scenario: ACJ-FB-01 — chip save clears welfare suggestion
    Given a guardian owns a pet with microchip welfare pending
    When the guardian saves a microchip id on the pet profile
    Then the pet profile no longer shows the microchip welfare suggestion
