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

  /// No description provided for @profileErrorTitle.
  ///
  /// In en, this message translates to:
  /// **'Profile Error'**
  String get profileErrorTitle;

  /// No description provided for @profileErrorContent.
  ///
  /// In en, this message translates to:
  /// **'Could not load your profile. Please try again.'**
  String get profileErrorContent;

  /// No description provided for @accessDeniedTitle.
  ///
  /// In en, this message translates to:
  /// **'Access Denied'**
  String get accessDeniedTitle;

  /// No description provided for @accessDeniedContent.
  ///
  /// In en, this message translates to:
  /// **'You do not have an active role in any school.'**
  String get accessDeniedContent;

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

  /// No description provided for @language.
  ///
  /// In en, this message translates to:
  /// **'Language'**
  String get language;

  /// No description provided for @ok.
  ///
  /// In en, this message translates to:
  /// **'Ok'**
  String get ok;

  /// A welcome message with the user's name
  ///
  /// In en, this message translates to:
  /// **'Welcome, {userName}!'**
  String welcomeTitle(String userName);

  /// No description provided for @teacher.
  ///
  /// In en, this message translates to:
  /// **'Teacher'**
  String get teacher;

  /// No description provided for @teacherLower.
  ///
  /// In en, this message translates to:
  /// **'teacher'**
  String get teacherLower;

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

  /// No description provided for @studentLower.
  ///
  /// In en, this message translates to:
  /// **'student'**
  String get studentLower;

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

  /// No description provided for @technics.
  ///
  /// In en, this message translates to:
  /// **'Techniques'**
  String get technics;

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

  /// No description provided for @errorLoadHistory.
  ///
  /// In en, this message translates to:
  /// **'Error loading history.'**
  String get errorLoadHistory;

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

  /// No description provided for @removeAssistance.
  ///
  /// In en, this message translates to:
  /// **'Remove this attendance'**
  String get removeAssistance;

  /// No description provided for @confirm.
  ///
  /// In en, this message translates to:
  /// **'Confirm'**
  String get confirm;

  /// No description provided for @removeAssistanceCOnfirmation.
  ///
  /// In en, this message translates to:
  /// **'Are you sure you want to remove this attendance from the student\'s record?'**
  String get removeAssistanceCOnfirmation;

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

  /// No description provided for @assistanceDelete.
  ///
  /// In en, this message translates to:
  /// **'Attendance deleted.'**
  String get assistanceDelete;

  /// No description provided for @deleteError.
  ///
  /// In en, this message translates to:
  /// **'Error deleting: {e}'**
  String deleteError(String e);

  /// No description provided for @loadProgressError.
  ///
  /// In en, this message translates to:
  /// **'Error loading progress.'**
  String get loadProgressError;

  /// No description provided for @noHistPromotion.
  ///
  /// In en, this message translates to:
  /// **'This student has no promotion history.'**
  String get noHistPromotion;

  /// No description provided for @rolUpdatedTo.
  ///
  /// In en, this message translates to:
  /// **'Role updated to {rol}'**
  String rolUpdatedTo(String rol);

  /// No description provided for @invalidRegisterPromotion.
  ///
  /// In en, this message translates to:
  /// **'Invalid promotion record'**
  String get invalidRegisterPromotion;

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

  /// No description provided for @notes.
  ///
  /// In en, this message translates to:
  /// **'Notes'**
  String get notes;

  /// No description provided for @notesWith.
  ///
  /// In en, this message translates to:
  /// **'Notes: {notesWith}'**
  String notesWith(Object notesWith);

  /// No description provided for @notesValue.
  ///
  /// In en, this message translates to:
  /// **'Notes: {notes}'**
  String notesValue(String notes);

  /// No description provided for @revertPromotion.
  ///
  /// In en, this message translates to:
  /// **'Revert Promotion'**
  String get revertPromotion;

  /// No description provided for @revertThisPromotion.
  ///
  /// In en, this message translates to:
  /// **'Revert this promotion'**
  String get revertThisPromotion;

  /// No description provided for @confirmReverPromotion.
  ///
  /// In en, this message translates to:
  /// **'Are you sure you want to delete this promotion record? \n\nThis will revert the student\'s current level to their previous one.'**
  String get confirmReverPromotion;

  /// No description provided for @yesRevert.
  ///
  /// In en, this message translates to:
  /// **'Yes, Revert'**
  String get yesRevert;

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

  /// No description provided for @payPlan.
  ///
  /// In en, this message translates to:
  /// **'Plan Payment'**
  String get payPlan;

  /// No description provided for @paySpecial.
  ///
  /// In en, this message translates to:
  /// **'Special Payment'**
  String get paySpecial;

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
  /// **'Student successfully promoted!'**
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

  /// No description provided for @errorLevelLoad.
  ///
  /// In en, this message translates to:
  /// **'Could not load the student\'s current level.'**
  String get errorLevelLoad;

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

  /// No description provided for @studentNotAssignedTechnics.
  ///
  /// In en, this message translates to:
  /// **'This student has no assigned techniques.'**
  String get studentNotAssignedTechnics;

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
