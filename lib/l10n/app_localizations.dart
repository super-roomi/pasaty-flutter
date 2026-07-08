import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_ar.dart';
import 'app_localizations_en.dart';

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
    Locale('ar'),
    Locale('en'),
  ];

  /// No description provided for @rimaAhmed.
  ///
  /// In en, this message translates to:
  /// **'Rima Ahmed'**
  String get rimaAhmed;

  /// No description provided for @mohammedAhmed.
  ///
  /// In en, this message translates to:
  /// **'Mohammed Ahmed'**
  String get mohammedAhmed;

  /// No description provided for @appTitle.
  ///
  /// In en, this message translates to:
  /// **'Masar Alburhan'**
  String get appTitle;

  /// No description provided for @welcomeToPasaty.
  ///
  /// In en, this message translates to:
  /// **'Welcome to Masar Alburhan!'**
  String get welcomeToPasaty;

  /// No description provided for @phoneNumber.
  ///
  /// In en, this message translates to:
  /// **'Phone Number'**
  String get phoneNumber;

  /// No description provided for @phoneNumberHint.
  ///
  /// In en, this message translates to:
  /// **'07XX XXX XXXX'**
  String get phoneNumberHint;

  /// No description provided for @role.
  ///
  /// In en, this message translates to:
  /// **'Role'**
  String get role;

  /// No description provided for @selectRole.
  ///
  /// In en, this message translates to:
  /// **'Select Role'**
  String get selectRole;

  /// No description provided for @driverRole.
  ///
  /// In en, this message translates to:
  /// **'Driver'**
  String get driverRole;

  /// No description provided for @parentRole.
  ///
  /// In en, this message translates to:
  /// **'Parent'**
  String get parentRole;

  /// No description provided for @staffRole.
  ///
  /// In en, this message translates to:
  /// **'Staff'**
  String get staffRole;

  /// No description provided for @logIn.
  ///
  /// In en, this message translates to:
  /// **'Login'**
  String get logIn;

  /// No description provided for @logOut.
  ///
  /// In en, this message translates to:
  /// **'Log Out'**
  String get logOut;

  /// No description provided for @signOutOfYourAccount.
  ///
  /// In en, this message translates to:
  /// **'Sign out of your account'**
  String get signOutOfYourAccount;

  /// No description provided for @logOutDialogMessage.
  ///
  /// In en, this message translates to:
  /// **'Please confirm you want to log out of your account.'**
  String get logOutDialogMessage;

  /// No description provided for @password.
  ///
  /// In en, this message translates to:
  /// **'Password'**
  String get password;

  /// No description provided for @passwordHint.
  ///
  /// In en, this message translates to:
  /// **'Enter your password'**
  String get passwordHint;

  /// No description provided for @invalidCredentials.
  ///
  /// In en, this message translates to:
  /// **'Invalid phone number or password'**
  String get invalidCredentials;

  /// No description provided for @connectionError.
  ///
  /// In en, this message translates to:
  /// **'Could not connect to the server. Please try again.'**
  String get connectionError;

  /// No description provided for @loginFailed.
  ///
  /// In en, this message translates to:
  /// **'Login failed. Please try again.'**
  String get loginFailed;

  /// No description provided for @unsupportedRole.
  ///
  /// In en, this message translates to:
  /// **'This account type is not supported in the app'**
  String get unsupportedRole;

  /// No description provided for @status.
  ///
  /// In en, this message translates to:
  /// **'Status'**
  String get status;

  /// No description provided for @payments.
  ///
  /// In en, this message translates to:
  /// **'Payments'**
  String get payments;

  /// No description provided for @profile.
  ///
  /// In en, this message translates to:
  /// **'Profile'**
  String get profile;

  /// No description provided for @history.
  ///
  /// In en, this message translates to:
  /// **'History'**
  String get history;

  /// No description provided for @settings.
  ///
  /// In en, this message translates to:
  /// **'Settings'**
  String get settings;

  /// No description provided for @language.
  ///
  /// In en, this message translates to:
  /// **'Language'**
  String get language;

  /// No description provided for @englishLanguage.
  ///
  /// In en, this message translates to:
  /// **'English'**
  String get englishLanguage;

  /// No description provided for @arabicLanguage.
  ///
  /// In en, this message translates to:
  /// **'Arabic'**
  String get arabicLanguage;

  /// No description provided for @managePersonalInformation.
  ///
  /// In en, this message translates to:
  /// **'Manage Personal Information'**
  String get managePersonalInformation;

  /// No description provided for @grade.
  ///
  /// In en, this message translates to:
  /// **'Grade'**
  String get grade;

  /// No description provided for @fourthGrade.
  ///
  /// In en, this message translates to:
  /// **'4th Grade'**
  String get fourthGrade;

  /// No description provided for @busRoute.
  ///
  /// In en, this message translates to:
  /// **'Bus Route'**
  String get busRoute;

  /// No description provided for @busId.
  ///
  /// In en, this message translates to:
  /// **'Bus ID'**
  String get busId;

  /// No description provided for @payBusFeesWithQi.
  ///
  /// In en, this message translates to:
  /// **'Pay your bus fees with Qi'**
  String get payBusFeesWithQi;

  /// No description provided for @noActiveTrips.
  ///
  /// In en, this message translates to:
  /// **'No Active Trips'**
  String get noActiveTrips;

  /// No description provided for @noActiveTripsMessage.
  ///
  /// In en, this message translates to:
  /// **'The bus is currently resting at the depot. We\'ll notify you as soon as the next route begins.'**
  String get noActiveTripsMessage;

  /// No description provided for @boardingStatus.
  ///
  /// In en, this message translates to:
  /// **'Boarding Status'**
  String get boardingStatus;

  /// No description provided for @boarded.
  ///
  /// In en, this message translates to:
  /// **'Boarded'**
  String get boarded;

  /// No description provided for @contactDriver.
  ///
  /// In en, this message translates to:
  /// **'Contact Driver'**
  String get contactDriver;

  /// No description provided for @contactDriverDescription.
  ///
  /// In en, this message translates to:
  /// **'Worried about delays? Checking on Rima and Mohammed?'**
  String get contactDriverDescription;

  /// No description provided for @callSamer.
  ///
  /// In en, this message translates to:
  /// **'Call Samer'**
  String get callSamer;

  /// No description provided for @currentStatus.
  ///
  /// In en, this message translates to:
  /// **'Current Status'**
  String get currentStatus;

  /// No description provided for @arrivingSoon.
  ///
  /// In en, this message translates to:
  /// **'Arriving Soon'**
  String get arrivingSoon;

  /// No description provided for @timeLeft.
  ///
  /// In en, this message translates to:
  /// **'Time Left'**
  String get timeLeft;

  /// No description provided for @aboutSixMinutesTillArrival.
  ///
  /// In en, this message translates to:
  /// **'About 6 mins till arrival'**
  String get aboutSixMinutesTillArrival;

  /// No description provided for @test.
  ///
  /// In en, this message translates to:
  /// **'Test'**
  String get test;

  /// No description provided for @activeDeliverySession.
  ///
  /// In en, this message translates to:
  /// **'Active Delivery Session'**
  String get activeDeliverySession;

  /// No description provided for @endSession.
  ///
  /// In en, this message translates to:
  /// **'End Session'**
  String get endSession;

  /// No description provided for @endSessionDialogTitle.
  ///
  /// In en, this message translates to:
  /// **'Are you sure?'**
  String get endSessionDialogTitle;

  /// No description provided for @endSessionDialogMessage.
  ///
  /// In en, this message translates to:
  /// **'Please confirm you want to end your session.'**
  String get endSessionDialogMessage;

  /// No description provided for @cancel.
  ///
  /// In en, this message translates to:
  /// **'Cancel'**
  String get cancel;

  /// No description provided for @ok.
  ///
  /// In en, this message translates to:
  /// **'OK'**
  String get ok;

  /// No description provided for @busNumber.
  ///
  /// In en, this message translates to:
  /// **'Bus #{number}'**
  String busNumber(String number);

  /// No description provided for @totalStops.
  ///
  /// In en, this message translates to:
  /// **'Total Stops'**
  String get totalStops;

  /// No description provided for @totalStopsCount.
  ///
  /// In en, this message translates to:
  /// **'{count}'**
  String totalStopsCount(int count);

  /// No description provided for @approxDuration.
  ///
  /// In en, this message translates to:
  /// **'Approx. Duration'**
  String get approxDuration;

  /// No description provided for @durationMinutes.
  ///
  /// In en, this message translates to:
  /// **'{minutes} minutes'**
  String durationMinutes(int minutes);

  /// No description provided for @startSession.
  ///
  /// In en, this message translates to:
  /// **'Start Session'**
  String get startSession;

  /// No description provided for @readyToGo.
  ///
  /// In en, this message translates to:
  /// **'Ready to Go?'**
  String get readyToGo;

  /// No description provided for @confirmStudentsOnBoard.
  ///
  /// In en, this message translates to:
  /// **'Please confirm that all present students are on board.'**
  String get confirmStudentsOnBoard;

  /// No description provided for @broadcastUpdates.
  ///
  /// In en, this message translates to:
  /// **'Broadcast Updates'**
  String get broadcastUpdates;

  /// No description provided for @majorDelay.
  ///
  /// In en, this message translates to:
  /// **'Major Delay 15m+'**
  String get majorDelay;

  /// No description provided for @minorDelay.
  ///
  /// In en, this message translates to:
  /// **'Minor Delay 5m+'**
  String get minorDelay;

  /// No description provided for @onSchedule.
  ///
  /// In en, this message translates to:
  /// **'On Schedule'**
  String get onSchedule;

  /// No description provided for @morningRun.
  ///
  /// In en, this message translates to:
  /// **'Morning run'**
  String get morningRun;

  /// No description provided for @afternoonRun.
  ///
  /// In en, this message translates to:
  /// **'Afternoon run'**
  String get afternoonRun;

  /// No description provided for @currentRunLabel.
  ///
  /// In en, this message translates to:
  /// **'Current run'**
  String get currentRunLabel;

  /// No description provided for @noRunScheduled.
  ///
  /// In en, this message translates to:
  /// **'No run scheduled right now'**
  String get noRunScheduled;

  /// No description provided for @runWindowsInfo.
  ///
  /// In en, this message translates to:
  /// **'Morning run: 6:00 – 9:00 AM\nAfternoon run: 1:00 – 4:00 PM'**
  String get runWindowsInfo;

  /// No description provided for @attendanceTitle.
  ///
  /// In en, this message translates to:
  /// **'Attendance'**
  String get attendanceTitle;

  /// No description provided for @attendanceHint.
  ///
  /// In en, this message translates to:
  /// **'Tap a student when they board the bus — swipe left to mark them absent.'**
  String get attendanceHint;

  /// No description provided for @startDropoffs.
  ///
  /// In en, this message translates to:
  /// **'Start drop-offs'**
  String get startDropoffs;

  /// No description provided for @nextPickup.
  ///
  /// In en, this message translates to:
  /// **'Next pickup'**
  String get nextPickup;

  /// No description provided for @pickupRemaining.
  ///
  /// In en, this message translates to:
  /// **'{count} students to pick up'**
  String pickupRemaining(int count);

  /// No description provided for @allPickedUp.
  ///
  /// In en, this message translates to:
  /// **'All students have been picked up'**
  String get allPickedUp;

  /// No description provided for @nextDropoff.
  ///
  /// In en, this message translates to:
  /// **'Next drop-off'**
  String get nextDropoff;

  /// No description provided for @dropoffRemaining.
  ///
  /// In en, this message translates to:
  /// **'{count} students still on the bus'**
  String dropoffRemaining(int count);

  /// No description provided for @upNext.
  ///
  /// In en, this message translates to:
  /// **'Up next'**
  String get upNext;

  /// No description provided for @allDroppedOff.
  ///
  /// In en, this message translates to:
  /// **'All students have been dropped off'**
  String get allDroppedOff;

  /// No description provided for @backToAttendance.
  ///
  /// In en, this message translates to:
  /// **'Back to attendance'**
  String get backToAttendance;

  /// No description provided for @myRoute.
  ///
  /// In en, this message translates to:
  /// **'My route'**
  String get myRoute;

  /// No description provided for @noRoutesAssigned.
  ///
  /// In en, this message translates to:
  /// **'No route is assigned to you yet'**
  String get noRoutesAssigned;

  /// No description provided for @studentsTitle.
  ///
  /// In en, this message translates to:
  /// **'Students'**
  String get studentsTitle;

  /// No description provided for @board.
  ///
  /// In en, this message translates to:
  /// **'Board'**
  String get board;

  /// No description provided for @dropoff.
  ///
  /// In en, this message translates to:
  /// **'Drop off'**
  String get dropoff;

  /// No description provided for @absent.
  ///
  /// In en, this message translates to:
  /// **'Absent'**
  String get absent;

  /// No description provided for @completeRun.
  ///
  /// In en, this message translates to:
  /// **'Complete run'**
  String get completeRun;

  /// No description provided for @completeRunDialogMessage.
  ///
  /// In en, this message translates to:
  /// **'This finalizes today\'s statuses for every student. Continue?'**
  String get completeRunDialogMessage;

  /// No description provided for @runCompleted.
  ///
  /// In en, this message translates to:
  /// **'Run completed'**
  String get runCompleted;

  /// No description provided for @summaryTotal.
  ///
  /// In en, this message translates to:
  /// **'Total students'**
  String get summaryTotal;

  /// No description provided for @summaryArrived.
  ///
  /// In en, this message translates to:
  /// **'Arrived at school'**
  String get summaryArrived;

  /// No description provided for @summaryDroppedOff.
  ///
  /// In en, this message translates to:
  /// **'Dropped off home'**
  String get summaryDroppedOff;

  /// No description provided for @summaryAbsent.
  ///
  /// In en, this message translates to:
  /// **'Absent'**
  String get summaryAbsent;

  /// No description provided for @summaryDuration.
  ///
  /// In en, this message translates to:
  /// **'Trip duration'**
  String get summaryDuration;

  /// No description provided for @statusWaiting.
  ///
  /// In en, this message translates to:
  /// **'Waiting'**
  String get statusWaiting;

  /// No description provided for @statusBoarded.
  ///
  /// In en, this message translates to:
  /// **'Boarded'**
  String get statusBoarded;

  /// No description provided for @statusArrived.
  ///
  /// In en, this message translates to:
  /// **'Arrived'**
  String get statusArrived;

  /// No description provided for @statusAbsent.
  ///
  /// In en, this message translates to:
  /// **'Absent'**
  String get statusAbsent;

  /// No description provided for @statusDroppedOff.
  ///
  /// In en, this message translates to:
  /// **'Dropped off'**
  String get statusDroppedOff;

  /// No description provided for @waitingForDriver.
  ///
  /// In en, this message translates to:
  /// **'Waiting for the driver to start the run'**
  String get waitingForDriver;

  /// No description provided for @noStudentsLinked.
  ///
  /// In en, this message translates to:
  /// **'No students are linked to your account'**
  String get noStudentsLinked;

  /// No description provided for @actionFailed.
  ///
  /// In en, this message translates to:
  /// **'Action failed'**
  String get actionFailed;

  /// No description provided for @retry.
  ///
  /// In en, this message translates to:
  /// **'Retry'**
  String get retry;
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
      <String>['ar', 'en'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'ar':
      return AppLocalizationsAr();
    case 'en':
      return AppLocalizationsEn();
  }

  throw FlutterError(
    'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
    'an issue with the localizations generation tool. Please file an issue '
    'on GitHub with a reproducible sample app and the gen-l10n configuration '
    'that was used.',
  );
}
