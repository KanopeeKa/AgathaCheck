Feature: Organisation edit
  As an organisation super admin
  I want to edit organisation details and media
  So that our public profile stays accurate

  Background:
    Given a registered user "Alice"
    And "Alice" is a super user of organisation "Rescue Hearts"

  @P1
  Scenario: Super admin can update structured address and postcode
    When "Alice" opens the edit form for "Rescue Hearts"
    And she updates the town to "Springfield"
    And she updates the postcode to "62701"
    Then the organisation should persist postcode in public profile metadata

  @P1
  Scenario: Super admin can upload cover and logo images
    When "Alice" opens the edit form for "Rescue Hearts"
    Then she should see cover and logo upload controls with file guidance

  @P1
  Scenario: Profile edit icon opens edit form for manage_permissions users
    Given a registered user "Bob"
    And "Bob" is a member of "Rescue Hearts" with role "admin"
    When "Bob" opens the organisation profile for "Rescue Hearts"
    Then he should see an edit control that opens the edit form

  @P1
  Scenario: Super admin can delete organisation from edit screen only
    When "Alice" opens the edit form for "Rescue Hearts"
    Then she should see a delete organisation control on the edit screen
