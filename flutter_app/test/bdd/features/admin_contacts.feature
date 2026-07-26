Feature: Admin contacts
  As an organisation member
  I want to browse the admin contacts directory
  So that I can reach the right people inside my organisation

  Background:
    Given a registered user "Alice"
    And "Alice" is a super user of organisation "Rescue Hearts"

  @P1
  Scenario: Admin contacts directory lists admins alphabetically
    Given a registered user "Bob"
    And "Bob" is a member of "Rescue Hearts" with role "admin"
    And a registered user "Carol"
    And "Carol" is a member of "Rescue Hearts" with role "admin"
    When "Alice" opens the admin contacts screen for "Rescue Hearts"
    Then she should see "Alice" listed first as her own card
    And she should see "Bob" and "Carol" listed after "Alice"
    And the admin contacts should be ordered alphabetically by last name after the self-card

  @P1
  Scenario: Team admin can add an admin contact
    Given a registered user "Dave"
    When "Alice" adds an admin contact for "Dave" on "Rescue Hearts"
    Then "Dave" should have a pending invite for "Rescue Hearts" with role "admin"

  @P1
  Scenario: Super admin can edit another admin contact
    Given a registered user "Eve"
    And "Eve" is a member of "Rescue Hearts" with role "admin"
    When "Alice" edits the admin contact card for "Eve" on "Rescue Hearts"
    Then she should be able to update "Eve"'s contact details

  @P1
  Scenario: Members can message an admin when contact details allow
    Given a registered user "Frank"
    And "Frank" is a foster member of "Rescue Hearts"
    And a registered user "Grace"
    And "Grace" is a member of "Rescue Hearts" with role "admin"
    When "Frank" opens the admin contacts screen for "Rescue Hearts"
    Then he should see a message affordance for "Grace"
