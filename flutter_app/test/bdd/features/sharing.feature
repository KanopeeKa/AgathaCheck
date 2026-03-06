Feature: Pet Sharing
  As a pet owner
  I want to share my pets with other users via share links
  So that family members or caregivers can view my pet's information

  Background:
    Given a registered user "Alice" who owns a pet "Bella"

  # ── Creating Share Links ─────────────────────────────────────

  Scenario: Creating a share link for a pet
    When "Alice" creates a share link for "Bella"
    Then a unique share link should be generated
    And the share link should contain a share code

  # ── Viewing Shared Pet (Unauthenticated) ─────────────────────

  Scenario: Viewing a shared pet without being logged in
    Given "Alice" has created a share link for "Bella"
    When an anonymous user opens the share link
    Then the user should see "Bella"'s profile information
    And the user should see a "View Only" badge
    And the user should see a prompt to sign up or log in

  Scenario: Viewing a shared pet's health entries
    Given "Bella" has health entries "Vaccination" and "Flea Treatment"
    And "Alice" has created a share link for "Bella"
    When a user opens the share link
    Then the user should see health entries "Vaccination" and "Flea Treatment"

  Scenario: Viewing a shared pet's vet information
    Given "Bella" is linked to vet "Dr. Smith"
    And "Alice" has created a share link for "Bella"
    When a user opens the share link
    Then the user should see "Dr. Smith" in the veterinarian section

  Scenario: Viewing owner information on shared pet page
    Given "Alice" has created a share link for "Bella"
    When a user opens the share link
    Then the user should see "Alice"'s name as the pet owner

  # ── Accepting Shares ─────────────────────────────────────────

  Scenario: Accepting a share into personal pet list
    Given a registered user "Bob"
    And "Alice" has created a share link for "Bella"
    When "Bob" opens the share link
    And "Bob" taps "Accept & Add"
    Then "Bella" should appear in "Bob"'s pet list as a shared pet

  Scenario: Pending share appears in pet list
    Given "Bob" has a pending share for "Bella"
    When "Bob" views the pet list
    Then a pending share card for "Bella" should appear
    And the card should have "Accept" and "Decline" buttons

  Scenario: Accepting a pending share into personal list
    Given "Bob" has a pending share for "Bella"
    When "Bob" accepts the pending share into their personal list
    Then "Bella" should appear under "My Pets" for "Bob"

  Scenario: Accepting a pending share into an organisation
    Given "Bob" is a member of organisation "Pet Care Team"
    And "Bob" has a pending share for "Bella"
    When "Bob" accepts the pending share into "Pet Care Team"
    Then "Bella" should appear under "Pet Care Team" for "Bob"

  Scenario: Declining a pending share
    Given "Bob" has a pending share for "Bella"
    When "Bob" declines the pending share for "Bella"
    Then the pending share card should disappear
    And "Bella" should not appear in "Bob"'s pet list

  # ── Hiding Shared Pets ───────────────────────────────────────

  Scenario: Hiding a shared pet via swipe
    Given "Bob" has a shared pet "Bella" in their pet list
    When "Bob" swipes left on "Bella"'s card
    And "Bob" confirms hiding "Bella"
    Then "Bella" should no longer appear in "Bob"'s pet list
    And "Bella" should not appear in "Bob"'s health dashboard
    And "Bella" should not generate notifications for "Bob"

  Scenario: Unhiding a shared pet
    Given "Bob" has hidden the shared pet "Bella"
    When "Bob" navigates to the organisation detail page
    And "Bob" unhides "Bella"
    Then "Bella" should appear again in "Bob"'s pet list

  # ── Invalid Share Links ──────────────────────────────────────

  Scenario: Opening an expired or invalid share link
    When a user opens an invalid share link
    Then an error message "Pet not found or share link expired" should be displayed
    And a "Go to My Pets" button should be available
