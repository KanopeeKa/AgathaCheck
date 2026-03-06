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
      'Agatha Track keeps your pet\'s health organized, so you don\'t have to.';

  @override
  String get appDescription =>
      'Track vet visits, medications, weight, and daily care in one simple dashboard designed for busy pet parents.';

  @override
  String get appCta =>
      'Log in to pick up where you left off, or create a free account to start keeping your pet\'s health history safe and accessible anytime.';

  @override
  String get signIn => 'Sign In';

  @override
  String get signUp => 'Sign Up';

  @override
  String get createAccount => 'Create Account';

  @override
  String get signInToAccount => 'Sign in to your account';

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
  String get addWeightEntry => 'Add Weight Entry';

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
  String get deleteWeightEntry => 'Delete weight entry';

  @override
  String weightChartLabel(int count) {
    return 'Weight chart showing $count entries';
  }

  @override
  String get healthEvents => 'Events';

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
  String get nextDueDate => 'Next Due Date';

  @override
  String get notes => 'Notes';

  @override
  String get healthIssueOptional => 'Health Issue (optional)';

  @override
  String get none => 'None';

  @override
  String get addHealthEntry2 => 'Add Entry';

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
  String get photos => 'Photos';

  @override
  String get addPhoto => 'Add photo';

  @override
  String get upTo4Photos => 'up to 4 pictures, max 2 MB';

  @override
  String get removePhoto => 'Remove photo';

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
  String get pdfAgathaCheck => 'AGATHA CHECK';

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
  String get myOrganizations => 'My Organizations';

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
  String get orgArchived => 'Archived Pets';

  @override
  String get orgNoOrganizations => 'No organizations yet';

  @override
  String get orgCreateFirst => 'Create your first organization to get started';

  @override
  String get createOrJoinOrganization => 'Create or Join an organization';

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
  String get orgSuperUser => 'Super User';

  @override
  String get orgMember => 'Member';

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
  String get transferSuccess => 'Pet transferred successfully';

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
      'Open the pet\'s detail page and use the share option to generate a share link. Send this link to the person you want to share with. When they accept, they will see the pet in their list.';

  @override
  String get faqSharingQ2 => 'What happens when someone accepts a share?';

  @override
  String get faqSharingA2 =>
      'The recipient receives a notification with the pending share. They can choose to place the shared pet into their personal list or into an organisation they belong to. The pet appears with a \"shared\" badge.';

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
      'Sharing gives someone view access to a pet — the original owner retains full control. Transferring (available for organisation pets) moves ownership of the pet to another user or organisation entirely.';

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
      'Open a pet\'s detail page and tap the report/PDF icon. You can customise what to include — profile information, weight history, health events, and health issues. The report is generated as a downloadable PDF.';

  @override
  String get faqReportsQ2 => 'What information is included in a report?';

  @override
  String get faqReportsA2 =>
      'Reports can include: pet profile details (name, breed, age, ID), a weight chart and history table, a list of all health entries by type, and any recorded health issues. You choose which sections to include before generating.';

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
}
