Feature: Organisation customisations
  As a Super Admin
  I want one place for templates and roles/permissions administration
  So that organisation configuration doesn't leak into public or directory screens

  @P1
  Scenario: Only Super Admin sees the customisations entry point
    Given "Alice" is a Foster Admin member of "Rescue Hearts"
    And "Zara" is the Super Admin
    When "Alice" views the organisation edit screen
    Then "Alice" should not see an "Organisation customisations" entry point
    When "Zara" views the organisation edit screen
    Then "Zara" should see an "Organisation customisations" entry point

  @P1
  Scenario: Audit log viewer shows a permission grant
    Given "Zara" applied the "Pet Admin" bundle preset to "Alice" yesterday
    When "Zara" opens the audit log viewer
    Then she should see a "bundle_preset_applied" entry for "Alice" with yesterday's timestamp
