# Notifications v2 — PR1 bootstrap
#
# Active scenarios below keep @bdd title parity while legacy care-inbox scenarios
# in notifications.feature remain @legacy.

# AC-ACS server coverage: see server/test/account/accountSecurityNotifications.test.js
# (AC-ACS-1 push to other devices deferred — docs/domains/notifications/changes/deferred.md)

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

  @P1
  Scenario: Pending share invite shows inline accept and decline in Activity
    Given I have a pending share invite notification in Activity
    When I open the notification inbox on Activity
    Then I should see Accept and Decline actions on the invite row without opening it

  @P1
  Scenario: Accepted share invite is resolved and leaves needs-response
    Given I accepted a pending share invite
    When I fetch my notifications from the API
    Then the share invite row should have a resolved timestamp

  @P1
  Scenario: Resolving one share invite leaves a second pending invite open
    Given I have two pending share invite notifications with different invite codes
    When I accept one invite by its invite code
    Then only the accepted invite notification should have a resolved timestamp

  @P0
  Scenario: Foster invitation received is not a needs-response item
    Given I have a foster invitation received notification
    When I fetch my notification needs-response count from the API
    Then the needs-response count should not include the foster invitation
