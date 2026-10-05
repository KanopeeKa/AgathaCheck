Feature: Care item form advanced settings
  As a pet parent
  I want schedule type and late-completion choices under Advanced settings
  So that the main form stays simple

  Background:
    Given the user is logged in
    And a pet "Milo" exists

  @P1
  Scenario: F42 expand Advanced and choose Fixed schedule
    When the user opens the care add form for "Milo"
    And the user selects care family "medication" on the form
    And the user expands Advanced settings on the care form
    And the user selects schedule type "Fixed schedule"
    Then the care form shows schedule type "Fixed schedule"
