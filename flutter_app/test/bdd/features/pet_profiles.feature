Feature: Pet Profiles
  As a pet owner
  I want to create, view, edit, and delete pet profiles
  So that I can keep track of all my pets' information

  Background:
    Given the user is logged in

  # ── Creating Pets ────────────────────────────────────────────

  Scenario: Creating a new pet with required fields
    When the user taps the "Add Pet" button
    And the user enters pet name "Bella"
    And the user selects species "Dog"
    And the user saves the pet
    Then "Bella" should appear in the pet list
    And "Bella" should have species "Dog"

  Scenario: Creating a pet with all fields populated
    When the user taps the "Add Pet" button
    And the user enters pet name "Max"
    And the user selects species "Cat"
    And the user enters breed "Siamese"
    And the user enters date of birth "2020-05-15"
    And the user enters bio "Friendly indoor cat"
    And the user selects a veterinarian
    And the user saves the pet
    Then "Max" should appear in the pet list
    And "Max" should have breed "Siamese"

  Scenario: Pet is assigned a unique color on creation
    When the user creates a pet named "Luna"
    Then "Luna" should have a color assigned from the 15-color palette

  Scenario: Age is dynamically calculated from date of birth
    Given a pet "Milo" with date of birth "2022-01-01"
    When the user views the profile of "Milo"
    Then the displayed age should be calculated from "2022-01-01"

  # ── Viewing Pets ─────────────────────────────────────────────

  Scenario: Viewing the pet list
    Given the user has pets "Bella", "Max", and "Luna"
    When the user views the pet list
    Then the user should see 3 pet cards
    And each pet card should show the pet's name, species, and color

  Scenario: Viewing pet details
    Given a pet "Bella" of species "Dog" with breed "Labrador"
    When the user taps on "Bella" in the pet list
    Then the user should see the pet detail screen for "Bella"
    And the screen should display species "Dog" and breed "Labrador"

  Scenario: Empty pet list shows prompt
    Given the user has no pets
    When the user views the pet list
    Then the user should see a "No pets yet" message
    And the user should see the "Add Pet" button

  # ── Editing Pets ─────────────────────────────────────────────

  Scenario: Editing a pet's name
    Given a pet "Bella" exists
    When the user edits "Bella" and changes the name to "Bella Rose"
    And the user saves the pet
    Then the pet list should show "Bella Rose"

  Scenario: Editing a pet's breed
    Given a pet "Bella" with breed "Labrador" exists
    When the user edits "Bella" and changes the breed to "Golden Retriever"
    And the user saves the pet
    Then "Bella" should have breed "Golden Retriever"

  # ── Deleting Pets ────────────────────────────────────────────

  Scenario: Deleting a pet
    Given a pet "Bella" exists
    When the user deletes "Bella"
    And the user confirms the deletion
    Then "Bella" should no longer appear in the pet list

  Scenario: Cancelling pet deletion
    Given a pet "Bella" exists
    When the user attempts to delete "Bella"
    And the user cancels the deletion
    Then "Bella" should still appear in the pet list

  # ── Passed Away ──────────────────────────────────────────────

  Scenario: Marking a pet as passed away
    Given a pet "Buddy" exists
    When the user marks "Buddy" as passed away
    Then "Buddy" should appear under the "Rainbow Bridge" section
    And "Buddy"'s color should change to white
    And a rainbow wings overlay should be applied to "Buddy"'s photo

  Scenario: Passed away pets appear in a collapsible section
    Given a pet "Buddy" has been marked as passed away
    When the user views the pet list
    Then "Buddy" should appear in the collapsed "Rainbow Bridge" section
    And active pets should not include "Buddy"

  # ── Identification Reminder ──────────────────────────────────

  Scenario: Showing identification reminder for pet without ID
    Given a pet "Luna" without an identification number
    When the user views the profile of "Luna"
    Then a species-specific identification reminder should be displayed

  Scenario: No identification reminder for pet with ID
    Given a pet "Luna" with identification number "FR-123-456"
    When the user views the profile of "Luna"
    Then no identification reminder should be displayed

  # ── Pet Photo ────────────────────────────────────────────────

  Scenario: Adding a photo to a pet profile
    Given a pet "Bella" exists without a photo
    When the user edits "Bella" and adds a photo
    And the user saves the pet
    Then "Bella"'s profile should display the uploaded photo

  # ── Linking Vet ──────────────────────────────────────────────

  Scenario: Linking a veterinarian to a pet
    Given a pet "Bella" exists
    And a veterinarian "Dr. Jones" exists
    When the user edits "Bella" and selects "Dr. Jones" as the vet
    And the user saves the pet
    Then "Bella" should be linked to "Dr. Jones"
