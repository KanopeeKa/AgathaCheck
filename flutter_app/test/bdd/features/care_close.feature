Feature: Close care
  As the pet owner
  I want to close a care item permanently
  So that it leaves my agenda without reopening it

  Background:
    Given the user is logged in
    And a pet "Rex" exists

  @P1
  Scenario: CC-1 owner closes active care from the detail screen
    Given "Rex" has monthly flea treatment due on "2026-06-05"
    When the owner opens the care item detail
    And the owner chooses Close care and confirms
    Then the care item status is closed stopped by you
    And the care item has no open dates

  @P1
  Scenario: CC-2 carer does not see Close care
    Given "Rex" has monthly flea treatment due on "2026-06-05"
    And a carer has access to "Rex"
    When the carer opens the care item detail
    Then Close care is not shown
