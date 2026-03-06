Feature: Subscriptions
  As a user
  I want to manage my subscription to Agatha Track
  So that I can access unlimited features

  Background:
    Given the user is logged in

  # ── Free Plan ────────────────────────────────────────────────

  Scenario: Viewing the paywall on a free plan
    Given the user is on the free plan
    When the user navigates to the subscription screen
    Then the user should see "Free Plan" as the current plan
    And the user should see a list of premium features
    And the user should see available subscription offerings

  Scenario: Viewing premium features list
    Given the user is on the free plan
    When the user views the subscription screen
    Then the user should see features including:
      | feature                     |
      | Unlimited pet profiles      |
      | Full health tracking        |
      | Pet sharing with family     |
      | PDF report generation       |
      | Health reminders            |
      | Priority support            |

  # ── Purchasing ───────────────────────────────────────────────

  Scenario: Purchasing a monthly subscription
    Given the user is on the free plan
    And a monthly subscription offering is available
    When the user taps subscribe on the monthly plan
    Then the subscription should be processed
    And the user should see "Agatha Track Unlimited" as the current plan

  Scenario: Purchasing a yearly subscription
    Given the user is on the free plan
    And a yearly subscription offering is available
    When the user taps subscribe on the yearly plan
    Then the subscription should be processed
    And the yearly plan should show a "Best Value" tag

  Scenario: Purchase failure shows error
    Given the user is on the free plan
    When the user attempts to purchase a subscription and the purchase fails
    Then an error snackbar "Purchase failed" should be displayed

  # ── Active Subscription ──────────────────────────────────────

  Scenario: Viewing active subscription details
    Given the user has an active unlimited subscription
    When the user navigates to the subscription screen
    Then the user should see "Agatha Track Unlimited" as the current plan
    And the user should see a renewal date
    And a premium icon should be displayed

  Scenario: Managing active subscription
    Given the user has an active unlimited subscription with a management URL
    When the user navigates to the subscription screen
    Then a "Manage Subscription" button should be visible

  # ── Restoring Purchases ─────────────────────────────────────

  Scenario: Restoring previous purchases
    When the user taps "Restore Purchases"
    Then the app should check for previous purchases
    And a confirmation message should appear

  Scenario: Restore purchases with no previous purchases
    Given the user has no previous purchases
    When the user taps "Restore Purchases"
    Then the subscription status should remain on the free plan

  # ── No Offerings Available ───────────────────────────────────

  Scenario: No subscription offerings available
    Given no subscription offerings are configured
    When the user navigates to the subscription screen
    Then an error message "No subscription plans are available" should be displayed
    And a "Load Plans" retry button should be visible

  Scenario: Failed to load subscription offerings
    Given the subscription service is unavailable
    When the user navigates to the subscription screen
    Then an error message "Unable to load subscription options" should be displayed
