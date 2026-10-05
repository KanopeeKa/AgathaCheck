@people
Feature: People directory
  Personal directory of carers and pet professionals.

  @smoke-ci @P1
  Scenario: Open Contacts from bottom navigation and see household, carers and professionals sections
    Given I am logged in as a pet parent
    When I open the People page from bottom navigation
    Then I see trusted carers and pet professionals sections on the roster

  @P1
  Scenario: Search by role and filter to professionals; /pc/vets lands on the professionals filter
    Given I am logged in with a saved pet professional
    When I search the People roster by role and filter to professionals
    And I open the legacy veterinarian list route
    Then I see the professionals filter applied on the People roster

  @P1
  Scenario: Desktop: select a person, the detail shows in the pane, and search is kept
    Given I am logged in with a saved pet professional on a wide viewport
    When I search the People roster and select a person
    Then the person detail is visible alongside the roster
    And my search query is still applied

  @P1
  Scenario: Add a pet professional as Buddy's primary vet; Buddy appears on their Pets & access tab
    Given I am logged in with a pet named Buddy
    When I add a pet professional and mark Buddy as their primary vet
    Then Buddy appears on the professional's Pets and access tab

  @P1
  Scenario: Add a trusted carer and share Buddy with Can log care; a pending invite shows in the roster
    Given I am logged in with a pet named Buddy
    When I add a trusted carer and invite them to share Buddy with can log care access
    Then a pending invite for the carer appears in the People roster

  @P1
  Scenario: Edit a contact's roles and name; its kind is unchanged
    Given I am logged in with a saved pet professional
    When I edit the contact's name and roles
    Then the contact's kind is unchanged

  @P1
  Scenario: Removing a contact in use lists where it's used; mark it inactive; it shows as Inactive
    Given a pet professional is linked to my pet
    When I attempt to remove the contact and see where it is used
    And I mark the contact inactive
    Then the contact shows as inactive on the People roster

  @P1
  Scenario: Create a household, invite a member by email (accepted via API helper), then remove them with the remaining-access preview
    Given I am logged in as a pet parent
    When I create a household and invite a member by email
    And the invitee accepts via the API helper
    Then I can remove the member and see the remaining-access preview

  @smoke-ci @P1
  Scenario: Today desk Vet team and Trusted carers cards open person detail
    Given I am logged in with a vet linked to my pet
    When I open the Pet Care dashboard
    And I open a vet from the Today desk People module
    Then I see the person detail screen
