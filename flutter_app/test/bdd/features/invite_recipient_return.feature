Feature: Invite recipient return-to-invite journeys
  As a person who opens an invitation link while signed out
  I want to sign in and return to the same invite
  So that I can explicitly accept or decline without auto-accepting

  @P1
  Scenario: Share link recipient signs in and returns to the same share code
    Given a registered pet owner has created a share link for their pet
    And a registered user who is not signed in
    When the user opens the share link
    Then they see who invited them and a sign-in action
    And they do not see accept or add buttons
    When they continue to sign in or create an account
    And they sign in with valid credentials
    Then they return to the same share link
    And they see an explicit accept action

  @P1
  Scenario: Email share invite recipient signs in and returns to the same invite code
    Given a registered pet owner has emailed a share invitation
    And the invited user is not signed in
    When the invited user opens the email invite link
    Then they see who invited them and a sign-in action
    And they do not see accept or decline buttons
    When they continue to sign in or create an account
    And they sign in with valid credentials
    Then they return to the same invite link
    And they see explicit accept and decline actions

  @P1
  Scenario: Away-plan carer invite recipient signs in and returns to the same invite code
    Given a guardian has created an away-plan carer invitation
    And the invited carer is not signed in
    When the carer opens the away-plan invite link
    Then they see who invited them and a sign-in action
    When they continue to sign in or create an account
    And they sign in with valid credentials
    Then they return to the same away-plan invite link
    And they see an explicit accept action

  @P1
  Scenario: Household invite recipient signs in and returns to the same invite code
    Given a household organiser has invited a member by email
    And the invited member is not signed in
    When the member opens the household invite link
    Then they see who invited them and a sign-in action
    And they do not see accept or decline buttons
    When they continue to sign in or create an account
    And they sign in with valid credentials
    Then they return to the same household invite link
    And they see explicit accept and decline actions
