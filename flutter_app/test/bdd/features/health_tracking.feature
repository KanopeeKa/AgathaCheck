Feature: Health Tracking
  As a pet owner
  I want to track my pets' health entries including medications, preventives, and vet visits
  So that I can manage their healthcare schedule effectively

  Background:
    Given the user is logged in
    And a pet "Bella" exists

  # ── Creating Health Entries ──────────────────────────────────

  Scenario: Creating a medication entry
    When the user navigates to the health dashboard
    And the user taps the "Add Entry" button
    And the user selects type "Medication"
    And the user enters entry name "Heartworm Prevention"
    And the user selects pet "Bella"
    And the user enters dosage "1 tablet"
    And the user selects frequency "Monthly"
    And the user sets the next due date to "2025-07-01"
    And the user saves the health entry
    Then "Heartworm Prevention" should appear in the health dashboard
    And "Heartworm Prevention" should be of type "Medication"

  Scenario: Creating a preventive entry
    When the user creates a health entry "Flea Treatment" of type "Preventive" for "Bella"
    Then "Flea Treatment" should appear under the "Preventives" tab

  Scenario: Creating a vet visit entry
    When the user creates a health entry "Annual Checkup" of type "Vet Visit" for "Bella"
    Then "Annual Checkup" should appear under the "Vet Visits" tab

  Scenario: Creating a procedure entry
    When the user creates a health entry "Dental Cleaning" of type "Procedure" for "Bella"
    Then "Dental Cleaning" should appear under the "Other" tab

  Scenario: Adding a photo attachment to a health entry
    When the user creates a health entry "Vaccination" for "Bella"
    And the user attaches a photo to the entry
    And the user saves the health entry
    Then the health entry should have a photo attachment

  # ── Viewing Health Entries ───────────────────────────────────

  Scenario: Viewing all health entries in the dashboard
    Given "Bella" has health entries "Heartworm", "Flea Treatment", and "Annual Checkup"
    When the user navigates to the health dashboard
    And the user selects the "All" tab
    Then the user should see all 3 entries listed

  Scenario: Filtering entries by type using tabs
    Given "Bella" has a medication "Heartworm" and a preventive "Flea Treatment"
    When the user navigates to the health dashboard
    And the user selects the "Medications" tab
    Then only "Heartworm" should be displayed

  Scenario: Grouping entries by due date
    Given "Bella" has an overdue entry and a future entry
    When the user navigates to the health dashboard
    And the user selects group by "Due Date"
    Then entries should be grouped into "Overdue", "Today", "This Week", and "Later" sections

  Scenario: Grouping entries by pet
    Given "Bella" and "Max" each have health entries
    When the user selects group by "Pet"
    Then entries should be grouped under "Bella" and "Max"

  Scenario: Grouping entries by species
    Given "Bella" is a Dog and "Whiskers" is a Cat with health entries
    When the user selects group by "Species"
    Then entries should be grouped under "Dogs" and "Cats"

  Scenario: Empty health dashboard shows prompt
    Given "Bella" has no health entries
    When the user navigates to the health dashboard
    Then the user should see a "No entries yet" message

  # ── Updating Health Entries ──────────────────────────────────

  Scenario: Editing a health entry
    Given "Bella" has a health entry "Heartworm" with dosage "1 tablet"
    When the user edits "Heartworm" and changes dosage to "2 tablets"
    And the user saves the health entry
    Then "Heartworm" should have dosage "2 tablets"

  # ── Deleting Health Entries ──────────────────────────────────

  Scenario: Deleting a health entry
    Given "Bella" has a health entry "Old Treatment"
    When the user deletes "Old Treatment"
    And the user confirms the deletion
    Then "Old Treatment" should no longer appear in the dashboard

  # ── Marking Entries as Done ──────────────────────────────────

  Scenario: Marking a health entry as taken
    Given "Bella" has a due health entry "Heartworm"
    When the user marks "Heartworm" as taken
    Then "Heartworm" should move to the "Completed" section
    And a success message "Marked as done" should appear

  Scenario: Undoing a completed entry
    Given "Bella" has a completed health entry "Heartworm"
    When the user undoes the completion of "Heartworm"
    Then "Heartworm" should move back to the active entries

  # ── Snoozing Entries ─────────────────────────────────────────

  Scenario: Snoozing a health entry
    Given "Bella" has a due health entry "Flea Treatment"
    When the user snoozes "Flea Treatment" for 3 days
    Then the due date of "Flea Treatment" should be pushed forward by 3 days
    And a snackbar should confirm the snooze

  # ── Entry History ────────────────────────────────────────────

  Scenario: Viewing history for a health entry
    Given "Bella" has a health entry "Heartworm" that has been marked taken 3 times
    When the user views the history for "Heartworm"
    Then the user should see 3 history records with timestamps

  # ── Health Issues ────────────────────────────────────────────

  Scenario: Creating a health issue for a pet
    Given a pet "Bella" exists
    When the user creates a health issue "Arthritis" for "Bella" with start date "2024-01-15"
    Then "Bella" should have a health issue "Arthritis"

  Scenario: Linking a health entry to a health issue
    Given "Bella" has a health issue "Arthritis"
    When the user creates a health entry "Pain Medication" linked to "Arthritis"
    Then "Pain Medication" should display the health issue name "Arthritis"

  # ── Due Events on Pet List ──────────────────────────────────

  Scenario: Due events appear on the pet list screen
    Given "Bella" has a health entry due today
    When the user views the pet list
    Then a "Due & Overdue Events" section should be visible
    And the due entry for "Bella" should be listed

  Scenario: No due events shows all caught up
    Given no health entries are due or overdue
    When the user views the pet list
    Then a "You're all caught up" message should appear

  # ── CSV Export ───────────────────────────────────────────────

  Scenario: Exporting health entries as CSV
    Given "Bella" has health entries
    When the user taps the CSV export button on the health dashboard
    Then a dialog should display the CSV content

  # ── PDF Export ───────────────────────────────────────────────

  Scenario: Exporting health entries as PDF
    Given "Bella" has health entries
    When the user taps the PDF export button on the health dashboard
    Then a PDF file should be generated and downloaded

  # ── Organisation Filter ─────────────────────────────────────

  Scenario: Filtering health entries by organisation
    Given the user has pets in "Happy Paws Clinic" and personal pets
    When the user selects the "Happy Paws Clinic" filter chip
    Then only health entries for pets in "Happy Paws Clinic" should be displayed
