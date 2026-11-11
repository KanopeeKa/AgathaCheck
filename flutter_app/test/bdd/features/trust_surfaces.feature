# Truthful outcomes — bell panel and consent (ui-truthful-outcomes-7c1d phase 5)
#
# Subscription store disclosure is manual UAT only (see subscription specs).

@trust-surfaces
Feature: Trust surfaces bell panel and consent

  Background:
    Given the user is logged in

  @P0
  Scenario: Bell panel opens notification settings from the shell
    When the user opens the notification bell panel
    And the user chooses notification settings from the panel header
    Then the notification settings screen should be shown

  @P0
  Scenario: Bell panel opens the full inbox from the shell
    When the user opens the notification bell panel
    And the user chooses open full inbox from the panel header
    Then the full notifications inbox screen should be shown

  @P0
  Scenario: Reject optional on the consent banner dismisses and persists the choice
    Given a fresh browser session without prior consent
    When the user rejects optional cookies on the consent banner
    Then the consent banner should not be shown
    And the consent choice should persist after reload
