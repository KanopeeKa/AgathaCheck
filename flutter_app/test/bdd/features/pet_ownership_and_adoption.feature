Feature: Pet Ownership and Adoption
  As an organisation super user
  I want to transfer pets to private users and manage archived records
  So that I can handle adoptions and maintain a history of the pet's journey

  Background:
    Given an organisation "Rescue Hearts" of type "Charity"
    And "Alice" is a super user of "Rescue Hearts"

  # ── Adoption / Transfer ──────────────────────────────────────

  Scenario: Sharing an organisation pet with a prospective adopter
    Given a pet "Max" exists under "Rescue Hearts"
    And a registered user "Eve"
    When "Alice" creates a share link for "Max"
    And "Eve" accepts the share link
    Then "Eve" should see "Max" in her pet list as a shared pet

  Scenario: Adopter places a shared pet into their personal list
    Given "Eve" has accepted a share for pet "Max"
    When "Eve" accepts the pending share for "Max" into her personal list
    Then "Max" should appear under "My Pets" for "Eve"
    And "Max" should still belong to "Rescue Hearts"

  Scenario: Adopter places a shared pet into another organisation
    Given "Eve" is a member of organisation "Eve's Foster Home"
    And "Eve" has accepted a share for pet "Max"
    When "Eve" accepts the pending share for "Max" into "Eve's Foster Home"
    Then "Max" should appear under "Eve's Foster Home" for "Eve"

  # ── Archiving ────────────────────────────────────────────────

  Scenario: Archiving a pet from the organisation after adoption
    Given a pet "Max" exists under "Rescue Hearts"
    When "Alice" archives "Max" from "Rescue Hearts"
    Then "Max" should no longer appear in the active pet list of "Rescue Hearts"
    And "Max" should appear in the archived pets of "Rescue Hearts"

  Scenario: Viewing archived pets
    Given a pet "Max" has been archived from "Rescue Hearts"
    When "Alice" views the archived pets of "Rescue Hearts"
    Then she should see "Max" in the archived list

  Scenario: Restoring an archived pet
    Given a pet "Max" has been archived from "Rescue Hearts"
    When "Alice" restores "Max" from the archive of "Rescue Hearts"
    Then "Max" should appear in the active pet list of "Rescue Hearts"
    And "Max" should no longer appear in the archived list

  # ── Hiding Shared Pets ───────────────────────────────────────

  Scenario: Hiding a shared pet from the organisation view
    Given "Eve" has a shared pet "Max" under "Rescue Hearts"
    When "Eve" hides "Max"
    Then "Max" should not appear in "Eve"'s pet list
    And "Max" should not generate notifications for "Eve"
    And "Max" should not appear in "Eve"'s health dashboard

  Scenario: Unhiding a previously hidden shared pet
    Given "Eve" has hidden the shared pet "Max" under "Rescue Hearts"
    When "Eve" unhides "Max" from the organisation detail page
    Then "Max" should appear again in "Eve"'s pet list
    And "Max" should resume generating notifications for "Eve"
