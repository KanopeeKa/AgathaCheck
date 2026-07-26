Feature: Organisation roles and permissions
  As a Super Admin
  I want to grant and revoke specific permissions
  So that I can delegate operational work without giving away full admin access

  @P1
  Scenario: Super Admin applies the Pet Admin bundle preset
    Given "Alice" is a super user of organisation "Rescue Hearts"
    And a registered user "Bob"
    And "Bob" is a member of "Rescue Hearts" with role "associate"
    When the Super Admin applies the "Pet Admin" bundle preset to "Bob" on "Rescue Hearts"
    Then "Bob" should be able to add a pet on "Rescue Hearts"
    And an audit event "bundle_preset_applied" should be recorded for "Rescue Hearts"

  @P1
  Scenario: Only Super Admin can manage permissions
    Given a registered user "Carol"
    And "Carol" is a Foster Admin member of "Rescue Hearts"
    And a registered user "Dave"
    And "Dave" is a member of "Rescue Hearts" with role "foster"
    When "Carol" attempts to grant the "manage_pets" permission to "Dave" on "Rescue Hearts"
    Then the action should be denied
