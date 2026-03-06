Feature: Notifications
  As a pet owner
  I want to receive in-app notifications about due health entries and events
  So that I never miss an important health task for my pets

  Background:
    Given the user is logged in

  # ── Notification Generation ──────────────────────────────────

  Scenario: Notification generated for overdue health entry
    Given a pet "Bella" has a health entry "Vaccination" that is overdue
    When the system checks for due entries
    Then a notification of type "overdue" should be created for "Vaccination"

  Scenario: Notification generated for entry due soon
    Given a pet "Bella" has a health entry "Flea Treatment" due tomorrow
    When the system checks for due entries
    Then a notification of type "due_soon" should be created for "Flea Treatment"

  Scenario: Notification generated when entry is completed
    Given a pet "Bella" has a health entry "Heartworm"
    When the user marks "Heartworm" as taken
    Then a notification of type "completed" should be created for "Heartworm"

  # ── Viewing Notifications ────────────────────────────────────

  Scenario: Viewing the notification list
    Given there are 5 unread notifications
    When the user navigates to the notifications screen
    Then the user should see 5 notification items

  Scenario: Notifications grouped by date
    Given there are notifications from today and yesterday
    When the user views the notifications screen
    Then notifications should be grouped under "Today" and "Yesterday"

  Scenario: Empty notifications shows message
    Given the user has no notifications
    When the user navigates to the notifications screen
    Then the user should see a "No notifications" message
    And a description about when notifications will appear

  Scenario: Notification shows pet name and color
    Given a notification exists for pet "Bella" with a custom color
    When the user views the notifications screen
    Then the notification should display "Bella"'s name with her assigned color

  # ── Unread Badge ─────────────────────────────────────────────

  Scenario: Unread notification badge on app bar
    Given there are 3 unread notifications
    When the user views the pet list screen
    Then the notification icon should show a badge with "3"

  Scenario: Badge updates when notifications are read
    Given there are 3 unread notifications
    When the user reads one notification
    Then the notification badge should show "2"

  Scenario: No badge when all notifications are read
    Given all notifications are read
    When the user views the pet list screen
    Then the notification icon should not show a badge

  # ── Marking as Read ──────────────────────────────────────────

  Scenario: Marking a single notification as read
    Given there is an unread notification for "Vaccination"
    When the user taps on the notification
    Then the notification should be marked as read
    And the unread indicator should disappear

  Scenario: Marking all notifications as read
    Given there are 5 unread notifications
    When the user taps "Mark All Read"
    Then all notifications should be marked as read
    And a confirmation snackbar should appear

  # ── Notification Navigation ──────────────────────────────────

  Scenario: Tapping a pet notification navigates to pet detail
    Given a notification exists for pet "Bella"
    When the user taps the notification
    Then the user should be navigated to "Bella"'s detail screen

  Scenario: Tapping an organisation notification navigates to org detail
    Given a notification exists for organisation "Happy Paws Clinic"
    When the user taps the notification
    Then the user should be navigated to the "Happy Paws Clinic" detail screen

  # ── Notification Settings ────────────────────────────────────

  Scenario: Accessing notification settings
    When the user navigates to the notifications screen
    And the user taps the settings icon
    Then the user should see the notification settings screen

  Scenario: Muting notifications for a specific pet
    Given a pet "Bella" exists
    When the user mutes notifications for "Bella"
    Then notifications for "Bella" should not appear in the list

  Scenario: Unmuting notifications for a pet
    Given notifications for "Bella" are muted
    When the user unmutes notifications for "Bella"
    Then notifications for "Bella" should appear in the list again

  # ── Organisation Notifications ───────────────────────────────

  Scenario: Organisation-related notifications display org icon
    Given a notification related to organisation "Happy Paws Clinic" exists
    When the user views the notifications screen
    Then the notification should display an organisation icon
