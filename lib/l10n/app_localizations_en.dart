// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get appName => 'Warrior Path';

  @override
  String get appSlogan => 'Be a warrior, create your path';

  @override
  String get emailLabel => 'Email';

  @override
  String get loginButton => 'Log In';

  @override
  String get createAccountButton => 'Create Account';

  @override
  String get forgotPasswordLink => 'Forgot your password?';

  @override
  String get profileErrorTitle => 'Profile Error';

  @override
  String get profileErrorContent =>
      'Could not load your profile. Please try again.';

  @override
  String get accessDeniedTitle => 'Access Denied';

  @override
  String get accessDeniedContent =>
      'You do not have an active role in any school.';

  @override
  String get loginErrorTitle => 'Login Error';

  @override
  String get loginErrorUserNotFound => 'No user found for that email.';

  @override
  String get loginErrorWrongPassword =>
      'Wrong password provided for that user.';

  @override
  String get loginErrorInvalidCredential =>
      'The credentials provided are incorrect.';

  @override
  String get unexpectedError => 'An unexpected error occurred.';

  @override
  String get registrationErrorTitle => 'Registration Error';

  @override
  String get registrationErrorContent =>
      'Could not complete registration. The email may already be in use or the password is too weak.';

  @override
  String get errorTitle => 'Error';

  @override
  String genericErrorContent(String errorDetails) {
    return 'An error occurred: $errorDetails';
  }

  @override
  String get language => 'Language';

  @override
  String get ok => 'Ok';

  @override
  String welcomeTitle(String userName) {
    return 'Welcome, $userName!';
  }

  @override
  String get teacher => 'Teacher';

  @override
  String get sessionError => 'Error: Invalid session.';

  @override
  String get noSchedulerClass => 'There are no classes scheduled for today.';

  @override
  String get choseClass => 'Select Class';

  @override
  String get todayClass => 'Today\'s Classes';

  @override
  String get takeAssistance => 'Take Attendance';

  @override
  String get loading => 'Loading...';

  @override
  String get activeStudents => 'Active Students';

  @override
  String get pendingApplication => 'Pending Applications';
}
