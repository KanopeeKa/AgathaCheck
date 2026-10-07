Feature: Away Planning
  As a pet parent
  I want to plan for absences and see who will care for my pets
  So that I can prepare calmly before I am away

  # ── Dashboard entry ────────────────────────────────────────

  @implemented
  @P0
  Scenario: Dashboard away planning tile opens the hub
    Given I am signed in as a guardian with a pet
    When I open away planning from the Pet Care dashboard
    Then I should see the away planning hub

  # ── Create form ──────────────────────────────────────────────

  @implemented
  @P0
  Scenario: Guardian can save a planned absence from the create form
    Given I am signed in as a guardian with a pet
    When I create a planned absence for that pet from the create form
    Then I should see the away plan for the saved absence

  # ── Hub ──────────────────────────────────────────────────────

  @implemented
  @P1
  Scenario: Away planning hub lists a saved upcoming absence
    Given I am signed in as a guardian with a saved planned absence
    When I open the away planning hub
    Then I should see the upcoming absence in the hub

  # ── Plan page ────────────────────────────────────────────────

  @implemented
  @P1
  Scenario: Away plan page shows who is caring for each pet
    Given I am signed in as a guardian with a saved planned absence
    When I open the away plan for that absence
    Then I should see who is caring for each pet on the plan page

  @implemented
  @P2
  Scenario: Guardian assigns a contact carer on the away plan page
    Given I am signed in as a guardian with a person contact saved
    And I have a saved planned absence for that pet
    When I assign the contact as carer on the away plan page
    Then I should see the contact's name in who is caring

  @P2
  Scenario: Guardian assigns a shared carer on the away plan page
    Given I am signed in as a guardian with a pet shared to a collaborator
    And I have a saved planned absence for that pet
    When I assign the collaborator as carer on the away plan page
    Then I should see the collaborator's name in who is caring

  @P1
  Scenario: Assign an absence carer with the picker; the handover lists emergency contacts and vets
    Given I am logged in with a pet named Buddy
    And Buddy has veterinary contacts for handover
    And I have a planned absence including Buddy
    When I assign a trusted carer with the away plan picker
    And I download Buddy's handover plan
    Then the handover lists Buddy's emergency contacts and vets
