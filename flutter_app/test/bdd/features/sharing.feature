Feature: Pet Sharing
  As a pet owner
  I want to share my pets with other users via share links
  So that family members or caregivers can view my pet's information

  Background:
    Given a registered user "Alice" who owns a pet "Bella"

  # ── Creating Share Links ─────────────────────────────────────

  @P0
  Scenario: Creating a share link for a pet
    When "Alice" creates a share link for "Bella"
    Then a unique share link should be generated
    And the share link should contain a share code

  # ── Viewing Shared Pet (Unauthenticated) ─────────────────────

  @P0
  Scenario: Viewing a shared pet without being logged in
    Given "Alice" has created a share link for "Bella"
    When an anonymous user opens the share link
    Then the user should see "Bella"'s profile information
    And the user should see a "View Only" badge
    And the user should see a prompt to sign up or log in

  @P1
  Scenario: Scoped share preview hides health entries
    Given "Bella" has health entries "Vaccination" and "Flea Treatment"
    And "Alice" has created a share link for "Bella"
    When a user opens the share link
    Then the user should not see health entries on the share preview

  @P1
  Scenario: Scoped share preview hides veterinarian
    Given "Bella" is linked to vet "Dr. Smith"
    And "Alice" has created a share link for "Bella"
    When a user opens the share link
    Then the user should not see veterinarian details on the share preview

  @P1
  Scenario: Viewing owner first name on shared pet page
    Given "Alice" has created a share link for "Bella"
    When a user opens the share link
    Then the user should see "Alice"'s first name as the pet owner

  # ── Accepting Shares ─────────────────────────────────────────

  @P1
  Scenario: Accepting a share into personal pet list
    Given a registered user "Bob"
    And "Alice" has created a share link for "Bella"
    When "Bob" opens the share link
    And "Bob" taps "Accept & Add"
    Then "Bella" should appear in "Bob"'s pet list as a shared pet

  # ── Revoking and hiding shared access ──────────────────────────

  @P2
  Scenario: Carer stops following a shared pet
    Given "Bob" has a shared pet "Bella" in their pet list
    When "Bob" opens sharing for "Bella"
    And "Bob" taps "Stop following"
    Then "Bella" should no longer appear in "Bob"'s pet list

  @P2
  Scenario: Carer hides a shared pet from their list
    Given "Bob" has a shared pet "Bella" in their pet list
    When "Bob" opens sharing for "Bella"
    And "Bob" taps "Hide from my pets"
    Then "Bella" should no longer appear in "Bob"'s pet list

  # ── Hiding Shared Pets ───────────────────────────────────────

  @P2
  Scenario: Hiding a shared pet via swipe
    Given "Bob" has a shared pet "Bella" in their pet list
    When "Bob" swipes left on "Bella"'s card
    And "Bob" confirms hiding "Bella"
    Then "Bella" should no longer appear in "Bob"'s pet list
    And "Bella" should not appear in "Bob"'s health dashboard
    And "Bella" should not generate notifications for "Bob"

  @P2
  Scenario: Unhiding a shared pet
    Given "Bob" has hidden the shared pet "Bella"
    When "Bob" navigates to the organisation detail page
    And "Bob" unhides "Bella"
    Then "Bella" should appear again in "Bob"'s pet list

  # ── Invalid Share Links ──────────────────────────────────────

  @P1
  Scenario: Opening an expired or invalid share link
    When a user opens an invalid share link
    Then an error message "Pet not found or share link expired" should be displayed
    And a "Go to My Pets" button should be available

  # ── Email invites ─────────────────────────────────────────────

  @P1
  Scenario: Accepting an email share invite into personal pet list
    Given a registered user "Bob"
    And "Alice" owns a pet "Bella"
    When "Alice" sends an email share invite for "Bella" to "Bob" as a carer
    And "Bob" opens the invite link
    And "Bob" accepts the invitation
    Then "Bella" should appear in "Bob"'s pet list as a shared pet

  @P2
  Scenario: Declining an email share invite
    Given a registered user "Bob"
    And "Alice" owns a pet "Bella"
    When "Alice" sends an email share invite for "Bella" to "Bob" as a carer
    And "Bob" opens the invite link
    And "Bob" declines the invitation
    Then "Bella" should not appear in "Bob"'s pet list
