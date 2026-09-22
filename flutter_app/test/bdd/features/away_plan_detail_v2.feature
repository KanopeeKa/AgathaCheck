Feature: Away Plan Detail V2
  As a pet parent
  I want the away plan detail screen to show unified planned care and a dedicated edit flow
  So that I can review care calmly and update notes without clutter on the display screen

  # ── Attention-only header (AWD-1) ───────────────────────────

  @P1
  Scenario: Away plan page hides coverage headers when carers and care are reassured
    Given I am signed in as a guardian with a saved planned absence without scheduled care
    And every pet on the absence has a carer assigned
    When I open the away plan for that absence
    Then I should not see carer coverage or care coverage headers on the plan page

  # ── Unified planned care list (AWD-2/AWD-3) ────────────────

  @P1
  Scenario: Away plan planned care row opens care item detail
    Given I am signed in as a guardian with a saved planned absence
    And a health entry is scheduled during the absence dates
    When I open the away plan for that absence
    Then I should see the health entry in the planned care list
    When I open that planned care item from the away plan
    Then I should see the care item detail screen for that entry

  # ── Edit screen (AWD-4) ───────────────────────────────────

  @P1
  Scenario: Guardian can save handover note and delete away plan from edit screen
    Given I am signed in as a guardian with a saved planned absence
    When I open the away plan edit screen for that absence
    And I enter a handover note on the edit screen
    And I save the away plan edit
    Then I should see the handover note on the away plan page
    When I open the away plan edit screen again
    And I delete the away plan from the edit screen
    Then I should see the away planning hub without that absence
