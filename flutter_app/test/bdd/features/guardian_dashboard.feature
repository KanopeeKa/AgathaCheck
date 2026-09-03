Feature: Pet Care dashboard
  As a pet carer
  I want a calm operations desk for my pets and care
  So that I can orient myself and act quickly

  @implemented
  @P0
  Scenario: Dashboard shows exactly three sections
    Given I am signed in as a guardian with pets, due health entries, and vets
    When I view the Pet Care dashboard
    Then I should see "My Pets", "CARE ACTIONS", and "Care team" sections only

  @implemented
  @P0
  Scenario: Today orientation prioritises attention above the management sections
    Given I am signed in as a guardian with overdue and due-today care
    When I view the Pet Care dashboard
    Then I should see a Today orientation before the management sections
    And I should see the most urgent care first

  @implemented
  @P0
  Scenario: My Pets preview is capped at four with an All Pets destination
    Given I have 6 pets
    When I view the Pet Care dashboard
    Then I should see at most 4 pet cards
    And I should see an "All pets" link

  @implemented
  @P0
  Scenario: Care preview orders overdue, due today, and upcoming items
    Given I am signed in as a guardian with overdue, due-today, and upcoming care
    When I view the Pet Care dashboard
    Then the CARE ACTIONS preview should show those priorities in urgency order
    And I should be able to open the full Events screen

  @implemented
  @P0
  Scenario: Care preview supports completion and undo
    Given I am signed in as a guardian with due care
    When I complete a care item from the Pet Care dashboard
    Then the care item should acknowledge completion
    And I should be able to undo that completion

  @implemented
  @P1
  Scenario: Care preview row opens the event view screen
    Given I am signed in as a guardian with due care
    When I open a care preview item from the Pet Care dashboard
    Then I should see the event view screen for that item
    And snooze should be available on the event view screen only

  @implemented
  @P1
  Scenario: Care team preview reaches linked vet details
    Given I am signed in as a guardian with a linked veterinarian
    When I view the Pet Care dashboard
    Then I should see the veterinarian and linked-pet count
    And I should be able to open the veterinarian detail screen

  @implemented
  @P1
  Scenario: Empty Pet Care dashboard shows first-use guidance without false alerts
    Given I am signed in as a guardian with no pets
    When I view the Pet Care dashboard
    Then I should see first-use Today guidance
    And I should not see an overdue care alert

  @implemented
  @P1
  Scenario: Pending foster placement surfaces as a notification, not a dashboard banner
    Given an organisation has sent me a pending foster placement
    When I view the Pet Care dashboard
    Then I should not see a pending-placement banner on the dashboard
    And I should see an unresolved administrative notification in the bell panel

  @implemented
  @P1
  Scenario: Global events screen shows unified list without tabs
    Given I am signed in as a guardian with pets, due health entries, and vets
    When I open the global events screen
    Then I should see an "Events" list without type tabs
    And I should see an "Add an event" action

  @implemented
  @P1
  Scenario: Global events screen supports pet and cohort filters
    Given I am signed in as a guardian with owned and foster pets and health entries
    When I open the global events screen
    Then I should see cohort filters for my pets and foster pets
    And I should be able to filter events by pet

  @implemented
  @P1
  Scenario: Pet Care compact bottom nav reaches Pets, Actions, and Fostering destinations
    Given I am signed in as a guardian with pets
    When I use the compact bottom navigation
    Then I should reach the Pets, Actions, and Fostering destinations

  @implemented
  @P1
  Scenario: Pet Care leading navigation rail reaches primary destinations at medium width
    Given I am signed in as a guardian with pets
    When I use the leading navigation at medium width
    Then I should reach the Pets, Actions, and Fostering destinations via the navigation rail

  @implemented
  @P1
  Scenario: Pet Care expanded sidebar reaches primary destinations at wide width
    Given I am signed in as a guardian with pets
    When I use the leading navigation at wide width
    Then I should reach the Pets, Actions, and Fostering destinations via the navigation sidebar

  @implemented
  @P1
  Scenario: Workspace toggle switches between Pet Care and Shelter when available
    Given I am signed in as a guardian with shelter access
    When I view the Pet Care dashboard
    Then I should see the workspace toggle
    And I should be able to switch to Shelter and back to Pet Care

  @implemented
  @P1
  Scenario: Mobile Pet Care home shows one product brand in the app bar
    Given I am signed in as a guardian with pets
    When I view the Pet Care dashboard at compact width
    Then I should see exactly one "AgathaTrack" brand label
    And I should see compact bottom navigation
    And I should not see leading navigation rail or sidebar

  @implemented
  @P1
  Scenario: Tablet Pet Care home carries brand in the navigation rail only
    Given I am signed in as a guardian with pets
    When I view the Pet Care dashboard at medium width
    Then I should see the navigation rail brand
    And I should not see duplicate "AgathaTrack" text in the content chrome
    And the notification bell should sit outside the navigation rail

  @implemented
  @P1
  Scenario: Desktop Pet Care home carries brand in the sidebar only
    Given I am signed in as a guardian with pets
    When I view the Pet Care dashboard at wide width
    Then I should see exactly one "AgathaTrack" brand label in the sidebar
    And the notification bell should sit outside the navigation sidebar
