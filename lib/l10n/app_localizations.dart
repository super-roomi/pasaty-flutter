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
  /// **'Couldn\'t connect to the server. Check your internet connection.'**
  String get connectionError;

  /// No description provided for @unsupportedRole.
  ///
  /// In en, this message translates to:
  /// **'This account type is not supported in the app'**
  String get unsupportedRole;

  /// No description provided for @greetingMorning.
  ///
  /// In en, this message translates to:
  /// **'Good morning'**
  String get greetingMorning;

  /// No description provided for @greetingAfternoon.
  ///
  /// In en, this message translates to:
  /// **'Good afternoon'**
  String get greetingAfternoon;

  /// No description provided for @greetingEvening.
  ///
  /// In en, this message translates to:
  /// **'Good evening'**
  String get greetingEvening;

  /// No description provided for @todayAtAGlance.
  ///
  /// In en, this message translates to:
  /// **'Today'**
  String get todayAtAGlance;

  /// No description provided for @runPending.
  ///
  /// In en, this message translates to:
  /// **'Not yet'**
  String get runPending;

  /// No description provided for @nextRunIn.
  ///
  /// In en, this message translates to:
  /// **'Starts in {time}'**
  String nextRunIn(String time);

  /// No description provided for @hoursMinutesShort.
  ///
  /// In en, this message translates to:
  /// **'{h}h {m}m'**
  String hoursMinutesShort(int h, int m);

  /// No description provided for @minutesShort.
  ///
  /// In en, this message translates to:
  /// **'{m}m'**
  String minutesShort(int m);

  /// No description provided for @noRunsToday.
  ///
  /// In en, this message translates to:
  /// **'No runs recorded today yet'**
  String get noRunsToday;

  /// No description provided for @errorUnexpectedResponse.
  ///
  /// In en, this message translates to:
  /// **'The server sent an unexpected response. Please try again.'**
  String get errorUnexpectedResponse;

  /// No description provided for @errorSessionExpired.
  ///
  /// In en, this message translates to:
  /// **'Your session has expired. Please sign in again.'**
  String get errorSessionExpired;

  /// No description provided for @errorNotAllowed.
  ///
  /// In en, this message translates to:
  /// **'You do not have permission to do that.'**
  String get errorNotAllowed;

  /// No description provided for @errorNotFound.
  ///
  /// In en, this message translates to:
  /// **'We could not find what you were looking for.'**
  String get errorNotFound;

  /// No description provided for @errorConflict.
  ///
  /// In en, this message translates to:
  /// **'That is not possible right now. Refresh and try again.'**
  String get errorConflict;

  /// No description provided for @errorServer.
  ///
  /// In en, this message translates to:
  /// **'The server ran into a problem. Please try again shortly.'**
  String get errorServer;

  /// No description provided for @errorUnknown.
  ///
  /// In en, this message translates to:
  /// **'Something went wrong. Please try again.'**
  String get errorUnknown;

  /// No description provided for @signInSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Sign in to follow your child\'s school run.'**
  String get signInSubtitle;

  /// No description provided for @enterPhoneNumber.
  ///
  /// In en, this message translates to:
  /// **'Enter your phone number'**
  String get enterPhoneNumber;

  /// No description provided for @enterPassword.
  ///
  /// In en, this message translates to:
  /// **'Enter your password'**
  String get enterPassword;

  /// No description provided for @showPassword.
  ///
  /// In en, this message translates to:
  /// **'Show password'**
  String get showPassword;

  /// No description provided for @hidePassword.
  ///
  /// In en, this message translates to:
  /// **'Hide password'**
  String get hidePassword;

  /// No description provided for @accountsManagedBySchool.
  ///
  /// In en, this message translates to:
  /// **'Accounts are created for you by Masar Alburhan. Contact us if you cannot sign in.'**
  String get accountsManagedBySchool;

  /// No description provided for @signingIn.
  ///
  /// In en, this message translates to:
  /// **'Signing in…'**
  String get signingIn;

  /// No description provided for @status.
  ///
  /// In en, this message translates to:
  /// **'Status'**
  String get status;

  /// No description provided for @liveUpdatesPaused.
  ///
  /// In en, this message translates to:
  /// **'Live updates paused — this may be out of date'**
  String get liveUpdatesPaused;

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

  /// No description provided for @privacyPolicy.
  ///
  /// In en, this message translates to:
  /// **'Privacy Policy'**
  String get privacyPolicy;

  /// No description provided for @privacyPolicyDescription.
  ///
  /// In en, this message translates to:
  /// **'How we collect, use, and protect your data'**
  String get privacyPolicyDescription;

  /// No description provided for @couldNotOpenLink.
  ///
  /// In en, this message translates to:
  /// **'Could not open the link'**
  String get couldNotOpenLink;

  /// No description provided for @deleteAccount.
  ///
  /// In en, this message translates to:
  /// **'Delete Account'**
  String get deleteAccount;

  /// No description provided for @deleteAccountDescription.
  ///
  /// In en, this message translates to:
  /// **'Permanently remove your account and data'**
  String get deleteAccountDescription;

  /// No description provided for @deleteAccountDialogTitle.
  ///
  /// In en, this message translates to:
  /// **'Delete your account?'**
  String get deleteAccountDialogTitle;

  /// No description provided for @deleteAccountDialogMessage.
  ///
  /// In en, this message translates to:
  /// **'This permanently removes your account and the data linked to it. It cannot be undone.'**
  String get deleteAccountDialogMessage;

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

  /// No description provided for @notAssigned.
  ///
  /// In en, this message translates to:
  /// **'Not assigned'**
  String get notAssigned;

  /// No description provided for @tripProgress.
  ///
  /// In en, this message translates to:
  /// **'Trip progress'**
  String get tripProgress;

  /// No description provided for @etaWaiting.
  ///
  /// In en, this message translates to:
  /// **'Waiting for update'**
  String get etaWaiting;

  /// No description provided for @stepHome.
  ///
  /// In en, this message translates to:
  /// **'Home'**
  String get stepHome;

  /// No description provided for @stepOnBus.
  ///
  /// In en, this message translates to:
  /// **'On the bus'**
  String get stepOnBus;

  /// No description provided for @stepSchool.
  ///
  /// In en, this message translates to:
  /// **'School'**
  String get stepSchool;

  /// No description provided for @atHome.
  ///
  /// In en, this message translates to:
  /// **'At home'**
  String get atHome;

  /// No description provided for @onBus.
  ///
  /// In en, this message translates to:
  /// **'On bus'**
  String get onBus;

  /// No description provided for @inSchool.
  ///
  /// In en, this message translates to:
  /// **'In school'**
  String get inSchool;

  /// No description provided for @undo.
  ///
  /// In en, this message translates to:
  /// **'Undo'**
  String get undo;

  /// No description provided for @markedAbsent.
  ///
  /// In en, this message translates to:
  /// **'{name} marked absent'**
  String markedAbsent(String name);

  /// No description provided for @pastTrips.
  ///
  /// In en, this message translates to:
  /// **'Past Trips'**
  String get pastTrips;

  /// No description provided for @noPastTrips.
  ///
  /// In en, this message translates to:
  /// **'No trips recorded in this period'**
  String get noPastTrips;

  /// No description provided for @historyIncomplete.
  ///
  /// In en, this message translates to:
  /// **'{count} days could not be loaded — pull to refresh to try again'**
  String historyIncomplete(int count);

  /// No description provided for @present.
  ///
  /// In en, this message translates to:
  /// **'Present'**
  String get present;

  /// No description provided for @noRunRecorded.
  ///
  /// In en, this message translates to:
  /// **'No run recorded'**
  String get noRunRecorded;

  /// No description provided for @tripDetails.
  ///
  /// In en, this message translates to:
  /// **'Trip Details'**
  String get tripDetails;

  /// No description provided for @parentLabel.
  ///
  /// In en, this message translates to:
  /// **'Parent'**
  String get parentLabel;

  /// No description provided for @pickDate.
  ///
  /// In en, this message translates to:
  /// **'Pick a date'**
  String get pickDate;

  /// No description provided for @loadEarlier.
  ///
  /// In en, this message translates to:
  /// **'Load earlier days'**
  String get loadEarlier;

  /// No description provided for @noTripOnDate.
  ///
  /// In en, this message translates to:
  /// **'No trip was recorded on this date'**
  String get noTripOnDate;

  /// No description provided for @allHome.
  ///
  /// In en, this message translates to:
  /// **'All home'**
  String get allHome;

  /// No description provided for @noActiveTripsMessage.
  ///
  /// In en, this message translates to:
  /// **'There is no trip running right now. Live trip progress will appear here once the driver starts the route.'**
  String get noActiveTripsMessage;

  /// No description provided for @studentStatus.
  ///
  /// In en, this message translates to:
  /// **'Student Status'**
  String get studentStatus;

  /// No description provided for @account.
  ///
  /// In en, this message translates to:
  /// **'Account'**
  String get account;

  /// No description provided for @support.
  ///
  /// In en, this message translates to:
  /// **'Support'**
  String get support;

  /// No description provided for @contactUs.
  ///
  /// In en, this message translates to:
  /// **'Contact us'**
  String get contactUs;

  /// No description provided for @contactUsDescription.
  ///
  /// In en, this message translates to:
  /// **'Questions about the trip? Message us on WhatsApp.'**
  String get contactUsDescription;

  /// No description provided for @contactViaWhatsapp.
  ///
  /// In en, this message translates to:
  /// **'Contact us via WhatsApp'**
  String get contactViaWhatsapp;

  /// No description provided for @couldNotOpenWhatsapp.
  ///
  /// In en, this message translates to:
  /// **'Could not open WhatsApp'**
  String get couldNotOpenWhatsapp;

  /// No description provided for @endSessionDialogTitle.
  ///
  /// In en, this message translates to:
  /// **'Are you sure?'**
  String get endSessionDialogTitle;

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

  /// No description provided for @startSession.
  ///
  /// In en, this message translates to:
  /// **'Start Session'**
  String get startSession;

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
  /// **'Morning run: 6:00 - 9:00 AM\nAfternoon run: 1:00 - 4:00 PM'**
  String get runWindowsInfo;

  /// No description provided for @attendanceTitle.
  ///
  /// In en, this message translates to:
  /// **'Attendance'**
  String get attendanceTitle;

  /// No description provided for @attendanceHint.
  ///
  /// In en, this message translates to:
  /// **'Tap a student when they board the bus. Swipe left to mark them absent.'**
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
  /// **'{count, plural, =0{No students to pick up} =1{1 student to pick up} other{{count} students to pick up}}'**
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
  /// **'{count, plural, =0{No students still on the bus} =1{1 student still on the bus} other{{count} students still on the bus}}'**
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

  /// No description provided for @routeMap.
  ///
  /// In en, this message translates to:
  /// **'Route map'**
  String get routeMap;

  /// No description provided for @centreOnMe.
  ///
  /// In en, this message translates to:
  /// **'Centre on me'**
  String get centreOnMe;

  /// No description provided for @fitRoute.
  ///
  /// In en, this message translates to:
  /// **'Fit route'**
  String get fitRoute;

  /// No description provided for @mapNotConfigured.
  ///
  /// In en, this message translates to:
  /// **'Map is not configured for this build'**
  String get mapNotConfigured;

  /// No description provided for @noRouteGeometry.
  ///
  /// In en, this message translates to:
  /// **'This route has no map data yet'**
  String get noRouteGeometry;

  /// No description provided for @trackingNotificationTitle.
  ///
  /// In en, this message translates to:
  /// **'Run in progress'**
  String get trackingNotificationTitle;

  /// No description provided for @trackingNotificationText.
  ///
  /// In en, this message translates to:
  /// **'Sharing the bus location until the run ends'**
  String get trackingNotificationText;

  /// No description provided for @locationDisabled.
  ///
  /// In en, this message translates to:
  /// **'Location services are off'**
  String get locationDisabled;

  /// No description provided for @locationDenied.
  ///
  /// In en, this message translates to:
  /// **'Location permission denied'**
  String get locationDenied;

  /// No description provided for @locationUnavailable.
  ///
  /// In en, this message translates to:
  /// **'Location unavailable'**
  String get locationUnavailable;

  /// No description provided for @locationNotReporting.
  ///
  /// In en, this message translates to:
  /// **'Location is not reaching the server. Check your connection — the school cannot see the bus.'**
  String get locationNotReporting;

  /// No description provided for @locationDisclosureTitle.
  ///
  /// In en, this message translates to:
  /// **'Location sharing during the run'**
  String get locationDisclosureTitle;

  /// No description provided for @locationDisclosureMessage.
  ///
  /// In en, this message translates to:
  /// **'While this run is active, Masar Alburhan collects and sends your precise location to our servers so we can monitor the bus. Reporting continues while the app is in the background or the screen is locked, and stops when the run ends.'**
  String get locationDisclosureMessage;

  /// No description provided for @continueLabel.
  ///
  /// In en, this message translates to:
  /// **'Continue'**
  String get continueLabel;

  /// No description provided for @back.
  ///
  /// In en, this message translates to:
  /// **'Back'**
  String get back;

  /// No description provided for @resumeRun.
  ///
  /// In en, this message translates to:
  /// **'Resume run'**
  String get resumeRun;

  /// No description provided for @runInProgressNotice.
  ///
  /// In en, this message translates to:
  /// **'A run is in progress'**
  String get runInProgressNotice;

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

  /// No description provided for @noStudentsLinked.
  ///
  /// In en, this message translates to:
  /// **'No students are linked to your account'**
  String get noStudentsLinked;

  /// No description provided for @retry.
  ///
  /// In en, this message translates to:
  /// **'Retry'**
  String get retry;

  /// No description provided for @etaMinutesUnit.
  ///
  /// In en, this message translates to:
  /// **'min'**
  String get etaMinutesUnit;

  /// No description provided for @etaUntilPickup.
  ///
  /// In en, this message translates to:
  /// **'until pickup'**
  String get etaUntilPickup;

  /// No description provided for @etaUntilHome.
  ///
  /// In en, this message translates to:
  /// **'until home'**
  String get etaUntilHome;

  /// No description provided for @etaArrivesBy.
  ///
  /// In en, this message translates to:
  /// **'Arrives by {time}'**
  String etaArrivesBy(String time);

  /// No description provided for @etaKm.
  ///
  /// In en, this message translates to:
  /// **'{km} km'**
  String etaKm(String km);

  /// No description provided for @etaMeters.
  ///
  /// In en, this message translates to:
  /// **'{m} m away'**
  String etaMeters(int m);

  /// No description provided for @etaStale.
  ///
  /// In en, this message translates to:
  /// **'Last known {m} min, not updating'**
  String etaStale(int m);

  /// No description provided for @allAtSchool.
  ///
  /// In en, this message translates to:
  /// **'All at school'**
  String get allAtSchool;

  /// No description provided for @notifications.
  ///
  /// In en, this message translates to:
  /// **'Notifications'**
  String get notifications;

  /// No description provided for @noNotifications.
  ///
  /// In en, this message translates to:
  /// **'No notifications yet'**
  String get noNotifications;

  /// No description provided for @clearAll.
  ///
  /// In en, this message translates to:
  /// **'Clear all'**
  String get clearAll;

  /// No description provided for @justNow.
  ///
  /// In en, this message translates to:
  /// **'Just now'**
  String get justNow;

  /// No description provided for @minutesAgo.
  ///
  /// In en, this message translates to:
  /// **'{count} min ago'**
  String minutesAgo(int count);

  /// No description provided for @hoursAgo.
  ///
  /// In en, this message translates to:
  /// **'{count} h ago'**
  String hoursAgo(int count);

  /// No description provided for @daysAgo.
  ///
  /// In en, this message translates to:
  /// **'{count} d ago'**
  String daysAgo(int count);

  /// No description provided for @openSettings.
  ///
  /// In en, this message translates to:
  /// **'Open Settings'**
  String get openSettings;

  /// No description provided for @locationBlockedTitle.
  ///
  /// In en, this message translates to:
  /// **'Location permission is turned off'**
  String get locationBlockedTitle;

  /// No description provided for @locationBlockedMessage.
  ///
  /// In en, this message translates to:
  /// **'Masar Alburhan needs your location to report the bus position while a run is active. Turn on location access for this app in Settings, then start the run again.'**
  String get locationBlockedMessage;

  /// No description provided for @locationReducedAccuracy.
  ///
  /// In en, this message translates to:
  /// **'Precise Location is off, so your position is too imprecise to report and the bus is not visible. Turn on Precise Location for this app in Settings.'**
  String get locationReducedAccuracy;

  /// No description provided for @absenceNotBookedLabel.
  ///
  /// In en, this message translates to:
  /// **'Not booked'**
  String get absenceNotBookedLabel;

  /// No description provided for @driverNotRiding.
  ///
  /// In en, this message translates to:
  /// **'Not riding today'**
  String get driverNotRiding;

  /// No description provided for @driverNotRidingNote.
  ///
  /// In en, this message translates to:
  /// **'A parent took {name} off this morning\'s run. Do not wait at this stop.'**
  String driverNotRidingNote(String name);

  /// No description provided for @driverSkipStop.
  ///
  /// In en, this message translates to:
  /// **'Skip this stop'**
  String get driverSkipStop;

  /// No description provided for @driverBoardAnyway.
  ///
  /// In en, this message translates to:
  /// **'They turned up — board'**
  String get driverBoardAnyway;

  /// No description provided for @absencePickMorning.
  ///
  /// In en, this message translates to:
  /// **'Which morning?'**
  String get absencePickMorning;

  /// No description provided for @absenceDayToday.
  ///
  /// In en, this message translates to:
  /// **'This morning'**
  String get absenceDayToday;

  /// No description provided for @absenceDayTomorrow.
  ///
  /// In en, this message translates to:
  /// **'Tomorrow'**
  String get absenceDayTomorrow;

  /// No description provided for @absenceTodayPassed.
  ///
  /// In en, this message translates to:
  /// **'This morning\'s run is over'**
  String get absenceTodayPassed;

  /// No description provided for @absenceBookedOn.
  ///
  /// In en, this message translates to:
  /// **'Booked — {name} will not be collected on {day}.'**
  String absenceBookedOn(String name, String day);

  /// No description provided for @absenceConfirmDayMessage.
  ///
  /// In en, this message translates to:
  /// **'The bus will not stop for {name} on {day}.'**
  String absenceConfirmDayMessage(String name, String day);

  /// No description provided for @absenceBookedLabel.
  ///
  /// In en, this message translates to:
  /// **'Booked'**
  String get absenceBookedLabel;

  /// No description provided for @planAhead.
  ///
  /// In en, this message translates to:
  /// **'Plan ahead'**
  String get planAhead;

  /// No description provided for @manageAbsence.
  ///
  /// In en, this message translates to:
  /// **'Bus attendance'**
  String get manageAbsence;

  /// No description provided for @absenceConfirmTitle.
  ///
  /// In en, this message translates to:
  /// **'Skip the bus?'**
  String get absenceConfirmTitle;

  /// No description provided for @absenceConfirmAction.
  ///
  /// In en, this message translates to:
  /// **'Yes, skip'**
  String get absenceConfirmAction;

  /// No description provided for @absenceRangeConfirmTitle.
  ///
  /// In en, this message translates to:
  /// **'Skip these mornings?'**
  String get absenceRangeConfirmTitle;

  /// No description provided for @absenceRangeConfirmMessage.
  ///
  /// In en, this message translates to:
  /// **'The bus will not stop for {name} on the days you picked.'**
  String absenceRangeConfirmMessage(String name);

  /// No description provided for @absenceBooked.
  ///
  /// In en, this message translates to:
  /// **'Booked — {name} will not be collected.'**
  String absenceBooked(String name);

  /// No description provided for @absenceBookedLive.
  ///
  /// In en, this message translates to:
  /// **'Done — the driver has been told.'**
  String get absenceBookedLive;

  /// No description provided for @absenceCancelled.
  ///
  /// In en, this message translates to:
  /// **'{name} is back on the bus.'**
  String absenceCancelled(String name);

  /// No description provided for @absenceAlreadyBoarded.
  ///
  /// In en, this message translates to:
  /// **'{name} is already on the bus. Call the driver if you need them taken off.'**
  String absenceAlreadyBoarded(String name);

  /// No description provided for @absenceRunFinished.
  ///
  /// In en, this message translates to:
  /// **'This morning\'s run has finished.'**
  String get absenceRunFinished;

  /// No description provided for @absenceRunStarted.
  ///
  /// In en, this message translates to:
  /// **'This morning\'s run has already started. Call the driver.'**
  String get absenceRunStarted;

  /// No description provided for @absenceSkippedChip.
  ///
  /// In en, this message translates to:
  /// **'Not riding'**
  String get absenceSkippedChip;

  /// No description provided for @absencePickDays.
  ///
  /// In en, this message translates to:
  /// **'Choose days'**
  String get absencePickDays;

  /// No description provided for @absenceUndo.
  ///
  /// In en, this message translates to:
  /// **'Put back on the bus'**
  String get absenceUndo;

  /// No description provided for @absenceRangeTooLong.
  ///
  /// In en, this message translates to:
  /// **'Pick at most {count} days at a time.'**
  String absenceRangeTooLong(int count);

  /// No description provided for @absencePartlyBooked.
  ///
  /// In en, this message translates to:
  /// **'{booked} of {total} mornings booked.'**
  String absencePartlyBooked(int booked, int total);

  /// No description provided for @absenceMorningOnly.
  ///
  /// In en, this message translates to:
  /// **'Morning runs only. If plans change, the driver can still pick {name} up.'**
  String absenceMorningOnly(String name);

  /// No description provided for @absenceMorningsCount.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 morning} other{{count} mornings}}'**
  String absenceMorningsCount(int count);
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
