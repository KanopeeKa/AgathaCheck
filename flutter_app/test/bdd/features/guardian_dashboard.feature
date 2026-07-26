Feature: Guardian dashboard
  As a guardian
  I want a dashboard that previews my pets, upcoming events, and vets
  So that I can act quickly without wading through a mixed feed

  Scenario: Dashboard shows exactly three sections
    Given I am signed in as a guardian with pets, due health entries, and vets
    When I view the Guardian dashboard
    Then I should see "My Pets", "Upcoming Pet Events", and "My Vets" sections only

  Scenario: My Pets preview is capped at four
    Given I have 6 pets
    When I view the Guardian dashboard
    Then I should see at most 4 pet cards
    And I should see an "All Pets" link

  Scenario: Pending foster placement surfaces as a notification, not a dashboard banner
    Given an organisation has sent me a pending foster placement
    When I view the Guardian dashboard
    Then I should not see a pending-placement banner on the dashboard
    And I should see an unresolved administrative notification in the bell panel
