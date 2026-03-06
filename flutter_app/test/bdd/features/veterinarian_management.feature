Feature: Veterinarian Management
  As a pet owner
  I want to manage my veterinarian contacts
  So that I can associate vets with my pets and access their details

  Background:
    Given the user is logged in

  # ── Creating Vets ────────────────────────────────────────────

  Scenario: Creating a veterinarian with all details
    When the user navigates to the veterinarian list
    And the user taps the "Add Vet" button
    And the user enters vet name "Dr. Smith"
    And the user enters phone "555-1234"
    And the user enters email "drsmith@vetclinic.com"
    And the user enters address "123 Vet Lane"
    And the user enters notes "Open on weekends"
    And the user saves the veterinarian
    Then "Dr. Smith" should appear in the veterinarian list
    And the vet details should show phone "555-1234"

  Scenario: Creating a veterinarian with only a name
    When the user creates a vet named "Dr. Jones"
    Then "Dr. Jones" should appear in the veterinarian list

  # ── Viewing Vets ─────────────────────────────────────────────

  Scenario: Viewing the veterinarian list
    Given vets "Dr. Smith" and "Dr. Jones" exist
    When the user navigates to the veterinarian list
    Then the user should see 2 veterinarian cards

  Scenario: Viewing vet with linked pets
    Given a vet "Dr. Smith" exists
    And pets "Bella" and "Max" are linked to "Dr. Smith"
    When the user views the veterinarian list
    Then "Dr. Smith" should show "Bella" and "Max" as linked pets

  Scenario: Empty vet list shows prompt
    Given the user has no veterinarians
    When the user navigates to the veterinarian list
    Then the user should see a "No vets yet" message

  # ── Editing Vets ─────────────────────────────────────────────

  Scenario: Editing a veterinarian's phone number
    Given a vet "Dr. Smith" with phone "555-1234" exists
    When the user edits "Dr. Smith" and changes the phone to "555-5678"
    And the user saves the veterinarian
    Then "Dr. Smith" should have phone "555-5678"

  # ── Deleting Vets ────────────────────────────────────────────

  Scenario: Deleting a veterinarian
    Given a vet "Dr. Smith" exists
    When the user deletes "Dr. Smith"
    And the user confirms the deletion
    Then "Dr. Smith" should no longer appear in the veterinarian list

  Scenario: Cancelling vet deletion
    Given a vet "Dr. Smith" exists
    When the user attempts to delete "Dr. Smith"
    And the user cancels the deletion
    Then "Dr. Smith" should still appear in the veterinarian list

  # ── Navigation ───────────────────────────────────────────────

  Scenario: Navigating to vet list from the app bar
    When the user taps the veterinarian icon in the app bar
    Then the user should be navigated to the veterinarian list screen

  Scenario: Navigating back from vet list
    Given the user is on the veterinarian list screen
    When the user taps the back button
    Then the user should be navigated to the pet list screen
