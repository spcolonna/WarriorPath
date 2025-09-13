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
