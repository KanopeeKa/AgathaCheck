Feature: Guardian dashboard
  As a guardian
  I want a dashboard that previews my pets, upcoming events, and vets
  So that I can act quickly without wading through a mixed feed

  @P1
  Scenario: Dashboard shows exactly three sections
    Given I am signed in as a guardian with pets, due health entries, and vets
    When I view the Guardian dashboard
    Then I should see "My Pets", "Due and Overdue", and "My Vets" sections only

  @P1
  Scenario: My Pets shows all personal pets with Manage pets link
    Given I have 6 pets
    When I view the Guardian dashboard
    Then I should see 6 pet cards
    And I should see a "Manage pets" link

  @P1
  Scenario: Pending foster placement surfaces as a notification, not a dashboard banner
    Given an organisation has sent me a pending foster placement
    When I view the Guardian dashboard
    Then I should not see a pending-placement banner on the dashboard
    And I should see an unresolved administrative notification in the bell panel
