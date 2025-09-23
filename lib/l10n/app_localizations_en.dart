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
  String notesValue(String notes) {
    return 'Notes: $notes';
  }

  @override
  String get notesLabel => 'Notes';

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
  String get studentSuccessPromotion => 'Student promoted successfully!';

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

  @override
  String get saveAndContinue => 'Save and Continue';

  @override
  String get subscriptionExpired => 'Subscription Expired';

  @override
  String get subscriptionExpiredMessage =>
      'Your access to teacher tools has been paused. To renew your subscription and reactivate your account, please contact the administrator.';

  @override
  String get contactAdmin => 'Contact Administrator';

  @override
  String get renewalSubject => 'Subscription Renewal - Warrior Path';

  @override
  String get mailError => 'Could not open mail application.';

  @override
  String mailLaunchError(String e) {
    return 'Error trying to open mail: $e';
  }

  @override
  String get nameAndMartialArtRequired => 'Name and Martial Art are required.';

  @override
  String get needSelectSubSchool =>
      'If it is a sub-school, you must select the main school.';

  @override
  String get notAuthenticatedUser => 'User not authenticated.';

  @override
  String createSchoolError(String e) {
    return 'Error creating school: $e';
  }

  @override
  String get crateSchoolStep2 => 'Create Your School (Step 2)';

  @override
  String get isSubSchool => 'Is it a Sub-School?';

  @override
  String get pickAColor => 'Pick a color';

  @override
  String get select => 'Select';

  @override
  String get configureLevelsStep3 => 'Configure Levels (Step 3)';

  @override
  String get addYourFirstLevel => 'Add your first level below.';

  @override
  String get addLevel => 'Add Level';

  @override
  String get schoolManagement => 'School Management';

  @override
  String get noActiveSchoolError => 'Error: No active school in session.';

  @override
  String get myProfileAndActions => 'My Profile & Actions';

  @override
  String get logOut => 'Log Out';

  @override
  String get editMyProfile => 'Edit My Profile';

  @override
  String get updateProfileInfo => 'Update your name, photo, or password.';

  @override
  String get switchProfileSchool => 'Switch Profile/School';

  @override
  String get accessOtherRoles => 'Access your other roles or schools.';

  @override
  String get enrollInAnotherSchool => 'Enroll in another School';

  @override
  String get joinAnotherCommunity => 'Join another community as a student.';

  @override
  String get createNewSchool => 'Create a New School';

  @override
  String get expandYourLegacy => 'Expand your legacy or open a new branch.';

  @override
  String get students => 'Students';

  @override
  String get reject => 'Reject';

  @override
  String get accept => 'Accept';

  @override
  String get selectProfile => 'Select Profile';

  @override
  String get addSchedule => 'Add Schedule';

  @override
  String get saveSchedule => 'Save Schedule';

  @override
  String get confirmDeletion => 'Confirm Deletion';

  @override
  String get confirmDeleteSchedule =>
      'Are you sure you want to delete this schedule?';

  @override
  String get manageSchedules => 'Manage Schedules';

  @override
  String get confirmDeleteEvent =>
      'Are you sure you want to permanently delete this event? This action cannot be undone.';

  @override
  String get eventDeleted => 'Event deleted.';

  @override
  String get eventNoLongerExists => 'This event no longer exists.';

  @override
  String get attendees => 'Attendees';

  @override
  String get manageGuests => 'Manage Guests';

  @override
  String get noStudentsInvitedYet => 'You haven\'t invited any students yet.';

  @override
  String get endTime => 'End Time';

  @override
  String get startTime => 'Start Time';

  @override
  String get daysOfTheWeek => 'Days of the week';

  @override
  String get classTitle => 'Class Title';

  @override
  String get classTitleExample => 'Ex: Kids, Adults, Kicks';

  @override
  String get scheduleSavedSuccess => 'Schedule saved successfully.';

  @override
  String get endTimeAfterStartTimeError =>
      'The end time must be after the start time.';

  @override
  String get pleaseFillAllFields => 'Please fill all required fields.';

  @override
  String get unknownSchool => 'Unknown School';

  @override
  String get noActiveProfilesFound => 'No active profiles found.';

  @override
  String enterAs(String e) {
    return 'Enter as $e';
  }

  @override
  String inSchool(String message) {
    return 'in $message';
  }

  @override
  String yourAnswer(String message) {
    return 'Your Answer: $message';
  }

  @override
  String get cost => 'Cost';

  @override
  String get time => 'Time';

  @override
  String get date => 'Date';

  @override
  String get location => 'Location';

  @override
  String get invited => 'Invited';

  @override
  String get eventDetails => 'Event Details';

  @override
  String errorSendingResponse(String e) {
    return 'Error sending response: $e';
  }

  @override
  String responseSent(String message) {
    return 'Response sent: $message';
  }

  @override
  String get manageEvents => 'Manage Events';

  @override
  String get manageEventsDescription =>
      'Create exams, tournaments, and seminars.';

  @override
  String get manageSchedulesDescription =>
      'Define the shifts and days of your classes.';

  @override
  String get manageLevels => 'Manage Levels';

  @override
  String get manageLevelsDescription =>
      'Edit the names, colors, and order of the sashes/belts.';

  @override
  String get manageTechniques => 'Manage Techniques';

  @override
  String get manageTechniquesDescription =>
      'Add or modify your school\'s curriculum.';

  @override
  String get manageFinances => 'Manage Finances';

  @override
  String get manageFinancesDescription => 'Adjust prices and payment plans.';

  @override
  String get editSchoolData => 'Edit School Data';

  @override
  String get editSchoolDataDescription =>
      'Modify the address, phone, description, etc.';

  @override
  String get upcoming => 'Upcoming';

  @override
  String get past => 'Past';

  @override
  String get noUpcomingEvents => 'No upcoming events.';

  @override
  String get noPastEvents => 'No past events.';

  @override
  String get errorNoActiveSession => 'Error: No active session.';

  @override
  String get profileLoadedError => 'Could not load profile.';

  @override
  String get fullName => 'Full Name';

  @override
  String get saveChanges => 'Save Changes';

  @override
  String get emergencyInfoNotice =>
      'This information will only be visible to your school\'s teachers if necessary.';

  @override
  String get emergencyContactName => 'Emergency Contact Name';

  @override
  String get emergencyContactPhone => 'Emergency Contact Phone';

  @override
  String get medicalEmergencyService => 'Medical Emergency Service';

  @override
  String get medicalServiceExample => 'Ex: 911, Local Paramedics';

  @override
  String get relevantMedicalInfo => 'Relevant Medical Information';

  @override
  String get medicalInfoExample => 'Ex: Allergies, asthma, medication, etc.';

  @override
  String get accountActions => 'Account Actions';

  @override
  String get becomeATeacher => 'Become a teacher and start your journey.';

  @override
  String get myData => 'My Data';

  @override
  String get myProfile => 'My Profile';

  @override
  String profileUpdateError(String message) {
    return 'Error updating profile: $message';
  }

  @override
  String get profileUpdatedSuccess => 'Profile updated successfully.';

  @override
  String noStudentsWithStatus(String state) {
    return 'No students with status $state';
  }

  @override
  String get noName => 'No Name';

  @override
  String applicationDate(String message) {
    return 'Application date: $message';
  }

  @override
  String get noLevelsConfiguredError =>
      'Your school has no levels configured. Go to Management -> Levels to add them.';

  @override
  String get studentAcceptedSuccess => 'Student accepted successfully.';

  @override
  String get applicationRejected => 'Application rejected.';

  @override
  String get monday => 'Monday';

  @override
  String get tuesday => 'Tuesday';

  @override
  String get wednesday => 'Wednesday';

  @override
  String get thursday => 'Thursday';

  @override
  String get friday => 'Friday';

  @override
  String get saturday => 'Saturday';

  @override
  String get sunday => 'Sunday';

  @override
  String get noSchedulesDefined =>
      'No schedules defined.\nPress (+) to add the first one.';

  @override
  String get schoolCommunity => 'School Community';

  @override
  String get errorLoadingLevels => 'Error loading school levels.';

  @override
  String get errorLoadingMembers => 'Error loading members.';

  @override
  String get noActiveMembersYet =>
      'There are no active members in the school yet.';

  @override
  String get myPayments => 'My Payments';

  @override
  String get errorLoadingPaymentHistory =>
      'Error loading your payment history.';

  @override
  String get noPaymentsRegisteredYet => 'You have no registered payments yet.';

  @override
  String paymentDetails(String concept, String date) {
    return '$concept\nPaid on $date';
  }

  @override
  String get myProgress => 'My Progress';

  @override
  String get couldNotLoadProgress => 'Could not load your progress.';

  @override
  String get yourPath => 'Your Path';

  @override
  String get promotionHistory => 'Promotion History';

  @override
  String get assignedTechniques => 'Assigned Techniques';

  @override
  String get myAttendanceHistory => 'My Attendance History';

  @override
  String get noLevelAssignedYet => 'You don\'t have a level assigned yet.';

  @override
  String get yourCurrentLevel => 'Your Current Level';

  @override
  String get progressionSystemNotDefined =>
      'The progression system has not been defined.';

  @override
  String get teacherHasNotAssignedTechniques =>
      'Your teacher has not assigned you techniques yet.';

  @override
  String get noPromotionsRegisteredYet =>
      'You have no promotions registered yet.';

  @override
  String couldNotOpenVideo(String link) {
    return 'Could not open video: $link';
  }

  @override
  String get noDescriptionAvailable => 'No description available.';

  @override
  String get watchTechniqueVideo => 'Watch Technique Video';

  @override
  String get close => 'Close';

  @override
  String get mySchool => 'My School';

  @override
  String get couldNotLoadSchoolInfo => 'Could not load school information.';

  @override
  String get schoolNameLabel => 'School name';

  @override
  String get martialArt => 'Martial Art';

  @override
  String get address => 'Address';

  @override
  String get upcomingEvents => 'Upcoming Events';

  @override
  String get classSchedule => 'Class Schedule';

  @override
  String get scheduleNotDefinedYet => 'The schedule has not been defined yet.';

  @override
  String get manageChildren => 'Manage Children';

  @override
  String get manageChildrenSubtitle =>
      'Add your children and manage their profiles.';

  @override
  String get iAmAParent => 'I\'m a Parent/Guardian';

  @override
  String get parentFlowDescription =>
      'By choosing \'Parent/Guardian\', the next step will be to add your children\'s profiles.';

  @override
  String get addChild => 'Add Child';

  @override
  String get childProfile => 'Child\'s Profile';

  @override
  String get childFullName => 'Child\'s Full Name';

  @override
  String get addChildTitle => 'Add Child\'s Profile';

  @override
  String get addChildDescription =>
      'Complete the data below to create a separate profile for your child. You will be able to enroll them in schools and manage their progress.';

  @override
  String get childData => 'Child\'s Data';

  @override
  String get saveChild => 'Save Child';

  @override
  String get creatingChildProfile => 'Creating child\'s profile...';

  @override
  String get childProfileCreatedSuccess =>
      'Child\'s profile created successfully.';

  @override
  String childProfileCreatedError(String e) {
    return 'Error creating child\'s profile: $e';
  }

  @override
  String get requiredField => 'This field is required.';

  @override
  String get guardianPanel => 'Guardian Panel';

  @override
  String get myChildren => 'My Children';

  @override
  String get noChildrenAdded =>
      'You haven\'t added any child profiles yet. Press (+) to start.';

  @override
  String get errorLoadingChildren => 'Error loading your children\'s profiles.';

  @override
  String get noActiveProfilesMessage =>
      'This profile is not yet enrolled in any school.';

  @override
  String get enrollInSchool => 'Enroll in a School';

  @override
  String get searchForNewSchool => 'Search for a New School';

  @override
  String get alreadyLinkedToSchool =>
      'You already have a link with this school.';

  @override
  String get confirmApplicationTitle => 'Confirm Application';

  @override
  String confirmApplicationMessage(String schoolName) {
    return 'Do you want to send your application to join \"$schoolName\"?';
  }

  @override
  String get send => 'Send';

  @override
  String applicationSentSuccess(String schoolName) {
    return 'Application to \"$schoolName\" sent!';
  }

  @override
  String applicationSentError(String e) {
    return 'Error sending application: $e';
  }

  @override
  String get errorLoadingSchools => 'Error loading schools.';

  @override
  String get noNewSchoolsFound => 'No new schools found.';

  @override
  String get apply => 'Apply';

  @override
  String get noCity => 'No City';

  @override
  String get manageProfiles => 'Manage Profiles';

  @override
  String get myUser => 'My User';

  @override
  String associatedWith(String schoolName) {
    return 'Associated with: $schoolName';
  }

  @override
  String get searchParentSchool => 'Search for main school';

  @override
  String get associateLaterMessage =>
      'If you can\'t find the school, you can associate it later from the management panel.';

  @override
  String get disciplines => 'Disciplines';

  @override
  String get addAtLeastOneDiscipline =>
      'You must add at least one discipline to your school.';

  @override
  String get disciplineName => 'Discipline Name';

  @override
  String get addDiscipline => 'Add Discipline';

  @override
  String get noDisciplinesAdded => 'No disciplines added yet.';

  @override
  String get baseStyle => 'Base Style';

  @override
  String get selectDisciplineToConfigure =>
      'Select a discipline to configure its levels';

  @override
  String get selectDisciplineToConfigureTechniques =>
      'Select a discipline to configure its techniques';

  @override
  String get configureTechniquesStep4 => 'Add Techniques (Step 4)';

  @override
  String get defineYourCategories => '1. Define your Categories';

  @override
  String get categoryName => 'Category Name';

  @override
  String get categoryNameHint => 'Ex: Forms, Katas, Techniques, Weapons';

  @override
  String get categoriesAppearHere => 'The categories you add will appear here.';

  @override
  String get addYourTechniques => '2. Add your Techniques';

  @override
  String get createCategoriesFirst =>
      'Create categories first, then add your first technique.';

  @override
  String techniqueNumber(String index) {
    return 'Technique #$index';
  }

  @override
  String get techniqueName => 'Technique Name *';

  @override
  String get selectCategory => 'Select a category';

  @override
  String get categoryLabel => 'Category *';

  @override
  String get descriptionOptional => 'Description (optional)';

  @override
  String get videoLinkOptional => 'Video Link (optional)';

  @override
  String get videoLinkHint => 'https://youtube.com/...';

  @override
  String get addTechnique => 'Add Technique';

  @override
  String get dontWorryAddEverythingNow =>
      'Don\'t worry about adding everything now. You can always manage your techniques from your school\'s control panel.';

  @override
  String get atLeastOneCategoryError =>
      'You must create at least one category.';

  @override
  String get allTechniquesNeedNameCategoryError =>
      'All techniques must have a name and a category assigned.';

  @override
  String techniquesFor(String disciplineName) {
    return 'Techniques for \"$disciplineName\"';
  }

  @override
  String get editTechnique => 'Edit Technique';

  @override
  String get curriculumUpdated => 'Curriculum updated.';

  @override
  String get configurePricingStep5 => 'Configure Pricing (Step 5)';

  @override
  String get uniqueCostsAndCurrency => 'Unique Costs & Currency';

  @override
  String get currency => 'Currency';

  @override
  String get inscriptionFee => 'Inscription Fee';

  @override
  String get examFee => 'Fee per Exam';

  @override
  String get monthlyFeePlans => 'Monthly Fee Plans';

  @override
  String get addNewPlan => 'Add new plan';

  @override
  String get addAtLeastOnePlan => 'Add at least one monthly payment plan.';

  @override
  String get planTitle => 'Plan Title';

  @override
  String get planTitleExample => 'Ex: Family Plan';

  @override
  String get monthlyAmount => 'Monthly Amount';

  @override
  String get planDescriptionOptional => 'Description (optional)';

  @override
  String get planDescriptionExample => 'Ex: For 2 or more siblings';

  @override
  String get allPlansNeedTitleAndAmount =>
      'All plans must have a title and an amount greater than zero.';

  @override
  String get reviewAndFinalizeStep6 => 'Review and Finalize (Step 6)';

  @override
  String get almostDoneReviewInfo =>
      'Almost there! Please review that all your school\'s information is correct.';

  @override
  String get schoolData => 'School Data';

  @override
  String get progressionSystem => 'Progression System';

  @override
  String get initialCurriculum => 'Initial Curriculum';

  @override
  String get pricingAndPlans => 'Pricing and Plans';

  @override
  String disciplineLabel(String disciplineName) {
    return 'Discipline: $disciplineName';
  }

  @override
  String get levelsCreated => 'Levels Created';

  @override
  String get techniquesAdded => 'Techniques Added';

  @override
  String get finalizeAndOpenSchool => 'Finalize and Open my School';

  @override
  String errorFinalizing(String e) {
    return 'Error finalizing: $e';
  }

  @override
  String get categoriesLabel => 'Categories';

  @override
  String get selectDisciplinesPrompt =>
      'Select one or more. The first one you choose will be the primary.';

  @override
  String get institutionalDataOptional => 'Institutional Data (Optional)';

  @override
  String get city => 'City';

  @override
  String get description => 'Description';

  @override
  String get disciplineConfigPanel => 'Discipline Configuration';

  @override
  String get disciplineConfigMessage =>
      'Select a discipline to configure its levels and techniques. When you\'re done with all of them, press \'Continue\'.';

  @override
  String get statusNotConfigured => 'Not configured';

  @override
  String get statusConfigured => 'Configured';

  @override
  String get continueToPricing => 'Continue to Pricing';

  @override
  String get errorLoadingDisciplines => 'Error loading disciplines.';

  @override
  String levelsFor(String disciplineName) {
    return 'Levels for \"$disciplineName\"';
  }

  @override
  String get progressionSystemName => 'Progression System Name *';

  @override
  String get progressionSystemHint => 'Ex: Sashes, Belts, Grades';

  @override
  String get levelsOrderHint => 'Levels (order from lowest to highest)';

  @override
  String get levelName => 'Level Name';

  @override
  String get progressionSystemNameRequired =>
      'Please give your progression system a name.';

  @override
  String get allLevelsNeedAName => 'Make sure all levels have a name.';

  @override
  String get noDisciplinesFound => 'No disciplines found.';

  @override
  String get levelModel => 'Level Model';

  @override
  String get levelDeletedSuccess => 'Level deleted successfully.';

  @override
  String get levelNameHint => 'Level Name';

  @override
  String get confirmDeleteLevelMessage =>
      'Are you sure you want to delete this level?';

  @override
  String get noLevelsConfigured => 'No levels configured for this discipline';

  @override
  String get configureDiscipline => 'Configure Discipline';

  @override
  String get step1Levels => 'Step 1: Configure Levels';

  @override
  String get step2Techniques => 'Step 2: Configure Techniques';

  @override
  String get continueStep => 'Continue';

  @override
  String get finish => 'Finish & Return to Panel';

  @override
  String get skipStep => 'Skip this step';

  @override
  String get unsavedChangesWarning =>
      'You have unsaved changes. Are you sure you want to exit? Progress for this discipline will not be saved.';

  @override
  String get yesExit => 'Yes, exit';

  @override
  String get noStay => 'No, stay';

  @override
  String get noDiscipline => 'No Discipline';

  @override
  String get selectDiscipline => 'Select a discipline *';

  @override
  String get manageCurriculum => 'Manage Curriculum';

  @override
  String get manageCurriculumDescription =>
      'Edit levels and techniques for each discipline.';

  @override
  String get curriculumByDiscipline => 'Curriculum by Discipline';

  @override
  String get selectDisciplineToEdit =>
      'Select a discipline to view and edit its levels and techniques.';

  @override
  String curriculumFor(String disciplineName) {
    return 'Curriculum for $disciplineName';
  }

  @override
  String get saveAllChanges => 'Save All Changes';

  @override
  String get curriculumSaveSuccess => 'Curriculum saved successfully.';

  @override
  String get manageDisciplines => 'Manage Disciplines';

  @override
  String get active => 'Active';

  @override
  String get inactive => 'Inactive';

  @override
  String get newDiscipline => 'New Discipline';

  @override
  String get schoolDataUpdated => 'School data updated.';

  @override
  String get enrollInDiscipline => 'Enroll in Discipline';

  @override
  String get selectDisciplineForStudent =>
      'Select the primary discipline this student will be enrolled in.';

  @override
  String get noDisciplinesAvailable =>
      'There are no active disciplines in your school. Go to Management -> Curriculum to create them.';

  @override
  String progressFor(String disciplineName) {
    return 'Progress ($disciplineName)';
  }

  @override
  String get enrollInDisciplines => 'Enroll in Disciplines';

  @override
  String get noDisciplinesEnrolled =>
      'This student is not yet enrolled in any disciplines.';

  @override
  String get enroll => 'Enroll';

  @override
  String get unenroll => 'Unenroll';

  @override
  String confirmUnenroll(String studentName, String disciplineName) {
    return 'Are you sure you want to unenroll $studentName from the $disciplineName discipline?';
  }

  @override
  String get noProgressSystemForDiscipline =>
      'This discipline does not have a progression system defined yet.';

  @override
  String get noTechniquesForDiscipline =>
      'This discipline does not have any techniques defined yet.';

  @override
  String assignTechniquesFor(String disciplineName) {
    return 'Assign Techniques for $disciplineName';
  }

  @override
  String get saveAssignments => 'Save Assignments';

  @override
  String get techniquesAssignedSuccess => 'Techniques assigned successfully.';

  @override
  String get noDisciplinesEnrolledStudent =>
      'You are not yet enrolled in any disciplines.';

  @override
  String get errorLoadingProgress =>
      'An error occurred while loading your progress.';
}
