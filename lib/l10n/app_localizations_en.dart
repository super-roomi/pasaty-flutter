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
  String get appTitle => 'Bus Tracker';

  @override
  String get welcomeToPasaty => 'Welcome to Pasaty!';

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
}
