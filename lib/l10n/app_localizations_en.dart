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
  String get teacherLower => 'teacher';

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

  @override
  String get password => 'Password';

  @override
  String get home => 'Home';

  @override
  String get student => 'Student';

  @override
  String get studentLower => 'student';

  @override
  String get managment => 'Management';

  @override
  String get profile => 'Profile';

  @override
  String get actives => 'Active';

  @override
  String get pending => 'Pending';

  @override
  String get inactives => 'Inactive';

  @override
  String get general => 'General';

  @override
  String get assistance => 'Attendance';

  @override
  String get payments => 'Payments';

  @override
  String get payment => 'Payment';

  @override
  String get progress => 'Progress';

  @override
  String get technics => 'Techniques';

  @override
  String get facturation => 'Billing';

  @override
  String get changeAssignedPlan => 'Change Assigned Plan';

  @override
  String get personalData => 'Personal Data';

  @override
  String get birdthDate => 'Date of Birth';

  @override
  String get gender => 'Gender';

  @override
  String get years => 'years';

  @override
  String get phone => 'Phone';

  @override
  String get emergencyInfo => 'Emergency Information';

  @override
  String get contact => 'Contact';

  @override
  String get medService => 'Medical Service';

  @override
  String get medInfo => 'Medical Information';

  @override
  String get noSpecify => 'Not specified';

  @override
  String get changeRol => 'Change Role';

  @override
  String get noPayment => 'There are no payments registered for this student.';

  @override
  String get errorLoadHistory => 'Error loading history.';

  @override
  String get noRegisterAssitance =>
      'There are no attendance records for this student.';

  @override
  String get classRoom => 'Class';

  @override
  String get removeAssistance => 'Remove this attendance';

  @override
  String get confirm => 'Confirm';

  @override
  String get removeAssistanceCOnfirmation =>
      'Are you sure you want to remove this attendance from the student\'s record?';

  @override
  String get cancel => 'Cancel';

  @override
  String get eliminate => 'Delete';

  @override
  String get assistanceDelete => 'Attendance deleted.';

  @override
  String deleteError(String e) {
    return 'Error deleting: $e';
  }

  @override
  String get loadProgressError => 'Error loading progress.';

  @override
  String get noHistPromotion => 'This student has no promotion history.';

  @override
  String rolUpdatedTo(String rol) {
    return 'Role updated to $rol';
  }

  @override
  String get invalidRegisterPromotion => 'Invalid promotion record';

  @override
  String get deleteLevel => 'Deleted Level';

  @override
  String promotionTo(String level) {
    return 'Promoted to $level';
  }

  @override
  String get notes => 'Notes';

  @override
  String notesWith(Object notesWith) {
    return 'Notes: $notesWith';
  }

  @override
  String notesValue(String notes) {
    return 'Notes: $notes';
  }

  @override
  String get revertPromotion => 'Revert Promotion';

  @override
  String get revertThisPromotion => 'Revert this promotion';

  @override
  String get confirmReverPromotion =>
      'Are you sure you want to delete this promotion record? \n\nThis will revert the student\'s current level to their previous one.';

  @override
  String get yesRevert => 'Yes, Revert';

  @override
  String get maleGender => 'Male';

  @override
  String get femaleGender => 'Female';

  @override
  String get otherGender => 'Other';

  @override
  String get noSpecifyGender => 'Prefers not to say';

  @override
  String get noClassForTHisDay =>
      'There were no classes scheduled for the selected day.';

  @override
  String classFor(String day) {
    return 'Classes for $day';
  }

  @override
  String get successAssistance => 'Attendance registered successfully.';

  @override
  String saveError(String e) {
    return 'Error saving: $e';
  }

  @override
  String get successRevertPromotion => 'Promotion reverted successfully.';

  @override
  String errorToRevert(String e) {
    return 'Error reverting: $e';
  }

  @override
  String get registerPayment => 'Register Payment';

  @override
  String get payPlan => 'Plan Payment';

  @override
  String get paySpecial => 'Special Payment';

  @override
  String get selectPlan => 'Select a plan';

  @override
  String get concept => 'Concept';

  @override
  String get amount => 'Amount';

  @override
  String get savePayment => 'Save Payment';

  @override
  String get promotionOrChangeLevel => 'Promote or Correct Level';

  @override
  String get choseNewLevel => 'Select the new level';

  @override
  String get optional => 'optional';

  @override
  String get studentSuccessPromotion => 'Student successfully promoted!';

  @override
  String promotionError(String e) {
    return 'Error promoting: $e';
  }

  @override
  String get changeRolMember => 'Change Member Role';

  @override
  String get instructor => 'instructor';

  @override
  String get save => 'Save';

  @override
  String get updateRolSuccess => 'Role updated successfully.';

  @override
  String updateRolError(String e) {
    return 'Error changing role: $e';
  }

  @override
  String get successPayment => 'Payment registered successfully.';

  @override
  String paymentError(String e) {
    return 'Error registering payment: $e';
  }

  @override
  String get assignPlan => 'Assign Payment Plan';

  @override
  String get removeAssignedPlan => 'Remove assigned plan';

  @override
  String get withPutLevel => 'No Level';

  @override
  String get registerPausedAssistance => 'Register Past Attendance';

  @override
  String get errorLevelLoad => 'Could not load the student\'s current level.';

  @override
  String get levelPromotion => 'Promote Level';

  @override
  String get assignTechnic => 'Assign Techniques';

  @override
  String get studentNotAssignedTechnics =>
      'This student has no assigned techniques.';

  @override
  String get notassignedPaymentPlan => 'No payment plan assigned.';

  @override
  String paymentPlanNotFoud(String assignedPlanId) {
    return 'Assigned plan (ID: $assignedPlanId) not found.';
  }

  @override
  String get contactData => 'Contact Data';
}
