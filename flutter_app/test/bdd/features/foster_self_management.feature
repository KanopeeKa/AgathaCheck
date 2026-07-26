Feature: Foster self-management
  As a foster
  I want to control who can see my details
  So that I feel safe sharing my information with a shelter

  Background:
    Given an organisation "Rescue Hearts" of type "Charity"
    And "Alice" is a super user of "Rescue Hearts"
    And a registered user "Eve" is a foster parent of "Rescue Hearts"

  @P2
  Scenario: Foster restricts address visibility to town only
    Given "Eve" has agreed to follow organisation rules for "Rescue Hearts"
    When "Eve" opens Manage Fosters for "Rescue Hearts"
    And "Eve" sets her address visibility to "town only"
    Then another foster viewing "Eve"'s card should see only her town

  @P2
  Scenario: Foster self-card appears first in the directory
    When "Eve" opens Manage Fosters for "Rescue Hearts"
    Then "Eve" should see her foster self-card pinned first

Feature: Foster agreement withdrawal
  As a foster who no longer agrees to the organisation's rules
  I want to withdraw my agreement deliberately
  So that the shelter is aware and my active sessions are reviewed

  Background:
    Given an organisation "Rescue Hearts" of type "Charity"
    And "Alice" is a super user of "Rescue Hearts"
    And a registered user "Eve" is a foster parent of "Rescue Hearts"

  @P2
  Scenario: Withdrawing agreement requires typed confirmation
    Given "Eve" has an active fostering session with "Rescue Hearts"
    And "Eve" has agreed to follow organisation rules for "Rescue Hearts"
    When "Eve" unticks her agreement to follow the rules
    Then "Eve" should be warned that her sessions may be affected
    And "Eve" should be required to type "withdraw" to confirm

  @P2
  Scenario: Withdrawal auto-pauses sessions and alerts admins
    Given "Eve" has an active fostering session with "Rescue Hearts"
    And "Eve" has agreed to follow organisation rules for "Rescue Hearts"
    When "Eve" confirms withdrawal by typing "withdraw"
    Then "Eve"'s active fostering session should be flagged for admin review
    And every admin of "Rescue Hearts" should receive an urgent notification
