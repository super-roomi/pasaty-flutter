// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get appTitle => 'Masar Alburhan';

  @override
  String get welcomeToPasaty => 'Welcome to Masar Alburhan!';

  @override
  String get phoneNumber => 'Phone Number';

  @override
  String get phoneNumberHint => '07XX XXX XXXX';

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
      'Couldn\'t connect to the server. Check your internet connection.';

  @override
  String get unsupportedRole => 'This account type is not supported in the app';

  @override
  String get greetingMorning => 'Good morning';

  @override
  String get greetingAfternoon => 'Good afternoon';

  @override
  String get greetingEvening => 'Good evening';

  @override
  String get todayAtAGlance => 'Today';

  @override
  String get runPending => 'Not yet';

  @override
  String nextRunIn(String time) {
    return 'Starts in $time';
  }

  @override
  String hoursMinutesShort(int h, int m) {
    return '${h}h ${m}m';
  }

  @override
  String minutesShort(int m) {
    return '${m}m';
  }

  @override
  String get noRunsToday => 'No runs recorded today yet';

  @override
  String get errorUnexpectedResponse =>
      'The server sent an unexpected response. Please try again.';

  @override
  String get errorSessionExpired =>
      'Your session has expired. Please sign in again.';

  @override
  String get errorNotAllowed => 'You do not have permission to do that.';

  @override
  String get errorNotFound => 'We could not find what you were looking for.';

  @override
  String get errorConflict =>
      'That is not possible right now. Refresh and try again.';

  @override
  String get errorServer =>
      'The server ran into a problem. Please try again shortly.';

  @override
  String get errorUnknown => 'Something went wrong. Please try again.';

  @override
  String get signInSubtitle => 'Sign in to follow your child\'s school run.';

  @override
  String get enterPhoneNumber => 'Enter your phone number';

  @override
  String get enterPassword => 'Enter your password';

  @override
  String get showPassword => 'Show password';

  @override
  String get hidePassword => 'Hide password';

  @override
  String get accountsManagedBySchool =>
      'Accounts are created for you by Masar Alburhan. Contact us if you cannot sign in.';

  @override
  String get signingIn => 'Signing in…';

  @override
  String get status => 'Status';

  @override
  String get liveUpdatesPaused =>
      'Live updates paused — this may be out of date';

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
  String get privacyPolicy => 'Privacy Policy';

  @override
  String get privacyPolicyDescription =>
      'How we collect, use, and protect your data';

  @override
  String get couldNotOpenLink => 'Could not open the link';

  @override
  String get deleteAccount => 'Delete Account';

  @override
  String get deleteAccountDescription =>
      'Permanently remove your account and data';

  @override
  String get deleteAccountDialogTitle => 'Delete your account?';

  @override
  String get deleteAccountDialogMessage =>
      'This permanently removes your account and the data linked to it. It cannot be undone.';

  @override
  String get busRoute => 'Bus Route';

  @override
  String get busId => 'Bus ID';

  @override
  String get notAssigned => 'Not assigned';

  @override
  String get tripProgress => 'Trip progress';

  @override
  String get etaBusArriving => 'Bus arriving now';

  @override
  String get etaHomeArriving => 'Arriving home now';

  @override
  String get etaWaiting => 'Waiting for update';

  @override
  String get stepHome => 'Home';

  @override
  String get stepOnBus => 'On the bus';

  @override
  String get stepSchool => 'School';

  @override
  String get atHome => 'At home';

  @override
  String get onBus => 'On bus';

  @override
  String get inSchool => 'In school';

  @override
  String get undo => 'Undo';

  @override
  String markedAbsent(String name) {
    return '$name marked absent';
  }

  @override
  String get pastTrips => 'Past Trips';

  @override
  String get noPastTrips => 'No trips recorded in this period';

  @override
  String historyIncomplete(int count) {
    return '$count days could not be loaded — pull to refresh to try again';
  }

  @override
  String get present => 'Present';

  @override
  String get noRunRecorded => 'No run recorded';

  @override
  String get tripDetails => 'Trip Details';

  @override
  String get parentLabel => 'Parent';

  @override
  String get pickDate => 'Pick a date';

  @override
  String get loadEarlier => 'Load earlier days';

  @override
  String get noTripOnDate => 'No trip was recorded on this date';

  @override
  String get allHome => 'All home';

  @override
  String get noActiveTripsMessage =>
      'There is no trip running right now. Live trip progress will appear here once the driver starts the route.';

  @override
  String get studentStatus => 'Student Status';

  @override
  String get account => 'Account';

  @override
  String get support => 'Support';

  @override
  String get contactUs => 'Contact us';

  @override
  String get contactUsDescription =>
      'Questions about the trip? Message us on WhatsApp.';

  @override
  String get contactViaWhatsapp => 'Contact us via WhatsApp';

  @override
  String get couldNotOpenWhatsapp => 'Could not open WhatsApp';

  @override
  String get endSessionDialogTitle => 'Are you sure?';

  @override
  String get cancel => 'Cancel';

  @override
  String get ok => 'OK';

  @override
  String get startSession => 'Start Session';

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
      'Morning run: 6:00 - 9:00 AM\nAfternoon run: 1:00 - 4:00 PM';

  @override
  String get attendanceTitle => 'Attendance';

  @override
  String get attendanceHint =>
      'Tap a student when they board the bus. Swipe left to mark them absent.';

  @override
  String get startDropoffs => 'Start drop-offs';

  @override
  String get nextPickup => 'Next pickup';

  @override
  String pickupRemaining(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count students to pick up',
      one: '1 student to pick up',
      zero: 'No students to pick up',
    );
    return '$_temp0';
  }

  @override
  String get allPickedUp => 'All students have been picked up';

  @override
  String get nextDropoff => 'Next drop-off';

  @override
  String dropoffRemaining(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count students still on the bus',
      one: '1 student still on the bus',
      zero: 'No students still on the bus',
    );
    return '$_temp0';
  }

  @override
  String get upNext => 'Up next';

  @override
  String get allDroppedOff => 'All students have been dropped off';

  @override
  String get backToAttendance => 'Back to attendance';

  @override
  String get routeMap => 'Route map';

  @override
  String get centreOnMe => 'Centre on me';

  @override
  String get fitRoute => 'Fit route';

  @override
  String get mapNotConfigured => 'Map is not configured for this build';

  @override
  String get noRouteGeometry => 'This route has no map data yet';

  @override
  String get trackingNotificationTitle => 'Run in progress';

  @override
  String get trackingNotificationText =>
      'Sharing the bus location until the run ends';

  @override
  String get locationDisabled => 'Location services are off';

  @override
  String get locationDenied => 'Location permission denied';

  @override
  String get locationUnavailable => 'Location unavailable';

  @override
  String get locationNotReporting =>
      'Location is not reaching the server. Check your connection — the school cannot see the bus.';

  @override
  String get locationDisclosureTitle => 'Location sharing during the run';

  @override
  String get locationDisclosureMessage =>
      'While this run is active, Masar Alburhan collects and sends your precise location to our servers so we can monitor the bus. Reporting continues while the app is in the background or the screen is locked, and stops when the run ends.';

  @override
  String get continueLabel => 'Continue';

  @override
  String get back => 'Back';

  @override
  String get resumeRun => 'Resume run';

  @override
  String get runInProgressNotice => 'A run is in progress';

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
  String get noStudentsLinked => 'No students are linked to your account';

  @override
  String get retry => 'Retry';

  @override
  String get etaMinutesUnit => 'min';

  @override
  String get etaUntilPickup => 'until pickup';

  @override
  String get etaUntilHome => 'until home';

  @override
  String etaArrivesBy(String time) {
    return 'Arrives by $time';
  }

  @override
  String etaKm(String km) {
    return '$km km';
  }

  @override
  String etaMeters(int m) {
    return '$m m away';
  }

  @override
  String etaStale(int m) {
    return 'Last known $m min, not updating';
  }

  @override
  String get allAtSchool => 'All at school';

  @override
  String get notifications => 'Notifications';

  @override
  String get noNotifications => 'No notifications yet';

  @override
  String get clearAll => 'Clear all';

  @override
  String get justNow => 'Just now';

  @override
  String minutesAgo(int count) {
    return '$count min ago';
  }

  @override
  String hoursAgo(int count) {
    return '$count h ago';
  }

  @override
  String daysAgo(int count) {
    return '$count d ago';
  }

  @override
  String get openSettings => 'Open Settings';

  @override
  String get locationBlockedTitle => 'Location permission is turned off';

  @override
  String get locationBlockedMessage =>
      'Masar Alburhan needs your location to report the bus position while a run is active. Turn on location access for this app in Settings, then start the run again.';

  @override
  String get locationReducedAccuracy =>
      'Precise Location is off, so your position is too imprecise to report and the bus is not visible. Turn on Precise Location for this app in Settings.';

  @override
  String get absenceNotBookedLabel => 'Not booked';

  @override
  String get driverNotRiding => 'Not riding today';

  @override
  String driverNotRidingNote(String name) {
    return 'A parent took $name off this morning\'s run. Do not wait at this stop.';
  }

  @override
  String get driverSkipStop => 'Skip this stop';

  @override
  String get driverBoardAnyway => 'They turned up — board';

  @override
  String get absencePickMorning => 'Which morning?';

  @override
  String get absenceDayToday => 'This morning';

  @override
  String get absenceDayTomorrow => 'Tomorrow';

  @override
  String get absenceTodayPassed => 'This morning\'s run is over';

  @override
  String absenceBookedOn(String name, String day) {
    return 'Booked — $name will not be collected on $day.';
  }

  @override
  String absenceConfirmDayMessage(String name, String day) {
    return 'The bus will not stop for $name on $day.';
  }

  @override
  String get absenceBookedLabel => 'Booked';

  @override
  String get planAhead => 'Plan ahead';

  @override
  String get manageAbsence => 'Bus attendance';

  @override
  String get absenceConfirmTitle => 'Skip the bus?';

  @override
  String get absenceConfirmAction => 'Yes, skip';

  @override
  String get absenceRangeConfirmTitle => 'Skip these mornings?';

  @override
  String absenceRangeConfirmMessage(String name) {
    return 'The bus will not stop for $name on the days you picked.';
  }

  @override
  String absenceBooked(String name) {
    return 'Booked — $name will not be collected.';
  }

  @override
  String get absenceBookedLive => 'Done — the driver has been told.';

  @override
  String absenceCancelled(String name) {
    return '$name is back on the bus.';
  }

  @override
  String absenceAlreadyBoarded(String name) {
    return '$name is already on the bus. Call the driver if you need them taken off.';
  }

  @override
  String get absenceRunFinished => 'This morning\'s run has finished.';

  @override
  String get absenceRunStarted =>
      'This morning\'s run has already started. Call the driver.';

  @override
  String get absenceSkippedChip => 'Not riding';

  @override
  String get absencePickDays => 'Choose days';

  @override
  String get absenceUndo => 'Put back on the bus';

  @override
  String absenceRangeTooLong(int count) {
    return 'Pick at most $count days at a time.';
  }

  @override
  String absencePartlyBooked(int booked, int total) {
    return '$booked of $total mornings booked.';
  }

  @override
  String absenceMorningOnly(String name) {
    return 'Morning runs only. If plans change, the driver can still pick $name up.';
  }

  @override
  String absenceMorningsCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count mornings',
      one: '1 morning',
    );
    return '$_temp0';
  }
}
