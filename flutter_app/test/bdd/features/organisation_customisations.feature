Feature: Organisation Administration
  As a Super Admin
  I want one place for templates and roles/permissions administration
  So that organisation configuration doesn't leak into public or directory screens

  Background:
    Given "Zara" is the Super Admin of "Rescue Hearts"

  @P1
  Scenario: Only Super Admin sees the Administration entry on profile
    Given "Alice" is a Foster Admin member of "Rescue Hearts"
    When "Alice" opens the organisation profile for "Rescue Hearts"
    Then "Alice" should not see a profile nav row for "Organisation Administration"
    When "Zara" opens the organisation profile for "Rescue Hearts"
    Then "Zara" should see a profile nav row for "Organisation Administration"

  @P1
  Scenario: Audit log viewer shows a permission grant
    Given "Zara" applied the "Pet Admin" bundle preset to "Alice" yesterday
    When "Zara" opens the audit log viewer
    Then she should see a "bundle_preset_applied" entry for "Alice" with yesterday's timestamp
