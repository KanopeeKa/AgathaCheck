Feature: Pet offline cache
  As a pet parent using the guardian pet list
  I want cached pets to load when the network fails
  So that I can still see who I am caring for offline

  Background:
    Given the user is logged in

  @P1
  Scenario: Pet list shows saved pets with an offline banner when the network fails
    Given a pet "Bella" exists for the user
    And the pet list has loaded successfully
    When pet list API requests are blocked
    And the user reloads the pet list
    Then the offline banner should be visible
    And "Bella" should appear in the pet list
    When pet list API requests are allowed again
    And the user taps Retry on the pet list
    Then the offline banner should not be visible

  @P1
  Scenario: Pet list does not show cached pets when the session is rejected
    Given a pet "Bella" exists for the user
    And the pet list has loaded successfully
    When pet list API requests return unauthorized
    And the user reloads the pet list
    Then the session should be rejected
    And "Bella" should not appear in the pet list
    And the offline banner should not be visible
