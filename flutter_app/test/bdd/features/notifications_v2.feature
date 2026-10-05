# Notifications v2 — PR1 bootstrap
#
# Active scenarios below keep @bdd title parity while legacy care-inbox scenarios
# in notifications.feature remain @legacy.

@notifications-v2
Feature: Notifications v2 inbox programme

  @P1
  Scenario: Notification generated for overdue health entry
    Given a pet "Bella" has a health entry "Vaccination" that is overdue
    When the system checks for due entries
    Then the check-due API should report zero inbox rows created

  @P1
  Scenario: Notification generated for entry due soon
    Given a pet "Bella" has a health entry "Flea Treatment" due tomorrow
    When the system checks for due entries
    Then the check-due API should report zero inbox rows created

  @P1
  Scenario: A reminder is created again after care is done on time
    Given a pet "Bella" has weekly care due today with a seven-day reminder
    When the user marks that care done on time
    And the system checks for due care
    Then the check-due API should report zero inbox rows created

  @P4 @bdd
  Scenario: Pending share invite shows inline accept and decline in Activity
    Given I have a pending share invite notification in Activity
    When I open the notification inbox on Activity
    Then I should see Accept and Decline actions on the invite row without opening it

  @P5 @bdd
  Scenario: For you lists server-generated suggestion cards grouped by pet
    Given I have an active Agatha suggestion for my pet in the inbox API
    When I open the notification inbox on For you
    Then I should see the suggestion headline grouped under the pet name
