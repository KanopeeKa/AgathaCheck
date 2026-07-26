// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get appTitle => 'Agatha Track';

  @override
  String get agathaCheckLogo => 'Agatha Track logo';

  @override
  String get appTagline =>
      'Agatha Track keeps your pet\'s health organized — whether you\'re a pet parent, a shelter, or a professional organisation.';

  @override
  String get appDescription =>
      'Track vet visits, medications, weight, and daily care in one simple dashboard. Create organisations to collaborate with your team, share pets, and coordinate care across your entire network.';

  @override
  String get appCta =>
      'Log in to pick up where you left off, or create a free account to start keeping your pet\'s health history safe and accessible anytime.';

  @override
  String get landingGuardianPathSummary => 'For pet parents and foster carers';

  @override
  String get landingGuardianPathExpandCta => 'See how it works';

  @override
  String get landingGuardianPathCollapseCta => 'Show less';

  @override
  String get landingGuardianPathDetail =>
      'Track vet visits, medications, weight, and daily care in one place. Coordinate with your household and keep every pet\'s health history safe.';

  @override
  String get landingOrgPathSummary => 'For shelters, rescues, and care teams';

  @override
  String get landingOrgPathExpandCta => 'See organisation features';

  @override
  String get landingOrgPathCollapseCta => 'Show less';

  @override
  String get landingOrgPathDetail =>
      'Manage inventory pets, coordinate staff and volunteers, and share care records across your organisation.';

  @override
  String get signIn => 'Sign In';

  @override
  String get signUp => 'Sign Up';

  @override
  String get createAccount => 'Create Account';

  @override
  String get signInToAccount => 'Sign in to your account';

  @override
  String get signInWithPasswordManager => 'Sign in with password manager';

  @override
  String get createYourAccount => 'Create your account';

  @override
  String get dontHaveAccount => 'Don\'t have an account?';

  @override
  String get alreadyHaveAccount => 'Already have an account?';

  @override
  String get email => 'Email';

  @override
  String get password => 'Password';

  @override
  String get name => 'Name';

  @override
  String get confirmPassword => 'Confirm Password';

  @override
  String get showPassword => 'Show password';

  @override
  String get hidePassword => 'Hide password';

  @override
  String get emailRequired => 'Email is required';

  @override
  String get enterValidEmail => 'Enter a valid email';

  @override
  String get passwordRequired => 'Password is required';

  @override
  String get atLeast6Characters => 'At least 6 characters';

  @override
  String get passwordsDoNotMatch => 'Passwords do not match';

  @override
  String get forgotPassword => 'Forgot Password?';

  @override
  String get logOut => 'Log Out';

  @override
  String get resetPassword => 'Reset Password';

  @override
  String get forgotPasswordTitle => 'Forgot Password';

  @override
  String get enterResetCode => 'Enter Reset Code';

  @override
  String get enterResetCodeInstructions =>
      'Enter the 6-digit code and your new password.';

  @override
  String get forgotPasswordInstructions =>
      'Enter your email address and we\'ll send you a code to reset your password.';

  @override
  String get resetCodeSentMessage =>
      'If an account with that email exists, a reset code has been sent. Check your email.';

  @override
  String get sendResetCode => 'Send Reset Code';

  @override
  String get resetCode => 'Reset Code';

  @override
  String get sixDigitCode => '6-digit code';

  @override
  String get codeRequired => 'Code is required';

  @override
  String get enterSixDigitCode => 'Enter the 6-digit code';

  @override
  String get newPassword => 'New Password';

  @override
  String get useDifferentEmail => 'Use a different email';

  @override
  String get passwordResetTitle => 'Password Reset';

  @override
  String get backToSignIn => 'Back to sign in';

  @override
  String get myDetails => 'My Details';

  @override
  String get notLoggedIn => 'Not logged in';

  @override
  String get editProfile => 'Edit profile';

  @override
  String get subscription => 'Subscription';

  @override
  String get managePlan => 'Manage your plan';

  @override
  String get changePassword => 'Change Password';

  @override
  String get currentPassword => 'Current Password';

  @override
  String get showCurrentPassword => 'Show current password';

  @override
  String get hideCurrentPassword => 'Hide current password';

  @override
  String get currentPasswordRequired => 'Current password is required';

  @override
  String get showNewPassword => 'Show new password';

  @override
  String get hideNewPassword => 'Hide new password';

  @override
  String get newPasswordRequired => 'New password is required';

  @override
  String get confirmNewPassword => 'Confirm New Password';

  @override
  String get detailsVisibleToShared =>
      'These details are visible to people you share pets with';

  @override
  String get profileUpdated => 'Profile updated';

  @override
  String failedToPickPhoto(String error) {
    return 'Failed to pick photo: $error';
  }

  @override
  String failedToSave(String error) {
    return 'Failed to save: $error';
  }

  @override
  String get petGuardian => 'Pet Guardian';

  @override
  String get professionalMultiPet => 'Professional Multi Pet';

  @override
  String categoryLabel(String category) {
    return 'Category: $category';
  }

  @override
  String get firstName => 'First Name';

  @override
  String get lastName => 'Last Name';

  @override
  String get bio => 'Bio';

  @override
  String get category => 'Category';

  @override
  String get save => 'Save';

  @override
  String get cancel => 'Cancel';

  @override
  String get delete => 'Delete';

  @override
  String get edit => 'Edit';

  @override
  String get close => 'Close';

  @override
  String get retry => 'Retry';

  @override
  String get language => 'Language';

  @override
  String get english => 'English';

  @override
  String get french => 'Français';

  @override
  String get myPets => 'My Pets';

  @override
  String get myFosteredPets => 'My Fostered Pets';

  @override
  String get noFosteredPets => 'You are not fostering any pets yet.';

  @override
  String get allPets => 'All Pets';

  @override
  String get filterByOrganization => 'Filter by organization';

  @override
  String get notifications => 'Notifications';

  @override
  String get veterinarians => 'Veterinarians';

  @override
  String get events => 'To Do';

  @override
  String get userMenu => 'User menu';

  @override
  String get addPet => 'Add Pet';

  @override
  String get addNewPet => 'Add a new pet';

  @override
  String failedToLoadPets(String error) {
    return 'Failed to load pets: $error';
  }

  @override
  String get noPetsYet => 'No pets yet';

  @override
  String get noPetsMatchFilter => 'No pets match this filter.';

  @override
  String get showAllPets => 'Show all pets';

  @override
  String get addFirstPet => 'Tap + to add your first pet';

  @override
  String get petDetails => 'Pet Details';

  @override
  String get petNotFound => 'Pet not found';

  @override
  String errorWithMessage(String error) {
    return 'Error: $error';
  }

  @override
  String get goBack => 'Go back';

  @override
  String get editPet => 'Edit Pet';

  @override
  String neuteredSpayed(String date) {
    return 'Neutered / Spayed: $date';
  }

  @override
  String idLabel(String id) {
    return 'ID: $id';
  }

  @override
  String get insuranceDetails => 'Insurance Details';

  @override
  String get noVetAssigned => 'No vet assigned';

  @override
  String get addVetFirst => 'Add a veterinarian. No vets yet.';

  @override
  String get selectVeterinarian => 'Select veterinarian';

  @override
  String get removeVet => 'Remove vet';

  @override
  String get passedAway => 'Passed Away';

  @override
  String get weightTracking => 'Weight Tracking';

  @override
  String get addEntry => 'Add Health Event';

  @override
  String errorLoadingWeightData(String error) {
    return 'Error loading weight data: $error';
  }

  @override
  String get noWeightDataYet => 'No weight data yet';

  @override
  String get tapAddEntryToStart => 'Tap \"Add Entry\" to start tracking';

  @override
  String get addWeightEntry => 'Add weight entry';

  @override
  String get selectDate => 'Select date for weight entry';

  @override
  String get date => 'Date';

  @override
  String weightWithUnit(String unit) {
    return 'Weight ($unit)';
  }

  @override
  String get notesOptional => 'Notes (optional)';

  @override
  String get pleaseEnterValidWeight => 'Please enter a valid weight';

  @override
  String get weightFormatHint => 'Enter a number greater than 0, e.g. 12.5';

  @override
  String get deleteWeightEntry => 'Delete weight entry';

  @override
  String weightChartLabel(int count) {
    return 'Weight chart showing $count entries';
  }

  @override
  String get healthEvents => 'Health Events';

  @override
  String get otherEvents => 'Other events';

  @override
  String get addOtherEvent => 'Add event';

  @override
  String get careEvent => 'Care event';

  @override
  String get careEvents => 'Care events';

  @override
  String get addHealthEntry => 'Add health entry';

  @override
  String get noEntriesYet => 'No entries yet';

  @override
  String noTypeEntriesYet(String type) {
    return 'No $type entries yet';
  }

  @override
  String get tapPlusToAdd => 'Tap + to add one';

  @override
  String errorLoadingEntries(String error) {
    return 'Error loading entries:\n$error';
  }

  @override
  String get all => 'All';

  @override
  String get medications => 'Medications';

  @override
  String get preventives => 'Preventives';

  @override
  String get vetVisits => 'Vet Visits';

  @override
  String get other => 'Other';

  @override
  String get overdue => 'Overdue';

  @override
  String get today => 'Today';

  @override
  String get tomorrow => 'Tomorrow';

  @override
  String get thisWeek => 'This Week';

  @override
  String get later => 'Later';

  @override
  String get completed => 'Completed';

  @override
  String get groupBy => 'Group by';

  @override
  String get byDueDate => 'By Due Date';

  @override
  String get byPet => 'By Pet';

  @override
  String get bySpecies => 'By Species';

  @override
  String get exportPdf => 'Export PDF';

  @override
  String get exportCsv => 'Export CSV';

  @override
  String get csvExport => 'CSV Export';

  @override
  String exportFailed(String error) {
    return 'Export failed: $error';
  }

  @override
  String pdfExportFailed(String error) {
    return 'PDF export failed: $error';
  }

  @override
  String markedAsDone(String name) {
    return '$name marked as done';
  }

  @override
  String snoozedForDays(String name, int days, String dayLabel) {
    return '$name snoozed for $days $dayLabel';
  }

  @override
  String get day => 'day';

  @override
  String get days => 'days';

  @override
  String get entryName => 'Entry Name *';

  @override
  String get entryNameRequired => 'Name is required';

  @override
  String get selectPet => 'Select Pet *';

  @override
  String get petRequired => 'Pet is required';

  @override
  String get entryType => 'Type *';

  @override
  String get medication => 'Medication';

  @override
  String get preventive => 'Preventive';

  @override
  String get vetVisit => 'Vet Visit';

  @override
  String get procedure => 'Other';

  @override
  String get familyEvent => 'Family Event';

  @override
  String get dosage => 'Dosage';

  @override
  String get frequency => 'Frequency';

  @override
  String get doesNotRepeat => 'Does not repeat';

  @override
  String get daily => 'Day';

  @override
  String get weekly => 'Week';

  @override
  String get monthly => 'Month';

  @override
  String get yearly => 'Year';

  @override
  String get custom => 'Custom';

  @override
  String get periodDays => 'Days';

  @override
  String get periodWeeks => 'Weeks';

  @override
  String get periodMonths => 'Months';

  @override
  String get periodYears => 'Years';

  @override
  String get every => 'Every';

  @override
  String everyPeriod(String period) {
    return 'Every $period';
  }

  @override
  String everyNPeriods(int n, String periods) {
    return 'Every $n $periods';
  }

  @override
  String get repeatEndDate => 'Repeat End Date';

  @override
  String get noEndDate => 'No end date';

  @override
  String get startDate => 'Start Date';

  @override
  String get dueDate => 'Due date';

  @override
  String get completedOn => 'Completed on';

  @override
  String get dueOrCompletedRequired =>
      'Enter a due date, a completed date, or both';

  @override
  String get recurrenceAnchorTitle => 'Next occurrence';

  @override
  String get recurrenceFromCompletion => 'From completion';

  @override
  String get recurrenceFromDueDate => 'Fixed schedule';

  @override
  String get recurrenceAnchorInfoTitle => 'How does scheduling work?';

  @override
  String get recurrenceAnchorInfoBody =>
      'Example: every 7 days. You complete it 1 day late.\n• From completion: next due 7 days after you mark it done.\n• Fixed schedule: next due 6 days from today (7 days after the original due date).';

  @override
  String get markCompleteSheetTitle => 'Mark as completed';

  @override
  String get markCompleteSheetSubtitle => 'When did this actually happen?';

  @override
  String eventHistoryLine(
    String due,
    String completed,
    String recorded,
    String user,
  ) {
    return 'Due $due, completed $completed, recorded $recorded by $user';
  }

  @override
  String get unknownUser => 'Unknown user';

  @override
  String get clear => 'Clear';

  @override
  String get nextDueDate => 'Next Due Date';

  @override
  String get notes => 'Notes';

  @override
  String get healthIssueOptional => 'Health Issue (optional)';

  @override
  String get none => 'None';

  @override
  String get addHealthEntry2 => 'Add a health event';

  @override
  String get editEntry => 'Edit Entry';

  @override
  String get saveEntry => 'Save';

  @override
  String get deleteEntry => 'Delete Entry';

  @override
  String get deleteEntryConfirm =>
      'Are you sure you want to delete this entry?';

  @override
  String get entryCreated => 'Entry created';

  @override
  String get entryUpdated => 'Entry updated';

  @override
  String get entryDeleted => 'Entry deleted';

  @override
  String get photos => 'Documents';

  @override
  String get addPhoto => 'Add document';

  @override
  String get upTo4Photos => 'up to 4 documents (jpg, png, pdf), max 2 MB';

  @override
  String get removePhoto => 'Remove document';

  @override
  String get failedToPickImage => 'Failed to pick image';

  @override
  String get done => 'Done';

  @override
  String doneOn(String date) {
    return 'Done $date';
  }

  @override
  String dueLabel(String date) {
    return 'Due $date';
  }

  @override
  String get snooze => 'Snooze';

  @override
  String snoozeEntry(String name) {
    return 'Snooze $name';
  }

  @override
  String snoozeDays(int count, String label) {
    return '$count $label';
  }

  @override
  String get markAsDone => 'Mark as done';

  @override
  String get sharing => 'Sharing';

  @override
  String get couldNotLoadSharingInfo => 'Could not load sharing info';

  @override
  String get sessionExpired => 'Session expired. Please log in again.';

  @override
  String get shareLinkTitle => 'Share Link';

  @override
  String shareLinkDescription(String petName) {
    return 'Share this link so others can view $petName\'s profile:';
  }

  @override
  String get linkCopied => 'Link copied to clipboard';

  @override
  String get copy => 'Copy';

  @override
  String get sharePet => 'Share Pet';

  @override
  String get noOneHasAccess => 'No one else has access yet';

  @override
  String get manageAccess => 'Manage user access';

  @override
  String get removeAccess => 'Remove Access';

  @override
  String get guardian => 'Guardian';

  @override
  String get viewOnly => 'View Only';

  @override
  String roleLabel(String role) {
    return 'Role: $role';
  }

  @override
  String get acceptAndAdd => 'Accept & Add to My Pets';

  @override
  String get sharedBy => 'Shared by';

  @override
  String get shareLinkPending => 'New link pending';

  @override
  String sharingWithActive(String userName) {
    return 'Sharing with $userName active';
  }

  @override
  String get copyLinkAgain => 'Copy link';

  @override
  String get deleteLink => 'Delete link';

  @override
  String get deleteShareLinkConfirm =>
      'Delete this share link? Anyone with the link will no longer be able to use it.';

  @override
  String get stopFollowing => 'Stop following';

  @override
  String stopFollowingConfirm(String petName) {
    return 'Stop following $petName? The pet will be removed from your list.';
  }

  @override
  String sharedPetFollowerDescription(String petName) {
    return 'You are following $petName via a share link. You can stop following at any time.';
  }

  @override
  String fosterSharingDescription(String petName) {
    return 'While fostering $petName, you can share a view-only link with others. You cannot transfer ownership.';
  }

  @override
  String get healthIssues => 'Health Issues';

  @override
  String get addIssue => 'Add Issue';

  @override
  String get editIssue => 'Edit Issue';

  @override
  String get deleteIssue => 'Delete Issue';

  @override
  String get deleteIssueConfirm =>
      'Are you sure you want to delete this health issue?';

  @override
  String get issueTitle => 'Title *';

  @override
  String get issueTitleRequired => 'Title is required';

  @override
  String get issueDescription => 'Description';

  @override
  String get create => 'Create';

  @override
  String get update => 'Update';

  @override
  String nEvents(int count) {
    return '$count event(s)';
  }

  @override
  String get startDateOptional => 'Start Date';

  @override
  String get endDateOptional => 'End Date';

  @override
  String get linkedEvents => 'Linked Events';

  @override
  String get noLinkedEvents => 'No linked events';

  @override
  String get addPetTitle => 'Add Pet';

  @override
  String get editPetTitle => 'Edit Pet';

  @override
  String get petName => 'Name *';

  @override
  String get petNameRequired => 'Name is required';

  @override
  String get species => 'Species *';

  @override
  String get speciesRequired => 'Species is required';

  @override
  String get breed => 'Breed';

  @override
  String get gender => 'Gender';

  @override
  String get male => 'Male';

  @override
  String get female => 'Female';

  @override
  String get dateOfBirth => 'Date of Birth';

  @override
  String get weight => 'Weight';

  @override
  String get petBio => 'Bio';

  @override
  String get insurance => 'Insurance';

  @override
  String get savePet => 'Save Pet';

  @override
  String get deletePet => 'Delete Pet';

  @override
  String deletePetConfirm(String name) {
    return 'Are you sure you want to delete $name? This cannot be undone.';
  }

  @override
  String petDeleted(String name) {
    return '$name deleted';
  }

  @override
  String get neuteredSpayedDate => 'Neutered / Spayed Date';

  @override
  String get idMicrochip => 'ID / Microchip';

  @override
  String get speciesDog => 'Dog';

  @override
  String get speciesCat => 'Cat';

  @override
  String get speciesBird => 'Bird';

  @override
  String get speciesFish => 'Fish';

  @override
  String get speciesRabbit => 'Rabbit';

  @override
  String get speciesHamster => 'Hamster';

  @override
  String get speciesFerret => 'Ferret';

  @override
  String get speciesHorsePoney => 'Horse / Poney';

  @override
  String get speciesOther => 'Other';

  @override
  String get notificationSettings => 'Notification Settings';

  @override
  String get inAppNotifications => 'In-App Notifications';

  @override
  String get overdueAlerts => 'Overdue Alerts';

  @override
  String get dueSoonAlerts => 'Due Soon Alerts';

  @override
  String get completedAlerts => 'Completed Alerts';

  @override
  String get emailReminders => 'Email Reminders';

  @override
  String get emailNotifications => 'Email Notifications';

  @override
  String get reminderDaysBefore => 'Reminder Days Before';

  @override
  String get mutedPets => 'Muted Pets';

  @override
  String get saveSettings => 'Save Settings';

  @override
  String get settingsSaved => 'Settings saved';

  @override
  String get noNotifications => 'No notifications';

  @override
  String get markAllRead => 'Mark all as read';

  @override
  String get notificationSettingsTooltip => 'Notification settings';

  @override
  String get dueSoonAlertsLabel => 'Due Soon Alerts';

  @override
  String get generalLabel => 'General';

  @override
  String get addVet => 'Add Vet';

  @override
  String get editVet => 'Edit Vet';

  @override
  String get addNewVet => 'Add a new veterinarian';

  @override
  String get backToVets => 'Back to veterinarians';

  @override
  String get vetName => 'Name *';

  @override
  String get vetNameRequired => 'Name is required';

  @override
  String get phone => 'Phone';

  @override
  String get vetEmail => 'Email';

  @override
  String get website => 'Website';

  @override
  String get address => 'Address';

  @override
  String get vetNotes => 'Notes';

  @override
  String get deleteVet => 'Delete Vet';

  @override
  String deleteVetConfirm(String name) {
    return 'Are you sure you want to delete $name?';
  }

  @override
  String get noVetsYet => 'No veterinarians yet';

  @override
  String failedToLoadVets(String error) {
    return 'Failed to load vets: $error';
  }

  @override
  String failedToLoadVet(String error) {
    return 'Failed to load vet: $error';
  }

  @override
  String get vetOptions => 'Vet options';

  @override
  String get linkedPets => 'Linked Pets';

  @override
  String couldNotLoadPets(String error) {
    return 'Could not load pets: $error';
  }

  @override
  String get noPetsAddFirst => 'No pets yet. Add pets first to link them.';

  @override
  String get unlink => 'Unlink';

  @override
  String get link => 'Link';

  @override
  String get availablePets => 'Available pets:';

  @override
  String get subscriptionTitle => 'Subscription';

  @override
  String get welcomeUnlimited => 'Welcome to Agatha Track Unlimited!';

  @override
  String purchaseFailed(String error) {
    return 'Purchase failed: $error';
  }

  @override
  String get purchasesRestored => 'Purchases restored successfully';

  @override
  String couldNotRestore(String error) {
    return 'Could not restore purchases: $error';
  }

  @override
  String get restorePurchases => 'Restore Purchases';

  @override
  String get manageSubscription => 'Manage Subscription';

  @override
  String get subscribe => 'Subscribe';

  @override
  String get loadPlans => 'Load Plans';

  @override
  String get petReport => 'Pet Report';

  @override
  String get chooseSections => 'Choose which sections to include';

  @override
  String get petProfile => 'Pet Profile';

  @override
  String get basicInfoVet => 'Basic info, vet details';

  @override
  String get chartAndDataTable => 'Chart and data table';

  @override
  String get medicationsPreventivesVetVisits =>
      'Medications, preventives, vet visits';

  @override
  String get includeFullLog => 'Include full log for each event';

  @override
  String get ongoingConditions => 'Ongoing conditions and linked events';

  @override
  String get sharingSection => 'Sharing';

  @override
  String get accessListAndRoles => 'Access list and roles';

  @override
  String get downloadReport => 'Download Report';

  @override
  String get downloadPetReport => 'Download Pet Report';

  @override
  String get generating => 'Generating...';

  @override
  String get reportGenerated => 'Report downloaded';

  @override
  String reportFailed(String error) {
    return 'Report failed: $error';
  }

  @override
  String get passedAwayConfirmTitle => 'Mark as Passed Away';

  @override
  String passedAwayConfirmMessage(String name) {
    return 'Are you sure you want to mark $name as having crossed the rainbow bridge?';
  }

  @override
  String passedAwayCondolence(String name) {
    return 'We are so sorry for your loss. $name\'s profile will be kept as a loving memorial.';
  }

  @override
  String get confirm => 'Confirm';

  @override
  String get ok => 'OK';

  @override
  String get reminderSnooze =>
      'Reminder snoozed. We\'ll remind you again later.';

  @override
  String get dontWantToNeuter => 'I don\'t want to neuter';

  @override
  String get dontWantToChip => 'I don\'t want to chip / identify my pet';

  @override
  String get chipReminderDog =>
      'Microchipping is recommended for dogs. It\'s a simple procedure that helps reunite you if your pet gets lost.';

  @override
  String get chipReminderCat =>
      'Microchipping is recommended for cats. It helps identify your cat and reunite you if they wander off.';

  @override
  String get chipReminderFerret =>
      'Microchipping is recommended for ferrets. It helps identify your pet if they escape.';

  @override
  String get chipReminderRabbit =>
      'Microchipping is recommended for rabbits. It provides a permanent form of identification.';

  @override
  String get chipReminderHorse =>
      'A passport is recommended for horses and ponies. It\'s a legal requirement in many countries.';

  @override
  String get chipReminderBird =>
      'A leg ring is recommended for birds. It helps identify your bird if they fly away.';

  @override
  String get chipReminderFish =>
      'A tank label is recommended for fish tanks. It helps track species and care requirements.';

  @override
  String get chipReminderHamster =>
      'A photo ID record is recommended for hamsters. Keep a photo for identification purposes.';

  @override
  String get chipReminderDefault =>
      'An identification method is recommended for your pet.';

  @override
  String get neuterReminderTitle => 'Neutering Reminder';

  @override
  String get chipReminderTitle => 'Identification Reminder';

  @override
  String get pdfEventsChecklist => 'Events Checklist';

  @override
  String get pdfAllEvents => 'All Events';

  @override
  String pdfGroupedBy(String filter, String group) {
    return '$filter  •  Grouped $group';
  }

  @override
  String get pdfNoEventsToDisplay => 'No events to display.';

  @override
  String pdfGeneratedBy(String date) {
    return 'Generated $date by Agatha Track';
  }

  @override
  String pdfPageOf(int current, int total) {
    return 'Page $current of $total';
  }

  @override
  String get pdfPetLabel => 'Pet';

  @override
  String get pdfDueLabel => 'Due';

  @override
  String get pdfFreqLabel => 'Freq';

  @override
  String get pdfNotesLabel => 'Notes';

  @override
  String get pdfIssueLabel => 'Issue';

  @override
  String get pdfOnce => 'Once';

  @override
  String get pdfDone => 'Done';

  @override
  String get pdfReportTitle => 'Pet Health Report';

  @override
  String get pdfAgathaCheck => 'AGATHA TRACK';

  @override
  String get pdfPetProfileSection => 'Pet Profile';

  @override
  String get pdfWeightTrackingSection => 'Weight Tracking';

  @override
  String get pdfHealthEventsSection => 'Health Events';

  @override
  String get pdfHealthIssuesSection => 'Health Issues';

  @override
  String get pdfSharingSection => 'Sharing';

  @override
  String get pdfFosterHistorySection => 'Foster History';

  @override
  String get pdfNoFosterHistory => 'No foster placements recorded yet.';

  @override
  String get pdfFosterParent => 'Foster parent';

  @override
  String get pdfPlacementStatus => 'Status';

  @override
  String get pdfPlacementAdopted => 'Adopted';

  @override
  String get fosterHistory => 'Foster history';

  @override
  String get pdfNoWeightData => 'No weight data recorded yet.';

  @override
  String get pdfNoHealthEvents => 'No health events recorded yet.';

  @override
  String get pdfNoHealthIssues => 'No health issues recorded yet.';

  @override
  String get pdfCurrentRecurring => 'Current & Recurring Events';

  @override
  String pdfEventsFromTo(String from, String to) {
    return 'Events from $from to $to';
  }

  @override
  String get pdfNoEventsInPeriod => 'No events in this period.';

  @override
  String get pdfAdminLog => 'Administration Log';

  @override
  String get pdfName => 'Name';

  @override
  String get pdfSpecies => 'Species';

  @override
  String get pdfBreed => 'Breed';

  @override
  String get pdfGender => 'Gender';

  @override
  String get pdfAge => 'Age';

  @override
  String get pdfDateOfBirth => 'Date of Birth';

  @override
  String get pdfCurrentWeight => 'Current Weight';

  @override
  String get pdfBio => 'Bio';

  @override
  String get pdfNeuteredSpayed => 'Neutered / Spayed';

  @override
  String get pdfIdMicrochip => 'ID / Microchip';

  @override
  String get pdfInsurance => 'Insurance Details';

  @override
  String get pdfVet => 'Vet';

  @override
  String get pdfDate => 'Date';

  @override
  String get pdfWeight => 'Weight';

  @override
  String get pdfNotes => 'Notes';

  @override
  String get pdfType => 'Type';

  @override
  String get pdfFrequency => 'Frequency';

  @override
  String get pdfNextDue => 'Next Due';

  @override
  String get pdfDosage => 'Dosage';

  @override
  String get pdfStart => 'Start';

  @override
  String get pdfDue => 'Due';

  @override
  String get pdfCompleted => 'Completed';

  @override
  String get pdfNotShared => 'This pet is not shared with anyone.';

  @override
  String get pdfRole => 'Role';

  @override
  String get pdfSince => 'Since';

  @override
  String get pdfGuardian => 'Guardian';

  @override
  String get pdfShared => 'Shared';

  @override
  String pdfUserNumber(String id) {
    return 'User #$id';
  }

  @override
  String pdfNEvent(int count) {
    return '$count event';
  }

  @override
  String pdfNEvents(int count) {
    return '$count events';
  }

  @override
  String pdfFrom(String date) {
    return 'From $date';
  }

  @override
  String pdfUntil(String date) {
    return 'Until $date';
  }

  @override
  String get pdfLinkedEvents => 'Linked Events';

  @override
  String get pdfCustom => 'Custom';

  @override
  String pdfEvery(String period) {
    return 'Every $period';
  }

  @override
  String pdfEveryN(int n, String periods) {
    return 'Every $n $periods';
  }

  @override
  String get pdfFamilyEventsSection => 'Family Events';

  @override
  String get pdfNoFamilyEvents => 'No family events recorded for this pet.';

  @override
  String get pdfAssignedTo => 'Assigned To';

  @override
  String get pdfFromDate => 'From';

  @override
  String get pdfToDate => 'To';

  @override
  String get pdfOngoing => 'Ongoing';

  @override
  String get pdfNotificationsSection => 'Notifications';

  @override
  String get pdfNoNotifications => 'No recent notifications for this pet.';

  @override
  String get pdfNotificationType => 'Type';

  @override
  String get pdfNotificationMessage => 'Message';

  @override
  String get familyEventsSection => 'Family Events';

  @override
  String get familyEventsDesc => 'Care assignments and foster stays';

  @override
  String get notificationsSection => 'Notifications';

  @override
  String get notificationsDesc => 'Recent alerts and reminders';

  @override
  String get myOrganizations => 'My Organizations';

  @override
  String get discoverOrganizations => 'Discover Organisations';

  @override
  String get orgDiscoveryEmpty => 'No organisations to discover yet';

  @override
  String get orgDiscoveryLoadError =>
      'Could not load discoverable organisations';

  @override
  String orgDiscoveryLocation(String town, String administrativeArea) {
    return '$town, $administrativeArea';
  }

  @override
  String get organizations => 'Organizations';

  @override
  String get createOrganization => 'Create Organization';

  @override
  String get editOrganization => 'Edit Organization';

  @override
  String get deleteOrganization => 'Delete Organization';

  @override
  String get organizationName => 'Organization Name';

  @override
  String get organizationType => 'Type';

  @override
  String get orgTypeProfessional => 'Professional';

  @override
  String get orgTypeCharity => 'Charity';

  @override
  String get orgEmail => 'Email';

  @override
  String get orgPhone => 'Phone';

  @override
  String get orgAddress => 'Address';

  @override
  String get orgWebsite => 'Website';

  @override
  String get orgBio => 'Bio';

  @override
  String get orgMembers => 'Members';

  @override
  String get orgPets => 'Pets';

  @override
  String get orgPetsTabNeedAttention => 'Need attention';

  @override
  String get orgPetsTabInFoster => 'In foster';

  @override
  String get orgPetsTabAdopted => 'Adopted';

  @override
  String get orgPetsTabAll => 'All';

  @override
  String get orgPetsFiltersLabel => 'Filters';

  @override
  String get orgPetsFilterName => 'Name';

  @override
  String get orgPetsFilterFosteredBy => 'Fostered by';

  @override
  String get orgPetsFilterShadow => 'Shadow';

  @override
  String get orgPetsFilterRainbowBridge => 'Rainbow bridge';

  @override
  String get orgPetsFilterNameHint => 'Search by pet name';

  @override
  String get orgPetsFilterFosteredByHint => 'Search by foster parent';

  @override
  String get orgPetsNeedAttentionNotInFoster => 'Not in foster';

  @override
  String get orgPetsNeedAttentionFosterFinishingSoon => 'Foster finishing soon';

  @override
  String get orgPetsNeedAttentionTooltip =>
      'Pets that are not in foster, or whose foster placement ends within 10 days with no next session or adoption planned.';

  @override
  String get orgPetsEmptyTab => 'No pets match this view';

  @override
  String get orgArchived => 'Archived Pets';

  @override
  String get orgNoOrganizations => 'No organizations yet';

  @override
  String get orgCreateFirst => 'Create your first organization to get started';

  @override
  String get createOrJoinOrganization => 'Create an organization';

  @override
  String get orgMembershipByEmailInvite =>
      'To join an organization, ask an admin to invite you by email.';

  @override
  String get orgInviteEmailRequired => 'Email is required';

  @override
  String get orgInviteEmailInvalid => 'Enter a valid email address';

  @override
  String get joinOrganization => 'Join Organization';

  @override
  String get enterInviteCode => 'Enter the invite code you received';

  @override
  String get inviteCode => 'Invite code';

  @override
  String get joinSuccess => 'Successfully joined the organization';

  @override
  String get join => 'Join';

  @override
  String get orgSuperUser => 'Super admin';

  @override
  String get orgSuperAdmin => 'Super admin';

  @override
  String get orgMember => 'Admin';

  @override
  String get orgAdmin => 'Admin';

  @override
  String get orgFoster => 'Foster';

  @override
  String get orgAssociate => 'Associate';

  @override
  String get orgSelectNewRole => 'Select new role';

  @override
  String get orgInviteMember => 'Invite Member';

  @override
  String get orgInviteLinkCopied => 'Invite link copied to clipboard';

  @override
  String get orgInviteExpiry => 'This invite link expires in 7 days';

  @override
  String get orgJoinSuccess => 'Successfully joined organization';

  @override
  String get orgLeave => 'Leave Organization';

  @override
  String get orgLeaveConfirm =>
      'Are you sure you want to leave this organization?';

  @override
  String get orgRemoveMember => 'Remove Member';

  @override
  String get orgRemoveMemberConfirm =>
      'Are you sure you want to remove this member?';

  @override
  String get orgChangeRole => 'Change Role';

  @override
  String get orgPromoteToSuperUser => 'Promote to Super User';

  @override
  String get orgDemoteToMember => 'Demote to Member';

  @override
  String get orgDeleteConfirm =>
      'Are you sure you want to delete this organization? This action cannot be undone.';

  @override
  String get orgDeleteRequireNoPets =>
      'Transfer or remove all pets before deleting';

  @override
  String get orgNoPets => 'No pets in this organization';

  @override
  String get orgNoMembers => 'No members';

  @override
  String get orgNoArchived => 'No archived records';

  @override
  String get orgAddPet => 'Add Pet';

  @override
  String get transferPet => 'Transfer Pet';

  @override
  String get transferToUser => 'Transfer to User';

  @override
  String get transferToOrganization => 'Transfer to Organization';

  @override
  String get transferType => 'Transfer Type';

  @override
  String get transferTypeAdoption => 'Adoption';

  @override
  String get transferTypeTransfer => 'Transfer';

  @override
  String get transferTypeRelease => 'Release';

  @override
  String get transferTypeOther => 'Other';

  @override
  String get recipientEmail => 'Recipient Email';

  @override
  String get transferNotes => 'Notes (optional)';

  @override
  String get confirmTransfer => 'Confirm Transfer';

  @override
  String get transferConfirmTitle => 'Confirm Transfer';

  @override
  String transferConfirmMessage(String petName) {
    return 'Are you sure you want to transfer $petName? This action cannot be undone.';
  }

  @override
  String get transferSuccess => 'Custody transfer request sent';

  @override
  String get transferRequestSent =>
      'Custody transfer request sent. The recipient must accept to complete the transfer.';

  @override
  String get pendingCustodyTransfers => 'Pending custody transfers';

  @override
  String get acceptCustodyTransfer => 'Accept transfer';

  @override
  String get custodyTransferAccepted => 'Custody transfer accepted';

  @override
  String get custodyTransferKindIndividual => 'Adoption to individual';

  @override
  String get custodyTransferKindOrgToOrg => 'Transfer to organisation';

  @override
  String get custodyTransferKindReturn => 'Return to organisation';

  @override
  String get orgConnections => 'Connected organisations';

  @override
  String get orgConnectionsEmpty => 'No connected organisations yet';

  @override
  String get createConnectionRequest => 'Connect to organisation';

  @override
  String get targetOrgId => 'Target organisation ID';

  @override
  String get connectionTokenCreated =>
      'Connection link created. Share this token with the other organisation\'s admin:';

  @override
  String get acceptConnection => 'Accept connection';

  @override
  String get connectionAccepted => 'Organisations are now connected';

  @override
  String get disconnectOrganisation => 'Disconnect';

  @override
  String disconnectOrganisationConfirm(String orgName) {
    return 'Disconnect from $orgName? Pending transfers between you will be cancelled.';
  }

  @override
  String get transferToOrganisation => 'Transfer to organisation';

  @override
  String get selectConnectedOrg => 'Select connected organisation';

  @override
  String get requestReturnToOrg => 'Return to organisation';

  @override
  String get returnRequestSent => 'Return request sent';

  @override
  String get homeHiddenPets => 'Hidden from home list';

  @override
  String get hideFromHomeList => 'Hide from home list';

  @override
  String hideFromHomeListConfirm(String petName) {
    return 'Hide $petName from your home pet list? The pet stays visible in the organisation section.';
  }

  @override
  String get hideFosteredPet => 'Hide fostered pet';

  @override
  String hideFosteredPetConfirm(String petName) {
    return 'Hide $petName from your list and health dashboard?';
  }

  @override
  String get frozenShadow => 'Frozen shadow';

  @override
  String get shadowSnapshotReadOnly =>
      'Point-in-time snapshot — does not sync with the live pet.';

  @override
  String shadowCapturedAt(String date) {
    return 'Captured $date';
  }

  @override
  String get shadowHealthEntries => 'Health entries in snapshot';

  @override
  String get shadowWeightEntries => 'Weight entries in snapshot';

  @override
  String get revokeConnectionRequest => 'Revoke request';

  @override
  String get connectionRequests => 'Connection requests';

  @override
  String get noConnectionRequests => 'No connection requests';

  @override
  String get orgToOrgTransferNotes => 'Transfer notes (optional)';

  @override
  String get transferOwnership => 'Transfer ownership';

  @override
  String get transferNameConfirmationHint => 'Type the pet\'s name to confirm';

  @override
  String get transferNameMismatch => 'Pet name does not match';

  @override
  String get transferOwnershipDescription =>
      'Transfer full ownership to another user. You will keep shared access unless they remove you.';

  @override
  String get archivedPets => 'Archived Pets';

  @override
  String archivedOn(String date) {
    return 'Archived on $date';
  }

  @override
  String get noArchivedPets => 'No archived pets';

  @override
  String get orgNameRequired => 'Organization name is required';

  @override
  String get orgCreated => 'Organization created';

  @override
  String get orgUpdated => 'Organization updated';

  @override
  String get orgDeleted => 'Organization deleted';

  @override
  String memberCount(int count) {
    return '$count members';
  }

  @override
  String orgMemberCountSummary(int registered, int external) {
    return '$registered registered members + $external external';
  }

  @override
  String orgMemberCountRegisteredOnly(int registered) {
    return '$registered registered members';
  }

  @override
  String orgEmergencyContactTitle(String orgName) {
    return 'Emergency contact details for $orgName';
  }

  @override
  String get orgPrimaryContact => 'Primary contact';

  @override
  String get orgSetPrimaryContact => 'Set as primary contact';

  @override
  String get orgPrimaryContactBadge => 'Primary contact';

  @override
  String get orgUploadPicture => 'Upload picture';

  @override
  String get orgUploadLogo => 'Upload logo';

  @override
  String get orgPicture => 'Organisation picture';

  @override
  String get orgLogo => 'Organisation logo';

  @override
  String petCount(int count) {
    return '$count pets';
  }

  @override
  String get remindBefore => 'Remind me';

  @override
  String get daysBefore => 'day(s) before';

  @override
  String get undoComplete => 'Undo\nComplete';

  @override
  String undoCompleteDone(String name) {
    return '$name marked as not completed';
  }

  @override
  String get addUser => 'Add a User';

  @override
  String get inviteByEmail => 'Invite by Email';

  @override
  String get sendInvite => 'Send Invite';

  @override
  String get selectRole => 'Select Role';

  @override
  String get inviteSent => 'Invitation sent successfully';

  @override
  String get pendingInvites => 'Pending Invitations';

  @override
  String inviteToJoinOrg(String orgName) {
    return 'You\'ve been invited to join $orgName';
  }

  @override
  String inviteAsRole(String role) {
    return 'as $role';
  }

  @override
  String get acceptInvite => 'Accept';

  @override
  String get declineInvite => 'Decline';

  @override
  String get userNotFound => 'No user found with this email';

  @override
  String get inviteAccepted => 'Invitation accepted';

  @override
  String get inviteDeclined => 'Invitation declined';

  @override
  String get alreadyMember => 'This user is already a member';

  @override
  String get enterEmail => 'Enter the user\'s email address';

  @override
  String invitedBy(String name) {
    return 'Invited by $name';
  }

  @override
  String get people => 'People';

  @override
  String get orgPeopleDescription =>
      'Everyone in your organisation. The green disk shows how many pets each person is currently fostering.';

  @override
  String get addExternalFoster => 'Add foster manually';

  @override
  String get fosterContactAddress => 'Foster contact address';

  @override
  String get editFosterContact => 'Edit foster contact';

  @override
  String get fosterContactSaved => 'Foster contact details saved';

  @override
  String get currentlyFostering => 'Currently fostering';

  @override
  String get previouslyFostered => 'Previously fostered';

  @override
  String get noPreviousFosterPlacements => 'No previous foster placements';

  @override
  String get placementOutcomeAdopted => 'Adopted';

  @override
  String get placementOutcomeNotInFoster => 'Not in foster';

  @override
  String get placementOutcomeElsewhere => 'In foster elsewhere';

  @override
  String get placementOutcomePassedAway => 'Passed away';

  @override
  String get lawfulBasisConfirm =>
      'I confirm I have a lawful basis to store this person\'s contact details for shelter foster coordination. They will receive an email explaining retention and how to opt out of outreach.';

  @override
  String get lawfulBasisConfirmRequired =>
      'Please confirm you have a lawful basis to add this contact.';

  @override
  String get emailRequiredForExternalFoster =>
      'Email is required so we can send a privacy notice';

  @override
  String get externalFosterNoticeSent =>
      'External foster added and privacy notice sent';

  @override
  String get orgNotesOperationalOnly =>
      'Operational notes only — avoid sensitive personal information';

  @override
  String get fosterParents => 'Foster parents';

  @override
  String get fosterParentsDescription =>
      'Members and contacts who can foster organisation pets. Pet counts reflect active placements.';

  @override
  String get manageFostersTitle => 'Manage fosters';

  @override
  String get manageFostersDescription =>
      'Operational view of foster families — invite, review, and track who is fostering now.';

  @override
  String get manageFostersTabNew => 'New';

  @override
  String get manageFostersTabFostering => 'Fostering';

  @override
  String get manageFostersTabRecentlyFostered => 'Recently fostered';

  @override
  String get manageFostersTabInactive => 'Inactive';

  @override
  String get manageFostersTabAll => 'All';

  @override
  String get manageFostersStatusFostering => 'Fostering';

  @override
  String get manageFostersEmptyTab => 'No fosters match this tab';

  @override
  String get manageFostersRecentlyFosteredPlaceholder =>
      'Recently ended foster placements will appear here once session history is available.';

  @override
  String get manageFostersApprovalFiltersLabel => 'Approval filters';

  @override
  String get manageFostersFilterUnderReview => 'Under review';

  @override
  String get manageFostersFilterApproved => 'Approved';

  @override
  String get manageFostersFilterArchived => 'Archived';

  @override
  String get manageFostersApprovalApprove => 'Approve';

  @override
  String get manageFostersApprovalDecline => 'Decline';

  @override
  String get manageFostersApprovalArchive => 'Archive';

  @override
  String get manageFostersApprovalStateUnderReview => 'Under review';

  @override
  String get manageFostersApprovalStateApproved => 'Approved';

  @override
  String get manageFostersApprovalStateDeclined => 'Declined';

  @override
  String get manageFostersApprovalStateArchived => 'Archived';

  @override
  String get manageFostersMergeIntoAccount => 'Link to registered account';

  @override
  String get manageFostersMergeSelectAccount => 'Select registered account';

  @override
  String get manageFostersMergeConfirmTitle => 'Link foster record?';

  @override
  String manageFostersMergeConfirmBody(
    String manualName,
    String registeredName,
  ) {
    return 'Link $manualName to the registered account for $registeredName? Shelter notes stay on this relationship.';
  }

  @override
  String get manageFostersMergeConfirmAction => 'Link account';

  @override
  String get manageFostersMergeSuccess =>
      'Foster record linked to registered account';

  @override
  String get manageFostersMergeNoMatch =>
      'No registered account matches this email';

  @override
  String get manageFostersLinkedAccount => 'Linked account';

  @override
  String get manageFostersOutreachOptOut => 'Outreach opt-out';

  @override
  String get manageFostersRecordOutreachOptOut => 'Record outreach opt-out';

  @override
  String get manageFostersClearOutreachOptOut => 'Clear outreach opt-out';

  @override
  String get manageFostersRetentionShelterFosterRelationship =>
      'Shelter foster relationship';

  @override
  String get manageFostersRetentionDeclinedArchived => 'Declined / archived';

  @override
  String get manageFostersRetentionManualContact => 'Manual contact';

  @override
  String get fosterSelfPrefsTitle => 'Your visibility preferences';

  @override
  String get fosterSelfPrefsYourCard => 'Your card';

  @override
  String get fosterSelfPrefsVisibleToLabel => 'Who can see your foster card';

  @override
  String get fosterSelfPrefsVisibleToOtherFosters => 'Other fosters';

  @override
  String get fosterSelfPrefsVisibleToAdmins => 'Admins only';

  @override
  String get fosterSelfPrefsVisibleToBoth => 'Fosters and admins';

  @override
  String get fosterSelfPrefsVisibleToNobody => 'Nobody';

  @override
  String get fosterSelfPrefsAddressVisibilityLabel => 'Address visibility';

  @override
  String get fosterSelfPrefsAddressFull => 'Full address';

  @override
  String get fosterSelfPrefsAddressTown => 'Town only';

  @override
  String get fosterSelfPrefsAddressHidden => 'Hidden';

  @override
  String get fosterSelfPrefsContactVisibilityLabel =>
      'Contact details visibility';

  @override
  String get fosterSelfPrefsContactEmail => 'Email only';

  @override
  String get fosterSelfPrefsContactPhone => 'Phone only';

  @override
  String get fosterSelfPrefsContactNeither => 'Neither';

  @override
  String get fosterSelfPrefsContactBoth => 'Email and phone';

  @override
  String get fosterSelfPrefsMessageChannelLabel => 'Message notifications';

  @override
  String get fosterWithdrawAgreementTitle => 'Withdraw agreement';

  @override
  String get fosterWithdrawAgreementWarning =>
      'Withdrawing your agreement to follow organisation rules will flag your active fostering sessions for admin review and notify all organisation admins. This action is difficult to undo.';

  @override
  String get fosterWithdrawAgreementConfirmLabel => 'Type withdraw to confirm';

  @override
  String get fosterWithdrawAgreementConfirmHint => 'withdraw';

  @override
  String get fosterWithdrawAgreementSubmit => 'Confirm withdrawal';

  @override
  String get fosterWithdrawAgreementSuccess =>
      'Agreement withdrawn. Admins have been notified.';

  @override
  String get fosterRulesAgreementLabel =>
      'I agree to follow organisation rules and terms';

  @override
  String get fosterRequestsTitle => 'Foster requests';

  @override
  String get fosterRequestsDescription =>
      'Send structured outreach to approved foster families and track their responses.';

  @override
  String get fosterRequestsEmpty =>
      'No foster requests yet. Send one when you need help placing pets.';

  @override
  String get fosterRequestSendNew => 'Send foster request';

  @override
  String get fosterRequestSendDescription =>
      'Choose pets that need placement and foster families to contact. You can save a draft or send immediately.';

  @override
  String get fosterRequestMessageLabel => 'Message';

  @override
  String get fosterRequestMessageHint =>
      'Describe what help you need and any timing details';

  @override
  String get fosterRequestMessageRequired => 'Message is required';

  @override
  String get fosterRequestSelectPets => 'Pets needing foster care';

  @override
  String get fosterRequestSelectFosters => 'Foster families to contact';

  @override
  String get fosterRequestNoPets => 'No active pets available for this request';

  @override
  String get fosterRequestNoEligibleFosters =>
      'No approved foster families without outreach opt-out are available';

  @override
  String get fosterRequestSelectionRequired =>
      'Select at least one pet and one foster family';

  @override
  String get fosterRequestSaveDraft => 'Save draft';

  @override
  String get fosterRequestSendNow => 'Send now';

  @override
  String get fosterRequestDraftSaved => 'Foster request saved as draft';

  @override
  String get fosterRequestSendSuccess => 'Foster request sent';

  @override
  String get fosterRequestStatusDraft => 'Draft';

  @override
  String get fosterRequestStatusSent => 'Sent';

  @override
  String get fosterRequestStatusCancelled => 'Cancelled';

  @override
  String fosterRequestPetsLabel(String names) {
    return 'Pets: $names';
  }

  @override
  String fosterRequestTargetsSummary(
    int targetCount,
    int canHelp,
    int cannotHelp,
    int pending,
  ) {
    return '$targetCount targets · $canHelp can help · $cannotHelp cannot help · $pending pending';
  }

  @override
  String get fosterRequestDetailTitle => 'Foster request';

  @override
  String get fosterRequestPetsSection => 'Pets';

  @override
  String get fosterRequestTargetsSection => 'Foster families contacted';

  @override
  String get fosterRequestResponsesSection => 'Responses';

  @override
  String get fosterRequestNoResponses => 'No responses yet';

  @override
  String get fosterRequestResponseCanHelp => 'Can help';

  @override
  String get fosterRequestResponseCannotHelp => 'Cannot help';

  @override
  String get fosterRequestResponsePending => 'Pending';

  @override
  String fosterRequestEarliestAvailability(String date) {
    return 'Available from $date';
  }

  @override
  String get fosterRequestRespondTitle => 'Respond to foster request';

  @override
  String get fosterRequestRespondDescription =>
      'Let the shelter know whether you can help and when you could start.';

  @override
  String get fosterRequestEarliestAvailabilityLabel => 'Earliest availability';

  @override
  String get fosterRequestSelectDate => 'Select a date';

  @override
  String get fosterRequestAvailabilityRequired =>
      'Earliest availability is required when you can help';

  @override
  String get fosterRequestRespondMessageLabel => 'Message (optional)';

  @override
  String get fosterRequestRespondMessageHint =>
      'Share timing, capacity, or questions for the shelter';

  @override
  String get fosterRequestRespondSubmit => 'Submit response';

  @override
  String get fosterRequestRespondSuccess => 'Response submitted';

  @override
  String get noFosterParents => 'No foster parents yet';

  @override
  String get addFosterParent => 'Add foster parent';

  @override
  String get addFosterParentDescription =>
      'Add someone who fosters without an app account. You can assign pets to them in a later step.';

  @override
  String get fosterParentDisplayName => 'Display name';

  @override
  String get fosterParentNoAccount => 'No account';

  @override
  String get fosterParentCreated => 'Foster parent added';

  @override
  String get fosterParentDeleted => 'Foster parent removed';

  @override
  String get deleteFosterParent => 'Remove foster parent';

  @override
  String deleteFosterParentConfirm(String name) {
    return 'Remove $name from the foster parent directory?';
  }

  @override
  String get fosterPlacement => 'Foster placement';

  @override
  String get fosterPlacementNotInFoster =>
      'This pet is not currently in foster care.';

  @override
  String get fosterPlacementNotInFosterShort => 'Not in foster';

  @override
  String get startFosterPlacement => 'Start foster placement';

  @override
  String startFosterPlacementDescription(String petName) {
    return 'Invite a foster parent to care for $petName. They must accept before the placement begins.';
  }

  @override
  String get fosterPlacementStarted => 'Foster placement request sent';

  @override
  String get endFosterPlacement => 'End foster period';

  @override
  String endFosterPlacementConfirm(String petName) {
    return 'End the foster period for $petName? The pet returns to organisation custody.';
  }

  @override
  String get fosterPlacementEnded => 'Foster period ended';

  @override
  String get fosterPlacementPending => 'Pending acceptance';

  @override
  String get fosterPlacementInProgress => 'In foster care';

  @override
  String fosterPlacementStatus(String status) {
    return 'Status: $status';
  }

  @override
  String fosterPlacementAssignedTo(String name) {
    return 'Foster parent: $name';
  }

  @override
  String fosterPlacementStartDate(String date) {
    return 'Start date: $date';
  }

  @override
  String get noFosterParentsWithAccounts =>
      'Add a foster parent with an app account first (invite by email).';

  @override
  String get pendingFosterPlacements => 'Pending foster placements';

  @override
  String fosterPlacementInviteFrom(String orgName) {
    return 'From $orgName';
  }

  @override
  String get fosterPlacementAccepted => 'Foster placement accepted';

  @override
  String get fosterPlacementDeclined => 'Foster placement declined';

  @override
  String get fosteringSessionDetailTitle => 'Fostering session';

  @override
  String get fosteringSessionManage => 'Manage fostering session';

  @override
  String get fosteringSessionStatusPendingAcceptance => 'Pending acceptance';

  @override
  String get fosteringSessionStatusPreparation => 'Preparation';

  @override
  String get fosteringSessionStatusReadyToStart => 'Ready to start';

  @override
  String get fosteringSessionStatusActive => 'Active';

  @override
  String get fosteringSessionStatusEndPending => 'End pending confirmation';

  @override
  String get fosteringSessionStatusAdoptionInProgress => 'Adoption in progress';

  @override
  String get fosteringSessionStatusReturned => 'Returned to shelter';

  @override
  String get fosteringSessionStatusTransferred => 'Transferred';

  @override
  String get fosteringSessionStatusConvertedToAdoption =>
      'Converted to adoption';

  @override
  String get fosteringSessionStatusCancelled => 'Cancelled';

  @override
  String get fosteringSessionPreparationTitle => 'Preparation checklist';

  @override
  String get fosteringSessionPreparationPlaceholder =>
      'Track shelter preparation steps before handover. Full checklist tracking arrives in a later release.';

  @override
  String get fosteringSessionChecklistDescription =>
      'Track foster readiness items from your organisation templates.';

  @override
  String get fosteringSessionChecklistEmpty =>
      'No checklist items configured yet.';

  @override
  String get fosteringSessionChecklistRequired => 'Required';

  @override
  String get fosteringSessionRegisterExport => 'View register export';

  @override
  String get fosteringSessionRegisterExportTitle => 'Foster register export';

  @override
  String get fosteringSessionExpediteAdoption =>
      'Complete visit & start adoption today';

  @override
  String get fosteringSessionExpediteAdoptionSuccess =>
      'Visit completed and adoption journey started';

  @override
  String get fosteringSessionStartAdoptionSuccess => 'Adoption journey started';

  @override
  String fosteringSessionVisitPathBlocked(String reason) {
    return 'Adoption cannot start yet: $reason';
  }

  @override
  String get fosteringSessionChecklistSupplies =>
      'Confirm supplies and equipment are ready';

  @override
  String get fosteringSessionChecklistMedical =>
      'Review medical records and medications';

  @override
  String get fosteringSessionChecklistTransport =>
      'Arrange transport to the foster home';

  @override
  String get fosteringSessionChecklistHandover =>
      'Schedule handover with the foster family';

  @override
  String get fosteringSessionDualStartTitle => 'Dual-start confirmation';

  @override
  String get fosteringSessionShelterStartLabel => 'Shelter confirms handover';

  @override
  String get fosteringSessionFosterStartLabel => 'Foster confirms pickup';

  @override
  String get fosteringSessionAwaitingConfirmation => 'Awaiting confirmation';

  @override
  String fosteringSessionConfirmedAt(String timestamp) {
    return 'Confirmed $timestamp';
  }

  @override
  String get fosteringSessionStartPreparation => 'Start preparation';

  @override
  String get fosteringSessionMarkReady => 'Mark ready to start';

  @override
  String get fosteringSessionConfirmShelterStart => 'Confirm shelter handover';

  @override
  String get fosteringSessionConfirmFosterStart => 'Confirm foster pickup';

  @override
  String get fosteringSessionRequestEnd => 'Request end of session';

  @override
  String get fosteringSessionEndReturned => 'Confirm return to shelter';

  @override
  String get fosteringSessionEndCancelled => 'Cancel session';

  @override
  String get fosteringSessionTransitionSuccess => 'Session updated';

  @override
  String get fosteringSessionShelterStartSuccess =>
      'Shelter handover confirmed';

  @override
  String get fosteringSessionFosterStartSuccess => 'Foster pickup confirmed';

  @override
  String get fosteringSessionRequestEndSuccess => 'End confirmation requested';

  @override
  String get fosteringSessionEndSuccess => 'Fostering session ended';

  @override
  String get fosteringSessionEndPendingDescription =>
      'The foster period is ending. Confirm how the pet returns to shelter custody.';

  @override
  String get fosteringSessionEndConfirmTitle => 'End fostering session?';

  @override
  String get fosteringSessionEndConfirmReturned =>
      'Confirm the pet has returned to shelter custody and close this session.';

  @override
  String get fosteringSessionEndConfirmCancelled =>
      'Cancel this fostering session without marking a return handover.';

  @override
  String get startAdoption => 'Start adoption';

  @override
  String startAdoptionDescription(String petName) {
    return 'Begin the adoption process for $petName. You can add optional pre-adoption conditions (e.g. neutering) before the foster parent confirms.';
  }

  @override
  String get adoptionConditions => 'Pre-adoption conditions';

  @override
  String get adoptionConditionsHint =>
      'Optional — e.g. must be neutered before adoption';

  @override
  String get adoptionStarted => 'Adoption process started';

  @override
  String get markAdoptionConditionsMet => 'Mark conditions met';

  @override
  String get adoptionConditionsMet => 'Pre-adoption conditions marked complete';

  @override
  String get waitingAdoptionConfirmation => 'Awaiting foster confirmation';

  @override
  String get pendingAdoptionConditions => 'Pending pre-adoption conditions';

  @override
  String get cancelAdoption => 'Cancel adoption';

  @override
  String cancelAdoptionConfirm(String petName) {
    return 'Cancel the adoption process for $petName? The pet returns to organisation custody.';
  }

  @override
  String get adoptionCancelled => 'Adoption cancelled';

  @override
  String get directAdopt => 'Direct adopt';

  @override
  String directAdoptDescription(String petName) {
    return 'Skip the foster period and invite $petName\'s new owner to confirm adoption directly.';
  }

  @override
  String get pendingAdoptionConfirmations => 'Pending adoptions';

  @override
  String get confirmAdoption => 'Confirm adoption';

  @override
  String confirmAdoptionDescription(String petName) {
    return 'Confirm that you are adopting $petName. Ownership will transfer to you.';
  }

  @override
  String get adoptionConfirmed => 'Adoption complete — you are now the owner';

  @override
  String assignedPets(int count) {
    return '$count pets assigned';
  }

  @override
  String get familyEvents => 'Family Events';

  @override
  String get noFamilyEvents => 'No family events yet';

  @override
  String get addFamilyEvent => 'Add Family Event';

  @override
  String get editFamilyEvent => 'Edit Family Event';

  @override
  String get deleteFamilyEventConfirm =>
      'Are you sure you want to delete this family event?';

  @override
  String get assignedToMember => 'Assigned to';

  @override
  String get unassigned => 'Unassigned';

  @override
  String get fromDateLabel => 'From date';

  @override
  String get toDateLabel => 'To date';

  @override
  String get optional => 'optional';

  @override
  String get assignTo => 'Assign to';

  @override
  String get assignToHint => 'Optionally assign a member to this pet';

  @override
  String get assignedMember => 'Assigned member';

  @override
  String get notAssigned => 'Not assigned';

  @override
  String get autoAssignedToYou =>
      'You will be automatically assigned to this pet';

  @override
  String get notSet => 'Not set';

  @override
  String get petOwnership => 'Pet Ownership';

  @override
  String get myPet => 'My Pet';

  @override
  String get orgPet => 'Organisation Pet';

  @override
  String get petTimelineTitle => 'Timeline';

  @override
  String get petTimelineNoData => 'No data';

  @override
  String get petTimelineFillAction => 'Fill';

  @override
  String get petTimelineLoadError => 'Could not load timeline';

  @override
  String get petTimelineManualEntry => 'Manual entry';

  @override
  String get petTimelineUnknownPerson => 'Unknown';

  @override
  String get petTimelineCustodySegmentHidden => 'Guardian custody';

  @override
  String petTimelineFosteringSession(String fosterName) {
    return 'Fostering with $fosterName';
  }

  @override
  String petTimelineCustodySegment(String guardianName) {
    return 'Guardian: $guardianName';
  }

  @override
  String petTimelineDateRange(String startDate, String endDate) {
    return '$startDate – $endDate';
  }

  @override
  String petTimelineFillTitle(String petName) {
    return 'Add timeline entry for $petName';
  }

  @override
  String get petTimelineFillTitleLabel => 'Title';

  @override
  String get petTimelineFillTitleRequired => 'Title is required';

  @override
  String get petTimelineFillDescriptionLabel => 'Description';

  @override
  String get petTimelineFillStartDateLabel => 'Start date';

  @override
  String get petTimelineFillStartDateRequired => 'Start date is required';

  @override
  String get petTimelineFillEndDateLabel => 'End date';

  @override
  String get petTimelineFillError => 'Could not save timeline entry';

  @override
  String get bulkShare => 'Bulk share';

  @override
  String get bulkShareSelectHint => 'Select pets to share';

  @override
  String get bulkShareAction => 'Share selected';

  @override
  String get bulkShareDone => 'Share links created for selected pets';

  @override
  String get bulkShareNoneSelected => 'Select at least one pet';

  @override
  String get pendingShares => 'Pending Shares';

  @override
  String petSharedWithYou(String guardianName, String petName) {
    return '$guardianName wants to share $petName with you';
  }

  @override
  String get acceptShare => 'Accept';

  @override
  String get declineShare => 'Decline';

  @override
  String get shareAccepted => 'Share accepted';

  @override
  String get acceptShareTo => 'Accept pet to…';

  @override
  String get acceptShareToHint => 'Choose where this shared pet should appear.';

  @override
  String get shareDeclined => 'Share declined';

  @override
  String get sharedPets => 'Shared Pets';

  @override
  String get invited => 'Invited';

  @override
  String get pendingInvite => 'Pending';

  @override
  String get hideSharedPet => 'Hide Pet';

  @override
  String get hide => 'Hide';

  @override
  String get unhide => 'Unhide';

  @override
  String hideSharedPetConfirm(String petName) {
    return 'Hide $petName? You won\'t see it in your list, events, or notifications. You can unhide it later from the organisation page.';
  }

  @override
  String petHidden(String petName) {
    return '$petName has been hidden';
  }

  @override
  String petUnhidden(String petName) {
    return '$petName is now visible again';
  }

  @override
  String get hiddenSharedPets => 'Hidden Shared Pets';

  @override
  String get help => 'Help';

  @override
  String get helpTitle => 'Help & FAQ';

  @override
  String get helpSubtitle =>
      'Find answers to common questions about every feature in Agatha Track.';

  @override
  String get faqAccountTitle => 'Account & Authentication';

  @override
  String get faqAccountQ1 => 'How do I create an account?';

  @override
  String get faqAccountA1 =>
      'Tap \"Sign Up\" on the landing page. Enter your email address, choose a password, and provide your first and last name. You will be logged in automatically after signing up.';

  @override
  String get faqAccountQ2 => 'How do I log in?';

  @override
  String get faqAccountA2 =>
      'Tap \"Log In\" on the landing page and enter your email and password. Your session stays active until you log out.';

  @override
  String get faqAccountQ3 => 'I forgot my password — how do I reset it?';

  @override
  String get faqAccountA3 =>
      'On the login screen, tap \"Forgot password?\". Enter the email address associated with your account and follow the instructions to set a new password.';

  @override
  String get faqAccountQ4 => 'How do I update my profile?';

  @override
  String get faqAccountA4 =>
      'Go to the user menu (your avatar in the top-right corner), then tap \"My Details\". From there you can edit your name, bio, profile photo, and change your password.';

  @override
  String get faqAccountQ5 => 'How do I log out?';

  @override
  String get faqAccountA5 =>
      'Open the user menu (avatar icon in the top-right corner) and tap \"Logout\". You will be returned to the landing page.';

  @override
  String get faqPetProfileTitle => 'Pet Profiles';

  @override
  String get faqPetProfileQ1 => 'How do I add a new pet?';

  @override
  String get faqPetProfileA1 =>
      'Tap the \"+\" button on the main pet list screen. Fill in your pet\'s name, species, breed, date of birth, and optional details like microchip number and photo. Each pet is assigned a unique colour for easy identification.';

  @override
  String get faqPetProfileQ2 => 'How do I edit or delete a pet?';

  @override
  String get faqPetProfileA2 =>
      'Tap on the pet\'s card to open its detail page. Use the edit icon in the top-right to update information. To delete a pet, use the delete option — note that deleting a pet permanently removes all associated health entries, weight records, and other data.';

  @override
  String get faqPetProfileQ3 => 'What does the identification reminder mean?';

  @override
  String get faqPetProfileA3 =>
      'If your pet does not have an ID (microchip or tag number) recorded, a species-specific reminder will appear on the pet\'s card. You can dismiss this reminder or add the ID in the pet\'s edit form.';

  @override
  String get faqPetProfileQ4 => 'How do I mark a pet as passed away?';

  @override
  String get faqPetProfileA4 =>
      'Open the pet\'s edit form and enable the \"Passed away\" option. This changes the pet\'s colour to white, adds a memorial overlay to the photo, and sends a notification. The pet remains in your list as a memorial.';

  @override
  String get faqPetProfileQ5 => 'What is the pet colour system?';

  @override
  String get faqPetProfileA5 =>
      'Each pet is assigned a unique colour from a palette of 15 colours when created. This colour appears on cards, charts, and throughout the app to help you quickly identify each pet at a glance.';

  @override
  String get faqPetProfileQ6 => 'How is my pet\'s age calculated?';

  @override
  String get faqPetProfileA6 =>
      'Age is automatically calculated from the date of birth you enter. It updates dynamically and is displayed on the pet\'s detail page and profile cards.';

  @override
  String get faqHealthTitle => 'Health Tracking';

  @override
  String get faqHealthQ1 => 'What types of health entries can I track?';

  @override
  String get faqHealthA1 =>
      'You can track medications, preventive treatments (vaccinations, deworming, flea/tick treatments), vet visits, and medical procedures. Each type has its own icon and colour in the dashboard.';

  @override
  String get faqHealthQ2 => 'How do I add a health entry?';

  @override
  String get faqHealthA2 =>
      'You can add entries from two places: the pet\'s detail page (specific to that pet) or the global Health Dashboard (accessible from the medical icon in the top bar). Fill in the type, name, date, and optional details like frequency, notes, and photo attachments.';

  @override
  String get faqHealthQ3 => 'What is the Health Dashboard?';

  @override
  String get faqHealthA3 =>
      'The Health Dashboard is a global view of all health events across all your pets. It is organised into tabs by type (medications, preventives, vet visits, etc.) and shows upcoming, due, and overdue entries. You can filter by organisation to focus on specific groups of pets.';

  @override
  String get faqHealthQ4 => 'How do recurring health entries work?';

  @override
  String get faqHealthA4 =>
      'When creating a health entry, you can set a frequency (e.g., daily, weekly, monthly, yearly, or a custom number of days). The app will automatically schedule the next occurrence and notify you when it is due.';

  @override
  String get faqHealthQ5 => 'What are Health Issues?';

  @override
  String get faqHealthA5 =>
      'Health Issues let you track ongoing medical conditions (e.g., allergies, chronic illness). Each issue can have a start date, optional end date, and can be linked to related health entries for a complete medical history.';

  @override
  String get faqHealthQ6 => 'Can I attach photos to health entries?';

  @override
  String get faqHealthA6 =>
      'Yes. When creating or editing a health entry, you can attach a photo — for example, a picture of a prescription, lab results, or a wound. The photo is stored with the entry and visible on the detail view.';

  @override
  String get faqWeightTitle => 'Weight Tracking';

  @override
  String get faqWeightQ1 => 'How do I record my pet\'s weight?';

  @override
  String get faqWeightA1 =>
      'Open the pet\'s detail page and scroll to the Weight section. Tap the add button to enter a new weight reading. You can choose between kilograms (kg) and pounds (lb).';

  @override
  String get faqWeightQ2 => 'How is weight data displayed?';

  @override
  String get faqWeightA2 =>
      'Weight history is shown as an interactive line chart on the pet\'s detail page. You can see trends over time and tap individual data points for details. The chart uses your pet\'s unique colour.';

  @override
  String get faqWeightQ3 => 'Can I switch between kg and lb?';

  @override
  String get faqWeightA3 =>
      'Yes. Use the unit toggle on the weight section to switch between kilograms and pounds. The conversion is applied to all displayed values.';

  @override
  String get faqVetTitle => 'Veterinarian Management';

  @override
  String get faqVetQ1 => 'How do I add a veterinarian?';

  @override
  String get faqVetA1 =>
      'Go to the Veterinarians section (accessible from the stethoscope icon in the top bar). Tap the \"+\" button and fill in the clinic name, vet name, phone number, email, address, and website.';

  @override
  String get faqVetQ2 => 'How do I link a vet to my pet?';

  @override
  String get faqVetA2 =>
      'When editing a pet\'s profile, you can select a veterinarian from your saved list. This links the vet to the pet so their contact information is readily available on the pet\'s detail page.';

  @override
  String get faqVetQ3 => 'Can I edit or delete a vet?';

  @override
  String get faqVetA3 =>
      'Yes. From the Veterinarians list, tap on a vet to view their details, then use the edit or delete options. Deleting a vet removes the link from any associated pets but does not delete the pets themselves.';

  @override
  String get faqSharingTitle => 'Pet Sharing';

  @override
  String get faqSharingQ1 => 'How do I share a pet with someone?';

  @override
  String get faqSharingA1 =>
      'Open the pet\'s detail page, expand the Sharing section, and tap Share Link. Send the link to one person. Each link works for a single recipient — when they accept, the pet appears in their list immediately.';

  @override
  String get faqSharingQ2 => 'What happens when someone accepts a share?';

  @override
  String get faqSharingA2 =>
      'The pet is added to their list right away with a \"shared\" badge. The owner is notified and can see who is following in the Sharing section.';

  @override
  String get faqSharingQ3 => 'Can I hide a shared pet?';

  @override
  String get faqSharingA3 =>
      'Yes. Swipe left on a shared pet\'s card to hide it. Hidden pets will not appear in your pet list, health dashboard, or generate notifications. You can unhide them from the organisation\'s detail page under \"Hidden Shared Pets\".';

  @override
  String get faqSharingQ4 =>
      'What is the difference between sharing and transferring?';

  @override
  String get faqSharingA4 =>
      'Sharing gives someone view access to a pet — the original owner retains full control. Transferring ownership (personal pets) moves the pet to another user; you keep shared access unless they remove you. Organisation pet transfers are managed separately.';

  @override
  String get faqOrgTitle => 'Organisations';

  @override
  String get faqOrgQ1 => 'What are organisations for?';

  @override
  String get faqOrgA1 =>
      'Organisations let multiple people collaborate on pet care. They are ideal for vet clinics, shelters, charities, and foster networks. You can create Professional or Charity organisations.';

  @override
  String get faqOrgQ2 => 'How do I create an organisation?';

  @override
  String get faqOrgA2 =>
      'Go to the Organisations page (accessible from the business icon in the top bar or from My Details). Tap \"Create\" and choose Professional or Charity, then fill in the name and details. You become the super user automatically.';

  @override
  String get faqOrgQ3 => 'How do I invite people to my organisation?';

  @override
  String get faqOrgA3 =>
      'From the organisation\'s detail page, tap \"Add User\". Enter the person\'s email address and choose their role — either \"Member\" or \"Super User\". They will receive a pending invite they can accept or decline.';

  @override
  String get faqOrgQ4 =>
      'What is the difference between a Member and a Super User?';

  @override
  String get faqOrgA4 =>
      'Members can view and manage pets within the organisation. Super Users have additional permissions: they can invite or remove members, edit organisation details, transfer pets, and manage archives.';

  @override
  String get faqOrgQ5 =>
      'How do I archive or restore a pet in an organisation?';

  @override
  String get faqOrgA5 =>
      'Super Users can archive a pet from the organisation\'s pet list (e.g., after an adoption). Archived pets are hidden from the active list but preserved for record-keeping. They can be restored at any time from the Archived Pets section.';

  @override
  String get faqFamilyEventsTitle => 'Family Events';

  @override
  String get faqFamilyEventsQ1 => 'What are Family Events?';

  @override
  String get faqFamilyEventsA1 =>
      'Family Events are care assignments for organisation pets. They record who is responsible for a pet during a specific period — such as a foster stay or temporary care. Each event has an assigned member, date range, and optional notes.';

  @override
  String get faqFamilyEventsQ2 => 'How do I create a Family Event?';

  @override
  String get faqFamilyEventsA2 =>
      'Open an organisation pet\'s detail page and scroll to the Family Events section. Tap the add button, choose the assigned member, set the from and optional to dates, and add any notes. All organisation members will be notified.';

  @override
  String get faqFamilyEventsQ3 =>
      'Do Family Events appear in the Health Dashboard?';

  @override
  String get faqFamilyEventsA3 =>
      'Yes. Family Events have their own dedicated tab in the Health Dashboard. They also trigger reminder notifications when an event\'s end date is approaching, so all organisation members stay informed.';

  @override
  String get faqNotificationsTitle => 'Notifications';

  @override
  String get faqNotificationsQ1 => 'What notifications will I receive?';

  @override
  String get faqNotificationsA1 =>
      'You will receive in-app notifications for: due or overdue health entries, upcoming medication reminders, organisation invites, share requests, pet memorials, and family event reminders.';

  @override
  String get faqNotificationsQ2 => 'How do I manage notification preferences?';

  @override
  String get faqNotificationsA2 =>
      'Go to the Notifications screen (bell icon in the top bar) and tap the settings icon. From there you can customise which types of notifications you receive.';

  @override
  String get faqNotificationsQ3 =>
      'Can I mute notifications for a specific pet?';

  @override
  String get faqNotificationsA3 =>
      'Yes. Each pet has a mute option in its notification settings. Muted pets will not generate any health-related notifications until unmuted.';

  @override
  String get faqNotificationsQ4 => 'Can I snooze a notification?';

  @override
  String get faqNotificationsA4 =>
      'Yes. You can snooze individual notifications to be reminded again after a chosen number of days. The snoozed reminder will reappear counting from today, not from the original due date.';

  @override
  String get faqReportsTitle => 'Reports';

  @override
  String get faqReportsQ1 => 'How do I generate a pet report?';

  @override
  String get faqReportsA1 =>
      'Open a pet\'s detail page and tap the report/PDF icon. You can customise what to include — profile information, weight history, health events, health issues, family events, notifications, and sharing details. The report is generated as a downloadable PDF.';

  @override
  String get faqReportsQ2 => 'What information is included in a report?';

  @override
  String get faqReportsA2 =>
      'Reports can include: pet profile details (name, breed, age, ID), a weight chart and history table, a list of all health entries by type, recorded health issues, family event assignments and foster stays (for organisation pets), recent notifications and alerts, and sharing access details. You choose which sections to include before generating.';

  @override
  String get faqSubscriptionTitle => 'Subscription';

  @override
  String get faqSubscriptionQ1 => 'Is Agatha Track free to use?';

  @override
  String get faqSubscriptionA1 =>
      'Agatha Track offers a free tier with core features. An optional premium subscription unlocks additional capabilities and removes limits. Visit the Subscription page from My Details to learn more.';

  @override
  String get faqSubscriptionQ2 => 'How do I subscribe?';

  @override
  String get faqSubscriptionA2 =>
      'Go to My Details and tap \"Subscription\". Choose a plan and complete the purchase through your platform\'s payment system. Your subscription is managed securely through RevenueCat.';

  @override
  String get faqSubscriptionQ3 => 'How do I cancel my subscription?';

  @override
  String get faqSubscriptionA3 =>
      'Subscriptions can be managed or cancelled through your device\'s app store settings (App Store or Google Play). Changes take effect at the end of the current billing period.';

  @override
  String get faqLanguageTitle => 'Language & Accessibility';

  @override
  String get faqLanguageQ1 => 'How do I change the app language?';

  @override
  String get faqLanguageA1 =>
      'Go to My Details and use the language dropdown to switch between English and French. The change takes effect immediately across the entire app and is saved to your profile.';

  @override
  String get faqLanguageQ2 => 'Is the app accessible?';

  @override
  String get faqLanguageA2 =>
      'Yes. Agatha Track includes accessibility features throughout: semantic labels for screen readers, tooltips on all interactive elements, proper form field labelling, and keyboard navigation support.';

  @override
  String get consentBannerTitle => 'Your Privacy Matters';

  @override
  String get consentBannerMessage =>
      'We use essential cookies and services to make Agatha Track work. We\'d also like to set optional cookies for analytics and marketing to improve your experience. You can manage your preferences at any time.';

  @override
  String get consentAcceptAll => 'Accept All';

  @override
  String get consentManagePreferences => 'Manage Preferences';

  @override
  String get consentSettings => 'Privacy Preferences';

  @override
  String get consentPreferencesDescription =>
      'Choose which types of data processing you consent to. Essential services are always active as they are required for the app to function.';

  @override
  String get consentEssential => 'Essential';

  @override
  String get consentEssentialDescription =>
      'Required for authentication, data storage, and core app functionality. Cannot be disabled.';

  @override
  String get consentAnalytics => 'Analytics';

  @override
  String get consentAnalyticsDescription =>
      'Helps us understand how you use the app so we can improve it. No personal data is shared with third parties.';

  @override
  String get consentMarketing => 'Marketing';

  @override
  String get consentMarketingDescription =>
      'Allows us to send you relevant updates and offers about Agatha Track features and services.';

  @override
  String get consentSavePreferences => 'Save Preferences';

  @override
  String get consentPreferencesSaved => 'Privacy preferences saved';

  @override
  String consentLastUpdated(String timestamp) {
    return 'Last updated: $timestamp';
  }

  @override
  String get aboutUs => 'About Us';

  @override
  String get aboutIntro =>
      'Agatha Track helps pet guardians and organisations keep their animals\' health organised. Track vet visits, medications, weight, and daily care — whether you manage one pet or coordinate across a whole team.';

  @override
  String get privacyPolicy => 'Privacy Notice';

  @override
  String get termsOfService => 'Terms of Use';

  @override
  String get legalInformation => 'Legal Information';

  @override
  String get legalDocumentsIntro =>
      'Review our legal documents for information about how Agatha Track operates, how we handle personal data, and your rights.';

  @override
  String get legalNotice => 'Legal Notice';

  @override
  String get dataProcessingAddendum => 'Data Processing Addendum';

  @override
  String get viewAllLegalDocuments => 'View all legal documents';

  @override
  String get legalDocumentLoadError =>
      'Unable to load this legal document. Please try again later.';

  @override
  String get appVersion => 'Version 1.0.0';

  @override
  String get version => 'Version';

  @override
  String get ppDataController => 'Data Controller';

  @override
  String get ppDataControllerDesc =>
      'The data controller is responsible for processing your personal data in accordance with Regulation (EU) 2016/679 (General Data Protection Regulation, \"GDPR\"). Contact us for data controller details.';

  @override
  String get ppScope => 'Scope';

  @override
  String get ppScopeDesc =>
      'This Privacy Policy applies to the Agatha Track application, a pet management platform available as a web application, and describes how we collect, use, store, and protect your personal data.';

  @override
  String get ppDataCollected => 'Data We Collect';

  @override
  String get ppDataCollectedDesc =>
      'We collect the following categories of data:\n\n• Account Data: email address, password (hashed), first name, last name, display name, category, bio, profile photo, locale preference.\n• Pet Data: pet name, species, breed, date of birth, sex, chip/microchip ID, insurance information, pet photo, passed-away status.\n• Health Tracking Data: health entries (medications, preventives, vet visits), photos/attachments, health issues, administration history.\n• Weight Tracking Data: weight entries (value, date, unit).\n• Veterinarian Contact Data: vet name, clinic, phone, email, address.\n• Organisation Data: organisation name, type, description, membership, roles, family events.\n• Sharing Data: pet access records, share links, pending invitations.\n• Notification Data: in-app notifications, notification preferences.\n• Technical Data: JWT authentication tokens, local preferences.';

  @override
  String get ppLegalBasis => 'Legal Basis for Processing';

  @override
  String get ppLegalBasisDesc =>
      'We process your personal data on the following legal bases under GDPR Article 6:\n\n• Consent (Art. 6(1)(a)): For optional data such as profile photos, pet photos, and bio text.\n• Contractual Necessity (Art. 6(1)(b)): For data required to provide the core service.\n• Legitimate Interest (Art. 6(1)(f)): For security measures and service improvement.\n• Legal Obligation (Art. 6(1)(c)): Where required by applicable law.';

  @override
  String get ppHowWeUse => 'How We Use Your Data';

  @override
  String get ppHowWeUseDesc =>
      'We use your personal data to:\n\n• Provide the Service: manage your account, pet profiles, health records, and all related features.\n• Generate Reports: create PDF pet reports.\n• Send Notifications: deliver in-app reminders and alerts.\n• Manage Subscriptions: process subscription entitlements via RevenueCat.\n• Ensure Security: authenticate users, prevent fraud, and maintain service integrity.';

  @override
  String get ppDataSharing => 'Data Sharing and Sub-Processors';

  @override
  String get ppDataSharingDesc =>
      'We use RevenueCat for subscription management (User ID, subscription status). We do not sell, rent, or trade your personal data to third parties. We may disclose your data if required by law.';

  @override
  String get ppInternationalTransfers => 'International Data Transfers';

  @override
  String get ppInternationalTransfersDesc =>
      'Where data is transferred outside the European Economic Area (EEA), we ensure adequate safeguards are in place, including EU Standard Contractual Clauses (SCCs) and adequacy decisions by the European Commission.';

  @override
  String get ppDataRetention => 'Data Retention';

  @override
  String get ppDataRetentionDesc =>
      'Account data is retained for the duration of your account plus 30 days after deletion. Pet profiles, health entries, weight entries, and vet contacts are kept until individually deleted or account deletion. Notifications are auto-purged after 90 days. When you delete your account, all associated data is permanently removed within 30 days.';

  @override
  String get ppYourRights => 'Your Rights (GDPR Art. 15–22)';

  @override
  String get ppYourRightsDesc =>
      'Under the GDPR, you have the right to:\n\n• Access your personal data (Art. 15)\n• Rectify inaccurate data (Art. 16)\n• Erase your data — \"Right to Be Forgotten\" (Art. 17)\n• Restrict processing (Art. 18)\n• Data portability in machine-readable format (Art. 20)\n• Object to processing (Art. 21)\n• Withdraw consent at any time (Art. 7(3))\n• Lodge a complaint with your local Data Protection Authority (Art. 77)\n\nYou can exercise these rights through the App\'s My Details screen or by contacting us directly. We will respond within 30 days.';

  @override
  String get ppCookies => 'Cookies and Local Storage';

  @override
  String get ppCookiesDesc =>
      'The App uses local storage (SharedPreferences) to store authentication tokens, locale preferences, consent state, and local cache data. We do not use third-party tracking cookies.';

  @override
  String get ppChildrensData => 'Children\'s Data';

  @override
  String get ppChildrensDataDesc =>
      'The App is not directed at children under the age of 16. We do not knowingly collect personal data from children under 16 (GDPR Art. 8).';

  @override
  String get ppSecurity => 'Data Security';

  @override
  String get ppSecurityDesc =>
      'We implement appropriate technical and organisational measures to protect your data, including encryption in transit (TLS/HTTPS), password hashing (bcrypt), JWT-based authentication, role-based access control, and parameterised database queries.';

  @override
  String get ppChanges => 'Changes to This Policy';

  @override
  String get ppChangesDesc =>
      'We may update this Privacy Policy from time to time. We will notify you of material changes via in-app notification or by updating the last updated date.';

  @override
  String get ppContact => 'Contact Us';

  @override
  String get ppContactDesc =>
      'For any questions, requests, or concerns about this Privacy Policy or our data processing practices, please contact us through the App or via email.';

  @override
  String get tosAcceptance => 'Introduction and Acceptance';

  @override
  String get tosAcceptanceDesc =>
      'These Terms of Service govern your access to and use of the Agatha Track application. By creating an account or using the App, you agree to be bound by these Terms. If you do not agree, you must not use the App.';

  @override
  String get tosEligibility => 'Eligibility';

  @override
  String get tosEligibilityDesc =>
      'You must be at least 16 years of age to use the App, in accordance with GDPR Article 8. By creating an account, you represent that you meet the age requirement and have the legal capacity to enter into these Terms.';

  @override
  String get tosAccountSecurity => 'Account Registration and Security';

  @override
  String get tosAccountSecurityDesc =>
      'To use the App, you must register with a valid email address and password. You are responsible for maintaining the confidentiality of your login credentials and all activities that occur under your account.';

  @override
  String get tosServiceDescription => 'Description of Service';

  @override
  String get tosServiceDescriptionDesc =>
      'The App provides pet profile management, health tracking, weight tracking, veterinarian contacts, organisation management, pet sharing, family events, pet reports, notifications, and subscription management.';

  @override
  String get tosUserContent => 'User Content and Responsibilities';

  @override
  String get tosUserContentDesc =>
      'You retain ownership of all content you upload. By uploading content, you grant us a limited licence to store, process, and display it solely for providing the Service. You agree not to upload unlawful, harmful, or infringing content. The App is not a substitute for professional veterinary advice.';

  @override
  String get tosProhibitedUses => 'Prohibited Uses';

  @override
  String get tosProhibitedUsesDesc =>
      'You agree not to use the App for any illegal purpose, attempt to gain unauthorised access, interfere with the App\'s infrastructure, use automated tools without consent, reverse engineer any part of the App, or share, sell, or transfer your account without our consent.';

  @override
  String get tosSubscriptions => 'Subscriptions and Payments';

  @override
  String get tosSubscriptionsDesc =>
      'Certain features require a paid subscription managed through RevenueCat. Subscriptions auto-renew unless cancelled before the end of the current billing period. Refunds are governed by the applicable app store\'s policies.';

  @override
  String get tosIntellectualProperty => 'Intellectual Property';

  @override
  String get tosIntellectualPropertyDesc =>
      'The App, including its design, code, graphics, logos, and documentation, is protected by copyright, trademark, and other intellectual property laws. We grant you a limited, non-exclusive, non-transferable, revocable licence to use the App in accordance with these Terms.';

  @override
  String get tosLiability => 'Limitation of Liability';

  @override
  String get tosLiabilityDesc =>
      'The App is provided \"as is\" without warranties. We shall not be liable for indirect, incidental, special, or consequential damages. Our total aggregate liability shall not exceed the amount paid by you in the twelve months preceding the claim. For EU consumers, nothing limits our liability for death, personal injury, fraud, or non-conformity under Directive (EU) 2019/770.';

  @override
  String get tosTermination => 'Termination';

  @override
  String get tosTerminationDesc =>
      'You may terminate your account at any time using the Delete Account feature. We may suspend or terminate your access if you breach these Terms or if required by law. Before terminating, you may export your data using the Export My Data feature (GDPR Art. 20).';

  @override
  String get tosGoverningLaw => 'Governing Law and Dispute Resolution';

  @override
  String get tosGoverningLawDesc =>
      'These Terms are governed by applicable European Union and national law. For EU consumers, you benefit from mandatory consumer protection laws of your country of residence. You may use the European Commission\'s Online Dispute Resolution (ODR) platform to resolve disputes online.';

  @override
  String get tosContact => 'Contact Information';

  @override
  String get tosContactDesc =>
      'For questions about these Terms, please contact us through the App or via email.';

  @override
  String get exportMyData => 'Export My Data';

  @override
  String get exportMyDataSubtitle => 'Download all your data as a JSON file';

  @override
  String get dataExported => 'Your data has been exported';

  @override
  String get consentPreferences => 'Privacy Preferences';

  @override
  String get consentReset =>
      'Consent preferences reset. The consent banner will appear on next launch.';

  @override
  String get deleteAccount => 'Delete Account';

  @override
  String get deleteAccountSubtitle =>
      'Permanently delete your account and all data';

  @override
  String get deleteAccountWarning =>
      'This action is irreversible. All your pets, health entries, weight records, notifications, and organisation memberships will be permanently deleted. Enter your password to confirm.';

  @override
  String get error => 'Error';

  @override
  String get maxPhotosReached => 'Maximum 4 documents per event';

  @override
  String failedToLoadPhotos(String error) {
    return 'Failed to load documents: $error';
  }

  @override
  String failedToAddPhoto(String error) {
    return 'Failed to add document: $error';
  }

  @override
  String failedToUploadPhotoNamed(String name, String error) {
    return 'Failed to upload document \"$name\": $error';
  }

  @override
  String get deletePhotoTitle => 'Delete Document';

  @override
  String get deletePhotoConfirm =>
      'Remove this document? This cannot be undone.';

  @override
  String failedToDeletePhoto(String error) {
    return 'Failed to delete document: $error';
  }

  @override
  String failedToLoadEntry(String error) {
    return 'Failed to load entry: $error';
  }

  @override
  String get createHealthIssuesHint =>
      'You can create health issues from the pet\'s profile page';

  @override
  String get noPetsFoundAddFirst => 'No pets found. Please add a pet first.';

  @override
  String get entryNameHint => 'e.g., Heartgard, Annual Checkup';

  @override
  String get dosageHint => 'e.g., 1 tablet, 0.5ml';

  @override
  String get period => 'Period';

  @override
  String get repeatEndsBy => 'Repeat ends by';

  @override
  String get never => 'Never';

  @override
  String get pickADate => 'Pick a date';

  @override
  String get notesHint => 'Additional information...';

  @override
  String addEntryForPets(int count) {
    return 'Add Entry for $count Pets';
  }

  @override
  String get administrationHistory => 'Administration History';

  @override
  String get selectAtLeastOnePet => 'Please select at least one pet';

  @override
  String get markAsCompletedTitle => 'Mark as Completed?';

  @override
  String get markCompletedPast =>
      'This event is in the past. Would you like to mark it as completed?';

  @override
  String get markCompletedToday =>
      'This event is today. Would you like to mark it as completed?';

  @override
  String get keepActive => 'Keep Active';

  @override
  String get markCompletedAction => 'Mark Completed';

  @override
  String entriesCreated(int count) {
    return '$count entries created';
  }

  @override
  String get noHistoryYet => 'No history yet.';

  @override
  String deleteEntryNamedConfirm(String name) {
    return 'Delete \"$name\"? This cannot be undone.';
  }

  @override
  String failedToDelete(String error) {
    return 'Failed to delete: $error';
  }

  @override
  String failedToLoadHistory(String error) {
    return 'Failed to load history: $error';
  }

  @override
  String get petLabel => 'Pet';

  @override
  String get unknownPet => 'Unknown pet';

  @override
  String get selectPets => 'Select Pets';

  @override
  String get atLeastOnePetMustBeSelected => 'At least one pet must be selected';

  @override
  String get selectMultiplePetsHint =>
      'Select multiple pets to create an entry for each';

  @override
  String get selectAll => 'Select All';

  @override
  String get clearSelection => 'Clear';

  @override
  String get tapToChangeDate => 'Tap to change date';

  @override
  String get cameraOption => 'Camera';

  @override
  String get galleryFilesOption => 'Gallery / Files';

  @override
  String photoCountLabel(int count) {
    return '$count/4 Documents';
  }

  @override
  String pendingUploadSuffix(int count) {
    return ' ($count will upload on save)';
  }

  @override
  String get pendingLabel => 'Pending';

  @override
  String get unsupportedDocumentFormat =>
      'Only JPG, PNG, and PDF documents are supported';

  @override
  String get documentTooLarge => 'Document must be 2 MB or smaller';

  @override
  String get home => 'Home';

  @override
  String get eventsNavLabel => 'Events';

  @override
  String get settings => 'Settings';

  @override
  String get upcomingEvents => 'Upcoming events';

  @override
  String get invite => 'Invite';

  @override
  String get contact => 'Contact';

  @override
  String get continueButton => 'Continue';

  @override
  String get experienceChooserTitle => 'How will you use Agatha Track?';

  @override
  String get experienceChooserSubtitle =>
      'Choose the experience that fits what you need today.';

  @override
  String get experienceGuardianTitle => 'Individual Pet Guardian';

  @override
  String get experienceGuardianSubtitle =>
      'Track care, reminders, and shared looking-after for your pets.';

  @override
  String get experienceOrganizationTitle => 'Shelter / Organisation';

  @override
  String get experienceOrganizationSubtitle =>
      'Manage pets, fosters, adoptions, and your team.';

  @override
  String get experienceBoardingTitle => 'Pet boarding';

  @override
  String get experienceBoardingSubtitle => 'Coming soon';

  @override
  String get experienceRememberChoice => 'Remember my choice for next time';

  @override
  String get experienceRememberChoiceHint =>
      'You can change your default view later in Settings.';

  @override
  String get experienceOrgView => 'Organisation view';

  @override
  String get drawerCreateOrg => 'Create an organisation';

  @override
  String get orgNotificationsDrawer => 'Organisation notifications';

  @override
  String get guardianNotificationsDrawer => 'Guardian notifications';

  @override
  String get myVets => 'My vets';

  @override
  String get guardianDashboardTitle => 'Guardian dashboard';

  @override
  String get upcomingPetEvents => 'Upcoming Pet Events';

  @override
  String get allEvents => 'All Events';

  @override
  String get allVets => 'All Vets';

  @override
  String get addAnEvent => 'Add an event';

  @override
  String get dashboardAddPet => 'Add a pet';

  @override
  String vetLinkedPetCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count pets',
      one: '1 pet',
    );
    return '$_temp0';
  }

  @override
  String get vetLinkedPets => 'Linked pets';

  @override
  String get vetNotFound => 'Veterinarian not found';

  @override
  String get selectPetForWeight => 'Select a pet for weight entry';

  @override
  String get selectPetForEvent => 'Select a pet for this event';

  @override
  String get orgVets => 'Org vets';

  @override
  String get myOrganisation => 'My Organisation';

  @override
  String get experienceGuardianView => 'Pet guardian view';

  @override
  String get experienceDefaultSettingTitle => 'Default experience';

  @override
  String get experienceDefaultSettingSubtitle =>
      'Used when you sign in. You can still switch anytime from the menu.';

  @override
  String get experienceGuardianInviteHint =>
      'Add a pet or open a pet profile to share care with someone.';

  @override
  String get experienceOrganizationInviteHint =>
      'Invite team members to help run your organisation.';

  @override
  String get guardianOnboardingTitle => 'Get started';

  @override
  String get guardianOnboardingSkip => 'Skip for now';

  @override
  String get guardianOnboardingWelcomeTitle => 'Welcome to Agatha Track';

  @override
  String get guardianOnboardingWelcomeBody =>
      'Add your first pet to start tracking their care.';

  @override
  String get guardianOnboardingGetStarted => 'Get started';

  @override
  String get guardianOnboardingPetStepTitle => 'Add your first pet';

  @override
  String get guardianOnboardingPetStepBody =>
      'Tell us who you are caring for. You can add more details later.';

  @override
  String get guardianOnboardingReminderStepTitle => 'Set your first reminder';

  @override
  String get guardianOnboardingReminderStepBody =>
      'Medications, preventives, and vet visits — we will remind you when they are due.';

  @override
  String get guardianOnboardingReminderNameLabel => 'Reminder name';

  @override
  String get guardianOnboardingFinish => 'Finish setup';

  @override
  String get orgOnboardingTitle => 'Set up your organisation';

  @override
  String get orgOnboardingSkip => 'Skip for now';

  @override
  String get orgOnboardingWelcomeTitle =>
      'Welcome to your organisation workspace';

  @override
  String get orgOnboardingWelcomeBody =>
      'Create your organisation profile, add your first inventory pet, and set a reminder to stay on top of care.';

  @override
  String get orgOnboardingGetStarted => 'Get started';

  @override
  String get orgOnboardingOrgStepTitle => 'Create your organisation';

  @override
  String get orgOnboardingOrgStepBody =>
      'Tell us about your shelter or organisation. You can add more details later.';

  @override
  String get orgOnboardingPetStepTitle => 'Add your first inventory pet';

  @override
  String get orgOnboardingPetStepBody =>
      'Add a pet your organisation is caring for. Foster and adoption workflows come next.';

  @override
  String get orgOnboardingReminderStepTitle => 'Set your first reminder';

  @override
  String get orgOnboardingReminderStepBody =>
      'Medications, vaccines, and vet visits — we will remind your team when they are due.';

  @override
  String get orgOnboardingFinish => 'Finish setup';

  @override
  String failedToSaveOnboarding(String error) {
    return 'Could not save your setup: $error';
  }

  @override
  String sharedWithGroupTitle(String name) {
    return 'Shared with $name';
  }

  @override
  String fosteredViaGroupTitle(String orgName) {
    return 'Fostered via $orgName';
  }

  @override
  String get petResponsibilityGuardian => 'You are the pet guardian';

  @override
  String petResponsibilityOrgCustody(String orgName) {
    return '$orgName · Organisation custody';
  }

  @override
  String get homeAllCaughtUp => 'You\'re all caught up';

  @override
  String get homeNoDueEvents => 'No events are overdue or due today.';

  @override
  String get open => 'Open';

  @override
  String get viewOrganization => 'View organisation';

  @override
  String get prospectsTitle => 'Prospects';

  @override
  String get prospectsEmpty => 'No prospects yet';

  @override
  String get adoptionVisitsTitle => 'Adoption visits';

  @override
  String get adoptionVisitsEmpty => 'No adoption visits scheduled';

  @override
  String get adoptionVisitOutcomePositive => 'Positive';

  @override
  String get adoptionVisitOutcomeNegative => 'Negative';

  @override
  String get adoptionVisitOutcomeNoShow => 'No show';

  @override
  String get adoptionVisitOutcomePending => 'Outcome pending';

  @override
  String get adoptionVisitOutcomeSaved => 'Visit outcome recorded';

  @override
  String get adoptionJourneyTitle => 'Adoption journey';

  @override
  String get adoptionJourneyStatusLabel => 'Status';

  @override
  String get adoptionJourneyConditionsLabel => 'Conditions';

  @override
  String get adoptionJourneyMilestonesTitle => 'Adoption milestones';

  @override
  String get adoptionJourneyMilestonesEmpty => 'No milestones configured yet.';

  @override
  String get adoptionJourneyStatusUnknown => 'Unknown';

  @override
  String get drawerGuardian => 'Guardian';

  @override
  String get drawerOrganisation => 'Organisation';

  @override
  String get drawerAccount => 'Account';

  @override
  String get notificationsBellTooltip => 'Open notifications';

  @override
  String get sectionDrawerTooltip => 'Open menu';

  @override
  String failedToLoadNotifications(String error) {
    return 'Failed to load notifications: $error';
  }

  @override
  String get notificationKindAll => 'All';

  @override
  String get notificationKindCare => 'Care';

  @override
  String get notificationKindOrganisation => 'Organisation';

  @override
  String get notificationActionNeeded => 'Action needed';

  @override
  String get accountTitle => 'Account';

  @override
  String get adminContactsTitle => 'Admin contacts';

  @override
  String get adminContactsDescription =>
      'Internal directory of organisation admins. Call or message using the contact details they share.';

  @override
  String get adminContactsEmpty => 'No admin contacts yet.';

  @override
  String get adminContactsYourCard => 'Your card';

  @override
  String get adminContactsAddAdmin => 'Add admin';

  @override
  String get adminContactsCall => 'Call';

  @override
  String get adminContactsMessage => 'Message';

  @override
  String get adminContactsMoreOptions => 'More options';

  @override
  String get adminContactsSelfPrefsTitle => 'Your visibility preferences';

  @override
  String get adminContactsSelfPrefsStubNote =>
      'Saved locally until org-scoped notification preferences are available.';

  @override
  String get adminContactsPhoneVisibilityLabel =>
      'Who can see your phone number';

  @override
  String get adminContactsPhoneVisibilityFosters => 'Fosters';

  @override
  String get adminContactsPhoneVisibilityAdmins => 'Admins';

  @override
  String get adminContactsPhoneVisibilityAll => 'Everyone in the organisation';

  @override
  String get adminContactsPhoneVisibilityNobody => 'Nobody';

  @override
  String get adminContactsMessageChannelLabel => 'Message notifications';

  @override
  String get adminContactsMessageChannelInApp => 'In app';

  @override
  String get adminContactsMessageChannelEmail => 'Email';

  @override
  String get adminContactsMessageChannelBoth => 'In app and email';

  @override
  String adminContactsSelfCardSemantics(String name) {
    return 'Your admin contact card, $name';
  }

  @override
  String adminContactsCardSemantics(String name, String role) {
    return 'Admin contact $name, $role';
  }

  @override
  String adminContactsRemoveConfirm(String name) {
    return 'Remove $name from this organisation?';
  }

  @override
  String adminContactsRemoved(String name) {
    return '$name was removed';
  }

  @override
  String get orgDashboardIntro =>
      'Choose a section to manage your organisation.';

  @override
  String get orgDashboardPetsSubtitle => 'Browse pets, tabs, and care filters.';

  @override
  String get orgDashboardConnectionsSubtitle =>
      'Manage links with other organisations.';

  @override
  String get orgDashboardEditSubtitle =>
      'Update organisation details and branding.';

  @override
  String get orgPresentationTitle => 'Organisation presentation';

  @override
  String get orgPresentationSubtitle =>
      'Public-facing identity, legal details, and contact information.';

  @override
  String get orgPresentationContactTitle => 'Contact';

  @override
  String get orgPresentationLegalTitle => 'Legal information';

  @override
  String get orgLegalIdentifierRna => 'RNA';

  @override
  String get orgLegalIdentifierSiren => 'SIREN';

  @override
  String get orgLegalIdentifierSiret => 'SIRET';

  @override
  String get orgLegalDocumentsTitle => 'Legal & documents';

  @override
  String get orgLegalDocumentsSubtitle =>
      'Read and download public organisation documents.';

  @override
  String get orgLegalDocumentsIntro =>
      'These documents are published by your organisation for members to read and download.';

  @override
  String get orgLegalDocumentsEmpty => 'No public documents are available yet.';

  @override
  String get orgLegalDocumentsTypeSession => 'Session documents';

  @override
  String get orgLegalDocumentsTypeAdoption => 'Adoption documents';

  @override
  String orgLegalDocumentsDownload(String title) {
    return 'Download $title';
  }

  @override
  String orgLegalDocumentsDownloaded(String title) {
    return 'Downloaded $title';
  }

  @override
  String get orgCustomisationsTitle => 'Organisation customisations';

  @override
  String get orgCustomisationsIntro =>
      'Configure templates and delegate permissions for this organisation.';

  @override
  String get orgCustomisationsTemplatesTitle => 'Document templates';

  @override
  String get orgCustomisationsTemplatesSubtitle =>
      'Session checklists and adoption milestone templates.';

  @override
  String get orgCustomisationsRolesTitle => 'Roles & permissions';

  @override
  String get orgCustomisationsRolesSubtitle =>
      'Apply bundle presets, manage overrides, and review the audit log.';

  @override
  String get orgDocumentTemplatesIntro =>
      'Templates used for fostering sessions and adoption journeys.';

  @override
  String get orgDocumentTemplatesEmpty =>
      'No document templates are configured yet.';

  @override
  String get orgRolesPermissionsIntro =>
      'Select a member, apply a bundle preset, then fine-tune individual permissions.';

  @override
  String get orgRolesPermissionsMemberLabel => 'Member';

  @override
  String get orgRolesPermissionsSelectMember =>
      'Select a member to view permissions.';

  @override
  String get orgRolesPermissionsEffectiveTitle => 'Effective permissions';

  @override
  String get orgRolesPermissionsNone => 'No permissions granted.';

  @override
  String get orgRolesPermissionsRoleDefault => 'Granted by role';

  @override
  String get orgRolesPermissionsOverrideActive => 'Individual override';

  @override
  String get orgRolesPermissionsAuditTitle => 'Audit log';

  @override
  String get orgRolesPermissionsAuditEmpty => 'No audit events recorded yet.';

  @override
  String orgRolesPermissionsApplyBundle(String name) {
    return 'Apply $name';
  }

  @override
  String orgRolesPermissionsBundleApplied(String name) {
    return '$name bundle applied';
  }

  @override
  String get orgPermissionManageFosters => 'Manage fosters';

  @override
  String get orgPermissionManagePets => 'Manage pets';

  @override
  String get orgPermissionManageMembers => 'Manage members';

  @override
  String get orgPermissionManageDocumentTemplates =>
      'Manage document templates';

  @override
  String get orgPermissionManagePermissions => 'Manage permissions';

  @override
  String get orgPermissionBundleFosterAdmin => 'Foster Admin';

  @override
  String get orgPermissionBundlePetAdmin => 'Pet Admin';

  @override
  String get orgPermissionBundleTeamAdmin => 'Team Admin';
}
