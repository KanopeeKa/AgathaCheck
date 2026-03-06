Feature: Weight Tracking
  As a pet owner
  I want to record and track my pets' weight over time
  So that I can monitor their health and growth

  Background:
    Given the user is logged in
    And a pet "Bella" exists

  # ── Recording Weight ─────────────────────────────────────────

  Scenario: Adding a weight entry
    When the user navigates to "Bella"'s weight tracking section
    And the user enters weight "25.5" in kilograms
    And the user selects the date "2025-06-01"
    And the user saves the weight entry
    Then a weight entry of 25.5 kg on "2025-06-01" should appear for "Bella"

  Scenario: Adding multiple weight entries
    When the user records weights of 24.0, 24.5, and 25.0 kg for "Bella" on consecutive months
    Then "Bella" should have 3 weight entries

  # ── Viewing Weight History ───────────────────────────────────

  Scenario: Viewing weight entries as a list
    Given "Bella" has weight entries on "2025-04-01", "2025-05-01", and "2025-06-01"
    When the user views "Bella"'s weight history
    Then the user should see 3 weight entries listed in chronological order

  Scenario: Viewing weight chart
    Given "Bella" has at least 2 weight entries
    When the user views "Bella"'s weight tracking section
    Then a line chart should be displayed showing weight over time

  Scenario: Viewing latest weight on pet profile
    Given "Bella" has a latest weight entry of 25.0 kg
    When the user views the profile of "Bella"
    Then "25.0 kg" should be displayed on the pet detail screen

  # ── Editing Weight ───────────────────────────────────────────

  Scenario: Editing a weight entry
    Given "Bella" has a weight entry of 25.0 kg on "2025-06-01"
    When the user edits the entry and changes the weight to 25.5 kg
    And the user saves the weight entry
    Then the weight entry should show 25.5 kg

  # ── Deleting Weight ──────────────────────────────────────────

  Scenario: Deleting a weight entry
    Given "Bella" has a weight entry of 25.0 kg on "2025-06-01"
    When the user deletes the weight entry
    Then the weight entry should no longer appear in "Bella"'s history

  # ── Weight Units ─────────────────────────────────────────────

  Scenario: Selecting weight unit
    When the user views the weight tracking section
    Then the user should be able to choose between kg and lbs

  # ── No Weight Entries ────────────────────────────────────────

  Scenario: Empty weight history
    Given "Bella" has no weight entries
    When the user views "Bella"'s weight tracking section
    Then the user should see a prompt to add a first weight entry
