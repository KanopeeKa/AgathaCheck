Feature: Organisation Pet Management
  As an organisation member
  I want to manage pets under my organisation
  So that all members can collaborate on the care of shared animals

  Background:
    Given a registered user "Alice" who is a super user of "Happy Paws Clinic"
    And a registered user "Bob" who is a member of "Happy Paws Clinic"

  # ── Adding Pets ──────────────────────────────────────────────

  Scenario: Super user creates a pet under the organisation
    When "Alice" creates a pet named "Bella" of species "Dog" under "Happy Paws Clinic"
    Then "Bella" should belong to organisation "Happy Paws Clinic"
    And "Alice" should see "Bella" in her pet list under "Happy Paws Clinic"

  Scenario: All organisation members can see an organisation pet
    Given a pet "Bella" exists under "Happy Paws Clinic"
    When "Bob" views his pet list
    Then "Bob" should see "Bella" listed under "Happy Paws Clinic"

  Scenario: Organisation pets appear grouped by organisation
    Given a pet "Bella" exists under "Happy Paws Clinic"
    And "Alice" has a personal pet named "Milo"
    When "Alice" views her pet list
    Then "Milo" should appear under "My Pets"
    And "Bella" should appear under "Happy Paws Clinic"

  # ── Assigning Members ───────────────────────────────────────

  Scenario: Assigning a member to an organisation pet on creation
    When "Alice" creates a pet named "Luna" under "Happy Paws Clinic" assigned to "Bob"
    Then "Luna" should belong to "Happy Paws Clinic"
    And a family event should be created assigning "Bob" to "Luna"

  # ── Health Tracking for Org Pets ─────────────────────────────

  Scenario: Adding a health entry to an organisation pet
    Given a pet "Bella" exists under "Happy Paws Clinic"
    When "Bob" adds a health entry "Annual Vaccination" of type "preventive" for "Bella"
    Then "Bella" should have a health entry named "Annual Vaccination"
    And "Alice" should also see "Annual Vaccination" in the health dashboard

  Scenario: Organisation pet events appear in all members' dashboards
    Given a pet "Bella" exists under "Happy Paws Clinic"
    And "Bella" has a health entry "Flea Treatment" due tomorrow
    When "Alice" views the health dashboard filtered by "Happy Paws Clinic"
    Then "Flea Treatment" should appear in the due events list
