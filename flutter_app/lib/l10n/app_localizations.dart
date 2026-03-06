import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_en.dart';
import 'app_localizations_fr.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of AppLocalizations
/// returned by `AppLocalizations.of(context)`.
///
/// Applications need to include `AppLocalizations.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'l10n/app_localizations.dart';
///
/// return MaterialApp(
///   localizationsDelegates: AppLocalizations.localizationsDelegates,
///   supportedLocales: AppLocalizations.supportedLocales,
///   home: MyApplicationHome(),
/// );
/// ```
///
/// ## Update pubspec.yaml
///
/// Please make sure to update your pubspec.yaml to include the following
/// packages:
///
/// ```yaml
/// dependencies:
///   # Internationalization support.
///   flutter_localizations:
///     sdk: flutter
///   intl: any # Use the pinned version from flutter_localizations
///
///   # Rest of dependencies
/// ```
///
/// ## iOS Applications
///
/// iOS applications define key application metadata, including supported
/// locales, in an Info.plist file that is built into the application bundle.
/// To configure the locales supported by your app, you’ll need to edit this
/// file.
///
/// First, open your project’s ios/Runner.xcworkspace Xcode workspace file.
/// Then, in the Project Navigator, open the Info.plist file under the Runner
/// project’s Runner folder.
///
/// Next, select the Information Property List item, select Add Item from the
/// Editor menu, then select Localizations from the pop-up menu.
///
/// Select and expand the newly-created Localizations item then, for each
/// locale your application supports, add a new item and select the locale
/// you wish to add from the pop-up menu in the Value field. This list should
/// be consistent with the languages listed in the AppLocalizations.supportedLocales
/// property.
abstract class AppLocalizations {
  AppLocalizations(String locale)
    : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static AppLocalizations? of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations);
  }

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

  /// A list of this localizations delegate along with the default localizations
  /// delegates.
  ///
  /// Returns a list of localizations delegates containing this delegate along with
  /// GlobalMaterialLocalizations.delegate, GlobalCupertinoLocalizations.delegate,
  /// and GlobalWidgetsLocalizations.delegate.
  ///
  /// Additional delegates can be added by appending to this list in
  /// MaterialApp. This list does not have to be used at all if a custom list
  /// of delegates is preferred or required.
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates =
      <LocalizationsDelegate<dynamic>>[
        delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
      ];

  /// A list of this localizations delegate's supported locales.
  static const List<Locale> supportedLocales = <Locale>[
    Locale('en'),
    Locale('fr'),
  ];

  /// No description provided for @appTitle.
  ///
  /// In en, this message translates to:
  /// **'Agatha Track'**
  String get appTitle;

  /// No description provided for @agathaCheckLogo.
  ///
  /// In en, this message translates to:
  /// **'Agatha Track logo'**
  String get agathaCheckLogo;

  /// No description provided for @appTagline.
  ///
  /// In en, this message translates to:
  /// **'Agatha Track keeps your pet\'s health organized, so you don\'t have to.'**
  String get appTagline;

  /// No description provided for @appDescription.
  ///
  /// In en, this message translates to:
  /// **'Track vet visits, medications, weight, and daily care in one simple dashboard designed for busy pet parents.'**
  String get appDescription;

  /// No description provided for @appCta.
  ///
  /// In en, this message translates to:
  /// **'Log in to pick up where you left off, or create a free account to start keeping your pet\'s health history safe and accessible anytime.'**
  String get appCta;

  /// No description provided for @signIn.
  ///
  /// In en, this message translates to:
  /// **'Sign In'**
  String get signIn;

  /// No description provided for @signUp.
  ///
  /// In en, this message translates to:
  /// **'Sign Up'**
  String get signUp;

  /// No description provided for @createAccount.
  ///
  /// In en, this message translates to:
  /// **'Create Account'**
  String get createAccount;

  /// No description provided for @signInToAccount.
  ///
  /// In en, this message translates to:
  /// **'Sign in to your account'**
  String get signInToAccount;

  /// No description provided for @createYourAccount.
  ///
  /// In en, this message translates to:
  /// **'Create your account'**
  String get createYourAccount;

  /// No description provided for @dontHaveAccount.
  ///
  /// In en, this message translates to:
  /// **'Don\'t have an account?'**
  String get dontHaveAccount;

  /// No description provided for @alreadyHaveAccount.
  ///
  /// In en, this message translates to:
  /// **'Already have an account?'**
  String get alreadyHaveAccount;

  /// No description provided for @email.
  ///
  /// In en, this message translates to:
  /// **'Email'**
  String get email;

  /// No description provided for @password.
  ///
  /// In en, this message translates to:
  /// **'Password'**
  String get password;

  /// No description provided for @name.
  ///
  /// In en, this message translates to:
  /// **'Name'**
  String get name;

  /// No description provided for @confirmPassword.
  ///
  /// In en, this message translates to:
  /// **'Confirm Password'**
  String get confirmPassword;

  /// No description provided for @showPassword.
  ///
  /// In en, this message translates to:
  /// **'Show password'**
  String get showPassword;

  /// No description provided for @hidePassword.
  ///
  /// In en, this message translates to:
  /// **'Hide password'**
  String get hidePassword;

  /// No description provided for @emailRequired.
  ///
  /// In en, this message translates to:
  /// **'Email is required'**
  String get emailRequired;

  /// No description provided for @enterValidEmail.
  ///
  /// In en, this message translates to:
  /// **'Enter a valid email'**
  String get enterValidEmail;

  /// No description provided for @passwordRequired.
  ///
  /// In en, this message translates to:
  /// **'Password is required'**
  String get passwordRequired;

  /// No description provided for @atLeast6Characters.
  ///
  /// In en, this message translates to:
  /// **'At least 6 characters'**
  String get atLeast6Characters;

  /// No description provided for @passwordsDoNotMatch.
  ///
  /// In en, this message translates to:
  /// **'Passwords do not match'**
  String get passwordsDoNotMatch;

  /// No description provided for @forgotPassword.
  ///
  /// In en, this message translates to:
  /// **'Forgot Password?'**
  String get forgotPassword;

  /// No description provided for @logOut.
  ///
  /// In en, this message translates to:
  /// **'Log Out'**
  String get logOut;

  /// No description provided for @resetPassword.
  ///
  /// In en, this message translates to:
  /// **'Reset Password'**
  String get resetPassword;

  /// No description provided for @forgotPasswordTitle.
  ///
  /// In en, this message translates to:
  /// **'Forgot Password'**
  String get forgotPasswordTitle;

  /// No description provided for @enterResetCode.
  ///
  /// In en, this message translates to:
  /// **'Enter Reset Code'**
  String get enterResetCode;

  /// No description provided for @enterResetCodeInstructions.
  ///
  /// In en, this message translates to:
  /// **'Enter the 6-digit code and your new password.'**
  String get enterResetCodeInstructions;

  /// No description provided for @forgotPasswordInstructions.
  ///
  /// In en, this message translates to:
  /// **'Enter your email address and we\'ll send you a code to reset your password.'**
  String get forgotPasswordInstructions;

  /// No description provided for @resetCodeSentMessage.
  ///
  /// In en, this message translates to:
  /// **'If an account with that email exists, a reset code has been sent. Check your email.'**
  String get resetCodeSentMessage;

  /// No description provided for @sendResetCode.
  ///
  /// In en, this message translates to:
  /// **'Send Reset Code'**
  String get sendResetCode;

  /// No description provided for @resetCode.
  ///
  /// In en, this message translates to:
  /// **'Reset Code'**
  String get resetCode;

  /// No description provided for @sixDigitCode.
  ///
  /// In en, this message translates to:
  /// **'6-digit code'**
  String get sixDigitCode;

  /// No description provided for @codeRequired.
  ///
  /// In en, this message translates to:
  /// **'Code is required'**
  String get codeRequired;

  /// No description provided for @enterSixDigitCode.
  ///
  /// In en, this message translates to:
  /// **'Enter the 6-digit code'**
  String get enterSixDigitCode;

  /// No description provided for @newPassword.
  ///
  /// In en, this message translates to:
  /// **'New Password'**
  String get newPassword;

  /// No description provided for @useDifferentEmail.
  ///
  /// In en, this message translates to:
  /// **'Use a different email'**
  String get useDifferentEmail;

  /// No description provided for @passwordResetTitle.
  ///
  /// In en, this message translates to:
  /// **'Password Reset'**
  String get passwordResetTitle;

  /// No description provided for @backToSignIn.
  ///
  /// In en, this message translates to:
  /// **'Back to sign in'**
  String get backToSignIn;

  /// No description provided for @myDetails.
  ///
  /// In en, this message translates to:
  /// **'My Details'**
  String get myDetails;

  /// No description provided for @notLoggedIn.
  ///
  /// In en, this message translates to:
  /// **'Not logged in'**
  String get notLoggedIn;

  /// No description provided for @editProfile.
  ///
  /// In en, this message translates to:
  /// **'Edit profile'**
  String get editProfile;

  /// No description provided for @subscription.
  ///
  /// In en, this message translates to:
  /// **'Subscription'**
  String get subscription;

  /// No description provided for @managePlan.
  ///
  /// In en, this message translates to:
  /// **'Manage your plan'**
  String get managePlan;

  /// No description provided for @changePassword.
  ///
  /// In en, this message translates to:
  /// **'Change Password'**
  String get changePassword;

  /// No description provided for @currentPassword.
  ///
  /// In en, this message translates to:
  /// **'Current Password'**
  String get currentPassword;

  /// No description provided for @showCurrentPassword.
  ///
  /// In en, this message translates to:
  /// **'Show current password'**
  String get showCurrentPassword;

  /// No description provided for @hideCurrentPassword.
  ///
  /// In en, this message translates to:
  /// **'Hide current password'**
  String get hideCurrentPassword;

  /// No description provided for @currentPasswordRequired.
  ///
  /// In en, this message translates to:
  /// **'Current password is required'**
  String get currentPasswordRequired;

  /// No description provided for @showNewPassword.
  ///
  /// In en, this message translates to:
  /// **'Show new password'**
  String get showNewPassword;

  /// No description provided for @hideNewPassword.
  ///
  /// In en, this message translates to:
  /// **'Hide new password'**
  String get hideNewPassword;

  /// No description provided for @newPasswordRequired.
  ///
  /// In en, this message translates to:
  /// **'New password is required'**
  String get newPasswordRequired;

  /// No description provided for @confirmNewPassword.
  ///
  /// In en, this message translates to:
  /// **'Confirm New Password'**
  String get confirmNewPassword;

  /// No description provided for @detailsVisibleToShared.
  ///
  /// In en, this message translates to:
  /// **'These details are visible to people you share pets with'**
  String get detailsVisibleToShared;

  /// No description provided for @profileUpdated.
  ///
  /// In en, this message translates to:
  /// **'Profile updated'**
  String get profileUpdated;

  /// No description provided for @failedToPickPhoto.
  ///
  /// In en, this message translates to:
  /// **'Failed to pick photo: {error}'**
  String failedToPickPhoto(String error);

  /// No description provided for @failedToSave.
  ///
  /// In en, this message translates to:
  /// **'Failed to save: {error}'**
  String failedToSave(String error);

  /// No description provided for @petGuardian.
  ///
  /// In en, this message translates to:
  /// **'Pet Guardian'**
  String get petGuardian;

  /// No description provided for @professionalMultiPet.
  ///
  /// In en, this message translates to:
  /// **'Professional Multi Pet'**
  String get professionalMultiPet;

  /// No description provided for @categoryLabel.
  ///
  /// In en, this message translates to:
  /// **'Category: {category}'**
  String categoryLabel(String category);

  /// No description provided for @firstName.
  ///
  /// In en, this message translates to:
  /// **'First Name'**
  String get firstName;

  /// No description provided for @lastName.
  ///
  /// In en, this message translates to:
  /// **'Last Name'**
  String get lastName;

  /// No description provided for @bio.
  ///
  /// In en, this message translates to:
  /// **'Bio'**
  String get bio;

  /// No description provided for @category.
  ///
  /// In en, this message translates to:
  /// **'Category'**
  String get category;

  /// No description provided for @save.
  ///
  /// In en, this message translates to:
  /// **'Save'**
  String get save;

  /// No description provided for @cancel.
  ///
  /// In en, this message translates to:
  /// **'Cancel'**
  String get cancel;

  /// No description provided for @delete.
  ///
  /// In en, this message translates to:
  /// **'Delete'**
  String get delete;

  /// No description provided for @edit.
  ///
  /// In en, this message translates to:
  /// **'Edit'**
  String get edit;

  /// No description provided for @close.
  ///
  /// In en, this message translates to:
  /// **'Close'**
  String get close;

  /// No description provided for @retry.
  ///
  /// In en, this message translates to:
  /// **'Retry'**
  String get retry;

  /// No description provided for @language.
  ///
  /// In en, this message translates to:
  /// **'Language'**
  String get language;

  /// No description provided for @english.
  ///
  /// In en, this message translates to:
  /// **'English'**
  String get english;

  /// No description provided for @french.
  ///
  /// In en, this message translates to:
  /// **'Français'**
  String get french;

  /// No description provided for @myPets.
  ///
  /// In en, this message translates to:
  /// **'My Pets'**
  String get myPets;

  /// No description provided for @allPets.
  ///
  /// In en, this message translates to:
  /// **'All Pets'**
  String get allPets;

  /// No description provided for @filterByOrganization.
  ///
  /// In en, this message translates to:
  /// **'Filter by organization'**
  String get filterByOrganization;

  /// No description provided for @notifications.
  ///
  /// In en, this message translates to:
  /// **'Notifications'**
  String get notifications;

  /// No description provided for @veterinarians.
  ///
  /// In en, this message translates to:
  /// **'Veterinarians'**
  String get veterinarians;

  /// No description provided for @events.
  ///
  /// In en, this message translates to:
  /// **'To Do'**
  String get events;

  /// No description provided for @userMenu.
  ///
  /// In en, this message translates to:
  /// **'User menu'**
  String get userMenu;

  /// No description provided for @addPet.
  ///
  /// In en, this message translates to:
  /// **'Add Pet'**
  String get addPet;

  /// No description provided for @addNewPet.
  ///
  /// In en, this message translates to:
  /// **'Add a new pet'**
  String get addNewPet;

  /// No description provided for @failedToLoadPets.
  ///
  /// In en, this message translates to:
  /// **'Failed to load pets: {error}'**
  String failedToLoadPets(String error);

  /// No description provided for @noPetsYet.
  ///
  /// In en, this message translates to:
  /// **'No pets yet'**
  String get noPetsYet;

  /// No description provided for @addFirstPet.
  ///
  /// In en, this message translates to:
  /// **'Tap + to add your first pet'**
  String get addFirstPet;

  /// No description provided for @petDetails.
  ///
  /// In en, this message translates to:
  /// **'Pet Details'**
  String get petDetails;

  /// No description provided for @petNotFound.
  ///
  /// In en, this message translates to:
  /// **'Pet not found'**
  String get petNotFound;

  /// No description provided for @errorWithMessage.
  ///
  /// In en, this message translates to:
  /// **'Error: {error}'**
  String errorWithMessage(String error);

  /// No description provided for @goBack.
  ///
  /// In en, this message translates to:
  /// **'Go back'**
  String get goBack;

  /// No description provided for @editPet.
  ///
  /// In en, this message translates to:
  /// **'Edit Pet'**
  String get editPet;

  /// No description provided for @neuteredSpayed.
  ///
  /// In en, this message translates to:
  /// **'Neutered / Spayed: {date}'**
  String neuteredSpayed(String date);

  /// No description provided for @idLabel.
  ///
  /// In en, this message translates to:
  /// **'ID: {id}'**
  String idLabel(String id);

  /// No description provided for @insuranceDetails.
  ///
  /// In en, this message translates to:
  /// **'Insurance Details'**
  String get insuranceDetails;

  /// No description provided for @noVetAssigned.
  ///
  /// In en, this message translates to:
  /// **'No vet assigned'**
  String get noVetAssigned;

  /// No description provided for @addVetFirst.
  ///
  /// In en, this message translates to:
  /// **'Add a veterinarian. No vets yet.'**
  String get addVetFirst;

  /// No description provided for @selectVeterinarian.
  ///
  /// In en, this message translates to:
  /// **'Select veterinarian'**
  String get selectVeterinarian;

  /// No description provided for @removeVet.
  ///
  /// In en, this message translates to:
  /// **'Remove vet'**
  String get removeVet;

  /// No description provided for @passedAway.
  ///
  /// In en, this message translates to:
  /// **'Passed Away'**
  String get passedAway;

  /// No description provided for @weightTracking.
  ///
  /// In en, this message translates to:
  /// **'Weight Tracking'**
  String get weightTracking;

  /// No description provided for @addEntry.
  ///
  /// In en, this message translates to:
  /// **'Add Health Event'**
  String get addEntry;

  /// No description provided for @errorLoadingWeightData.
  ///
  /// In en, this message translates to:
  /// **'Error loading weight data: {error}'**
  String errorLoadingWeightData(String error);

  /// No description provided for @noWeightDataYet.
  ///
  /// In en, this message translates to:
  /// **'No weight data yet'**
  String get noWeightDataYet;

  /// No description provided for @tapAddEntryToStart.
  ///
  /// In en, this message translates to:
  /// **'Tap \"Add Entry\" to start tracking'**
  String get tapAddEntryToStart;

  /// No description provided for @addWeightEntry.
  ///
  /// In en, this message translates to:
  /// **'Add Weight Entry'**
  String get addWeightEntry;

  /// No description provided for @selectDate.
  ///
  /// In en, this message translates to:
  /// **'Select date for weight entry'**
  String get selectDate;

  /// No description provided for @date.
  ///
  /// In en, this message translates to:
  /// **'Date'**
  String get date;

  /// No description provided for @weightWithUnit.
  ///
  /// In en, this message translates to:
  /// **'Weight ({unit})'**
  String weightWithUnit(String unit);

  /// No description provided for @notesOptional.
  ///
  /// In en, this message translates to:
  /// **'Notes (optional)'**
  String get notesOptional;

  /// No description provided for @pleaseEnterValidWeight.
  ///
  /// In en, this message translates to:
  /// **'Please enter a valid weight'**
  String get pleaseEnterValidWeight;

  /// No description provided for @deleteWeightEntry.
  ///
  /// In en, this message translates to:
  /// **'Delete weight entry'**
  String get deleteWeightEntry;

  /// No description provided for @weightChartLabel.
  ///
  /// In en, this message translates to:
  /// **'Weight chart showing {count} entries'**
  String weightChartLabel(int count);

  /// No description provided for @healthEvents.
  ///
  /// In en, this message translates to:
  /// **'Events'**
  String get healthEvents;

  /// No description provided for @addHealthEntry.
  ///
  /// In en, this message translates to:
  /// **'Add health entry'**
  String get addHealthEntry;

  /// No description provided for @noEntriesYet.
  ///
  /// In en, this message translates to:
  /// **'No entries yet'**
  String get noEntriesYet;

  /// No description provided for @noTypeEntriesYet.
  ///
  /// In en, this message translates to:
  /// **'No {type} entries yet'**
  String noTypeEntriesYet(String type);

  /// No description provided for @tapPlusToAdd.
  ///
  /// In en, this message translates to:
  /// **'Tap + to add one'**
  String get tapPlusToAdd;

  /// No description provided for @errorLoadingEntries.
  ///
  /// In en, this message translates to:
  /// **'Error loading entries:\n{error}'**
  String errorLoadingEntries(String error);

  /// No description provided for @all.
  ///
  /// In en, this message translates to:
  /// **'All'**
  String get all;

  /// No description provided for @medications.
  ///
  /// In en, this message translates to:
  /// **'Medications'**
  String get medications;

  /// No description provided for @preventives.
  ///
  /// In en, this message translates to:
  /// **'Preventives'**
  String get preventives;

  /// No description provided for @vetVisits.
  ///
  /// In en, this message translates to:
  /// **'Vet Visits'**
  String get vetVisits;

  /// No description provided for @other.
  ///
  /// In en, this message translates to:
  /// **'Other'**
  String get other;

  /// No description provided for @overdue.
  ///
  /// In en, this message translates to:
  /// **'Overdue'**
  String get overdue;

  /// No description provided for @today.
  ///
  /// In en, this message translates to:
  /// **'Today'**
  String get today;

  /// No description provided for @tomorrow.
  ///
  /// In en, this message translates to:
  /// **'Tomorrow'**
  String get tomorrow;

  /// No description provided for @thisWeek.
  ///
  /// In en, this message translates to:
  /// **'This Week'**
  String get thisWeek;

  /// No description provided for @later.
  ///
  /// In en, this message translates to:
  /// **'Later'**
  String get later;

  /// No description provided for @completed.
  ///
  /// In en, this message translates to:
  /// **'Completed'**
  String get completed;

  /// No description provided for @groupBy.
  ///
  /// In en, this message translates to:
  /// **'Group by'**
  String get groupBy;

  /// No description provided for @byDueDate.
  ///
  /// In en, this message translates to:
  /// **'By Due Date'**
  String get byDueDate;

  /// No description provided for @byPet.
  ///
  /// In en, this message translates to:
  /// **'By Pet'**
  String get byPet;

  /// No description provided for @bySpecies.
  ///
  /// In en, this message translates to:
  /// **'By Species'**
  String get bySpecies;

  /// No description provided for @exportPdf.
  ///
  /// In en, this message translates to:
  /// **'Export PDF'**
  String get exportPdf;

  /// No description provided for @exportCsv.
  ///
  /// In en, this message translates to:
  /// **'Export CSV'**
  String get exportCsv;

  /// No description provided for @csvExport.
  ///
  /// In en, this message translates to:
  /// **'CSV Export'**
  String get csvExport;

  /// No description provided for @exportFailed.
  ///
  /// In en, this message translates to:
  /// **'Export failed: {error}'**
  String exportFailed(String error);

  /// No description provided for @pdfExportFailed.
  ///
  /// In en, this message translates to:
  /// **'PDF export failed: {error}'**
  String pdfExportFailed(String error);

  /// No description provided for @markedAsDone.
  ///
  /// In en, this message translates to:
  /// **'{name} marked as done'**
  String markedAsDone(String name);

  /// No description provided for @snoozedForDays.
  ///
  /// In en, this message translates to:
  /// **'{name} snoozed for {days} {dayLabel}'**
  String snoozedForDays(String name, int days, String dayLabel);

  /// No description provided for @day.
  ///
  /// In en, this message translates to:
  /// **'day'**
  String get day;

  /// No description provided for @days.
  ///
  /// In en, this message translates to:
  /// **'days'**
  String get days;

  /// No description provided for @entryName.
  ///
  /// In en, this message translates to:
  /// **'Entry Name *'**
  String get entryName;

  /// No description provided for @entryNameRequired.
  ///
  /// In en, this message translates to:
  /// **'Name is required'**
  String get entryNameRequired;

  /// No description provided for @selectPet.
  ///
  /// In en, this message translates to:
  /// **'Select Pet *'**
  String get selectPet;

  /// No description provided for @petRequired.
  ///
  /// In en, this message translates to:
  /// **'Pet is required'**
  String get petRequired;

  /// No description provided for @entryType.
  ///
  /// In en, this message translates to:
  /// **'Type *'**
  String get entryType;

  /// No description provided for @medication.
  ///
  /// In en, this message translates to:
  /// **'Medication'**
  String get medication;

  /// No description provided for @preventive.
  ///
  /// In en, this message translates to:
  /// **'Preventive'**
  String get preventive;

  /// No description provided for @vetVisit.
  ///
  /// In en, this message translates to:
  /// **'Vet Visit'**
  String get vetVisit;

  /// No description provided for @procedure.
  ///
  /// In en, this message translates to:
  /// **'Other'**
  String get procedure;

  /// No description provided for @dosage.
  ///
  /// In en, this message translates to:
  /// **'Dosage'**
  String get dosage;

  /// No description provided for @frequency.
  ///
  /// In en, this message translates to:
  /// **'Frequency'**
  String get frequency;

  /// No description provided for @doesNotRepeat.
  ///
  /// In en, this message translates to:
  /// **'Does not repeat'**
  String get doesNotRepeat;

  /// No description provided for @daily.
  ///
  /// In en, this message translates to:
  /// **'Day'**
  String get daily;

  /// No description provided for @weekly.
  ///
  /// In en, this message translates to:
  /// **'Week'**
  String get weekly;

  /// No description provided for @monthly.
  ///
  /// In en, this message translates to:
  /// **'Month'**
  String get monthly;

  /// No description provided for @yearly.
  ///
  /// In en, this message translates to:
  /// **'Year'**
  String get yearly;

  /// No description provided for @custom.
  ///
  /// In en, this message translates to:
  /// **'Custom'**
  String get custom;

  /// No description provided for @every.
  ///
  /// In en, this message translates to:
  /// **'Every'**
  String get every;

  /// No description provided for @everyPeriod.
  ///
  /// In en, this message translates to:
  /// **'Every {period}'**
  String everyPeriod(String period);

  /// No description provided for @everyNPeriods.
  ///
  /// In en, this message translates to:
  /// **'Every {n} {periods}'**
  String everyNPeriods(int n, String periods);

  /// No description provided for @repeatEndDate.
  ///
  /// In en, this message translates to:
  /// **'Repeat End Date'**
  String get repeatEndDate;

  /// No description provided for @noEndDate.
  ///
  /// In en, this message translates to:
  /// **'No end date'**
  String get noEndDate;

  /// No description provided for @startDate.
  ///
  /// In en, this message translates to:
  /// **'Start Date'**
  String get startDate;

  /// No description provided for @nextDueDate.
  ///
  /// In en, this message translates to:
  /// **'Next Due Date'**
  String get nextDueDate;

  /// No description provided for @notes.
  ///
  /// In en, this message translates to:
  /// **'Notes'**
  String get notes;

  /// No description provided for @healthIssueOptional.
  ///
  /// In en, this message translates to:
  /// **'Health Issue (optional)'**
  String get healthIssueOptional;

  /// No description provided for @none.
  ///
  /// In en, this message translates to:
  /// **'None'**
  String get none;

  /// No description provided for @addHealthEntry2.
  ///
  /// In en, this message translates to:
  /// **'Add Entry'**
  String get addHealthEntry2;

  /// No description provided for @editEntry.
  ///
  /// In en, this message translates to:
  /// **'Edit Entry'**
  String get editEntry;

  /// No description provided for @saveEntry.
  ///
  /// In en, this message translates to:
  /// **'Save'**
  String get saveEntry;

  /// No description provided for @deleteEntry.
  ///
  /// In en, this message translates to:
  /// **'Delete Entry'**
  String get deleteEntry;

  /// No description provided for @deleteEntryConfirm.
  ///
  /// In en, this message translates to:
  /// **'Are you sure you want to delete this entry?'**
  String get deleteEntryConfirm;

  /// No description provided for @entryCreated.
  ///
  /// In en, this message translates to:
  /// **'Entry created'**
  String get entryCreated;

  /// No description provided for @entryUpdated.
  ///
  /// In en, this message translates to:
  /// **'Entry updated'**
  String get entryUpdated;

  /// No description provided for @entryDeleted.
  ///
  /// In en, this message translates to:
  /// **'Entry deleted'**
  String get entryDeleted;

  /// No description provided for @photos.
  ///
  /// In en, this message translates to:
  /// **'Photos'**
  String get photos;

  /// No description provided for @addPhoto.
  ///
  /// In en, this message translates to:
  /// **'Add photo'**
  String get addPhoto;

  /// No description provided for @upTo4Photos.
  ///
  /// In en, this message translates to:
  /// **'up to 4 pictures, max 2 MB'**
  String get upTo4Photos;

  /// No description provided for @removePhoto.
  ///
  /// In en, this message translates to:
  /// **'Remove photo'**
  String get removePhoto;

  /// No description provided for @failedToPickImage.
  ///
  /// In en, this message translates to:
  /// **'Failed to pick image'**
  String get failedToPickImage;

  /// No description provided for @done.
  ///
  /// In en, this message translates to:
  /// **'Done'**
  String get done;

  /// No description provided for @doneOn.
  ///
  /// In en, this message translates to:
  /// **'Done {date}'**
  String doneOn(String date);

  /// No description provided for @dueLabel.
  ///
  /// In en, this message translates to:
  /// **'Due {date}'**
  String dueLabel(String date);

  /// No description provided for @snooze.
  ///
  /// In en, this message translates to:
  /// **'Snooze'**
  String get snooze;

  /// No description provided for @snoozeEntry.
  ///
  /// In en, this message translates to:
  /// **'Snooze {name}'**
  String snoozeEntry(String name);

  /// No description provided for @snoozeDays.
  ///
  /// In en, this message translates to:
  /// **'{count} {label}'**
  String snoozeDays(int count, String label);

  /// No description provided for @markAsDone.
  ///
  /// In en, this message translates to:
  /// **'Mark as done'**
  String get markAsDone;

  /// No description provided for @sharing.
  ///
  /// In en, this message translates to:
  /// **'Sharing'**
  String get sharing;

  /// No description provided for @couldNotLoadSharingInfo.
  ///
  /// In en, this message translates to:
  /// **'Could not load sharing info'**
  String get couldNotLoadSharingInfo;

  /// No description provided for @sessionExpired.
  ///
  /// In en, this message translates to:
  /// **'Session expired. Please log in again.'**
  String get sessionExpired;

  /// No description provided for @shareLinkTitle.
  ///
  /// In en, this message translates to:
  /// **'Share Link'**
  String get shareLinkTitle;

  /// No description provided for @shareLinkDescription.
  ///
  /// In en, this message translates to:
  /// **'Share this link so others can view {petName}\'s profile:'**
  String shareLinkDescription(String petName);

  /// No description provided for @linkCopied.
  ///
  /// In en, this message translates to:
  /// **'Link copied to clipboard'**
  String get linkCopied;

  /// No description provided for @copy.
  ///
  /// In en, this message translates to:
  /// **'Copy'**
  String get copy;

  /// No description provided for @sharePet.
  ///
  /// In en, this message translates to:
  /// **'Share Pet'**
  String get sharePet;

  /// No description provided for @noOneHasAccess.
  ///
  /// In en, this message translates to:
  /// **'No one else has access yet'**
  String get noOneHasAccess;

  /// No description provided for @manageAccess.
  ///
  /// In en, this message translates to:
  /// **'Manage user access'**
  String get manageAccess;

  /// No description provided for @removeAccess.
  ///
  /// In en, this message translates to:
  /// **'Remove Access'**
  String get removeAccess;

  /// No description provided for @guardian.
  ///
  /// In en, this message translates to:
  /// **'Guardian'**
  String get guardian;

  /// No description provided for @viewOnly.
  ///
  /// In en, this message translates to:
  /// **'View Only'**
  String get viewOnly;

  /// No description provided for @roleLabel.
  ///
  /// In en, this message translates to:
  /// **'Role: {role}'**
  String roleLabel(String role);

  /// No description provided for @acceptAndAdd.
  ///
  /// In en, this message translates to:
  /// **'Accept & Add to My Pets'**
  String get acceptAndAdd;

  /// No description provided for @sharedBy.
  ///
  /// In en, this message translates to:
  /// **'Shared by'**
  String get sharedBy;

  /// No description provided for @healthIssues.
  ///
  /// In en, this message translates to:
  /// **'Health Issues'**
  String get healthIssues;

  /// No description provided for @addIssue.
  ///
  /// In en, this message translates to:
  /// **'Add Issue'**
  String get addIssue;

  /// No description provided for @editIssue.
  ///
  /// In en, this message translates to:
  /// **'Edit Issue'**
  String get editIssue;

  /// No description provided for @deleteIssue.
  ///
  /// In en, this message translates to:
  /// **'Delete Issue'**
  String get deleteIssue;

  /// No description provided for @deleteIssueConfirm.
  ///
  /// In en, this message translates to:
  /// **'Are you sure you want to delete this health issue?'**
  String get deleteIssueConfirm;

  /// No description provided for @issueTitle.
  ///
  /// In en, this message translates to:
  /// **'Title *'**
  String get issueTitle;

  /// No description provided for @issueTitleRequired.
  ///
  /// In en, this message translates to:
  /// **'Title is required'**
  String get issueTitleRequired;

  /// No description provided for @issueDescription.
  ///
  /// In en, this message translates to:
  /// **'Description'**
  String get issueDescription;

  /// No description provided for @create.
  ///
  /// In en, this message translates to:
  /// **'Create'**
  String get create;

  /// No description provided for @update.
  ///
  /// In en, this message translates to:
  /// **'Update'**
  String get update;

  /// No description provided for @nEvents.
  ///
  /// In en, this message translates to:
  /// **'{count} event(s)'**
  String nEvents(int count);

  /// No description provided for @startDateOptional.
  ///
  /// In en, this message translates to:
  /// **'Start Date'**
  String get startDateOptional;

  /// No description provided for @endDateOptional.
  ///
  /// In en, this message translates to:
  /// **'End Date'**
  String get endDateOptional;

  /// No description provided for @linkedEvents.
  ///
  /// In en, this message translates to:
  /// **'Linked Events'**
  String get linkedEvents;

  /// No description provided for @noLinkedEvents.
  ///
  /// In en, this message translates to:
  /// **'No linked events'**
  String get noLinkedEvents;

  /// No description provided for @addPetTitle.
  ///
  /// In en, this message translates to:
  /// **'Add Pet'**
  String get addPetTitle;

  /// No description provided for @editPetTitle.
  ///
  /// In en, this message translates to:
  /// **'Edit Pet'**
  String get editPetTitle;

  /// No description provided for @petName.
  ///
  /// In en, this message translates to:
  /// **'Name *'**
  String get petName;

  /// No description provided for @petNameRequired.
  ///
  /// In en, this message translates to:
  /// **'Name is required'**
  String get petNameRequired;

  /// No description provided for @species.
  ///
  /// In en, this message translates to:
  /// **'Species *'**
  String get species;

  /// No description provided for @speciesRequired.
  ///
  /// In en, this message translates to:
  /// **'Species is required'**
  String get speciesRequired;

  /// No description provided for @breed.
  ///
  /// In en, this message translates to:
  /// **'Breed'**
  String get breed;

  /// No description provided for @gender.
  ///
  /// In en, this message translates to:
  /// **'Gender'**
  String get gender;

  /// No description provided for @male.
  ///
  /// In en, this message translates to:
  /// **'Male'**
  String get male;

  /// No description provided for @female.
  ///
  /// In en, this message translates to:
  /// **'Female'**
  String get female;

  /// No description provided for @dateOfBirth.
  ///
  /// In en, this message translates to:
  /// **'Date of Birth'**
  String get dateOfBirth;

  /// No description provided for @weight.
  ///
  /// In en, this message translates to:
  /// **'Weight'**
  String get weight;

  /// No description provided for @petBio.
  ///
  /// In en, this message translates to:
  /// **'Bio'**
  String get petBio;

  /// No description provided for @insurance.
  ///
  /// In en, this message translates to:
  /// **'Insurance'**
  String get insurance;

  /// No description provided for @savePet.
  ///
  /// In en, this message translates to:
  /// **'Save Pet'**
  String get savePet;

  /// No description provided for @deletePet.
  ///
  /// In en, this message translates to:
  /// **'Delete Pet'**
  String get deletePet;

  /// No description provided for @deletePetConfirm.
  ///
  /// In en, this message translates to:
  /// **'Are you sure you want to delete {name}? This cannot be undone.'**
  String deletePetConfirm(String name);

  /// No description provided for @petDeleted.
  ///
  /// In en, this message translates to:
  /// **'{name} deleted'**
  String petDeleted(String name);

  /// No description provided for @neuteredSpayedDate.
  ///
  /// In en, this message translates to:
  /// **'Neutered / Spayed Date'**
  String get neuteredSpayedDate;

  /// No description provided for @idMicrochip.
  ///
  /// In en, this message translates to:
  /// **'ID / Microchip'**
  String get idMicrochip;

  /// No description provided for @speciesDog.
  ///
  /// In en, this message translates to:
  /// **'Dog'**
  String get speciesDog;

  /// No description provided for @speciesCat.
  ///
  /// In en, this message translates to:
  /// **'Cat'**
  String get speciesCat;

  /// No description provided for @speciesBird.
  ///
  /// In en, this message translates to:
  /// **'Bird'**
  String get speciesBird;

  /// No description provided for @speciesFish.
  ///
  /// In en, this message translates to:
  /// **'Fish'**
  String get speciesFish;

  /// No description provided for @speciesRabbit.
  ///
  /// In en, this message translates to:
  /// **'Rabbit'**
  String get speciesRabbit;

  /// No description provided for @speciesHamster.
  ///
  /// In en, this message translates to:
  /// **'Hamster'**
  String get speciesHamster;

  /// No description provided for @speciesFerret.
  ///
  /// In en, this message translates to:
  /// **'Ferret'**
  String get speciesFerret;

  /// No description provided for @speciesHorsePoney.
  ///
  /// In en, this message translates to:
  /// **'Horse / Poney'**
  String get speciesHorsePoney;

  /// No description provided for @speciesOther.
  ///
  /// In en, this message translates to:
  /// **'Other'**
  String get speciesOther;

  /// No description provided for @notificationSettings.
  ///
  /// In en, this message translates to:
  /// **'Notification Settings'**
  String get notificationSettings;

  /// No description provided for @inAppNotifications.
  ///
  /// In en, this message translates to:
  /// **'In-App Notifications'**
  String get inAppNotifications;

  /// No description provided for @overdueAlerts.
  ///
  /// In en, this message translates to:
  /// **'Overdue Alerts'**
  String get overdueAlerts;

  /// No description provided for @dueSoonAlerts.
  ///
  /// In en, this message translates to:
  /// **'Due Soon Alerts'**
  String get dueSoonAlerts;

  /// No description provided for @completedAlerts.
  ///
  /// In en, this message translates to:
  /// **'Completed Alerts'**
  String get completedAlerts;

  /// No description provided for @emailReminders.
  ///
  /// In en, this message translates to:
  /// **'Email Reminders'**
  String get emailReminders;

  /// No description provided for @emailNotifications.
  ///
  /// In en, this message translates to:
  /// **'Email Notifications'**
  String get emailNotifications;

  /// No description provided for @reminderDaysBefore.
  ///
  /// In en, this message translates to:
  /// **'Reminder Days Before'**
  String get reminderDaysBefore;

  /// No description provided for @mutedPets.
  ///
  /// In en, this message translates to:
  /// **'Muted Pets'**
  String get mutedPets;

  /// No description provided for @saveSettings.
  ///
  /// In en, this message translates to:
  /// **'Save Settings'**
  String get saveSettings;

  /// No description provided for @settingsSaved.
  ///
  /// In en, this message translates to:
  /// **'Settings saved'**
  String get settingsSaved;

  /// No description provided for @noNotifications.
  ///
  /// In en, this message translates to:
  /// **'No notifications'**
  String get noNotifications;

  /// No description provided for @markAllRead.
  ///
  /// In en, this message translates to:
  /// **'Mark all as read'**
  String get markAllRead;

  /// No description provided for @notificationSettingsTooltip.
  ///
  /// In en, this message translates to:
  /// **'Notification settings'**
  String get notificationSettingsTooltip;

  /// No description provided for @dueSoonAlertsLabel.
  ///
  /// In en, this message translates to:
  /// **'Due Soon Alerts'**
  String get dueSoonAlertsLabel;

  /// No description provided for @generalLabel.
  ///
  /// In en, this message translates to:
  /// **'General'**
  String get generalLabel;

  /// No description provided for @addVet.
  ///
  /// In en, this message translates to:
  /// **'Add Vet'**
  String get addVet;

  /// No description provided for @editVet.
  ///
  /// In en, this message translates to:
  /// **'Edit Vet'**
  String get editVet;

  /// No description provided for @addNewVet.
  ///
  /// In en, this message translates to:
  /// **'Add a new veterinarian'**
  String get addNewVet;

  /// No description provided for @backToVets.
  ///
  /// In en, this message translates to:
  /// **'Back to veterinarians'**
  String get backToVets;

  /// No description provided for @vetName.
  ///
  /// In en, this message translates to:
  /// **'Name *'**
  String get vetName;

  /// No description provided for @vetNameRequired.
  ///
  /// In en, this message translates to:
  /// **'Name is required'**
  String get vetNameRequired;

  /// No description provided for @phone.
  ///
  /// In en, this message translates to:
  /// **'Phone'**
  String get phone;

  /// No description provided for @vetEmail.
  ///
  /// In en, this message translates to:
  /// **'Email'**
  String get vetEmail;

  /// No description provided for @website.
  ///
  /// In en, this message translates to:
  /// **'Website'**
  String get website;

  /// No description provided for @address.
  ///
  /// In en, this message translates to:
  /// **'Address'**
  String get address;

  /// No description provided for @vetNotes.
  ///
  /// In en, this message translates to:
  /// **'Notes'**
  String get vetNotes;

  /// No description provided for @deleteVet.
  ///
  /// In en, this message translates to:
  /// **'Delete Vet'**
  String get deleteVet;

  /// No description provided for @deleteVetConfirm.
  ///
  /// In en, this message translates to:
  /// **'Are you sure you want to delete {name}?'**
  String deleteVetConfirm(String name);

  /// No description provided for @noVetsYet.
  ///
  /// In en, this message translates to:
  /// **'No veterinarians yet'**
  String get noVetsYet;

  /// No description provided for @failedToLoadVets.
  ///
  /// In en, this message translates to:
  /// **'Failed to load vets: {error}'**
  String failedToLoadVets(String error);

  /// No description provided for @failedToLoadVet.
  ///
  /// In en, this message translates to:
  /// **'Failed to load vet: {error}'**
  String failedToLoadVet(String error);

  /// No description provided for @vetOptions.
  ///
  /// In en, this message translates to:
  /// **'Vet options'**
  String get vetOptions;

  /// No description provided for @linkedPets.
  ///
  /// In en, this message translates to:
  /// **'Linked Pets'**
  String get linkedPets;

  /// No description provided for @couldNotLoadPets.
  ///
  /// In en, this message translates to:
  /// **'Could not load pets: {error}'**
  String couldNotLoadPets(String error);

  /// No description provided for @noPetsAddFirst.
  ///
  /// In en, this message translates to:
  /// **'No pets yet. Add pets first to link them.'**
  String get noPetsAddFirst;

  /// No description provided for @unlink.
  ///
  /// In en, this message translates to:
  /// **'Unlink'**
  String get unlink;

  /// No description provided for @link.
  ///
  /// In en, this message translates to:
  /// **'Link'**
  String get link;

  /// No description provided for @availablePets.
  ///
  /// In en, this message translates to:
  /// **'Available pets:'**
  String get availablePets;

  /// No description provided for @subscriptionTitle.
  ///
  /// In en, this message translates to:
  /// **'Subscription'**
  String get subscriptionTitle;

  /// No description provided for @welcomeUnlimited.
  ///
  /// In en, this message translates to:
  /// **'Welcome to Agatha Track Unlimited!'**
  String get welcomeUnlimited;

  /// No description provided for @purchaseFailed.
  ///
  /// In en, this message translates to:
  /// **'Purchase failed: {error}'**
  String purchaseFailed(String error);

  /// No description provided for @purchasesRestored.
  ///
  /// In en, this message translates to:
  /// **'Purchases restored successfully'**
  String get purchasesRestored;

  /// No description provided for @couldNotRestore.
  ///
  /// In en, this message translates to:
  /// **'Could not restore purchases: {error}'**
  String couldNotRestore(String error);

  /// No description provided for @restorePurchases.
  ///
  /// In en, this message translates to:
  /// **'Restore Purchases'**
  String get restorePurchases;

  /// No description provided for @manageSubscription.
  ///
  /// In en, this message translates to:
  /// **'Manage Subscription'**
  String get manageSubscription;

  /// No description provided for @subscribe.
  ///
  /// In en, this message translates to:
  /// **'Subscribe'**
  String get subscribe;

  /// No description provided for @loadPlans.
  ///
  /// In en, this message translates to:
  /// **'Load Plans'**
  String get loadPlans;

  /// No description provided for @petReport.
  ///
  /// In en, this message translates to:
  /// **'Pet Report'**
  String get petReport;

  /// No description provided for @chooseSections.
  ///
  /// In en, this message translates to:
  /// **'Choose which sections to include'**
  String get chooseSections;

  /// No description provided for @petProfile.
  ///
  /// In en, this message translates to:
  /// **'Pet Profile'**
  String get petProfile;

  /// No description provided for @basicInfoVet.
  ///
  /// In en, this message translates to:
  /// **'Basic info, vet details'**
  String get basicInfoVet;

  /// No description provided for @chartAndDataTable.
  ///
  /// In en, this message translates to:
  /// **'Chart and data table'**
  String get chartAndDataTable;

  /// No description provided for @medicationsPreventivesVetVisits.
  ///
  /// In en, this message translates to:
  /// **'Medications, preventives, vet visits'**
  String get medicationsPreventivesVetVisits;

  /// No description provided for @includeFullLog.
  ///
  /// In en, this message translates to:
  /// **'Include full log for each event'**
  String get includeFullLog;

  /// No description provided for @ongoingConditions.
  ///
  /// In en, this message translates to:
  /// **'Ongoing conditions and linked events'**
  String get ongoingConditions;

  /// No description provided for @sharingSection.
  ///
  /// In en, this message translates to:
  /// **'Sharing'**
  String get sharingSection;

  /// No description provided for @accessListAndRoles.
  ///
  /// In en, this message translates to:
  /// **'Access list and roles'**
  String get accessListAndRoles;

  /// No description provided for @downloadReport.
  ///
  /// In en, this message translates to:
  /// **'Download Report'**
  String get downloadReport;

  /// No description provided for @downloadPetReport.
  ///
  /// In en, this message translates to:
  /// **'Download Pet Report'**
  String get downloadPetReport;

  /// No description provided for @generating.
  ///
  /// In en, this message translates to:
  /// **'Generating...'**
  String get generating;

  /// No description provided for @reportGenerated.
  ///
  /// In en, this message translates to:
  /// **'Report downloaded'**
  String get reportGenerated;

  /// No description provided for @reportFailed.
  ///
  /// In en, this message translates to:
  /// **'Report failed: {error}'**
  String reportFailed(String error);

  /// No description provided for @passedAwayConfirmTitle.
  ///
  /// In en, this message translates to:
  /// **'Mark as Passed Away'**
  String get passedAwayConfirmTitle;

  /// No description provided for @passedAwayConfirmMessage.
  ///
  /// In en, this message translates to:
  /// **'Are you sure you want to mark {name} as having crossed the rainbow bridge?'**
  String passedAwayConfirmMessage(String name);

  /// No description provided for @passedAwayCondolence.
  ///
  /// In en, this message translates to:
  /// **'We are so sorry for your loss. {name}\'s profile will be kept as a loving memorial.'**
  String passedAwayCondolence(String name);

  /// No description provided for @confirm.
  ///
  /// In en, this message translates to:
  /// **'Confirm'**
  String get confirm;

  /// No description provided for @ok.
  ///
  /// In en, this message translates to:
  /// **'OK'**
  String get ok;

  /// No description provided for @reminderSnooze.
  ///
  /// In en, this message translates to:
  /// **'Reminder snoozed. We\'ll remind you again later.'**
  String get reminderSnooze;

  /// No description provided for @dontWantToNeuter.
  ///
  /// In en, this message translates to:
  /// **'I don\'t want to neuter'**
  String get dontWantToNeuter;

  /// No description provided for @dontWantToChip.
  ///
  /// In en, this message translates to:
  /// **'I don\'t want to chip / identify my pet'**
  String get dontWantToChip;

  /// No description provided for @chipReminderDog.
  ///
  /// In en, this message translates to:
  /// **'Microchipping is recommended for dogs. It\'s a simple procedure that helps reunite you if your pet gets lost.'**
  String get chipReminderDog;

  /// No description provided for @chipReminderCat.
  ///
  /// In en, this message translates to:
  /// **'Microchipping is recommended for cats. It helps identify your cat and reunite you if they wander off.'**
  String get chipReminderCat;

  /// No description provided for @chipReminderFerret.
  ///
  /// In en, this message translates to:
  /// **'Microchipping is recommended for ferrets. It helps identify your pet if they escape.'**
  String get chipReminderFerret;

  /// No description provided for @chipReminderRabbit.
  ///
  /// In en, this message translates to:
  /// **'Microchipping is recommended for rabbits. It provides a permanent form of identification.'**
  String get chipReminderRabbit;

  /// No description provided for @chipReminderHorse.
  ///
  /// In en, this message translates to:
  /// **'A passport is recommended for horses and ponies. It\'s a legal requirement in many countries.'**
  String get chipReminderHorse;

  /// No description provided for @chipReminderBird.
  ///
  /// In en, this message translates to:
  /// **'A leg ring is recommended for birds. It helps identify your bird if they fly away.'**
  String get chipReminderBird;

  /// No description provided for @chipReminderFish.
  ///
  /// In en, this message translates to:
  /// **'A tank label is recommended for fish tanks. It helps track species and care requirements.'**
  String get chipReminderFish;

  /// No description provided for @chipReminderHamster.
  ///
  /// In en, this message translates to:
  /// **'A photo ID record is recommended for hamsters. Keep a photo for identification purposes.'**
  String get chipReminderHamster;

  /// No description provided for @chipReminderDefault.
  ///
  /// In en, this message translates to:
  /// **'An identification method is recommended for your pet.'**
  String get chipReminderDefault;

  /// No description provided for @neuterReminderTitle.
  ///
  /// In en, this message translates to:
  /// **'Neutering Reminder'**
  String get neuterReminderTitle;

  /// No description provided for @chipReminderTitle.
  ///
  /// In en, this message translates to:
  /// **'Identification Reminder'**
  String get chipReminderTitle;

  /// No description provided for @pdfEventsChecklist.
  ///
  /// In en, this message translates to:
  /// **'Events Checklist'**
  String get pdfEventsChecklist;

  /// No description provided for @pdfAllEvents.
  ///
  /// In en, this message translates to:
  /// **'All Events'**
  String get pdfAllEvents;

  /// No description provided for @pdfGroupedBy.
  ///
  /// In en, this message translates to:
  /// **'{filter}  •  Grouped {group}'**
  String pdfGroupedBy(String filter, String group);

  /// No description provided for @pdfNoEventsToDisplay.
  ///
  /// In en, this message translates to:
  /// **'No events to display.'**
  String get pdfNoEventsToDisplay;

  /// No description provided for @pdfGeneratedBy.
  ///
  /// In en, this message translates to:
  /// **'Generated {date} by Agatha Track'**
  String pdfGeneratedBy(String date);

  /// No description provided for @pdfPageOf.
  ///
  /// In en, this message translates to:
  /// **'Page {current} of {total}'**
  String pdfPageOf(int current, int total);

  /// No description provided for @pdfPetLabel.
  ///
  /// In en, this message translates to:
  /// **'Pet'**
  String get pdfPetLabel;

  /// No description provided for @pdfDueLabel.
  ///
  /// In en, this message translates to:
  /// **'Due'**
  String get pdfDueLabel;

  /// No description provided for @pdfFreqLabel.
  ///
  /// In en, this message translates to:
  /// **'Freq'**
  String get pdfFreqLabel;

  /// No description provided for @pdfNotesLabel.
  ///
  /// In en, this message translates to:
  /// **'Notes'**
  String get pdfNotesLabel;

  /// No description provided for @pdfIssueLabel.
  ///
  /// In en, this message translates to:
  /// **'Issue'**
  String get pdfIssueLabel;

  /// No description provided for @pdfOnce.
  ///
  /// In en, this message translates to:
  /// **'Once'**
  String get pdfOnce;

  /// No description provided for @pdfDone.
  ///
  /// In en, this message translates to:
  /// **'Done'**
  String get pdfDone;

  /// No description provided for @pdfReportTitle.
  ///
  /// In en, this message translates to:
  /// **'Pet Health Report'**
  String get pdfReportTitle;

  /// No description provided for @pdfAgathaCheck.
  ///
  /// In en, this message translates to:
  /// **'AGATHA TRACK'**
  String get pdfAgathaCheck;

  /// No description provided for @pdfPetProfileSection.
  ///
  /// In en, this message translates to:
  /// **'Pet Profile'**
  String get pdfPetProfileSection;

  /// No description provided for @pdfWeightTrackingSection.
  ///
  /// In en, this message translates to:
  /// **'Weight Tracking'**
  String get pdfWeightTrackingSection;

  /// No description provided for @pdfHealthEventsSection.
  ///
  /// In en, this message translates to:
  /// **'Health Events'**
  String get pdfHealthEventsSection;

  /// No description provided for @pdfHealthIssuesSection.
  ///
  /// In en, this message translates to:
  /// **'Health Issues'**
  String get pdfHealthIssuesSection;

  /// No description provided for @pdfSharingSection.
  ///
  /// In en, this message translates to:
  /// **'Sharing'**
  String get pdfSharingSection;

  /// No description provided for @pdfNoWeightData.
  ///
  /// In en, this message translates to:
  /// **'No weight data recorded yet.'**
  String get pdfNoWeightData;

  /// No description provided for @pdfNoHealthEvents.
  ///
  /// In en, this message translates to:
  /// **'No health events recorded yet.'**
  String get pdfNoHealthEvents;

  /// No description provided for @pdfNoHealthIssues.
  ///
  /// In en, this message translates to:
  /// **'No health issues recorded yet.'**
  String get pdfNoHealthIssues;

  /// No description provided for @pdfCurrentRecurring.
  ///
  /// In en, this message translates to:
  /// **'Current & Recurring Events'**
  String get pdfCurrentRecurring;

  /// No description provided for @pdfEventsFromTo.
  ///
  /// In en, this message translates to:
  /// **'Events from {from} to {to}'**
  String pdfEventsFromTo(String from, String to);

  /// No description provided for @pdfNoEventsInPeriod.
  ///
  /// In en, this message translates to:
  /// **'No events in this period.'**
  String get pdfNoEventsInPeriod;

  /// No description provided for @pdfAdminLog.
  ///
  /// In en, this message translates to:
  /// **'Administration Log'**
  String get pdfAdminLog;

  /// No description provided for @pdfName.
  ///
  /// In en, this message translates to:
  /// **'Name'**
  String get pdfName;

  /// No description provided for @pdfSpecies.
  ///
  /// In en, this message translates to:
  /// **'Species'**
  String get pdfSpecies;

  /// No description provided for @pdfBreed.
  ///
  /// In en, this message translates to:
  /// **'Breed'**
  String get pdfBreed;

  /// No description provided for @pdfGender.
  ///
  /// In en, this message translates to:
  /// **'Gender'**
  String get pdfGender;

  /// No description provided for @pdfAge.
  ///
  /// In en, this message translates to:
  /// **'Age'**
  String get pdfAge;

  /// No description provided for @pdfDateOfBirth.
  ///
  /// In en, this message translates to:
  /// **'Date of Birth'**
  String get pdfDateOfBirth;

  /// No description provided for @pdfCurrentWeight.
  ///
  /// In en, this message translates to:
  /// **'Current Weight'**
  String get pdfCurrentWeight;

  /// No description provided for @pdfBio.
  ///
  /// In en, this message translates to:
  /// **'Bio'**
  String get pdfBio;

  /// No description provided for @pdfNeuteredSpayed.
  ///
  /// In en, this message translates to:
  /// **'Neutered / Spayed'**
  String get pdfNeuteredSpayed;

  /// No description provided for @pdfIdMicrochip.
  ///
  /// In en, this message translates to:
  /// **'ID / Microchip'**
  String get pdfIdMicrochip;

  /// No description provided for @pdfInsurance.
  ///
  /// In en, this message translates to:
  /// **'Insurance Details'**
  String get pdfInsurance;

  /// No description provided for @pdfVet.
  ///
  /// In en, this message translates to:
  /// **'Vet'**
  String get pdfVet;

  /// No description provided for @pdfDate.
  ///
  /// In en, this message translates to:
  /// **'Date'**
  String get pdfDate;

  /// No description provided for @pdfWeight.
  ///
  /// In en, this message translates to:
  /// **'Weight'**
  String get pdfWeight;

  /// No description provided for @pdfNotes.
  ///
  /// In en, this message translates to:
  /// **'Notes'**
  String get pdfNotes;

  /// No description provided for @pdfType.
  ///
  /// In en, this message translates to:
  /// **'Type'**
  String get pdfType;

  /// No description provided for @pdfFrequency.
  ///
  /// In en, this message translates to:
  /// **'Frequency'**
  String get pdfFrequency;

  /// No description provided for @pdfNextDue.
  ///
  /// In en, this message translates to:
  /// **'Next Due'**
  String get pdfNextDue;

  /// No description provided for @pdfDosage.
  ///
  /// In en, this message translates to:
  /// **'Dosage'**
  String get pdfDosage;

  /// No description provided for @pdfStart.
  ///
  /// In en, this message translates to:
  /// **'Start'**
  String get pdfStart;

  /// No description provided for @pdfDue.
  ///
  /// In en, this message translates to:
  /// **'Due'**
  String get pdfDue;

  /// No description provided for @pdfCompleted.
  ///
  /// In en, this message translates to:
  /// **'Completed'**
  String get pdfCompleted;

  /// No description provided for @pdfNotShared.
  ///
  /// In en, this message translates to:
  /// **'This pet is not shared with anyone.'**
  String get pdfNotShared;

  /// No description provided for @pdfRole.
  ///
  /// In en, this message translates to:
  /// **'Role'**
  String get pdfRole;

  /// No description provided for @pdfSince.
  ///
  /// In en, this message translates to:
  /// **'Since'**
  String get pdfSince;

  /// No description provided for @pdfGuardian.
  ///
  /// In en, this message translates to:
  /// **'Guardian'**
  String get pdfGuardian;

  /// No description provided for @pdfShared.
  ///
  /// In en, this message translates to:
  /// **'Shared'**
  String get pdfShared;

  /// No description provided for @pdfUserNumber.
  ///
  /// In en, this message translates to:
  /// **'User #{id}'**
  String pdfUserNumber(String id);

  /// No description provided for @pdfNEvent.
  ///
  /// In en, this message translates to:
  /// **'{count} event'**
  String pdfNEvent(int count);

  /// No description provided for @pdfNEvents.
  ///
  /// In en, this message translates to:
  /// **'{count} events'**
  String pdfNEvents(int count);

  /// No description provided for @pdfFrom.
  ///
  /// In en, this message translates to:
  /// **'From {date}'**
  String pdfFrom(String date);

  /// No description provided for @pdfUntil.
  ///
  /// In en, this message translates to:
  /// **'Until {date}'**
  String pdfUntil(String date);

  /// No description provided for @pdfLinkedEvents.
  ///
  /// In en, this message translates to:
  /// **'Linked Events'**
  String get pdfLinkedEvents;

  /// No description provided for @pdfCustom.
  ///
  /// In en, this message translates to:
  /// **'Custom'**
  String get pdfCustom;

  /// No description provided for @pdfEvery.
  ///
  /// In en, this message translates to:
  /// **'Every {period}'**
  String pdfEvery(String period);

  /// No description provided for @pdfEveryN.
  ///
  /// In en, this message translates to:
  /// **'Every {n} {periods}'**
  String pdfEveryN(int n, String periods);

  /// No description provided for @pdfFamilyEventsSection.
  ///
  /// In en, this message translates to:
  /// **'Family Events'**
  String get pdfFamilyEventsSection;

  /// No description provided for @pdfNoFamilyEvents.
  ///
  /// In en, this message translates to:
  /// **'No family events recorded for this pet.'**
  String get pdfNoFamilyEvents;

  /// No description provided for @pdfAssignedTo.
  ///
  /// In en, this message translates to:
  /// **'Assigned To'**
  String get pdfAssignedTo;

  /// No description provided for @pdfFromDate.
  ///
  /// In en, this message translates to:
  /// **'From'**
  String get pdfFromDate;

  /// No description provided for @pdfToDate.
  ///
  /// In en, this message translates to:
  /// **'To'**
  String get pdfToDate;

  /// No description provided for @pdfOngoing.
  ///
  /// In en, this message translates to:
  /// **'Ongoing'**
  String get pdfOngoing;

  /// No description provided for @pdfNotificationsSection.
  ///
  /// In en, this message translates to:
  /// **'Notifications'**
  String get pdfNotificationsSection;

  /// No description provided for @pdfNoNotifications.
  ///
  /// In en, this message translates to:
  /// **'No recent notifications for this pet.'**
  String get pdfNoNotifications;

  /// No description provided for @pdfNotificationType.
  ///
  /// In en, this message translates to:
  /// **'Type'**
  String get pdfNotificationType;

  /// No description provided for @pdfNotificationMessage.
  ///
  /// In en, this message translates to:
  /// **'Message'**
  String get pdfNotificationMessage;

  /// No description provided for @familyEventsSection.
  ///
  /// In en, this message translates to:
  /// **'Family Events'**
  String get familyEventsSection;

  /// No description provided for @familyEventsDesc.
  ///
  /// In en, this message translates to:
  /// **'Care assignments and foster stays'**
  String get familyEventsDesc;

  /// No description provided for @notificationsSection.
  ///
  /// In en, this message translates to:
  /// **'Notifications'**
  String get notificationsSection;

  /// No description provided for @notificationsDesc.
  ///
  /// In en, this message translates to:
  /// **'Recent alerts and reminders'**
  String get notificationsDesc;

  /// No description provided for @myOrganizations.
  ///
  /// In en, this message translates to:
  /// **'My Organizations'**
  String get myOrganizations;

  /// No description provided for @organizations.
  ///
  /// In en, this message translates to:
  /// **'Organizations'**
  String get organizations;

  /// No description provided for @createOrganization.
  ///
  /// In en, this message translates to:
  /// **'Create Organization'**
  String get createOrganization;

  /// No description provided for @editOrganization.
  ///
  /// In en, this message translates to:
  /// **'Edit Organization'**
  String get editOrganization;

  /// No description provided for @deleteOrganization.
  ///
  /// In en, this message translates to:
  /// **'Delete Organization'**
  String get deleteOrganization;

  /// No description provided for @organizationName.
  ///
  /// In en, this message translates to:
  /// **'Organization Name'**
  String get organizationName;

  /// No description provided for @organizationType.
  ///
  /// In en, this message translates to:
  /// **'Type'**
  String get organizationType;

  /// No description provided for @orgTypeProfessional.
  ///
  /// In en, this message translates to:
  /// **'Professional'**
  String get orgTypeProfessional;

  /// No description provided for @orgTypeCharity.
  ///
  /// In en, this message translates to:
  /// **'Charity'**
  String get orgTypeCharity;

  /// No description provided for @orgEmail.
  ///
  /// In en, this message translates to:
  /// **'Email'**
  String get orgEmail;

  /// No description provided for @orgPhone.
  ///
  /// In en, this message translates to:
  /// **'Phone'**
  String get orgPhone;

  /// No description provided for @orgAddress.
  ///
  /// In en, this message translates to:
  /// **'Address'**
  String get orgAddress;

  /// No description provided for @orgWebsite.
  ///
  /// In en, this message translates to:
  /// **'Website'**
  String get orgWebsite;

  /// No description provided for @orgBio.
  ///
  /// In en, this message translates to:
  /// **'Bio'**
  String get orgBio;

  /// No description provided for @orgMembers.
  ///
  /// In en, this message translates to:
  /// **'Members'**
  String get orgMembers;

  /// No description provided for @orgPets.
  ///
  /// In en, this message translates to:
  /// **'Pets'**
  String get orgPets;

  /// No description provided for @orgArchived.
  ///
  /// In en, this message translates to:
  /// **'Archived Pets'**
  String get orgArchived;

  /// No description provided for @orgNoOrganizations.
  ///
  /// In en, this message translates to:
  /// **'No organizations yet'**
  String get orgNoOrganizations;

  /// No description provided for @orgCreateFirst.
  ///
  /// In en, this message translates to:
  /// **'Create your first organization to get started'**
  String get orgCreateFirst;

  /// No description provided for @createOrJoinOrganization.
  ///
  /// In en, this message translates to:
  /// **'Create or Join an organization'**
  String get createOrJoinOrganization;

  /// No description provided for @joinOrganization.
  ///
  /// In en, this message translates to:
  /// **'Join Organization'**
  String get joinOrganization;

  /// No description provided for @enterInviteCode.
  ///
  /// In en, this message translates to:
  /// **'Enter the invite code you received'**
  String get enterInviteCode;

  /// No description provided for @inviteCode.
  ///
  /// In en, this message translates to:
  /// **'Invite code'**
  String get inviteCode;

  /// No description provided for @joinSuccess.
  ///
  /// In en, this message translates to:
  /// **'Successfully joined the organization'**
  String get joinSuccess;

  /// No description provided for @join.
  ///
  /// In en, this message translates to:
  /// **'Join'**
  String get join;

  /// No description provided for @orgSuperUser.
  ///
  /// In en, this message translates to:
  /// **'Super User'**
  String get orgSuperUser;

  /// No description provided for @orgMember.
  ///
  /// In en, this message translates to:
  /// **'Member'**
  String get orgMember;

  /// No description provided for @orgInviteMember.
  ///
  /// In en, this message translates to:
  /// **'Invite Member'**
  String get orgInviteMember;

  /// No description provided for @orgInviteLinkCopied.
  ///
  /// In en, this message translates to:
  /// **'Invite link copied to clipboard'**
  String get orgInviteLinkCopied;

  /// No description provided for @orgInviteExpiry.
  ///
  /// In en, this message translates to:
  /// **'This invite link expires in 7 days'**
  String get orgInviteExpiry;

  /// No description provided for @orgJoinSuccess.
  ///
  /// In en, this message translates to:
  /// **'Successfully joined organization'**
  String get orgJoinSuccess;

  /// No description provided for @orgLeave.
  ///
  /// In en, this message translates to:
  /// **'Leave Organization'**
  String get orgLeave;

  /// No description provided for @orgLeaveConfirm.
  ///
  /// In en, this message translates to:
  /// **'Are you sure you want to leave this organization?'**
  String get orgLeaveConfirm;

  /// No description provided for @orgRemoveMember.
  ///
  /// In en, this message translates to:
  /// **'Remove Member'**
  String get orgRemoveMember;

  /// No description provided for @orgRemoveMemberConfirm.
  ///
  /// In en, this message translates to:
  /// **'Are you sure you want to remove this member?'**
  String get orgRemoveMemberConfirm;

  /// No description provided for @orgChangeRole.
  ///
  /// In en, this message translates to:
  /// **'Change Role'**
  String get orgChangeRole;

  /// No description provided for @orgPromoteToSuperUser.
  ///
  /// In en, this message translates to:
  /// **'Promote to Super User'**
  String get orgPromoteToSuperUser;

  /// No description provided for @orgDemoteToMember.
  ///
  /// In en, this message translates to:
  /// **'Demote to Member'**
  String get orgDemoteToMember;

  /// No description provided for @orgDeleteConfirm.
  ///
  /// In en, this message translates to:
  /// **'Are you sure you want to delete this organization? This action cannot be undone.'**
  String get orgDeleteConfirm;

  /// No description provided for @orgDeleteRequireNoPets.
  ///
  /// In en, this message translates to:
  /// **'Transfer or remove all pets before deleting'**
  String get orgDeleteRequireNoPets;

  /// No description provided for @orgNoPets.
  ///
  /// In en, this message translates to:
  /// **'No pets in this organization'**
  String get orgNoPets;

  /// No description provided for @orgNoMembers.
  ///
  /// In en, this message translates to:
  /// **'No members'**
  String get orgNoMembers;

  /// No description provided for @orgNoArchived.
  ///
  /// In en, this message translates to:
  /// **'No archived records'**
  String get orgNoArchived;

  /// No description provided for @orgAddPet.
  ///
  /// In en, this message translates to:
  /// **'Add Pet'**
  String get orgAddPet;

  /// No description provided for @transferPet.
  ///
  /// In en, this message translates to:
  /// **'Transfer Pet'**
  String get transferPet;

  /// No description provided for @transferToUser.
  ///
  /// In en, this message translates to:
  /// **'Transfer to User'**
  String get transferToUser;

  /// No description provided for @transferToOrganization.
  ///
  /// In en, this message translates to:
  /// **'Transfer to Organization'**
  String get transferToOrganization;

  /// No description provided for @transferType.
  ///
  /// In en, this message translates to:
  /// **'Transfer Type'**
  String get transferType;

  /// No description provided for @transferTypeAdoption.
  ///
  /// In en, this message translates to:
  /// **'Adoption'**
  String get transferTypeAdoption;

  /// No description provided for @transferTypeTransfer.
  ///
  /// In en, this message translates to:
  /// **'Transfer'**
  String get transferTypeTransfer;

  /// No description provided for @transferTypeRelease.
  ///
  /// In en, this message translates to:
  /// **'Release'**
  String get transferTypeRelease;

  /// No description provided for @transferTypeOther.
  ///
  /// In en, this message translates to:
  /// **'Other'**
  String get transferTypeOther;

  /// No description provided for @recipientEmail.
  ///
  /// In en, this message translates to:
  /// **'Recipient Email'**
  String get recipientEmail;

  /// No description provided for @transferNotes.
  ///
  /// In en, this message translates to:
  /// **'Notes (optional)'**
  String get transferNotes;

  /// No description provided for @confirmTransfer.
  ///
  /// In en, this message translates to:
  /// **'Confirm Transfer'**
  String get confirmTransfer;

  /// No description provided for @transferConfirmTitle.
  ///
  /// In en, this message translates to:
  /// **'Confirm Transfer'**
  String get transferConfirmTitle;

  /// No description provided for @transferConfirmMessage.
  ///
  /// In en, this message translates to:
  /// **'Are you sure you want to transfer {petName}? This action cannot be undone.'**
  String transferConfirmMessage(String petName);

  /// No description provided for @transferSuccess.
  ///
  /// In en, this message translates to:
  /// **'Pet transferred successfully'**
  String get transferSuccess;

  /// No description provided for @archivedPets.
  ///
  /// In en, this message translates to:
  /// **'Archived Pets'**
  String get archivedPets;

  /// No description provided for @archivedOn.
  ///
  /// In en, this message translates to:
  /// **'Archived on {date}'**
  String archivedOn(String date);

  /// No description provided for @noArchivedPets.
  ///
  /// In en, this message translates to:
  /// **'No archived pets'**
  String get noArchivedPets;

  /// No description provided for @orgNameRequired.
  ///
  /// In en, this message translates to:
  /// **'Organization name is required'**
  String get orgNameRequired;

  /// No description provided for @orgCreated.
  ///
  /// In en, this message translates to:
  /// **'Organization created'**
  String get orgCreated;

  /// No description provided for @orgUpdated.
  ///
  /// In en, this message translates to:
  /// **'Organization updated'**
  String get orgUpdated;

  /// No description provided for @orgDeleted.
  ///
  /// In en, this message translates to:
  /// **'Organization deleted'**
  String get orgDeleted;

  /// No description provided for @memberCount.
  ///
  /// In en, this message translates to:
  /// **'{count} members'**
  String memberCount(int count);

  /// No description provided for @petCount.
  ///
  /// In en, this message translates to:
  /// **'{count} pets'**
  String petCount(int count);

  /// No description provided for @remindBefore.
  ///
  /// In en, this message translates to:
  /// **'Remind me'**
  String get remindBefore;

  /// No description provided for @daysBefore.
  ///
  /// In en, this message translates to:
  /// **'day(s) before'**
  String get daysBefore;

  /// No description provided for @undoComplete.
  ///
  /// In en, this message translates to:
  /// **'Undo\nComplete'**
  String get undoComplete;

  /// No description provided for @undoCompleteDone.
  ///
  /// In en, this message translates to:
  /// **'{name} marked as not completed'**
  String undoCompleteDone(String name);

  /// No description provided for @addUser.
  ///
  /// In en, this message translates to:
  /// **'Add a User'**
  String get addUser;

  /// No description provided for @inviteByEmail.
  ///
  /// In en, this message translates to:
  /// **'Invite by Email'**
  String get inviteByEmail;

  /// No description provided for @sendInvite.
  ///
  /// In en, this message translates to:
  /// **'Send Invite'**
  String get sendInvite;

  /// No description provided for @selectRole.
  ///
  /// In en, this message translates to:
  /// **'Select Role'**
  String get selectRole;

  /// No description provided for @inviteSent.
  ///
  /// In en, this message translates to:
  /// **'Invitation sent successfully'**
  String get inviteSent;

  /// No description provided for @pendingInvites.
  ///
  /// In en, this message translates to:
  /// **'Pending Invitations'**
  String get pendingInvites;

  /// No description provided for @inviteToJoinOrg.
  ///
  /// In en, this message translates to:
  /// **'You\'ve been invited to join {orgName}'**
  String inviteToJoinOrg(String orgName);

  /// No description provided for @inviteAsRole.
  ///
  /// In en, this message translates to:
  /// **'as {role}'**
  String inviteAsRole(String role);

  /// No description provided for @acceptInvite.
  ///
  /// In en, this message translates to:
  /// **'Accept'**
  String get acceptInvite;

  /// No description provided for @declineInvite.
  ///
  /// In en, this message translates to:
  /// **'Decline'**
  String get declineInvite;

  /// No description provided for @userNotFound.
  ///
  /// In en, this message translates to:
  /// **'No user found with this email'**
  String get userNotFound;

  /// No description provided for @inviteAccepted.
  ///
  /// In en, this message translates to:
  /// **'Invitation accepted'**
  String get inviteAccepted;

  /// No description provided for @inviteDeclined.
  ///
  /// In en, this message translates to:
  /// **'Invitation declined'**
  String get inviteDeclined;

  /// No description provided for @alreadyMember.
  ///
  /// In en, this message translates to:
  /// **'This user is already a member'**
  String get alreadyMember;

  /// No description provided for @enterEmail.
  ///
  /// In en, this message translates to:
  /// **'Enter the user\'s email address'**
  String get enterEmail;

  /// No description provided for @invitedBy.
  ///
  /// In en, this message translates to:
  /// **'Invited by {name}'**
  String invitedBy(String name);

  /// No description provided for @people.
  ///
  /// In en, this message translates to:
  /// **'People'**
  String get people;

  /// No description provided for @assignedPets.
  ///
  /// In en, this message translates to:
  /// **'{count} pets assigned'**
  String assignedPets(int count);

  /// No description provided for @familyEvents.
  ///
  /// In en, this message translates to:
  /// **'Family Events'**
  String get familyEvents;

  /// No description provided for @noFamilyEvents.
  ///
  /// In en, this message translates to:
  /// **'No family events yet'**
  String get noFamilyEvents;

  /// No description provided for @addFamilyEvent.
  ///
  /// In en, this message translates to:
  /// **'Add Family Event'**
  String get addFamilyEvent;

  /// No description provided for @editFamilyEvent.
  ///
  /// In en, this message translates to:
  /// **'Edit Family Event'**
  String get editFamilyEvent;

  /// No description provided for @deleteFamilyEventConfirm.
  ///
  /// In en, this message translates to:
  /// **'Are you sure you want to delete this family event?'**
  String get deleteFamilyEventConfirm;

  /// No description provided for @assignedToMember.
  ///
  /// In en, this message translates to:
  /// **'Assigned to'**
  String get assignedToMember;

  /// No description provided for @unassigned.
  ///
  /// In en, this message translates to:
  /// **'Unassigned'**
  String get unassigned;

  /// No description provided for @fromDateLabel.
  ///
  /// In en, this message translates to:
  /// **'From date'**
  String get fromDateLabel;

  /// No description provided for @toDateLabel.
  ///
  /// In en, this message translates to:
  /// **'To date'**
  String get toDateLabel;

  /// No description provided for @optional.
  ///
  /// In en, this message translates to:
  /// **'optional'**
  String get optional;

  /// No description provided for @assignTo.
  ///
  /// In en, this message translates to:
  /// **'Assign to'**
  String get assignTo;

  /// No description provided for @assignToHint.
  ///
  /// In en, this message translates to:
  /// **'Optionally assign a member to this pet'**
  String get assignToHint;

  /// No description provided for @assignedMember.
  ///
  /// In en, this message translates to:
  /// **'Assigned member'**
  String get assignedMember;

  /// No description provided for @notAssigned.
  ///
  /// In en, this message translates to:
  /// **'Not assigned'**
  String get notAssigned;

  /// No description provided for @autoAssignedToYou.
  ///
  /// In en, this message translates to:
  /// **'You will be automatically assigned to this pet'**
  String get autoAssignedToYou;

  /// No description provided for @notSet.
  ///
  /// In en, this message translates to:
  /// **'Not set'**
  String get notSet;

  /// No description provided for @petOwnership.
  ///
  /// In en, this message translates to:
  /// **'Pet Ownership'**
  String get petOwnership;

  /// No description provided for @myPet.
  ///
  /// In en, this message translates to:
  /// **'My Pet'**
  String get myPet;

  /// No description provided for @orgPet.
  ///
  /// In en, this message translates to:
  /// **'Organisation Pet'**
  String get orgPet;

  /// No description provided for @pendingShares.
  ///
  /// In en, this message translates to:
  /// **'Pending Shares'**
  String get pendingShares;

  /// No description provided for @petSharedWithYou.
  ///
  /// In en, this message translates to:
  /// **'{guardianName} wants to share {petName} with you'**
  String petSharedWithYou(String guardianName, String petName);

  /// No description provided for @acceptShare.
  ///
  /// In en, this message translates to:
  /// **'Accept'**
  String get acceptShare;

  /// No description provided for @declineShare.
  ///
  /// In en, this message translates to:
  /// **'Decline'**
  String get declineShare;

  /// No description provided for @shareAccepted.
  ///
  /// In en, this message translates to:
  /// **'Share accepted'**
  String get shareAccepted;

  /// No description provided for @acceptShareTo.
  ///
  /// In en, this message translates to:
  /// **'Accept pet to…'**
  String get acceptShareTo;

  /// No description provided for @acceptShareToHint.
  ///
  /// In en, this message translates to:
  /// **'Choose where this shared pet should appear.'**
  String get acceptShareToHint;

  /// No description provided for @shareDeclined.
  ///
  /// In en, this message translates to:
  /// **'Share declined'**
  String get shareDeclined;

  /// No description provided for @sharedPets.
  ///
  /// In en, this message translates to:
  /// **'Shared Pets'**
  String get sharedPets;

  /// No description provided for @invited.
  ///
  /// In en, this message translates to:
  /// **'Invited'**
  String get invited;

  /// No description provided for @pendingInvite.
  ///
  /// In en, this message translates to:
  /// **'Pending'**
  String get pendingInvite;

  /// No description provided for @hideSharedPet.
  ///
  /// In en, this message translates to:
  /// **'Hide Pet'**
  String get hideSharedPet;

  /// No description provided for @hide.
  ///
  /// In en, this message translates to:
  /// **'Hide'**
  String get hide;

  /// No description provided for @unhide.
  ///
  /// In en, this message translates to:
  /// **'Unhide'**
  String get unhide;

  /// No description provided for @hideSharedPetConfirm.
  ///
  /// In en, this message translates to:
  /// **'Hide {petName}? You won\'t see it in your list, events, or notifications. You can unhide it later from the organisation page.'**
  String hideSharedPetConfirm(String petName);

  /// No description provided for @petHidden.
  ///
  /// In en, this message translates to:
  /// **'{petName} has been hidden'**
  String petHidden(String petName);

  /// No description provided for @petUnhidden.
  ///
  /// In en, this message translates to:
  /// **'{petName} is now visible again'**
  String petUnhidden(String petName);

  /// No description provided for @hiddenSharedPets.
  ///
  /// In en, this message translates to:
  /// **'Hidden Shared Pets'**
  String get hiddenSharedPets;

  /// No description provided for @help.
  ///
  /// In en, this message translates to:
  /// **'Help'**
  String get help;

  /// No description provided for @helpTitle.
  ///
  /// In en, this message translates to:
  /// **'Help & FAQ'**
  String get helpTitle;

  /// No description provided for @helpSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Find answers to common questions about every feature in Agatha Track.'**
  String get helpSubtitle;

  /// No description provided for @faqAccountTitle.
  ///
  /// In en, this message translates to:
  /// **'Account & Authentication'**
  String get faqAccountTitle;

  /// No description provided for @faqAccountQ1.
  ///
  /// In en, this message translates to:
  /// **'How do I create an account?'**
  String get faqAccountQ1;

  /// No description provided for @faqAccountA1.
  ///
  /// In en, this message translates to:
  /// **'Tap \"Sign Up\" on the landing page. Enter your email address, choose a password, and provide your first and last name. You will be logged in automatically after signing up.'**
  String get faqAccountA1;

  /// No description provided for @faqAccountQ2.
  ///
  /// In en, this message translates to:
  /// **'How do I log in?'**
  String get faqAccountQ2;

  /// No description provided for @faqAccountA2.
  ///
  /// In en, this message translates to:
  /// **'Tap \"Log In\" on the landing page and enter your email and password. Your session stays active until you log out.'**
  String get faqAccountA2;

  /// No description provided for @faqAccountQ3.
  ///
  /// In en, this message translates to:
  /// **'I forgot my password — how do I reset it?'**
  String get faqAccountQ3;

  /// No description provided for @faqAccountA3.
  ///
  /// In en, this message translates to:
  /// **'On the login screen, tap \"Forgot password?\". Enter the email address associated with your account and follow the instructions to set a new password.'**
  String get faqAccountA3;

  /// No description provided for @faqAccountQ4.
  ///
  /// In en, this message translates to:
  /// **'How do I update my profile?'**
  String get faqAccountQ4;

  /// No description provided for @faqAccountA4.
  ///
  /// In en, this message translates to:
  /// **'Go to the user menu (your avatar in the top-right corner), then tap \"My Details\". From there you can edit your name, bio, profile photo, and change your password.'**
  String get faqAccountA4;

  /// No description provided for @faqAccountQ5.
  ///
  /// In en, this message translates to:
  /// **'How do I log out?'**
  String get faqAccountQ5;

  /// No description provided for @faqAccountA5.
  ///
  /// In en, this message translates to:
  /// **'Open the user menu (avatar icon in the top-right corner) and tap \"Logout\". You will be returned to the landing page.'**
  String get faqAccountA5;

  /// No description provided for @faqPetProfileTitle.
  ///
  /// In en, this message translates to:
  /// **'Pet Profiles'**
  String get faqPetProfileTitle;

  /// No description provided for @faqPetProfileQ1.
  ///
  /// In en, this message translates to:
  /// **'How do I add a new pet?'**
  String get faqPetProfileQ1;

  /// No description provided for @faqPetProfileA1.
  ///
  /// In en, this message translates to:
  /// **'Tap the \"+\" button on the main pet list screen. Fill in your pet\'s name, species, breed, date of birth, and optional details like microchip number and photo. Each pet is assigned a unique colour for easy identification.'**
  String get faqPetProfileA1;

  /// No description provided for @faqPetProfileQ2.
  ///
  /// In en, this message translates to:
  /// **'How do I edit or delete a pet?'**
  String get faqPetProfileQ2;

  /// No description provided for @faqPetProfileA2.
  ///
  /// In en, this message translates to:
  /// **'Tap on the pet\'s card to open its detail page. Use the edit icon in the top-right to update information. To delete a pet, use the delete option — note that deleting a pet permanently removes all associated health entries, weight records, and other data.'**
  String get faqPetProfileA2;

  /// No description provided for @faqPetProfileQ3.
  ///
  /// In en, this message translates to:
  /// **'What does the identification reminder mean?'**
  String get faqPetProfileQ3;

  /// No description provided for @faqPetProfileA3.
  ///
  /// In en, this message translates to:
  /// **'If your pet does not have an ID (microchip or tag number) recorded, a species-specific reminder will appear on the pet\'s card. You can dismiss this reminder or add the ID in the pet\'s edit form.'**
  String get faqPetProfileA3;

  /// No description provided for @faqPetProfileQ4.
  ///
  /// In en, this message translates to:
  /// **'How do I mark a pet as passed away?'**
  String get faqPetProfileQ4;

  /// No description provided for @faqPetProfileA4.
  ///
  /// In en, this message translates to:
  /// **'Open the pet\'s edit form and enable the \"Passed away\" option. This changes the pet\'s colour to white, adds a memorial overlay to the photo, and sends a notification. The pet remains in your list as a memorial.'**
  String get faqPetProfileA4;

  /// No description provided for @faqPetProfileQ5.
  ///
  /// In en, this message translates to:
  /// **'What is the pet colour system?'**
  String get faqPetProfileQ5;

  /// No description provided for @faqPetProfileA5.
  ///
  /// In en, this message translates to:
  /// **'Each pet is assigned a unique colour from a palette of 15 colours when created. This colour appears on cards, charts, and throughout the app to help you quickly identify each pet at a glance.'**
  String get faqPetProfileA5;

  /// No description provided for @faqPetProfileQ6.
  ///
  /// In en, this message translates to:
  /// **'How is my pet\'s age calculated?'**
  String get faqPetProfileQ6;

  /// No description provided for @faqPetProfileA6.
  ///
  /// In en, this message translates to:
  /// **'Age is automatically calculated from the date of birth you enter. It updates dynamically and is displayed on the pet\'s detail page and profile cards.'**
  String get faqPetProfileA6;

  /// No description provided for @faqHealthTitle.
  ///
  /// In en, this message translates to:
  /// **'Health Tracking'**
  String get faqHealthTitle;

  /// No description provided for @faqHealthQ1.
  ///
  /// In en, this message translates to:
  /// **'What types of health entries can I track?'**
  String get faqHealthQ1;

  /// No description provided for @faqHealthA1.
  ///
  /// In en, this message translates to:
  /// **'You can track medications, preventive treatments (vaccinations, deworming, flea/tick treatments), vet visits, and medical procedures. Each type has its own icon and colour in the dashboard.'**
  String get faqHealthA1;

  /// No description provided for @faqHealthQ2.
  ///
  /// In en, this message translates to:
  /// **'How do I add a health entry?'**
  String get faqHealthQ2;

  /// No description provided for @faqHealthA2.
  ///
  /// In en, this message translates to:
  /// **'You can add entries from two places: the pet\'s detail page (specific to that pet) or the global Health Dashboard (accessible from the medical icon in the top bar). Fill in the type, name, date, and optional details like frequency, notes, and photo attachments.'**
  String get faqHealthA2;

  /// No description provided for @faqHealthQ3.
  ///
  /// In en, this message translates to:
  /// **'What is the Health Dashboard?'**
  String get faqHealthQ3;

  /// No description provided for @faqHealthA3.
  ///
  /// In en, this message translates to:
  /// **'The Health Dashboard is a global view of all health events across all your pets. It is organised into tabs by type (medications, preventives, vet visits, etc.) and shows upcoming, due, and overdue entries. You can filter by organisation to focus on specific groups of pets.'**
  String get faqHealthA3;

  /// No description provided for @faqHealthQ4.
  ///
  /// In en, this message translates to:
  /// **'How do recurring health entries work?'**
  String get faqHealthQ4;

  /// No description provided for @faqHealthA4.
  ///
  /// In en, this message translates to:
  /// **'When creating a health entry, you can set a frequency (e.g., daily, weekly, monthly, yearly, or a custom number of days). The app will automatically schedule the next occurrence and notify you when it is due.'**
  String get faqHealthA4;

  /// No description provided for @faqHealthQ5.
  ///
  /// In en, this message translates to:
  /// **'What are Health Issues?'**
  String get faqHealthQ5;

  /// No description provided for @faqHealthA5.
  ///
  /// In en, this message translates to:
  /// **'Health Issues let you track ongoing medical conditions (e.g., allergies, chronic illness). Each issue can have a start date, optional end date, and can be linked to related health entries for a complete medical history.'**
  String get faqHealthA5;

  /// No description provided for @faqHealthQ6.
  ///
  /// In en, this message translates to:
  /// **'Can I attach photos to health entries?'**
  String get faqHealthQ6;

  /// No description provided for @faqHealthA6.
  ///
  /// In en, this message translates to:
  /// **'Yes. When creating or editing a health entry, you can attach a photo — for example, a picture of a prescription, lab results, or a wound. The photo is stored with the entry and visible on the detail view.'**
  String get faqHealthA6;

  /// No description provided for @faqWeightTitle.
  ///
  /// In en, this message translates to:
  /// **'Weight Tracking'**
  String get faqWeightTitle;

  /// No description provided for @faqWeightQ1.
  ///
  /// In en, this message translates to:
  /// **'How do I record my pet\'s weight?'**
  String get faqWeightQ1;

  /// No description provided for @faqWeightA1.
  ///
  /// In en, this message translates to:
  /// **'Open the pet\'s detail page and scroll to the Weight section. Tap the add button to enter a new weight reading. You can choose between kilograms (kg) and pounds (lb).'**
  String get faqWeightA1;

  /// No description provided for @faqWeightQ2.
  ///
  /// In en, this message translates to:
  /// **'How is weight data displayed?'**
  String get faqWeightQ2;

  /// No description provided for @faqWeightA2.
  ///
  /// In en, this message translates to:
  /// **'Weight history is shown as an interactive line chart on the pet\'s detail page. You can see trends over time and tap individual data points for details. The chart uses your pet\'s unique colour.'**
  String get faqWeightA2;

  /// No description provided for @faqWeightQ3.
  ///
  /// In en, this message translates to:
  /// **'Can I switch between kg and lb?'**
  String get faqWeightQ3;

  /// No description provided for @faqWeightA3.
  ///
  /// In en, this message translates to:
  /// **'Yes. Use the unit toggle on the weight section to switch between kilograms and pounds. The conversion is applied to all displayed values.'**
  String get faqWeightA3;

  /// No description provided for @faqVetTitle.
  ///
  /// In en, this message translates to:
  /// **'Veterinarian Management'**
  String get faqVetTitle;

  /// No description provided for @faqVetQ1.
  ///
  /// In en, this message translates to:
  /// **'How do I add a veterinarian?'**
  String get faqVetQ1;

  /// No description provided for @faqVetA1.
  ///
  /// In en, this message translates to:
  /// **'Go to the Veterinarians section (accessible from the stethoscope icon in the top bar). Tap the \"+\" button and fill in the clinic name, vet name, phone number, email, address, and website.'**
  String get faqVetA1;

  /// No description provided for @faqVetQ2.
  ///
  /// In en, this message translates to:
  /// **'How do I link a vet to my pet?'**
  String get faqVetQ2;

  /// No description provided for @faqVetA2.
  ///
  /// In en, this message translates to:
  /// **'When editing a pet\'s profile, you can select a veterinarian from your saved list. This links the vet to the pet so their contact information is readily available on the pet\'s detail page.'**
  String get faqVetA2;

  /// No description provided for @faqVetQ3.
  ///
  /// In en, this message translates to:
  /// **'Can I edit or delete a vet?'**
  String get faqVetQ3;

  /// No description provided for @faqVetA3.
  ///
  /// In en, this message translates to:
  /// **'Yes. From the Veterinarians list, tap on a vet to view their details, then use the edit or delete options. Deleting a vet removes the link from any associated pets but does not delete the pets themselves.'**
  String get faqVetA3;

  /// No description provided for @faqSharingTitle.
  ///
  /// In en, this message translates to:
  /// **'Pet Sharing'**
  String get faqSharingTitle;

  /// No description provided for @faqSharingQ1.
  ///
  /// In en, this message translates to:
  /// **'How do I share a pet with someone?'**
  String get faqSharingQ1;

  /// No description provided for @faqSharingA1.
  ///
  /// In en, this message translates to:
  /// **'Open the pet\'s detail page and use the share option to generate a share link. Send this link to the person you want to share with. When they accept, they will see the pet in their list.'**
  String get faqSharingA1;

  /// No description provided for @faqSharingQ2.
  ///
  /// In en, this message translates to:
  /// **'What happens when someone accepts a share?'**
  String get faqSharingQ2;

  /// No description provided for @faqSharingA2.
  ///
  /// In en, this message translates to:
  /// **'The recipient receives a notification with the pending share. They can choose to place the shared pet into their personal list or into an organisation they belong to. The pet appears with a \"shared\" badge.'**
  String get faqSharingA2;

  /// No description provided for @faqSharingQ3.
  ///
  /// In en, this message translates to:
  /// **'Can I hide a shared pet?'**
  String get faqSharingQ3;

  /// No description provided for @faqSharingA3.
  ///
  /// In en, this message translates to:
  /// **'Yes. Swipe left on a shared pet\'s card to hide it. Hidden pets will not appear in your pet list, health dashboard, or generate notifications. You can unhide them from the organisation\'s detail page under \"Hidden Shared Pets\".'**
  String get faqSharingA3;

  /// No description provided for @faqSharingQ4.
  ///
  /// In en, this message translates to:
  /// **'What is the difference between sharing and transferring?'**
  String get faqSharingQ4;

  /// No description provided for @faqSharingA4.
  ///
  /// In en, this message translates to:
  /// **'Sharing gives someone view access to a pet — the original owner retains full control. Transferring (available for organisation pets) moves ownership of the pet to another user or organisation entirely.'**
  String get faqSharingA4;

  /// No description provided for @faqOrgTitle.
  ///
  /// In en, this message translates to:
  /// **'Organisations'**
  String get faqOrgTitle;

  /// No description provided for @faqOrgQ1.
  ///
  /// In en, this message translates to:
  /// **'What are organisations for?'**
  String get faqOrgQ1;

  /// No description provided for @faqOrgA1.
  ///
  /// In en, this message translates to:
  /// **'Organisations let multiple people collaborate on pet care. They are ideal for vet clinics, shelters, charities, and foster networks. You can create Professional or Charity organisations.'**
  String get faqOrgA1;

  /// No description provided for @faqOrgQ2.
  ///
  /// In en, this message translates to:
  /// **'How do I create an organisation?'**
  String get faqOrgQ2;

  /// No description provided for @faqOrgA2.
  ///
  /// In en, this message translates to:
  /// **'Go to the Organisations page (accessible from the business icon in the top bar or from My Details). Tap \"Create\" and choose Professional or Charity, then fill in the name and details. You become the super user automatically.'**
  String get faqOrgA2;

  /// No description provided for @faqOrgQ3.
  ///
  /// In en, this message translates to:
  /// **'How do I invite people to my organisation?'**
  String get faqOrgQ3;

  /// No description provided for @faqOrgA3.
  ///
  /// In en, this message translates to:
  /// **'From the organisation\'s detail page, tap \"Add User\". Enter the person\'s email address and choose their role — either \"Member\" or \"Super User\". They will receive a pending invite they can accept or decline.'**
  String get faqOrgA3;

  /// No description provided for @faqOrgQ4.
  ///
  /// In en, this message translates to:
  /// **'What is the difference between a Member and a Super User?'**
  String get faqOrgQ4;

  /// No description provided for @faqOrgA4.
  ///
  /// In en, this message translates to:
  /// **'Members can view and manage pets within the organisation. Super Users have additional permissions: they can invite or remove members, edit organisation details, transfer pets, and manage archives.'**
  String get faqOrgA4;

  /// No description provided for @faqOrgQ5.
  ///
  /// In en, this message translates to:
  /// **'How do I archive or restore a pet in an organisation?'**
  String get faqOrgQ5;

  /// No description provided for @faqOrgA5.
  ///
  /// In en, this message translates to:
  /// **'Super Users can archive a pet from the organisation\'s pet list (e.g., after an adoption). Archived pets are hidden from the active list but preserved for record-keeping. They can be restored at any time from the Archived Pets section.'**
  String get faqOrgA5;

  /// No description provided for @faqFamilyEventsTitle.
  ///
  /// In en, this message translates to:
  /// **'Family Events'**
  String get faqFamilyEventsTitle;

  /// No description provided for @faqFamilyEventsQ1.
  ///
  /// In en, this message translates to:
  /// **'What are Family Events?'**
  String get faqFamilyEventsQ1;

  /// No description provided for @faqFamilyEventsA1.
  ///
  /// In en, this message translates to:
  /// **'Family Events are care assignments for organisation pets. They record who is responsible for a pet during a specific period — such as a foster stay or temporary care. Each event has an assigned member, date range, and optional notes.'**
  String get faqFamilyEventsA1;

  /// No description provided for @faqFamilyEventsQ2.
  ///
  /// In en, this message translates to:
  /// **'How do I create a Family Event?'**
  String get faqFamilyEventsQ2;

  /// No description provided for @faqFamilyEventsA2.
  ///
  /// In en, this message translates to:
  /// **'Open an organisation pet\'s detail page and scroll to the Family Events section. Tap the add button, choose the assigned member, set the from and optional to dates, and add any notes. All organisation members will be notified.'**
  String get faqFamilyEventsA2;

  /// No description provided for @faqFamilyEventsQ3.
  ///
  /// In en, this message translates to:
  /// **'Do Family Events appear in the Health Dashboard?'**
  String get faqFamilyEventsQ3;

  /// No description provided for @faqFamilyEventsA3.
  ///
  /// In en, this message translates to:
  /// **'Yes. Family Events have their own dedicated tab in the Health Dashboard. They also trigger reminder notifications when an event\'s end date is approaching, so all organisation members stay informed.'**
  String get faqFamilyEventsA3;

  /// No description provided for @faqNotificationsTitle.
  ///
  /// In en, this message translates to:
  /// **'Notifications'**
  String get faqNotificationsTitle;

  /// No description provided for @faqNotificationsQ1.
  ///
  /// In en, this message translates to:
  /// **'What notifications will I receive?'**
  String get faqNotificationsQ1;

  /// No description provided for @faqNotificationsA1.
  ///
  /// In en, this message translates to:
  /// **'You will receive in-app notifications for: due or overdue health entries, upcoming medication reminders, organisation invites, share requests, pet memorials, and family event reminders.'**
  String get faqNotificationsA1;

  /// No description provided for @faqNotificationsQ2.
  ///
  /// In en, this message translates to:
  /// **'How do I manage notification preferences?'**
  String get faqNotificationsQ2;

  /// No description provided for @faqNotificationsA2.
  ///
  /// In en, this message translates to:
  /// **'Go to the Notifications screen (bell icon in the top bar) and tap the settings icon. From there you can customise which types of notifications you receive.'**
  String get faqNotificationsA2;

  /// No description provided for @faqNotificationsQ3.
  ///
  /// In en, this message translates to:
  /// **'Can I mute notifications for a specific pet?'**
  String get faqNotificationsQ3;

  /// No description provided for @faqNotificationsA3.
  ///
  /// In en, this message translates to:
  /// **'Yes. Each pet has a mute option in its notification settings. Muted pets will not generate any health-related notifications until unmuted.'**
  String get faqNotificationsA3;

  /// No description provided for @faqNotificationsQ4.
  ///
  /// In en, this message translates to:
  /// **'Can I snooze a notification?'**
  String get faqNotificationsQ4;

  /// No description provided for @faqNotificationsA4.
  ///
  /// In en, this message translates to:
  /// **'Yes. You can snooze individual notifications to be reminded again after a chosen number of days. The snoozed reminder will reappear counting from today, not from the original due date.'**
  String get faqNotificationsA4;

  /// No description provided for @faqReportsTitle.
  ///
  /// In en, this message translates to:
  /// **'Reports'**
  String get faqReportsTitle;

  /// No description provided for @faqReportsQ1.
  ///
  /// In en, this message translates to:
  /// **'How do I generate a pet report?'**
  String get faqReportsQ1;

  /// No description provided for @faqReportsA1.
  ///
  /// In en, this message translates to:
  /// **'Open a pet\'s detail page and tap the report/PDF icon. You can customise what to include — profile information, weight history, health events, health issues, family events, notifications, and sharing details. The report is generated as a downloadable PDF.'**
  String get faqReportsA1;

  /// No description provided for @faqReportsQ2.
  ///
  /// In en, this message translates to:
  /// **'What information is included in a report?'**
  String get faqReportsQ2;

  /// No description provided for @faqReportsA2.
  ///
  /// In en, this message translates to:
  /// **'Reports can include: pet profile details (name, breed, age, ID), a weight chart and history table, a list of all health entries by type, recorded health issues, family event assignments and foster stays (for organisation pets), recent notifications and alerts, and sharing access details. You choose which sections to include before generating.'**
  String get faqReportsA2;

  /// No description provided for @faqSubscriptionTitle.
  ///
  /// In en, this message translates to:
  /// **'Subscription'**
  String get faqSubscriptionTitle;

  /// No description provided for @faqSubscriptionQ1.
  ///
  /// In en, this message translates to:
  /// **'Is Agatha Track free to use?'**
  String get faqSubscriptionQ1;

  /// No description provided for @faqSubscriptionA1.
  ///
  /// In en, this message translates to:
  /// **'Agatha Track offers a free tier with core features. An optional premium subscription unlocks additional capabilities and removes limits. Visit the Subscription page from My Details to learn more.'**
  String get faqSubscriptionA1;

  /// No description provided for @faqSubscriptionQ2.
  ///
  /// In en, this message translates to:
  /// **'How do I subscribe?'**
  String get faqSubscriptionQ2;

  /// No description provided for @faqSubscriptionA2.
  ///
  /// In en, this message translates to:
  /// **'Go to My Details and tap \"Subscription\". Choose a plan and complete the purchase through your platform\'s payment system. Your subscription is managed securely through RevenueCat.'**
  String get faqSubscriptionA2;

  /// No description provided for @faqSubscriptionQ3.
  ///
  /// In en, this message translates to:
  /// **'How do I cancel my subscription?'**
  String get faqSubscriptionQ3;

  /// No description provided for @faqSubscriptionA3.
  ///
  /// In en, this message translates to:
  /// **'Subscriptions can be managed or cancelled through your device\'s app store settings (App Store or Google Play). Changes take effect at the end of the current billing period.'**
  String get faqSubscriptionA3;

  /// No description provided for @faqLanguageTitle.
  ///
  /// In en, this message translates to:
  /// **'Language & Accessibility'**
  String get faqLanguageTitle;

  /// No description provided for @faqLanguageQ1.
  ///
  /// In en, this message translates to:
  /// **'How do I change the app language?'**
  String get faqLanguageQ1;

  /// No description provided for @faqLanguageA1.
  ///
  /// In en, this message translates to:
  /// **'Go to My Details and use the language dropdown to switch between English and French. The change takes effect immediately across the entire app and is saved to your profile.'**
  String get faqLanguageA1;

  /// No description provided for @faqLanguageQ2.
  ///
  /// In en, this message translates to:
  /// **'Is the app accessible?'**
  String get faqLanguageQ2;

  /// No description provided for @faqLanguageA2.
  ///
  /// In en, this message translates to:
  /// **'Yes. Agatha Track includes accessibility features throughout: semantic labels for screen readers, tooltips on all interactive elements, proper form field labelling, and keyboard navigation support.'**
  String get faqLanguageA2;
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(lookupAppLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) =>
      <String>['en', 'fr'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'en':
      return AppLocalizationsEn();
    case 'fr':
      return AppLocalizationsFr();
  }

  throw FlutterError(
    'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
    'an issue with the localizations generation tool. Please file an issue '
    'on GitHub with a reproducible sample app and the gen-l10n configuration '
    'that was used.',
  );
}
