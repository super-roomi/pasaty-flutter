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
  /// **'Bus Tracker'**
  String get appTitle;

  /// No description provided for @welcomeToPasaty.
  ///
  /// In en, this message translates to:
  /// **'Welcome to Pasaty!'**
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
