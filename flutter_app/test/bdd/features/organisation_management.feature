Feature: Organisation Management
  As a pet care professional or charity volunteer
  I want to create and manage an organisation
  So that multiple users can collaborate on pet care under a shared umbrella

  Background:
    Given a registered user "Alice"

  # ── Creation ──────────────────────────────────────────────────

  Scenario: Creating a Professional organisation
    When "Alice" creates a Professional organisation named "Happy Paws Clinic"
    Then the organisation "Happy Paws Clinic" should exist with type "Professional"
    And "Alice" should be a super user of "Happy Paws Clinic"

  Scenario: Creating a Charity organisation
    When "Alice" creates a Charity organisation named "Rescue Hearts"
    Then the organisation "Rescue Hearts" should exist with type "Charity"
    And "Alice" should be a super user of "Rescue Hearts"

  Scenario: Organisation requires a name
    When "Alice" attempts to create an organisation without a name
    Then the organisation should not be created
    And an error should indicate that a name is required

  # ── Inviting Members ─────────────────────────────────────────

  Scenario: Inviting a volunteer as a member
    Given "Alice" is a super user of organisation "Happy Paws Clinic"
    And a registered user "Bob"
    When "Alice" invites "Bob" to "Happy Paws Clinic" with the role "member"
    Then "Bob" should have a pending invite for "Happy Paws Clinic"

  Scenario: Accepting an organisation invite
    Given "Bob" has a pending invite for "Happy Paws Clinic" with the role "member"
    When "Bob" accepts the invite for "Happy Paws Clinic"
    Then "Bob" should be a member of "Happy Paws Clinic"
    And "Bob" should no longer have a pending invite for "Happy Paws Clinic"

  Scenario: Declining an organisation invite
    Given "Bob" has a pending invite for "Happy Paws Clinic" with the role "member"
    When "Bob" declines the invite for "Happy Paws Clinic"
    Then "Bob" should not be a member of "Happy Paws Clinic"
    And "Bob" should no longer have a pending invite for "Happy Paws Clinic"

  Scenario: Inviting a user as a super user
    Given "Alice" is a super user of organisation "Happy Paws Clinic"
    And a registered user "Carol"
    When "Alice" invites "Carol" to "Happy Paws Clinic" with the role "super_user"
    And "Carol" accepts the invite for "Happy Paws Clinic"
    Then "Carol" should be a super user of "Happy Paws Clinic"

  Scenario: Only super users can invite new members
    Given "Bob" is a member of organisation "Happy Paws Clinic"
    And a registered user "Dave"
    When "Bob" attempts to invite "Dave" to "Happy Paws Clinic"
    Then the invitation should be rejected
    And an error should indicate insufficient permissions

  # ── Organisation Details ─────────────────────────────────────

  Scenario: Viewing organisation details
    Given "Alice" is a super user of organisation "Happy Paws Clinic"
    And "Bob" is a member of "Happy Paws Clinic"
    When "Alice" views the details of "Happy Paws Clinic"
    Then she should see the organisation name "Happy Paws Clinic"
    And she should see 2 members listed
    And she should see "Bob" listed as a member

  Scenario: Updating organisation information
    Given "Alice" is a super user of organisation "Happy Paws Clinic"
    When "Alice" updates the bio of "Happy Paws Clinic" to "Full-service veterinary clinic"
    Then the bio of "Happy Paws Clinic" should be "Full-service veterinary clinic"

  Scenario: Leaving an organisation
    Given "Bob" is a member of organisation "Happy Paws Clinic"
    When "Bob" leaves "Happy Paws Clinic"
    Then "Bob" should no longer be a member of "Happy Paws Clinic"
