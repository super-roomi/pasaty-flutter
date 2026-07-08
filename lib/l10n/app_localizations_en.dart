// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get rimaAhmed => 'Rima Ahmed';

  @override
  String get mohammedAhmed => 'Mohammed Ahmed';

  @override
  String get appTitle => 'Masar Alburhan';

  @override
  String get welcomeToPasaty => 'Welcome to Masar Alburhan!';

  @override
  String get phoneNumber => 'Phone Number';

  @override
  String get phoneNumberHint => '07XX XXX XXXX';

  @override
  String get role => 'Role';

  @override
  String get selectRole => 'Select Role';

  @override
  String get driverRole => 'Driver';

  @override
  String get parentRole => 'Parent';

  @override
  String get staffRole => 'Staff';

  @override
  String get logIn => 'Login';

  @override
  String get logOut => 'Log Out';

  @override
  String get signOutOfYourAccount => 'Sign out of your account';

  @override
  String get logOutDialogMessage =>
      'Please confirm you want to log out of your account.';

  @override
  String get password => 'Password';

  @override
  String get passwordHint => 'Enter your password';

  @override
  String get invalidCredentials => 'Invalid phone number or password';

  @override
  String get connectionError =>
      'Could not connect to the server. Please try again.';

  @override
  String get loginFailed => 'Login failed. Please try again.';

  @override
  String get unsupportedRole => 'This account type is not supported in the app';

  @override
  String get status => 'Status';

  @override
  String get payments => 'Payments';

  @override
  String get profile => 'Profile';

  @override
  String get history => 'History';

  @override
  String get settings => 'Settings';

  @override
  String get language => 'Language';

  @override
  String get englishLanguage => 'English';

  @override
  String get arabicLanguage => 'Arabic';

  @override
  String get managePersonalInformation => 'Manage Personal Information';

  @override
  String get grade => 'Grade';

  @override
  String get fourthGrade => '4th Grade';

  @override
  String get busRoute => 'Bus Route';

  @override
  String get busId => 'Bus ID';

  @override
  String get payBusFeesWithQi => 'Pay your bus fees with Qi';

  @override
  String get noActiveTrips => 'No Active Trips';

  @override
  String get noActiveTripsMessage =>
      'The bus is currently resting at the depot. We\'ll notify you as soon as the next route begins.';

  @override
  String get boardingStatus => 'Boarding Status';

  @override
  String get boarded => 'Boarded';

  @override
  String get contactDriver => 'Contact Driver';

  @override
  String get contactDriverDescription =>
      'Worried about delays? Checking on Rima and Mohammed?';

  @override
  String get callSamer => 'Call Samer';

  @override
  String get currentStatus => 'Current Status';

  @override
  String get arrivingSoon => 'Arriving Soon';

  @override
  String get timeLeft => 'Time Left';

  @override
  String get aboutSixMinutesTillArrival => 'About 6 mins till arrival';

  @override
  String get test => 'Test';

  @override
  String get activeDeliverySession => 'Active Delivery Session';

  @override
  String get endSession => 'End Session';

  @override
  String get endSessionDialogTitle => 'Are you sure?';

  @override
  String get endSessionDialogMessage =>
      'Please confirm you want to end your session.';

  @override
  String get cancel => 'Cancel';

  @override
  String get ok => 'OK';

  @override
  String busNumber(String number) {
    return 'Bus #$number';
  }

  @override
  String get totalStops => 'Total Stops';

  @override
  String totalStopsCount(int count) {
    return '$count';
  }

  @override
  String get approxDuration => 'Approx. Duration';

  @override
  String durationMinutes(int minutes) {
    return '$minutes minutes';
  }

  @override
  String get startSession => 'Start Session';

  @override
  String get readyToGo => 'Ready to Go?';

  @override
  String get confirmStudentsOnBoard =>
      'Please confirm that all present students are on board.';

  @override
  String get broadcastUpdates => 'Broadcast Updates';

  @override
  String get majorDelay => 'Major Delay 15m+';

  @override
  String get minorDelay => 'Minor Delay 5m+';

  @override
  String get onSchedule => 'On Schedule';

  @override
  String get morningRun => 'Morning run';

  @override
  String get afternoonRun => 'Afternoon run';

  @override
  String get currentRunLabel => 'Current run';

  @override
  String get noRunScheduled => 'No run scheduled right now';

  @override
  String get runWindowsInfo =>
      'Morning run: 6:00 – 9:00 AM\nAfternoon run: 1:00 – 4:00 PM';

  @override
  String get attendanceTitle => 'Attendance';

  @override
  String get attendanceHint =>
      'Tap a student when they board the bus — swipe left to mark them absent.';

  @override
  String get startDropoffs => 'Start drop-offs';

  @override
  String get nextPickup => 'Next pickup';

  @override
  String pickupRemaining(int count) {
    return '$count students to pick up';
  }

  @override
  String get allPickedUp => 'All students have been picked up';

  @override
  String get nextDropoff => 'Next drop-off';

  @override
  String dropoffRemaining(int count) {
    return '$count students still on the bus';
  }

  @override
  String get upNext => 'Up next';

  @override
  String get allDroppedOff => 'All students have been dropped off';

  @override
  String get backToAttendance => 'Back to attendance';

  @override
  String get myRoute => 'My route';

  @override
  String get noRoutesAssigned => 'No route is assigned to you yet';

  @override
  String get studentsTitle => 'Students';

  @override
  String get board => 'Board';

  @override
  String get dropoff => 'Drop off';

  @override
  String get absent => 'Absent';

  @override
  String get completeRun => 'Complete run';

  @override
  String get completeRunDialogMessage =>
      'This finalizes today\'s statuses for every student. Continue?';

  @override
  String get runCompleted => 'Run completed';

  @override
  String get summaryTotal => 'Total students';

  @override
  String get summaryArrived => 'Arrived at school';

  @override
  String get summaryDroppedOff => 'Dropped off home';

  @override
  String get summaryAbsent => 'Absent';

  @override
  String get summaryDuration => 'Trip duration';

  @override
  String get statusWaiting => 'Waiting';

  @override
  String get statusBoarded => 'Boarded';

  @override
  String get statusArrived => 'Arrived';

  @override
  String get statusAbsent => 'Absent';

  @override
  String get statusDroppedOff => 'Dropped off';

  @override
  String get waitingForDriver => 'Waiting for the driver to start the run';

  @override
  String get noStudentsLinked => 'No students are linked to your account';

  @override
  String get actionFailed => 'Action failed';

  @override
  String get retry => 'Retry';
}
