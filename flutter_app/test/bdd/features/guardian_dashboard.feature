Feature: Guardian dashboard
  As a guardian
  I want a calm operations desk for my pets and care
  So that I can orient myself and act quickly

  @implemented
  @P0
  Scenario: Guardian Today prioritises pets and care
    Given I am signed in as a guardian with pets, due health entries, and vets
    When I view the Guardian dashboard
    Then I should see a horizontal pet preview, a CARE region, veterinary actions, and fostering context

  @implemented
  @P0
  Scenario: Care preview separates Due and Soon
    Given I am signed in as a guardian with overdue and due-today care
    When I view the Guardian dashboard
    Then I should see the three most urgent Due care items first
    And I should be able to open the Soon preview

  @implemented
  @P0
  Scenario: My Pets preview is capped at four with an All Pets destination
    Given I have 6 pets
    When I view the Guardian dashboard
    Then I should see at most 4 pet cards
    And I should see an "All Pets" link

  @implemented
  @P0
  Scenario: Care preview links to the full Care destination
    Given I am signed in as a guardian with overdue, due-today, and upcoming care
    When I view the Guardian dashboard
    Then the Due preview should show overdue then due-today care in urgency order
    And I should be able to open the full Events screen

  @implemented
  @P0
  Scenario: Care preview supports completion and undo
    Given I am signed in as a guardian with due care
    When I complete a care item from the Guardian dashboard
    Then the care item should acknowledge completion
    And I should be able to undo that completion

  @implemented
  @P1
  Scenario: My Vets preview reaches linked vet details
    Given I am signed in as a guardian with a linked veterinarian
    When I view the Guardian dashboard
    Then I should see the veterinarian and linked-pet count
    And I should be able to open the veterinarian detail screen

  @implemented
  @P1
  Scenario: Empty Guardian dashboard gives a truthful Care state without false alerts
    Given I am signed in as a guardian with no pets
    When I view the Guardian dashboard
    Then I should see a clear Care empty state
    And I should not see an overdue care alert

  @implemented
  @P1
  Scenario: Pending foster placement surfaces as a notification, not a dashboard banner
    Given an organisation has sent me a pending foster placement
    When I view the Guardian dashboard
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
