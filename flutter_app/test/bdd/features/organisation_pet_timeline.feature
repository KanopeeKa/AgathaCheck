Feature: Organisation Pet Timeline
  As an organisation member
  I want to view a timeline of a pet's stays, fostering, and status changes
  So that I have a complete history of the pet's journey through the organisation

  Background:
    Given an organisation "Rescue Hearts" of type "Charity"
    And "Alice" is a super user of "Rescue Hearts"
    And a pet "Max" exists under "Rescue Hearts"

  # ── Family Events as Timeline ────────────────────────────────

  Scenario: Recording a foster stay for a pet
    Given a registered user "Frank" who is a member of "Rescue Hearts"
    When "Alice" creates a family event for "Max" assigned to "Frank" from "2025-06-01" to "2025-08-31" with notes "Summer fostering"
    Then "Max" should have a family event assigned to "Frank"
    And the event should have from date "2025-06-01" and to date "2025-08-31"
    And the event notes should be "Summer fostering"

  Scenario: Recording an open-ended placement
    Given a registered user "Grace" who is a member of "Rescue Hearts"
    When "Alice" creates a family event for "Max" assigned to "Grace" from "2025-09-01" without an end date with notes "Long-term care"
    Then "Max" should have a family event assigned to "Grace"
    And the event should have from date "2025-09-01" and no end date

  Scenario: Viewing all family events for a pet
    Given "Max" has the following family events:
      | assigned_to | from       | to         | notes            |
      | Frank       | 2025-06-01 | 2025-08-31 | Summer fostering |
      | Grace       | 2025-09-01 |            | Long-term care   |
    When "Alice" views the family events for "Max"
    Then she should see 2 family events
    And the events should be ordered by from date

  Scenario: Removing a family event
    Given "Max" has a family event assigned to "Frank" from "2025-06-01" to "2025-08-31"
    When "Alice" removes the family event assigned to "Frank" for "Max"
    Then "Max" should no longer have a family event assigned to "Frank"

  # ── Timeline in Health Dashboard ─────────────────────────────

  Scenario: Family events appear in the health dashboard
    Given "Max" has a family event assigned to "Frank" from "2025-06-01" to "2025-06-15"
    When "Alice" views the health dashboard
    Then the family event for "Max" should appear under the "Family Events" tab

  Scenario: Notifications for ending family events
    Given "Max" has a family event assigned to "Frank" from "2025-06-01" to tomorrow
    When the system checks for due notifications
    Then all members of "Rescue Hearts" should receive a reminder about the ending family event
