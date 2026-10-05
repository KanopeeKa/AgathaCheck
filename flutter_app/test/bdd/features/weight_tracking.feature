Feature: Weight Tracking
  As a pet owner
  I want to record and track my pets' weight over time
  So that I can monitor their health and growth

  Background:
    Given the user is logged in
    And a pet "Bella" exists

  # ── Recording Weight ─────────────────────────────────────────

  @P0
  Scenario: Adding a weight entry
    When the user navigates to "Bella"'s weight tracking section
    And the user enters weight "25.5" in kilograms
    And the user selects the date "2025-06-01"
    And the user saves the weight entry
    Then a weight entry of 25.5 kg on "2025-06-01" should appear for "Bella"

  @P1
  Scenario: Adding multiple weight entries
    When the user records weights of 24.0, 24.5, and 25.0 kg for "Bella" on consecutive months
    Then "Bella" should have 3 weight entries

  # ── Viewing Weight History ───────────────────────────────────

  @P1
  Scenario: Viewing weight entries as a list
    Given "Bella" has weight entries on "2025-04-01", "2025-05-01", and "2025-06-01"
    When the user views "Bella"'s weight history
    Then the user should see 3 weight entries listed in chronological order

  @P1
  Scenario: Viewing weight chart
    Given "Bella" has at least 2 weight entries
    When the user views "Bella"'s weight tracking section
    Then a line chart should be displayed showing weight over time

  @P2
  Scenario: Pet profile weight is read-only and links to the weight screen
    Given "Bella" has a weight entry of 24.0 kg on "2025-04-01"
    When the user opens the pet edit screen for "Bella"
    Then the weight field should be read-only with a link to record weight
    When the user follows the record weight link
    Then the user should be on "Bella"'s weight tracking section

  @P2
  Scenario: Profile updates from older apps still record the weight
    Given "Bella" has a weight entry of 24.0 kg on "2025-04-01"
    When the pet profile is updated via API with weight 25.0 kg for today
    Then "Bella" should have a weight entry of 25.0 kg for today with no notes

  @P2
  Scenario: Viewing latest weight on pet profile
    Given "Bella" has a latest weight entry of 25.0 kg
    When the user views the profile of "Bella"
    Then "25.0 kg" should be displayed on the pet detail screen

  @P2
  Scenario: PDF pet report shows latest weight as current weight
    Given "Bella" has weight entries of 24.0 kg on "2025-04-01" and 25.0 kg on "2025-06-01"
    When the user downloads a pet report including the profile section
    Then the report should show "25.0 kg" as the current weight

  # ── Editing Weight ───────────────────────────────────────────

  @P1
  Scenario: Editing a weight entry
    Given "Bella" has a weight entry of 25.0 kg on "2025-06-01"
    When the user opens the weight entry from the history list
    And the user changes the weight to 25.5 kg in the sheet
    And the user saves the weight entry
    Then the weight entry should show 25.5 kg

  # ── Deleting Weight ──────────────────────────────────────────

  @P1
  Scenario: Deleting a weight entry
    Given "Bella" has a weight entry of 25.0 kg on "2025-06-01"
    When the user deletes the weight entry
    Then the weight entry should no longer appear in "Bella"'s history

  # ── Weight Units ─────────────────────────────────────────────

  @P1
  Scenario: Selecting weight unit
    When the user views the weight tracking section
    Then the user should be able to choose between kg and lbs

  # ── Weigh-in fulfilment (server) ─────────────────────────────

  @P1
  Scenario: A weight recorded with a weigh-in choice completes that weigh-in
    Given a weigh-in routine is due today for "Bella"
    When the user records a weight of 10.5 kg that fulfils that weigh-in
    Then the weigh-in occurrence should be completed
    And "Bella" should have a weight entry of 10.5 kg linked to that weigh-in

  @P1
  Scenario: Undoing a weigh-in removes the weight it created
    Given a weigh-in routine is due today for "Bella"
    And the user has recorded a weight that fulfils that weigh-in
    When the user undoes that weigh-in completion
    Then the weigh-in occurrence should be open again
    And the weight entry created for that weigh-in should no longer exist

  # ── No Weight Entries ────────────────────────────────────────

  @P0
  Scenario: Empty weight history
    Given "Bella" has no weight entries
    When the user views "Bella"'s weight tracking section
    Then the user should see a prompt to add a first weight entry

  # ── Weight hub (WEIGHT B W7) ─────────────────────────────────

  @P0
  Scenario: Recording a weight that counts as the due weigh-in
    Given a weigh-in routine is due today for "Bella"
    When the user records a weight of 10.5 kg that counts as that weigh-in
    Then the weigh-in occurrence should be completed
    And "Bella" should have a weight entry of 10.5 kg linked to that weigh-in

  @P1
  Scenario: Recording a weight without counting it as a weigh-in
    Given a weigh-in routine is due today for "Bella"
    When the user records a weight of 11.0 kg without counting it as a weigh-in
    Then the weigh-in occurrence should still be open
    And "Bella" should have a standalone weight entry of 11.0 kg

  @P1
  Scenario: Choosing which weigh-in a weight counts as
    Given two weigh-in routines are due today for "Bella"
    When the user records a weight choosing the second routine
    Then that weigh-in occurrence should be completed
    And the other weigh-in should still be open

  @P1
  Scenario: Undoing a weight that counted as a weigh-in
    Given a weigh-in routine is due today for "Bella"
    And the user has recorded a weight that counted as that weigh-in
    When the user undoes that weigh-in from the snackbar
    Then the weigh-in occurrence should be open again
    And the weight entry should no longer exist

  @P1
  Scenario: Deleting a weight that counted as a weigh-in asks for confirmation
    Given a weigh-in routine is due today for "Bella"
    And the user has recorded a weight that counted as that weigh-in
    When the user deletes that weight entry from the history list
    Then the user should see a confirmation explaining the linked weigh-in

  @P1
  Scenario: Weight unit preference follows the user
    Given the user's weight unit preference is pounds
    And "Bella" has a weight entry of 22.0 lb
    When the user views "Bella"'s weight tracking section
    Then weights should be displayed in pounds

  @P2
  Scenario: Weight screen suggests a weigh-in routine when there is none
    Given "Bella" has no weigh-in routine
    When the user views "Bella"'s weight tracking section
    Then the user should see a prompt to set up a weigh-in routine
