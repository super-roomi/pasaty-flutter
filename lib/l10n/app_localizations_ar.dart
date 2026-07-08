// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Arabic (`ar`).
class AppLocalizationsAr extends AppLocalizations {
  AppLocalizationsAr([String locale = 'ar']) : super(locale);

  @override
  String get rimaAhmed => 'ريما أحمد';

  @override
  String get mohammedAhmed => 'محمد أحمد';

  @override
  String get appTitle => 'مسار البرهان';

  @override
  String get welcomeToPasaty => 'مرحباً بك في مسار البرهان!';

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
  String get logOut => 'تسجيل الخروج';

  @override
  String get signOutOfYourAccount => 'الخروج من حسابك';

  @override
  String get logOutDialogMessage =>
      'يرجى تأكيد رغبتك في تسجيل الخروج من حسابك.';

  @override
  String get password => 'كلمة المرور';

  @override
  String get passwordHint => 'أدخل كلمة المرور';

  @override
  String get invalidCredentials => 'رقم الهاتف أو كلمة المرور غير صحيحة';

  @override
  String get connectionError => 'تعذر الاتصال بالخادم. حاول مرة أخرى.';

  @override
  String get loginFailed => 'فشل تسجيل الدخول. حاول مرة أخرى.';

  @override
  String get unsupportedRole => 'نوع هذا الحساب غير مدعوم في التطبيق';

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

  @override
  String get morningRun => 'الرحلة الصباحية';

  @override
  String get afternoonRun => 'رحلة العودة';

  @override
  String get currentRunLabel => 'الرحلة الحالية';

  @override
  String get noRunScheduled => 'لا توجد رحلة مجدولة الآن';

  @override
  String get runWindowsInfo =>
      'الرحلة الصباحية: 6:00 – 9:00 صباحًا\nرحلة العودة: 1:00 – 4:00 عصرًا';

  @override
  String get attendanceTitle => 'تسجيل الحضور';

  @override
  String get attendanceHint =>
      'اضغط على الطالب عند صعوده إلى الباص — أو اسحب لليمين لتسجيله غائبًا.';

  @override
  String get startDropoffs => 'بدء التوصيل';

  @override
  String get nextPickup => 'الصعود التالي';

  @override
  String pickupRemaining(int count) {
    return '$count طلاب بانتظار الصعود';
  }

  @override
  String get allPickedUp => 'تم صعود جميع الطلاب';

  @override
  String get nextDropoff => 'التوصيل التالي';

  @override
  String dropoffRemaining(int count) {
    return '$count طلاب ما زالوا في الباص';
  }

  @override
  String get upNext => 'التالي';

  @override
  String get allDroppedOff => 'تم توصيل جميع الطلاب';

  @override
  String get backToAttendance => 'العودة إلى تسجيل الحضور';

  @override
  String get myRoute => 'خطي';

  @override
  String get noRoutesAssigned => 'لا يوجد خط مخصص لك بعد';

  @override
  String get studentsTitle => 'الطلاب';

  @override
  String get board => 'صعود';

  @override
  String get dropoff => 'نزول';

  @override
  String get absent => 'غائب';

  @override
  String get completeRun => 'إنهاء الرحلة';

  @override
  String get completeRunDialogMessage =>
      'سيتم اعتماد حالات جميع الطلاب لهذا اليوم. هل تريد المتابعة؟';

  @override
  String get runCompleted => 'اكتملت الرحلة';

  @override
  String get summaryTotal => 'مجموع الطلاب';

  @override
  String get summaryArrived => 'وصلوا إلى المدرسة';

  @override
  String get summaryDroppedOff => 'تم إيصالهم إلى المنزل';

  @override
  String get summaryAbsent => 'غائبون';

  @override
  String get summaryDuration => 'مدة الرحلة';

  @override
  String get statusWaiting => 'بالانتظار';

  @override
  String get statusBoarded => 'صعد';

  @override
  String get statusArrived => 'وصل';

  @override
  String get statusAbsent => 'غائب';

  @override
  String get statusDroppedOff => 'نزل';

  @override
  String get waitingForDriver => 'بانتظار بدء السائق للرحلة';

  @override
  String get noStudentsLinked => 'لا يوجد طلاب مرتبطون بحسابك';

  @override
  String get actionFailed => 'فشل الإجراء';

  @override
  String get retry => 'إعادة المحاولة';
}
