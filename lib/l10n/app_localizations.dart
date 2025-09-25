import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_en.dart';
import 'app_localizations_es.dart';
import 'app_localizations_pt.dart';

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

  static AppLocalizations of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations)!;
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
    Locale('es'),
    Locale('pt'),
  ];

  /// No description provided for @appName.
  ///
  /// In en, this message translates to:
  /// **'Warrior Path'**
  String get appName;

  /// No description provided for @appSlogan.
  ///
  /// In en, this message translates to:
  /// **'Be a warrior, create your path'**
  String get appSlogan;

  /// No description provided for @emailLabel.
  ///
  /// In en, this message translates to:
  /// **'Email'**
  String get emailLabel;

  /// No description provided for @loginButton.
  ///
  /// In en, this message translates to:
  /// **'Log In'**
  String get loginButton;

  /// No description provided for @createAccountButton.
  ///
  /// In en, this message translates to:
  /// **'Create Account'**
  String get createAccountButton;

  /// No description provided for @forgotPasswordLink.
  ///
  /// In en, this message translates to:
  /// **'Forgot your password?'**
  String get forgotPasswordLink;

  /// No description provided for @loginErrorTitle.
  ///
  /// In en, this message translates to:
  /// **'Login Error'**
  String get loginErrorTitle;

  /// No description provided for @loginErrorUserNotFound.
  ///
  /// In en, this message translates to:
  /// **'No user found for that email.'**
  String get loginErrorUserNotFound;

  /// No description provided for @loginErrorWrongPassword.
  ///
  /// In en, this message translates to:
  /// **'Wrong password provided for that user.'**
  String get loginErrorWrongPassword;

  /// No description provided for @loginErrorInvalidCredential.
  ///
  /// In en, this message translates to:
  /// **'The credentials provided are incorrect.'**
  String get loginErrorInvalidCredential;

  /// No description provided for @unexpectedError.
  ///
  /// In en, this message translates to:
  /// **'An unexpected error occurred.'**
  String get unexpectedError;

  /// No description provided for @registrationErrorTitle.
  ///
  /// In en, this message translates to:
  /// **'Registration Error'**
  String get registrationErrorTitle;

  /// No description provided for @registrationErrorContent.
  ///
  /// In en, this message translates to:
  /// **'Could not complete registration. The email may already be in use or the password is too weak.'**
  String get registrationErrorContent;

  /// No description provided for @errorTitle.
  ///
  /// In en, this message translates to:
  /// **'Error'**
  String get errorTitle;

  /// No description provided for @genericErrorContent.
  ///
  /// In en, this message translates to:
  /// **'An error occurred: {errorDetails}'**
  String genericErrorContent(String errorDetails);

  /// No description provided for @ok.
  ///
  /// In en, this message translates to:
  /// **'Ok'**
  String get ok;

  /// No description provided for @welcomeTitle.
  ///
  /// In en, this message translates to:
  /// **'Welcome, {userName}!'**
  String welcomeTitle(String userName);

  /// No description provided for @teacher.
  ///
  /// In en, this message translates to:
  /// **'Teacher'**
  String get teacher;

  /// No description provided for @sessionError.
  ///
  /// In en, this message translates to:
  /// **'Error: Invalid session.'**
  String get sessionError;

  /// No description provided for @noSchedulerClass.
  ///
  /// In en, this message translates to:
  /// **'There are no classes scheduled for today.'**
  String get noSchedulerClass;

  /// No description provided for @choseClass.
  ///
  /// In en, this message translates to:
  /// **'Select Class'**
  String get choseClass;

  /// No description provided for @todayClass.
  ///
  /// In en, this message translates to:
  /// **'Today\'s Classes'**
  String get todayClass;

  /// No description provided for @takeAssistance.
  ///
  /// In en, this message translates to:
  /// **'Take Attendance'**
  String get takeAssistance;

  /// No description provided for @loading.
  ///
  /// In en, this message translates to:
  /// **'Loading...'**
  String get loading;

  /// No description provided for @activeStudents.
  ///
  /// In en, this message translates to:
  /// **'Active Students'**
  String get activeStudents;

  /// No description provided for @pendingApplication.
  ///
  /// In en, this message translates to:
  /// **'Pending Applications'**
  String get pendingApplication;

  /// No description provided for @password.
  ///
  /// In en, this message translates to:
  /// **'Password'**
  String get password;

  /// No description provided for @home.
  ///
  /// In en, this message translates to:
  /// **'Home'**
  String get home;

  /// No description provided for @student.
  ///
  /// In en, this message translates to:
  /// **'Student'**
  String get student;

  /// No description provided for @managment.
  ///
  /// In en, this message translates to:
  /// **'Management'**
  String get managment;

  /// No description provided for @profile.
  ///
  /// In en, this message translates to:
  /// **'Profile'**
  String get profile;

  /// No description provided for @actives.
  ///
  /// In en, this message translates to:
  /// **'Active'**
  String get actives;

  /// No description provided for @pending.
  ///
  /// In en, this message translates to:
  /// **'Pending'**
  String get pending;

  /// No description provided for @inactives.
  ///
  /// In en, this message translates to:
  /// **'Inactive'**
  String get inactives;

  /// No description provided for @general.
  ///
  /// In en, this message translates to:
  /// **'General'**
  String get general;

  /// No description provided for @assistance.
  ///
  /// In en, this message translates to:
  /// **'Attendance'**
  String get assistance;

  /// No description provided for @payments.
  ///
  /// In en, this message translates to:
  /// **'Payments'**
  String get payments;

  /// No description provided for @payment.
  ///
  /// In en, this message translates to:
  /// **'Payment'**
  String get payment;

  /// No description provided for @progress.
  ///
  /// In en, this message translates to:
  /// **'Progress'**
  String get progress;

  /// No description provided for @facturation.
  ///
  /// In en, this message translates to:
  /// **'Billing'**
  String get facturation;

  /// No description provided for @changeAssignedPlan.
  ///
  /// In en, this message translates to:
  /// **'Change Assigned Plan'**
  String get changeAssignedPlan;

  /// No description provided for @personalData.
  ///
  /// In en, this message translates to:
  /// **'Personal Data'**
  String get personalData;

  /// No description provided for @birdthDate.
  ///
  /// In en, this message translates to:
  /// **'Date of Birth'**
  String get birdthDate;

  /// No description provided for @gender.
  ///
  /// In en, this message translates to:
  /// **'Gender'**
  String get gender;

  /// No description provided for @years.
  ///
  /// In en, this message translates to:
  /// **'years'**
  String get years;

  /// No description provided for @phone.
  ///
  /// In en, this message translates to:
  /// **'Phone'**
  String get phone;

  /// No description provided for @emergencyInfo.
  ///
  /// In en, this message translates to:
  /// **'Emergency Information'**
  String get emergencyInfo;

  /// No description provided for @contact.
  ///
  /// In en, this message translates to:
  /// **'Contact'**
  String get contact;

  /// No description provided for @medService.
  ///
  /// In en, this message translates to:
  /// **'Medical Service'**
  String get medService;

  /// No description provided for @medInfo.
  ///
  /// In en, this message translates to:
  /// **'Medical Information'**
  String get medInfo;

  /// No description provided for @noSpecify.
  ///
  /// In en, this message translates to:
  /// **'Not specified'**
  String get noSpecify;

  /// No description provided for @changeRol.
  ///
  /// In en, this message translates to:
  /// **'Change Role'**
  String get changeRol;

  /// No description provided for @noPayment.
  ///
  /// In en, this message translates to:
  /// **'There are no payments registered for this student.'**
  String get noPayment;

  /// No description provided for @noRegisterAssitance.
  ///
  /// In en, this message translates to:
  /// **'There are no attendance records for this student.'**
  String get noRegisterAssitance;

  /// No description provided for @classRoom.
  ///
  /// In en, this message translates to:
  /// **'Class'**
  String get classRoom;

  /// No description provided for @confirm.
  ///
  /// In en, this message translates to:
  /// **'Confirm'**
  String get confirm;

  /// No description provided for @cancel.
  ///
  /// In en, this message translates to:
  /// **'Cancel'**
  String get cancel;

  /// No description provided for @eliminate.
  ///
  /// In en, this message translates to:
  /// **'Delete'**
  String get eliminate;

  /// No description provided for @deleteError.
  ///
  /// In en, this message translates to:
  /// **'Error deleting: {e}'**
  String deleteError(String e);

  /// No description provided for @rolUpdatedTo.
  ///
  /// In en, this message translates to:
  /// **'Role updated to {rol}'**
  String rolUpdatedTo(String rol);

  /// No description provided for @deleteLevel.
  ///
  /// In en, this message translates to:
  /// **'Deleted Level'**
  String get deleteLevel;

  /// No description provided for @promotionTo.
  ///
  /// In en, this message translates to:
  /// **'Promoted to {level}'**
  String promotionTo(String level);

  /// No description provided for @notesValue.
  ///
  /// In en, this message translates to:
  /// **'Notes: {notes}'**
  String notesValue(String notes);

  /// No description provided for @notesLabel.
  ///
  /// In en, this message translates to:
  /// **'Notes'**
  String get notesLabel;

  /// No description provided for @maleGender.
  ///
  /// In en, this message translates to:
  /// **'Male'**
  String get maleGender;

  /// No description provided for @femaleGender.
  ///
  /// In en, this message translates to:
  /// **'Female'**
  String get femaleGender;

  /// No description provided for @otherGender.
  ///
  /// In en, this message translates to:
  /// **'Other'**
  String get otherGender;

  /// No description provided for @noSpecifyGender.
  ///
  /// In en, this message translates to:
  /// **'Prefers not to say'**
  String get noSpecifyGender;

  /// No description provided for @noClassForTHisDay.
  ///
  /// In en, this message translates to:
  /// **'There were no classes scheduled for the selected day.'**
  String get noClassForTHisDay;

  /// No description provided for @classFor.
  ///
  /// In en, this message translates to:
  /// **'Classes for {day}'**
  String classFor(String day);

  /// No description provided for @successAssistance.
  ///
  /// In en, this message translates to:
  /// **'Attendance registered successfully.'**
  String get successAssistance;

  /// No description provided for @saveError.
  ///
  /// In en, this message translates to:
  /// **'Error saving: {e}'**
  String saveError(String e);

  /// No description provided for @successRevertPromotion.
  ///
  /// In en, this message translates to:
  /// **'Promotion reverted successfully.'**
  String get successRevertPromotion;

  /// No description provided for @errorToRevert.
  ///
  /// In en, this message translates to:
  /// **'Error reverting: {e}'**
  String errorToRevert(String e);

  /// No description provided for @registerPayment.
  ///
  /// In en, this message translates to:
  /// **'Register Payment'**
  String get registerPayment;

  /// No description provided for @selectPlan.
  ///
  /// In en, this message translates to:
  /// **'Select a plan'**
  String get selectPlan;

  /// No description provided for @concept.
  ///
  /// In en, this message translates to:
  /// **'Concept'**
  String get concept;

  /// No description provided for @amount.
  ///
  /// In en, this message translates to:
  /// **'Amount'**
  String get amount;

  /// No description provided for @savePayment.
  ///
  /// In en, this message translates to:
  /// **'Save Payment'**
  String get savePayment;

  /// No description provided for @promotionOrChangeLevel.
  ///
  /// In en, this message translates to:
  /// **'Promote or Correct Level'**
  String get promotionOrChangeLevel;

  /// No description provided for @choseNewLevel.
  ///
  /// In en, this message translates to:
  /// **'Select the new level'**
  String get choseNewLevel;

  /// No description provided for @optional.
  ///
  /// In en, this message translates to:
  /// **'optional'**
  String get optional;

  /// No description provided for @studentSuccessPromotion.
  ///
  /// In en, this message translates to:
  /// **'Student promoted successfully!'**
  String get studentSuccessPromotion;

  /// No description provided for @promotionError.
  ///
  /// In en, this message translates to:
  /// **'Error promoting: {e}'**
  String promotionError(String e);

  /// No description provided for @changeRolMember.
  ///
  /// In en, this message translates to:
  /// **'Change Member Role'**
  String get changeRolMember;

  /// No description provided for @instructor.
  ///
  /// In en, this message translates to:
  /// **'instructor'**
  String get instructor;

  /// No description provided for @save.
  ///
  /// In en, this message translates to:
  /// **'Save'**
  String get save;

  /// No description provided for @updateRolSuccess.
  ///
  /// In en, this message translates to:
  /// **'Role updated successfully.'**
  String get updateRolSuccess;

  /// No description provided for @updateRolError.
  ///
  /// In en, this message translates to:
  /// **'Error changing role: {e}'**
  String updateRolError(String e);

  /// No description provided for @successPayment.
  ///
  /// In en, this message translates to:
  /// **'Payment registered successfully.'**
  String get successPayment;

  /// No description provided for @paymentError.
  ///
  /// In en, this message translates to:
  /// **'Error registering payment: {e}'**
  String paymentError(String e);

  /// No description provided for @assignPlan.
  ///
  /// In en, this message translates to:
  /// **'Assign Payment Plan'**
  String get assignPlan;

  /// No description provided for @removeAssignedPlan.
  ///
  /// In en, this message translates to:
  /// **'Remove assigned plan'**
  String get removeAssignedPlan;

  /// No description provided for @withPutLevel.
  ///
  /// In en, this message translates to:
  /// **'No Level'**
  String get withPutLevel;

  /// No description provided for @registerPausedAssistance.
  ///
  /// In en, this message translates to:
  /// **'Register Past Attendance'**
  String get registerPausedAssistance;

  /// No description provided for @levelPromotion.
  ///
  /// In en, this message translates to:
  /// **'Promote Level'**
  String get levelPromotion;

  /// No description provided for @assignTechnic.
  ///
  /// In en, this message translates to:
  /// **'Assign Techniques'**
  String get assignTechnic;

  /// No description provided for @notassignedPaymentPlan.
  ///
  /// In en, this message translates to:
  /// **'No payment plan assigned.'**
  String get notassignedPaymentPlan;

  /// No description provided for @paymentPlanNotFoud.
  ///
  /// In en, this message translates to:
  /// **'Assigned plan (ID: {assignedPlanId}) not found.'**
  String paymentPlanNotFoud(String assignedPlanId);

  /// No description provided for @contactData.
  ///
  /// In en, this message translates to:
  /// **'Contact Data'**
  String get contactData;

  /// No description provided for @saveAndContinue.
  ///
  /// In en, this message translates to:
  /// **'Save and Continue'**
  String get saveAndContinue;

  /// No description provided for @subscriptionExpired.
  ///
  /// In en, this message translates to:
  /// **'Subscription Expired'**
  String get subscriptionExpired;

  /// No description provided for @subscriptionExpiredMessage.
  ///
  /// In en, this message translates to:
  /// **'Your access to teacher tools has been paused. To renew your subscription and reactivate your account, please contact the administrator.'**
  String get subscriptionExpiredMessage;

  /// No description provided for @contactAdmin.
  ///
  /// In en, this message translates to:
  /// **'Contact Administrator'**
  String get contactAdmin;

  /// No description provided for @renewalSubject.
  ///
  /// In en, this message translates to:
  /// **'Subscription Renewal - Warrior Path'**
  String get renewalSubject;

  /// No description provided for @mailError.
  ///
  /// In en, this message translates to:
  /// **'Could not open mail application.'**
  String get mailError;

  /// No description provided for @mailLaunchError.
  ///
  /// In en, this message translates to:
  /// **'Error trying to open mail: {e}'**
  String mailLaunchError(String e);

  /// No description provided for @nameAndMartialArtRequired.
  ///
  /// In en, this message translates to:
  /// **'Name and Martial Art are required.'**
  String get nameAndMartialArtRequired;

  /// No description provided for @needSelectSubSchool.
  ///
  /// In en, this message translates to:
  /// **'If it is a sub-school, you must select the main school.'**
  String get needSelectSubSchool;

  /// No description provided for @notAuthenticatedUser.
  ///
  /// In en, this message translates to:
  /// **'User not authenticated.'**
  String get notAuthenticatedUser;

  /// No description provided for @createSchoolError.
  ///
  /// In en, this message translates to:
  /// **'Error creating school: {e}'**
  String createSchoolError(String e);

  /// No description provided for @crateSchoolStep2.
  ///
  /// In en, this message translates to:
  /// **'Create Your School (Step 2)'**
  String get crateSchoolStep2;

  /// No description provided for @isSubSchool.
  ///
  /// In en, this message translates to:
  /// **'Is it a Sub-School?'**
  String get isSubSchool;

  /// No description provided for @pickAColor.
  ///
  /// In en, this message translates to:
  /// **'Pick a color'**
  String get pickAColor;

  /// No description provided for @select.
  ///
  /// In en, this message translates to:
  /// **'Select'**
  String get select;

  /// No description provided for @addYourFirstLevel.
  ///
  /// In en, this message translates to:
  /// **'Add your first level below.'**
  String get addYourFirstLevel;

  /// No description provided for @addLevel.
  ///
  /// In en, this message translates to:
  /// **'Add Level'**
  String get addLevel;

  /// No description provided for @schoolManagement.
  ///
  /// In en, this message translates to:
  /// **'School Management'**
  String get schoolManagement;

  /// No description provided for @noActiveSchoolError.
  ///
  /// In en, this message translates to:
  /// **'Error: No active school in session.'**
  String get noActiveSchoolError;

  /// No description provided for @myProfileAndActions.
  ///
  /// In en, this message translates to:
  /// **'My Profile & Actions'**
  String get myProfileAndActions;

  /// No description provided for @logOut.
  ///
  /// In en, this message translates to:
  /// **'Log Out'**
  String get logOut;

  /// No description provided for @editMyProfile.
  ///
  /// In en, this message translates to:
  /// **'Edit My Profile'**
  String get editMyProfile;

  /// No description provided for @updateProfileInfo.
  ///
  /// In en, this message translates to:
  /// **'Update your name, photo, or password.'**
  String get updateProfileInfo;

  /// No description provided for @switchProfileSchool.
  ///
  /// In en, this message translates to:
  /// **'Switch Profile/School'**
  String get switchProfileSchool;

  /// No description provided for @accessOtherRoles.
  ///
  /// In en, this message translates to:
  /// **'Access your other roles or schools.'**
  String get accessOtherRoles;

  /// No description provided for @enrollInAnotherSchool.
  ///
  /// In en, this message translates to:
  /// **'Enroll in another School'**
  String get enrollInAnotherSchool;

  /// No description provided for @joinAnotherCommunity.
  ///
  /// In en, this message translates to:
  /// **'Join another community as a student.'**
  String get joinAnotherCommunity;

  /// No description provided for @createNewSchool.
  ///
  /// In en, this message translates to:
  /// **'Create a New School'**
  String get createNewSchool;

  /// No description provided for @expandYourLegacy.
  ///
  /// In en, this message translates to:
  /// **'Expand your legacy or open a new branch.'**
  String get expandYourLegacy;

  /// No description provided for @students.
  ///
  /// In en, this message translates to:
  /// **'Students'**
  String get students;

  /// No description provided for @reject.
  ///
  /// In en, this message translates to:
  /// **'Reject'**
  String get reject;

  /// No description provided for @accept.
  ///
  /// In en, this message translates to:
  /// **'Accept'**
  String get accept;

  /// No description provided for @selectProfile.
  ///
  /// In en, this message translates to:
  /// **'Select Profile'**
  String get selectProfile;

  /// No description provided for @addSchedule.
  ///
  /// In en, this message translates to:
  /// **'Add Schedule'**
  String get addSchedule;

  /// No description provided for @saveSchedule.
  ///
  /// In en, this message translates to:
  /// **'Save Schedule'**
  String get saveSchedule;

  /// No description provided for @confirmDeletion.
  ///
  /// In en, this message translates to:
  /// **'Confirm Deletion'**
  String get confirmDeletion;

  /// No description provided for @confirmDeleteSchedule.
  ///
  /// In en, this message translates to:
  /// **'Are you sure you want to delete this schedule?'**
  String get confirmDeleteSchedule;

  /// No description provided for @manageSchedules.
  ///
  /// In en, this message translates to:
  /// **'Manage Schedules'**
  String get manageSchedules;

  /// No description provided for @eventNoLongerExists.
  ///
  /// In en, this message translates to:
  /// **'This event no longer exists.'**
  String get eventNoLongerExists;

  /// No description provided for @attendees.
  ///
  /// In en, this message translates to:
  /// **'Attendees'**
  String get attendees;

  /// No description provided for @manageGuests.
  ///
  /// In en, this message translates to:
  /// **'Manage Guests'**
  String get manageGuests;

  /// No description provided for @endTime.
  ///
  /// In en, this message translates to:
  /// **'End Time'**
  String get endTime;

  /// No description provided for @startTime.
  ///
  /// In en, this message translates to:
  /// **'Start Time'**
  String get startTime;

  /// No description provided for @daysOfTheWeek.
  ///
  /// In en, this message translates to:
  /// **'Days of the week'**
  String get daysOfTheWeek;

  /// No description provided for @classTitle.
  ///
  /// In en, this message translates to:
  /// **'Class Title'**
  String get classTitle;

  /// No description provided for @classTitleExample.
  ///
  /// In en, this message translates to:
  /// **'Ex: Kids, Adults, Kicks'**
  String get classTitleExample;

  /// No description provided for @scheduleSavedSuccess.
  ///
  /// In en, this message translates to:
  /// **'Schedule saved successfully.'**
  String get scheduleSavedSuccess;

  /// No description provided for @endTimeAfterStartTimeError.
  ///
  /// In en, this message translates to:
  /// **'The end time must be after the start time.'**
  String get endTimeAfterStartTimeError;

  /// No description provided for @pleaseFillAllFields.
  ///
  /// In en, this message translates to:
  /// **'Please fill all required fields.'**
  String get pleaseFillAllFields;

  /// No description provided for @unknownSchool.
  ///
  /// In en, this message translates to:
  /// **'Unknown School'**
  String get unknownSchool;

  /// No description provided for @noActiveProfilesFound.
  ///
  /// In en, this message translates to:
  /// **'No active profiles found.'**
  String get noActiveProfilesFound;

  /// No description provided for @enterAs.
  ///
  /// In en, this message translates to:
  /// **'Enter as {e}'**
  String enterAs(String e);

  /// No description provided for @inSchool.
  ///
  /// In en, this message translates to:
  /// **'in {message}'**
  String inSchool(String message);

  /// No description provided for @yourAnswer.
  ///
  /// In en, this message translates to:
  /// **'Your Answer: {message}'**
  String yourAnswer(String message);

  /// No description provided for @cost.
  ///
  /// In en, this message translates to:
  /// **'Cost'**
  String get cost;

  /// No description provided for @time.
  ///
  /// In en, this message translates to:
  /// **'Time'**
  String get time;

  /// No description provided for @date.
  ///
  /// In en, this message translates to:
  /// **'Date'**
  String get date;

  /// No description provided for @location.
  ///
  /// In en, this message translates to:
  /// **'Location'**
  String get location;

  /// No description provided for @invited.
  ///
  /// In en, this message translates to:
  /// **'Invited'**
  String get invited;

  /// No description provided for @eventDetails.
  ///
  /// In en, this message translates to:
  /// **'Event Details'**
  String get eventDetails;

  /// No description provided for @errorSendingResponse.
  ///
  /// In en, this message translates to:
  /// **'Error sending response: {e}'**
  String errorSendingResponse(String e);

  /// No description provided for @responseSent.
  ///
  /// In en, this message translates to:
  /// **'Response sent: {message}'**
  String responseSent(String message);

  /// No description provided for @manageEvents.
  ///
  /// In en, this message translates to:
  /// **'Manage Events'**
  String get manageEvents;

  /// No description provided for @manageEventsDescription.
  ///
  /// In en, this message translates to:
  /// **'Create exams, tournaments, and seminars.'**
  String get manageEventsDescription;

  /// No description provided for @manageSchedulesDescription.
  ///
  /// In en, this message translates to:
  /// **'Define the shifts and days of your classes.'**
  String get manageSchedulesDescription;

  /// No description provided for @manageLevels.
  ///
  /// In en, this message translates to:
  /// **'Manage Levels'**
  String get manageLevels;

  /// No description provided for @manageTechniques.
  ///
  /// In en, this message translates to:
  /// **'Manage Techniques'**
  String get manageTechniques;

  /// No description provided for @manageFinances.
  ///
  /// In en, this message translates to:
  /// **'Manage Finances'**
  String get manageFinances;

  /// No description provided for @manageFinancesDescription.
  ///
  /// In en, this message translates to:
  /// **'Adjust prices and payment plans.'**
  String get manageFinancesDescription;

  /// No description provided for @editSchoolData.
  ///
  /// In en, this message translates to:
  /// **'Edit School Data'**
  String get editSchoolData;

  /// No description provided for @editSchoolDataDescription.
  ///
  /// In en, this message translates to:
  /// **'Modify the address, phone, description, etc.'**
  String get editSchoolDataDescription;

  /// No description provided for @errorNoActiveSession.
  ///
  /// In en, this message translates to:
  /// **'Error: No active session.'**
  String get errorNoActiveSession;

  /// No description provided for @profileLoadedError.
  ///
  /// In en, this message translates to:
  /// **'Could not load profile.'**
  String get profileLoadedError;

  /// No description provided for @fullName.
  ///
  /// In en, this message translates to:
  /// **'Full Name'**
  String get fullName;

  /// No description provided for @saveChanges.
  ///
  /// In en, this message translates to:
  /// **'Save Changes'**
  String get saveChanges;

  /// No description provided for @emergencyInfoNotice.
  ///
  /// In en, this message translates to:
  /// **'This information will only be visible to your school\'s teachers if necessary.'**
  String get emergencyInfoNotice;

  /// No description provided for @emergencyContactName.
  ///
  /// In en, this message translates to:
  /// **'Emergency Contact Name'**
  String get emergencyContactName;

  /// No description provided for @emergencyContactPhone.
  ///
  /// In en, this message translates to:
  /// **'Emergency Contact Phone'**
  String get emergencyContactPhone;

  /// No description provided for @medicalEmergencyService.
  ///
  /// In en, this message translates to:
  /// **'Medical Emergency Service'**
  String get medicalEmergencyService;

  /// No description provided for @medicalServiceExample.
  ///
  /// In en, this message translates to:
  /// **'Ex: 911, Local Paramedics'**
  String get medicalServiceExample;

  /// No description provided for @relevantMedicalInfo.
  ///
  /// In en, this message translates to:
  /// **'Relevant Medical Information'**
  String get relevantMedicalInfo;

  /// No description provided for @medicalInfoExample.
  ///
  /// In en, this message translates to:
  /// **'Ex: Allergies, asthma, medication, etc.'**
  String get medicalInfoExample;

  /// No description provided for @accountActions.
  ///
  /// In en, this message translates to:
  /// **'Account Actions'**
  String get accountActions;

  /// No description provided for @becomeATeacher.
  ///
  /// In en, this message translates to:
  /// **'Become a teacher and start your journey.'**
  String get becomeATeacher;

  /// No description provided for @myData.
  ///
  /// In en, this message translates to:
  /// **'My Data'**
  String get myData;

  /// No description provided for @myProfile.
  ///
  /// In en, this message translates to:
  /// **'My Profile'**
  String get myProfile;

  /// No description provided for @profileUpdateError.
  ///
  /// In en, this message translates to:
  /// **'Error updating profile: {message}'**
  String profileUpdateError(String message);

  /// No description provided for @profileUpdatedSuccess.
  ///
  /// In en, this message translates to:
  /// **'Profile updated successfully.'**
  String get profileUpdatedSuccess;

  /// No description provided for @noStudentsWithStatus.
  ///
  /// In en, this message translates to:
  /// **'No students with status {state}'**
  String noStudentsWithStatus(String state);

  /// No description provided for @noName.
  ///
  /// In en, this message translates to:
  /// **'No Name'**
  String get noName;

  /// No description provided for @applicationDate.
  ///
  /// In en, this message translates to:
  /// **'Application date: {message}'**
  String applicationDate(String message);

  /// No description provided for @studentAcceptedSuccess.
  ///
  /// In en, this message translates to:
  /// **'Student accepted successfully.'**
  String get studentAcceptedSuccess;

  /// No description provided for @applicationRejected.
  ///
  /// In en, this message translates to:
  /// **'Application rejected.'**
  String get applicationRejected;

  /// No description provided for @monday.
  ///
  /// In en, this message translates to:
  /// **'Monday'**
  String get monday;

  /// No description provided for @tuesday.
  ///
  /// In en, this message translates to:
  /// **'Tuesday'**
  String get tuesday;

  /// No description provided for @wednesday.
  ///
  /// In en, this message translates to:
  /// **'Wednesday'**
  String get wednesday;

  /// No description provided for @thursday.
  ///
  /// In en, this message translates to:
  /// **'Thursday'**
  String get thursday;

  /// No description provided for @friday.
  ///
  /// In en, this message translates to:
  /// **'Friday'**
  String get friday;

  /// No description provided for @saturday.
  ///
  /// In en, this message translates to:
  /// **'Saturday'**
  String get saturday;

  /// No description provided for @sunday.
  ///
  /// In en, this message translates to:
  /// **'Sunday'**
  String get sunday;

  /// No description provided for @noSchedulesDefined.
  ///
  /// In en, this message translates to:
  /// **'No schedules defined.\nPress (+) to add the first one.'**
  String get noSchedulesDefined;

  /// No description provided for @schoolCommunity.
  ///
  /// In en, this message translates to:
  /// **'School Community'**
  String get schoolCommunity;

  /// No description provided for @errorLoadingMembers.
  ///
  /// In en, this message translates to:
  /// **'Error loading members.'**
  String get errorLoadingMembers;

  /// No description provided for @noActiveMembersYet.
  ///
  /// In en, this message translates to:
  /// **'There are no active members in the school yet.'**
  String get noActiveMembersYet;

  /// No description provided for @myPayments.
  ///
  /// In en, this message translates to:
  /// **'My Payments'**
  String get myPayments;

  /// No description provided for @errorLoadingPaymentHistory.
  ///
  /// In en, this message translates to:
  /// **'Error loading your payment history.'**
  String get errorLoadingPaymentHistory;

  /// No description provided for @noPaymentsRegisteredYet.
  ///
  /// In en, this message translates to:
  /// **'You have no registered payments yet.'**
  String get noPaymentsRegisteredYet;

  /// No description provided for @paymentDetails.
  ///
  /// In en, this message translates to:
  /// **'{concept}\nPaid on {date}'**
  String paymentDetails(String concept, String date);

  /// No description provided for @myProgress.
  ///
  /// In en, this message translates to:
  /// **'My Progress'**
  String get myProgress;

  /// No description provided for @yourPath.
  ///
  /// In en, this message translates to:
  /// **'Your Path'**
  String get yourPath;

  /// No description provided for @promotionHistory.
  ///
  /// In en, this message translates to:
  /// **'Promotion History'**
  String get promotionHistory;

  /// No description provided for @assignedTechniques.
  ///
  /// In en, this message translates to:
  /// **'Assigned Techniques'**
  String get assignedTechniques;

  /// No description provided for @myAttendanceHistory.
  ///
  /// In en, this message translates to:
  /// **'My Attendance History'**
  String get myAttendanceHistory;

  /// No description provided for @noLevelAssignedYet.
  ///
  /// In en, this message translates to:
  /// **'You don\'t have a level assigned yet.'**
  String get noLevelAssignedYet;

  /// No description provided for @yourCurrentLevel.
  ///
  /// In en, this message translates to:
  /// **'Your Current Level'**
  String get yourCurrentLevel;

  /// No description provided for @progressionSystemNotDefined.
  ///
  /// In en, this message translates to:
  /// **'The progression system has not been defined.'**
  String get progressionSystemNotDefined;

  /// No description provided for @teacherHasNotAssignedTechniques.
  ///
  /// In en, this message translates to:
  /// **'Your teacher has not assigned you techniques yet.'**
  String get teacherHasNotAssignedTechniques;

  /// No description provided for @noPromotionsRegisteredYet.
  ///
  /// In en, this message translates to:
  /// **'You have no promotions registered yet.'**
  String get noPromotionsRegisteredYet;

  /// No description provided for @couldNotOpenVideo.
  ///
  /// In en, this message translates to:
  /// **'Could not open video: {link}'**
  String couldNotOpenVideo(String link);

  /// No description provided for @noDescriptionAvailable.
  ///
  /// In en, this message translates to:
  /// **'No description available.'**
  String get noDescriptionAvailable;

  /// No description provided for @watchTechniqueVideo.
  ///
  /// In en, this message translates to:
  /// **'Watch Technique Video'**
  String get watchTechniqueVideo;

  /// No description provided for @close.
  ///
  /// In en, this message translates to:
  /// **'Close'**
  String get close;

  /// No description provided for @mySchool.
  ///
  /// In en, this message translates to:
  /// **'My School'**
  String get mySchool;

  /// No description provided for @couldNotLoadSchoolInfo.
  ///
  /// In en, this message translates to:
  /// **'Could not load school information.'**
  String get couldNotLoadSchoolInfo;

  /// No description provided for @schoolNameLabel.
  ///
  /// In en, this message translates to:
  /// **'School name'**
  String get schoolNameLabel;

  /// No description provided for @martialArt.
  ///
  /// In en, this message translates to:
  /// **'Martial Art'**
  String get martialArt;

  /// No description provided for @address.
  ///
  /// In en, this message translates to:
  /// **'Address'**
  String get address;

  /// No description provided for @upcomingEvents.
  ///
  /// In en, this message translates to:
  /// **'Upcoming Events'**
  String get upcomingEvents;

  /// No description provided for @classSchedule.
  ///
  /// In en, this message translates to:
  /// **'Class Schedule'**
  String get classSchedule;

  /// No description provided for @scheduleNotDefinedYet.
  ///
  /// In en, this message translates to:
  /// **'The schedule has not been defined yet.'**
  String get scheduleNotDefinedYet;

  /// No description provided for @manageChildren.
  ///
  /// In en, this message translates to:
  /// **'Manage Children'**
  String get manageChildren;

  /// No description provided for @manageChildrenSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Add your children and manage their profiles.'**
  String get manageChildrenSubtitle;

  /// No description provided for @iAmAParent.
  ///
  /// In en, this message translates to:
  /// **'I\'m a Parent/Guardian'**
  String get iAmAParent;

  /// No description provided for @parentFlowDescription.
  ///
  /// In en, this message translates to:
  /// **'By choosing \'Parent/Guardian\', the next step will be to add your children\'s profiles.'**
  String get parentFlowDescription;

  /// No description provided for @addChild.
  ///
  /// In en, this message translates to:
  /// **'Add Child'**
  String get addChild;

  /// No description provided for @childFullName.
  ///
  /// In en, this message translates to:
  /// **'Child\'s Full Name'**
  String get childFullName;

  /// No description provided for @addChildTitle.
  ///
  /// In en, this message translates to:
  /// **'Add Child\'s Profile'**
  String get addChildTitle;

  /// No description provided for @addChildDescription.
  ///
  /// In en, this message translates to:
  /// **'Complete the data below to create a separate profile for your child. You will be able to enroll them in schools and manage their progress.'**
  String get addChildDescription;

  /// No description provided for @childData.
  ///
  /// In en, this message translates to:
  /// **'Child\'s Data'**
  String get childData;

  /// No description provided for @saveChild.
  ///
  /// In en, this message translates to:
  /// **'Save Child'**
  String get saveChild;

  /// No description provided for @creatingChildProfile.
  ///
  /// In en, this message translates to:
  /// **'Creating child\'s profile...'**
  String get creatingChildProfile;

  /// No description provided for @childProfileCreatedSuccess.
  ///
  /// In en, this message translates to:
  /// **'Child\'s profile created successfully.'**
  String get childProfileCreatedSuccess;

  /// No description provided for @childProfileCreatedError.
  ///
  /// In en, this message translates to:
  /// **'Error creating child\'s profile: {e}'**
  String childProfileCreatedError(String e);

  /// No description provided for @requiredField.
  ///
  /// In en, this message translates to:
  /// **'This field is required.'**
  String get requiredField;

  /// No description provided for @guardianPanel.
  ///
  /// In en, this message translates to:
  /// **'Guardian Panel'**
  String get guardianPanel;

  /// No description provided for @myChildren.
  ///
  /// In en, this message translates to:
  /// **'My Children'**
  String get myChildren;

  /// No description provided for @noChildrenAdded.
  ///
  /// In en, this message translates to:
  /// **'You haven\'t added any child profiles yet. Press (+) to start.'**
  String get noChildrenAdded;

  /// No description provided for @errorLoadingChildren.
  ///
  /// In en, this message translates to:
  /// **'Error loading your children\'s profiles.'**
  String get errorLoadingChildren;

  /// No description provided for @noActiveProfilesMessage.
  ///
  /// In en, this message translates to:
  /// **'This profile is not yet enrolled in any school.'**
  String get noActiveProfilesMessage;

  /// No description provided for @enrollInSchool.
  ///
  /// In en, this message translates to:
  /// **'Enroll in a School'**
  String get enrollInSchool;

  /// No description provided for @searchForNewSchool.
  ///
  /// In en, this message translates to:
  /// **'Search for a New School'**
  String get searchForNewSchool;

  /// No description provided for @alreadyLinkedToSchool.
  ///
  /// In en, this message translates to:
  /// **'You already have a link with this school.'**
  String get alreadyLinkedToSchool;

  /// No description provided for @confirmApplicationTitle.
  ///
  /// In en, this message translates to:
  /// **'Confirm Application'**
  String get confirmApplicationTitle;

  /// No description provided for @confirmApplicationMessage.
  ///
  /// In en, this message translates to:
  /// **'Do you want to send your application to join \"{schoolName}\"?'**
  String confirmApplicationMessage(String schoolName);

  /// No description provided for @send.
  ///
  /// In en, this message translates to:
  /// **'Send'**
  String get send;

  /// No description provided for @applicationSentSuccess.
  ///
  /// In en, this message translates to:
  /// **'Application to \"{schoolName}\" sent!'**
  String applicationSentSuccess(String schoolName);

  /// No description provided for @applicationSentError.
  ///
  /// In en, this message translates to:
  /// **'Error sending application: {e}'**
  String applicationSentError(String e);

  /// No description provided for @noNewSchoolsFound.
  ///
  /// In en, this message translates to:
  /// **'No new schools found.'**
  String get noNewSchoolsFound;

  /// No description provided for @apply.
  ///
  /// In en, this message translates to:
  /// **'Apply'**
  String get apply;

  /// No description provided for @noCity.
  ///
  /// In en, this message translates to:
  /// **'No City'**
  String get noCity;

  /// No description provided for @manageProfiles.
  ///
  /// In en, this message translates to:
  /// **'Manage Profiles'**
  String get manageProfiles;

  /// No description provided for @myUser.
  ///
  /// In en, this message translates to:
  /// **'My User'**
  String get myUser;

  /// No description provided for @associatedWith.
  ///
  /// In en, this message translates to:
  /// **'Associated with: {schoolName}'**
  String associatedWith(String schoolName);

  /// No description provided for @searchParentSchool.
  ///
  /// In en, this message translates to:
  /// **'Search for main school'**
  String get searchParentSchool;

  /// No description provided for @associateLaterMessage.
  ///
  /// In en, this message translates to:
  /// **'If you can\'t find the school, you can associate it later from the management panel.'**
  String get associateLaterMessage;

  /// No description provided for @disciplines.
  ///
  /// In en, this message translates to:
  /// **'Disciplines'**
  String get disciplines;

  /// No description provided for @addAtLeastOneDiscipline.
  ///
  /// In en, this message translates to:
  /// **'You must add at least one discipline to your school.'**
  String get addAtLeastOneDiscipline;

  /// No description provided for @addDiscipline.
  ///
  /// In en, this message translates to:
  /// **'Add Discipline'**
  String get addDiscipline;

  /// No description provided for @noDisciplinesAdded.
  ///
  /// In en, this message translates to:
  /// **'No disciplines added yet.'**
  String get noDisciplinesAdded;

  /// No description provided for @defineYourCategories.
  ///
  /// In en, this message translates to:
  /// **'1. Define your Categories'**
  String get defineYourCategories;

  /// No description provided for @categoryName.
  ///
  /// In en, this message translates to:
  /// **'Category Name'**
  String get categoryName;

  /// No description provided for @categoryNameHint.
  ///
  /// In en, this message translates to:
  /// **'Ex: Forms, Katas, Techniques, Weapons'**
  String get categoryNameHint;

  /// No description provided for @categoriesAppearHere.
  ///
  /// In en, this message translates to:
  /// **'The categories you add will appear here.'**
  String get categoriesAppearHere;

  /// No description provided for @addYourTechniques.
  ///
  /// In en, this message translates to:
  /// **'2. Add your Techniques'**
  String get addYourTechniques;

  /// No description provided for @createCategoriesFirst.
  ///
  /// In en, this message translates to:
  /// **'Create categories first, then add your first technique.'**
  String get createCategoriesFirst;

  /// No description provided for @techniqueNumber.
  ///
  /// In en, this message translates to:
  /// **'Technique #{index}'**
  String techniqueNumber(String index);

  /// No description provided for @techniqueName.
  ///
  /// In en, this message translates to:
  /// **'Technique Name *'**
  String get techniqueName;

  /// No description provided for @selectCategory.
  ///
  /// In en, this message translates to:
  /// **'Select a category'**
  String get selectCategory;

  /// No description provided for @categoryLabel.
  ///
  /// In en, this message translates to:
  /// **'Category *'**
  String get categoryLabel;

  /// No description provided for @descriptionOptional.
  ///
  /// In en, this message translates to:
  /// **'Description (optional)'**
  String get descriptionOptional;

  /// No description provided for @videoLinkOptional.
  ///
  /// In en, this message translates to:
  /// **'Video Link (optional)'**
  String get videoLinkOptional;

  /// No description provided for @videoLinkHint.
  ///
  /// In en, this message translates to:
  /// **'https://youtube.com/...'**
  String get videoLinkHint;

  /// No description provided for @addTechnique.
  ///
  /// In en, this message translates to:
  /// **'Add Technique'**
  String get addTechnique;

  /// No description provided for @dontWorryAddEverythingNow.
  ///
  /// In en, this message translates to:
  /// **'Don\'t worry about adding everything now. You can always manage your techniques from your school\'s control panel.'**
  String get dontWorryAddEverythingNow;

  /// No description provided for @atLeastOneCategoryError.
  ///
  /// In en, this message translates to:
  /// **'You must create at least one category.'**
  String get atLeastOneCategoryError;

  /// No description provided for @allTechniquesNeedNameCategoryError.
  ///
  /// In en, this message translates to:
  /// **'All techniques must have a name and a category assigned.'**
  String get allTechniquesNeedNameCategoryError;

  /// No description provided for @techniquesFor.
  ///
  /// In en, this message translates to:
  /// **'Techniques for \"{disciplineName}\"'**
  String techniquesFor(String disciplineName);

  /// No description provided for @configurePricingStep5.
  ///
  /// In en, this message translates to:
  /// **'Configure Pricing (Step 5)'**
  String get configurePricingStep5;

  /// No description provided for @uniqueCostsAndCurrency.
  ///
  /// In en, this message translates to:
  /// **'Unique Costs & Currency'**
  String get uniqueCostsAndCurrency;

  /// No description provided for @currency.
  ///
  /// In en, this message translates to:
  /// **'Currency'**
  String get currency;

  /// No description provided for @inscriptionFee.
  ///
  /// In en, this message translates to:
  /// **'Inscription Fee'**
  String get inscriptionFee;

  /// No description provided for @examFee.
  ///
  /// In en, this message translates to:
  /// **'Fee per Exam'**
  String get examFee;

  /// No description provided for @monthlyFeePlans.
  ///
  /// In en, this message translates to:
  /// **'Monthly Fee Plans'**
  String get monthlyFeePlans;

  /// No description provided for @addNewPlan.
  ///
  /// In en, this message translates to:
  /// **'Add new plan'**
  String get addNewPlan;

  /// No description provided for @addAtLeastOnePlan.
  ///
  /// In en, this message translates to:
  /// **'Add at least one monthly payment plan.'**
  String get addAtLeastOnePlan;

  /// No description provided for @planTitle.
  ///
  /// In en, this message translates to:
  /// **'Plan Title'**
  String get planTitle;

  /// No description provided for @planTitleExample.
  ///
  /// In en, this message translates to:
  /// **'Ex: Family Plan'**
  String get planTitleExample;

  /// No description provided for @monthlyAmount.
  ///
  /// In en, this message translates to:
  /// **'Monthly Amount'**
  String get monthlyAmount;

  /// No description provided for @planDescriptionOptional.
  ///
  /// In en, this message translates to:
  /// **'Description (optional)'**
  String get planDescriptionOptional;

  /// No description provided for @planDescriptionExample.
  ///
  /// In en, this message translates to:
  /// **'Ex: For 2 or more siblings'**
  String get planDescriptionExample;

  /// No description provided for @allPlansNeedTitleAndAmount.
  ///
  /// In en, this message translates to:
  /// **'All plans must have a title and an amount greater than zero.'**
  String get allPlansNeedTitleAndAmount;

  /// No description provided for @reviewAndFinalizeStep6.
  ///
  /// In en, this message translates to:
  /// **'Review and Finalize (Step 6)'**
  String get reviewAndFinalizeStep6;

  /// No description provided for @almostDoneReviewInfo.
  ///
  /// In en, this message translates to:
  /// **'Almost there! Please review that all your school\'s information is correct.'**
  String get almostDoneReviewInfo;

  /// No description provided for @schoolData.
  ///
  /// In en, this message translates to:
  /// **'School Data'**
  String get schoolData;

  /// No description provided for @progressionSystem.
  ///
  /// In en, this message translates to:
  /// **'Progression System'**
  String get progressionSystem;

  /// No description provided for @pricingAndPlans.
  ///
  /// In en, this message translates to:
  /// **'Pricing and Plans'**
  String get pricingAndPlans;

  /// No description provided for @disciplineLabel.
  ///
  /// In en, this message translates to:
  /// **'Discipline: {disciplineName}'**
  String disciplineLabel(String disciplineName);

  /// No description provided for @levelsCreated.
  ///
  /// In en, this message translates to:
  /// **'Levels Created'**
  String get levelsCreated;

  /// No description provided for @techniquesAdded.
  ///
  /// In en, this message translates to:
  /// **'Techniques Added'**
  String get techniquesAdded;

  /// No description provided for @finalizeAndOpenSchool.
  ///
  /// In en, this message translates to:
  /// **'Finalize and Open my School'**
  String get finalizeAndOpenSchool;

  /// No description provided for @errorFinalizing.
  ///
  /// In en, this message translates to:
  /// **'Error finalizing: {e}'**
  String errorFinalizing(String e);

  /// No description provided for @categoriesLabel.
  ///
  /// In en, this message translates to:
  /// **'Categories'**
  String get categoriesLabel;

  /// No description provided for @selectDisciplinesPrompt.
  ///
  /// In en, this message translates to:
  /// **'Select one or more. The first one you choose will be the primary.'**
  String get selectDisciplinesPrompt;

  /// No description provided for @institutionalDataOptional.
  ///
  /// In en, this message translates to:
  /// **'Institutional Data (Optional)'**
  String get institutionalDataOptional;

  /// No description provided for @city.
  ///
  /// In en, this message translates to:
  /// **'City'**
  String get city;

  /// No description provided for @description.
  ///
  /// In en, this message translates to:
  /// **'Description'**
  String get description;

  /// No description provided for @disciplineConfigPanel.
  ///
  /// In en, this message translates to:
  /// **'Discipline Configuration'**
  String get disciplineConfigPanel;

  /// No description provided for @disciplineConfigMessage.
  ///
  /// In en, this message translates to:
  /// **'Select a discipline to configure its levels and techniques. When you\'re done with all of them, press \'Continue\'.'**
  String get disciplineConfigMessage;

  /// No description provided for @statusNotConfigured.
  ///
  /// In en, this message translates to:
  /// **'Not configured'**
  String get statusNotConfigured;

  /// No description provided for @statusConfigured.
  ///
  /// In en, this message translates to:
  /// **'Configured'**
  String get statusConfigured;

  /// No description provided for @continueToPricing.
  ///
  /// In en, this message translates to:
  /// **'Continue to Pricing'**
  String get continueToPricing;

  /// No description provided for @errorLoadingDisciplines.
  ///
  /// In en, this message translates to:
  /// **'Error loading disciplines.'**
  String get errorLoadingDisciplines;

  /// No description provided for @levelsFor.
  ///
  /// In en, this message translates to:
  /// **'Levels for \"{disciplineName}\"'**
  String levelsFor(String disciplineName);

  /// No description provided for @progressionSystemName.
  ///
  /// In en, this message translates to:
  /// **'Progression System Name *'**
  String get progressionSystemName;

  /// No description provided for @progressionSystemHint.
  ///
  /// In en, this message translates to:
  /// **'Ex: Sashes, Belts, Grades'**
  String get progressionSystemHint;

  /// No description provided for @levelsOrderHint.
  ///
  /// In en, this message translates to:
  /// **'Levels (order from lowest to highest)'**
  String get levelsOrderHint;

  /// No description provided for @progressionSystemNameRequired.
  ///
  /// In en, this message translates to:
  /// **'Please give your progression system a name.'**
  String get progressionSystemNameRequired;

  /// No description provided for @allLevelsNeedAName.
  ///
  /// In en, this message translates to:
  /// **'Make sure all levels have a name.'**
  String get allLevelsNeedAName;

  /// No description provided for @noDisciplinesFound.
  ///
  /// In en, this message translates to:
  /// **'No disciplines found.'**
  String get noDisciplinesFound;

  /// No description provided for @levelNameHint.
  ///
  /// In en, this message translates to:
  /// **'Level Name'**
  String get levelNameHint;

  /// No description provided for @configureDiscipline.
  ///
  /// In en, this message translates to:
  /// **'Configure Discipline'**
  String get configureDiscipline;

  /// No description provided for @step1Levels.
  ///
  /// In en, this message translates to:
  /// **'Step 1: Configure Levels'**
  String get step1Levels;

  /// No description provided for @step2Techniques.
  ///
  /// In en, this message translates to:
  /// **'Step 2: Configure Techniques'**
  String get step2Techniques;

  /// No description provided for @continueStep.
  ///
  /// In en, this message translates to:
  /// **'Continue'**
  String get continueStep;

  /// No description provided for @finish.
  ///
  /// In en, this message translates to:
  /// **'Finish & Return to Panel'**
  String get finish;

  /// No description provided for @skipStep.
  ///
  /// In en, this message translates to:
  /// **'Skip this step'**
  String get skipStep;

  /// No description provided for @unsavedChangesWarning.
  ///
  /// In en, this message translates to:
  /// **'You have unsaved changes. Are you sure you want to exit? Progress for this discipline will not be saved.'**
  String get unsavedChangesWarning;

  /// No description provided for @yesExit.
  ///
  /// In en, this message translates to:
  /// **'Yes, exit'**
  String get yesExit;

  /// No description provided for @noStay.
  ///
  /// In en, this message translates to:
  /// **'No, stay'**
  String get noStay;

  /// No description provided for @noDiscipline.
  ///
  /// In en, this message translates to:
  /// **'No Discipline'**
  String get noDiscipline;

  /// No description provided for @selectDiscipline.
  ///
  /// In en, this message translates to:
  /// **'Select a discipline *'**
  String get selectDiscipline;

  /// No description provided for @manageCurriculum.
  ///
  /// In en, this message translates to:
  /// **'Manage Curriculum'**
  String get manageCurriculum;

  /// No description provided for @manageCurriculumDescription.
  ///
  /// In en, this message translates to:
  /// **'Edit levels and techniques for each discipline.'**
  String get manageCurriculumDescription;

  /// No description provided for @curriculumByDiscipline.
  ///
  /// In en, this message translates to:
  /// **'Curriculum by Discipline'**
  String get curriculumByDiscipline;

  /// No description provided for @selectDisciplineToEdit.
  ///
  /// In en, this message translates to:
  /// **'Select a discipline to view and edit its levels and techniques.'**
  String get selectDisciplineToEdit;

  /// No description provided for @curriculumFor.
  ///
  /// In en, this message translates to:
  /// **'Curriculum for {disciplineName}'**
  String curriculumFor(String disciplineName);

  /// No description provided for @saveAllChanges.
  ///
  /// In en, this message translates to:
  /// **'Save All Changes'**
  String get saveAllChanges;

  /// No description provided for @curriculumSaveSuccess.
  ///
  /// In en, this message translates to:
  /// **'Curriculum saved successfully.'**
  String get curriculumSaveSuccess;

  /// No description provided for @manageDisciplines.
  ///
  /// In en, this message translates to:
  /// **'Manage Disciplines'**
  String get manageDisciplines;

  /// No description provided for @active.
  ///
  /// In en, this message translates to:
  /// **'Active'**
  String get active;

  /// No description provided for @inactive.
  ///
  /// In en, this message translates to:
  /// **'Inactive'**
  String get inactive;

  /// No description provided for @schoolDataUpdated.
  ///
  /// In en, this message translates to:
  /// **'School data updated.'**
  String get schoolDataUpdated;

  /// No description provided for @enrollInDiscipline.
  ///
  /// In en, this message translates to:
  /// **'Enroll in Discipline'**
  String get enrollInDiscipline;

  /// No description provided for @selectDisciplineForStudent.
  ///
  /// In en, this message translates to:
  /// **'Select the primary discipline this student will be enrolled in.'**
  String get selectDisciplineForStudent;

  /// No description provided for @noDisciplinesAvailable.
  ///
  /// In en, this message translates to:
  /// **'There are no active disciplines in your school. Go to Management -> Curriculum to create them.'**
  String get noDisciplinesAvailable;

  /// No description provided for @progressFor.
  ///
  /// In en, this message translates to:
  /// **'Progress ({disciplineName})'**
  String progressFor(String disciplineName);

  /// No description provided for @enrollInDisciplines.
  ///
  /// In en, this message translates to:
  /// **'Enroll in Disciplines'**
  String get enrollInDisciplines;

  /// No description provided for @noDisciplinesEnrolled.
  ///
  /// In en, this message translates to:
  /// **'This student is not yet enrolled in any disciplines.'**
  String get noDisciplinesEnrolled;

  /// No description provided for @noProgressSystemForDiscipline.
  ///
  /// In en, this message translates to:
  /// **'This discipline does not have a progression system defined yet.'**
  String get noProgressSystemForDiscipline;

  /// No description provided for @noTechniquesForDiscipline.
  ///
  /// In en, this message translates to:
  /// **'This discipline does not have any techniques defined yet.'**
  String get noTechniquesForDiscipline;

  /// No description provided for @assignTechniquesFor.
  ///
  /// In en, this message translates to:
  /// **'Assign Techniques for {disciplineName}'**
  String assignTechniquesFor(String disciplineName);

  /// No description provided for @saveAssignments.
  ///
  /// In en, this message translates to:
  /// **'Save Assignments'**
  String get saveAssignments;

  /// No description provided for @techniquesAssignedSuccess.
  ///
  /// In en, this message translates to:
  /// **'Techniques assigned successfully.'**
  String get techniquesAssignedSuccess;

  /// No description provided for @noDisciplinesEnrolledStudent.
  ///
  /// In en, this message translates to:
  /// **'You are not yet enrolled in any disciplines.'**
  String get noDisciplinesEnrolledStudent;

  /// No description provided for @planPayment.
  ///
  /// In en, this message translates to:
  /// **'Plan Payment'**
  String get planPayment;

  /// No description provided for @specialPayment.
  ///
  /// In en, this message translates to:
  /// **'Special Payment'**
  String get specialPayment;

  /// No description provided for @editEvent.
  ///
  /// In en, this message translates to:
  /// **'Edit Event'**
  String get editEvent;

  /// No description provided for @createNewEvent.
  ///
  /// In en, this message translates to:
  /// **'Create New Event'**
  String get createNewEvent;

  /// No description provided for @eventTitle.
  ///
  /// In en, this message translates to:
  /// **'Event Title *'**
  String get eventTitle;

  /// No description provided for @pleaseCompleteDateTime.
  ///
  /// In en, this message translates to:
  /// **'Please complete the date and times.'**
  String get pleaseCompleteDateTime;

  /// No description provided for @eventUpdated.
  ///
  /// In en, this message translates to:
  /// **'Event updated.'**
  String get eventUpdated;

  /// No description provided for @eventCreatedInviteStudents.
  ///
  /// In en, this message translates to:
  /// **'Event created! Now you can invite students.'**
  String get eventCreatedInviteStudents;

  /// No description provided for @eventCreationError.
  ///
  /// In en, this message translates to:
  /// **'Error creating event: {e}'**
  String eventCreationError(String e);

  /// No description provided for @selectDate.
  ///
  /// In en, this message translates to:
  /// **'Select Date *'**
  String get selectDate;

  /// No description provided for @locationOptional.
  ///
  /// In en, this message translates to:
  /// **'Location (Optional)'**
  String get locationOptional;

  /// No description provided for @costOptional.
  ///
  /// In en, this message translates to:
  /// **'Cost (Optional)'**
  String get costOptional;

  /// No description provided for @involvedDisciplines.
  ///
  /// In en, this message translates to:
  /// **'Involved Disciplines'**
  String get involvedDisciplines;

  /// No description provided for @selectAtLeastOneDiscipline.
  ///
  /// In en, this message translates to:
  /// **'You must select at least one discipline.'**
  String get selectAtLeastOneDiscipline;

  /// No description provided for @confirmPaymentDelete.
  ///
  /// In en, this message translates to:
  /// **'Are you sure you want to permanently delete this payment?'**
  String get confirmPaymentDelete;

  /// No description provided for @paymentDeletedSuccess.
  ///
  /// In en, this message translates to:
  /// **'Payment deleted successfully.'**
  String get paymentDeletedSuccess;

  /// No description provided for @confirmAttendanceDelete.
  ///
  /// In en, this message translates to:
  /// **'Are you sure you want to delete this attendance? This action only removes the student from this class record, it does not delete the class itself.'**
  String get confirmAttendanceDelete;

  /// No description provided for @assistanceDelete.
  ///
  /// In en, this message translates to:
  /// **'Attendance deleted.'**
  String get assistanceDelete;

  /// No description provided for @unassignTechnique.
  ///
  /// In en, this message translates to:
  /// **'Unassign Technique'**
  String get unassignTechnique;

  /// No description provided for @unassignTechniqueConfirm.
  ///
  /// In en, this message translates to:
  /// **'Are you sure you want to unassign this technique from the student?'**
  String get unassignTechniqueConfirm;

  /// No description provided for @techniqueUnassignedSuccess.
  ///
  /// In en, this message translates to:
  /// **'Technique unassigned successfully.'**
  String get techniqueUnassignedSuccess;

  /// No description provided for @revertPromotionConfirm.
  ///
  /// In en, this message translates to:
  /// **'Are you sure? This will delete the history record and revert the student\'s level to the previous one.'**
  String get revertPromotionConfirm;

  /// No description provided for @revertPromotion.
  ///
  /// In en, this message translates to:
  /// **'Revert Promotion'**
  String get revertPromotion;
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
      <String>['en', 'es', 'pt'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'en':
      return AppLocalizationsEn();
    case 'es':
      return AppLocalizationsEs();
    case 'pt':
      return AppLocalizationsPt();
  }

  throw FlutterError(
    'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
    'an issue with the localizations generation tool. Please file an issue '
    'on GitHub with a reproducible sample app and the gen-l10n configuration '
    'that was used.',
  );
}
