Feature: Authentication
  As a user
  I want to sign up, log in, and manage my account
  So that I can securely access and control my pet data

  # ── Sign Up ──────────────────────────────────────────────────

  Scenario: Signing up with valid credentials
    Given the user is on the signup screen
    When the user enters name "Alice Smith"
    And the user enters email "alice@example.com"
    And the user enters password "secret123"
    And the user confirms password "secret123"
    And the user taps the "Create Account" button
    Then the user should be logged in
    And the user should be navigated to the pet list screen

  Scenario: Signing up with mismatched passwords
    Given the user is on the signup screen
    When the user enters password "secret123"
    And the user confirms password "different456"
    And the user taps the "Create Account" button
    Then an error should indicate that passwords do not match

  Scenario: Signing up without an email
    Given the user is on the signup screen
    When the user leaves the email field empty
    And the user taps the "Create Account" button
    Then an error should indicate that email is required

  Scenario: Signing up with an invalid email
    Given the user is on the signup screen
    When the user enters email "not-an-email"
    And the user taps the "Create Account" button
    Then an error should indicate that the email is invalid

  Scenario: Signing up with a password shorter than 6 characters
    Given the user is on the signup screen
    When the user enters password "abc"
    And the user confirms password "abc"
    And the user taps the "Create Account" button
    Then an error should indicate that the password must be at least 6 characters

  Scenario: Signing up with an already registered email
    Given a user with email "alice@example.com" already exists
    And the user is on the signup screen
    When the user enters email "alice@example.com"
    And the user enters password "secret123"
    And the user confirms password "secret123"
    And the user taps the "Create Account" button
    Then an error should indicate that the email is already in use

  # ── Log In ───────────────────────────────────────────────────

  Scenario: Logging in with valid credentials
    Given a registered user with email "alice@example.com" and password "secret123"
    And the user is on the login screen
    When the user enters email "alice@example.com"
    And the user enters password "secret123"
    And the user taps the "Sign In" button
    Then the user should be logged in
    And the user should be navigated to the pet list screen

  Scenario: Logging in with incorrect password
    Given a registered user with email "alice@example.com" and password "secret123"
    And the user is on the login screen
    When the user enters email "alice@example.com"
    And the user enters password "wrongpassword"
    And the user taps the "Sign In" button
    Then an error should indicate invalid credentials

  Scenario: Logging in with a non-existent email
    Given the user is on the login screen
    When the user enters email "nobody@example.com"
    And the user enters password "secret123"
    And the user taps the "Sign In" button
    Then an error should indicate invalid credentials

  Scenario: Logging in without an email
    Given the user is on the login screen
    When the user leaves the email field empty
    And the user taps the "Sign In" button
    Then an error should indicate that email is required

  Scenario: Logging in without a password
    Given the user is on the login screen
    When the user enters email "alice@example.com"
    And the user leaves the password field empty
    And the user taps the "Sign In" button
    Then an error should indicate that password is required

  # ── Password Visibility ─────────────────────────────────────

  Scenario: Toggling password visibility on the login screen
    Given the user is on the login screen
    When the user taps the show password toggle
    Then the password field should display the text in plain text
    When the user taps the show password toggle again
    Then the password field should obscure the text

  # ── Log Out ──────────────────────────────────────────────────

  Scenario: Logging out from the app
    Given the user is logged in
    When the user opens the user menu
    And the user taps "Log Out"
    Then the user should be logged out
    And the user should be navigated to the landing screen

  # ── My Details ───────────────────────────────────────────────

  Scenario: Viewing user details
    Given the user is logged in as "Alice Smith" with email "alice@example.com"
    When the user opens the user menu
    And the user taps "My Details"
    Then the user should see their name "Alice Smith"
    And the user should see their email "alice@example.com"

  Scenario: Updating user profile
    Given the user is logged in
    When the user navigates to "My Details"
    And the user updates their first name to "Bob"
    And the user saves changes
    Then the user's name should be updated to "Bob"

  # ── Navigation ───────────────────────────────────────────────

  Scenario: Navigating from login to signup
    Given the user is on the login screen
    When the user taps the "Sign Up" link
    Then the user should be navigated to the signup screen

  Scenario: Navigating from signup to login
    Given the user is on the signup screen
    When the user taps the "Sign In" link
    Then the user should be navigated to the login screen
