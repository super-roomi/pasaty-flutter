// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Arabic (`ar`).
class AppLocalizationsAr extends AppLocalizations {
  AppLocalizationsAr([String locale = 'ar']) : super(locale);

  @override
  String get appTitle => 'متتبع الحافلة';

  @override
  String get welcomeToPasaty => 'مرحباً بك في باصاتي!';

  @override
  String get phoneNumber => 'رقم الهاتف';

  @override
  String get phoneNumberHint => '07XX XXX XXXX';

  @override
  String get role => 'الدور';

  @override
  String get selectRole => 'اختر الدور';

  @override
  String get driverRole => 'سائق';

  @override
  String get parentRole => 'ولي أمر';

  @override
  String get staffRole => 'موظف';

  @override
  String get logIn => 'تسجيل الدخول';

  @override
  String get status => 'الحالة';

  @override
  String get payments => 'المدفوعات';

  @override
  String get profile => 'الملف الشخصي';

  @override
  String get history => 'السجل';

  @override
  String get settings => 'الإعدادات';

  @override
  String get language => 'اللغة';

  @override
  String get englishLanguage => 'الإنجليزية';

  @override
  String get arabicLanguage => 'العربية';

  @override
  String get managePersonalInformation => 'إدارة المعلومات الشخصية';

  @override
  String get grade => 'الصف';

  @override
  String get fourthGrade => 'الصف الرابع';

  @override
  String get busRoute => 'مسار الحافلة';

  @override
  String get busId => 'معرف الحافلة';

  @override
  String get payBusFeesWithQi => 'ادفع رسوم الحافلة عبر كي';

  @override
  String get noActiveTrips => 'لا توجد رحلات نشطة';

  @override
  String get noActiveTripsMessage =>
      'الحافلة متوقفة حالياً في المرآب. سنبلغك فور بدء المسار التالي.';

  @override
  String get boardingStatus => 'حالة الصعود';

  @override
  String get boarded => 'صعد';

  @override
  String get contactDriver => 'التواصل مع السائق';

  @override
  String get contactDriverDescription =>
      'قلق بشأن التأخير؟ تريد الاطمئنان على ريما ومحمد؟';

  @override
  String get callSamer => 'اتصل بسامر';

  @override
  String get currentStatus => 'الحالة الحالية';

  @override
  String get arrivingSoon => 'سيصل قريباً';

  @override
  String get timeLeft => 'الوقت المتبقي';

  @override
  String get aboutSixMinutesTillArrival => 'حوالي 6 دقائق حتى الوصول';

  @override
  String get test => 'اختبار';

  @override
  String get activeDeliverySession => 'جلسة توصيل نشطة';

  @override
  String get endSession => 'إنهاء الجلسة';

  @override
  String get endSessionDialogTitle => 'هل أنت متأكد؟';

  @override
  String get endSessionDialogMessage => 'يرجى تأكيد رغبتك في إنهاء رحلة.';

  @override
  String get cancel => 'إلغاء';

  @override
  String get ok => 'موافق';

  @override
  String busNumber(String number) {
    return 'الحافلة رقم $number';
  }

  @override
  String get totalStops => 'إجمالي المحطات';

  @override
  String totalStopsCount(int count) {
    return '$count';
  }

  @override
  String get approxDuration => 'المدة التقريبية';

  @override
  String durationMinutes(int minutes) {
    return '$minutes دقيقة';
  }

  @override
  String get startSession => 'بدء الرحلة';

  @override
  String get readyToGo => 'جاهز للانطلاق؟';

  @override
  String get confirmStudentsOnBoard =>
      'يرجى تأكيد أن جميع الطلاب الحاضرين صعدوا إلى الحافلة.';

  @override
  String get broadcastUpdates => 'إرسال التحديثات';

  @override
  String get majorDelay => 'تأخير كبير 15 دقيقة+';

  @override
  String get minorDelay => 'تأخير بسيط 5 دقائق+';

  @override
  String get onSchedule => 'في الموعد';
}
