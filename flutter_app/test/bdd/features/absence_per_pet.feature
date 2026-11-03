Feature: Per-pet away plans hub and pet entry
  As a pet parent with co-parents
  I want the away hub and pet page to reflect per-pet away plans
  So that shared care stays clear without leaking other pets

  @P1
  Scenario: Away hub groups absences under your absences
    Given I am signed in as a guardian with a saved planned absence
    When I open the away planning hub
    Then I should see your absences on the away hub
