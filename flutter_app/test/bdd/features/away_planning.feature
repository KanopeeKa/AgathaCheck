Feature: Away Planning
  As a pet parent
  I want to plan for absences and see who will care for my pets
  So that I can prepare calmly before I am away

  # ── Dashboard entry ────────────────────────────────────────

  @implemented
  @P0
  Scenario: Dashboard away planning tile opens the hub
    Given I am signed in as a guardian with a pet
    When I open away planning from the Pet Care dashboard
    Then I should see the away planning hub

  # ── Wizard ───────────────────────────────────────────────────

  @implemented
  @P0
  Scenario: Guardian can save a planned absence from the wizard
    Given I am signed in as a guardian with a pet
    When I create a planned absence for that pet from the wizard
    Then I should see the away plan for the saved absence

  # ── Hub ──────────────────────────────────────────────────────

  @implemented
  @P1
  Scenario: Away planning hub lists a saved upcoming absence
    Given I am signed in as a guardian with a saved planned absence
    When I open the away planning hub
    Then I should see the upcoming absence in the hub

  # ── Plan page ────────────────────────────────────────────────

  @implemented
  @P1
  Scenario: Away plan page shows who is caring for each pet
    Given I am signed in as a guardian with a saved planned absence
    When I open the away plan for that absence
    Then I should see who is caring for each pet on the plan page
