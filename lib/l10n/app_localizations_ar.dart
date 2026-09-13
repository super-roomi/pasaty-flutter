// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Arabic (`ar`).
class AppLocalizationsAr extends AppLocalizations {
  AppLocalizationsAr([String locale = 'ar']) : super(locale);

  @override
  String get appTitle => 'مسار البرهان';

  @override
  String get welcomeToPasaty => 'مرحباً بك في مسار البرهان!';

  @override
  String get phoneNumber => 'رقم الهاتف';

  @override
  String get phoneNumberHint => '07XX XXX XXXX';

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
  String get connectionError =>
      'تعذّر الاتصال بالخادم. تحقّق من اتصالك بالإنترنت.';

  @override
  String get unsupportedRole => 'نوع هذا الحساب غير مدعوم في التطبيق';

  @override
  String get greetingMorning => 'صباح الخير';

  @override
  String get greetingAfternoon => 'مساء الخير';

  @override
  String get greetingEvening => 'مساء الخير';

  @override
  String get todayAtAGlance => 'اليوم';

  @override
  String get runPending => 'لم يبدأ';

  @override
  String nextRunIn(String time) {
    return 'يبدأ خلال $time';
  }

  @override
  String hoursMinutesShort(int h, int m) {
    return '$h س $m د';
  }

  @override
  String minutesShort(int m) {
    return '$m د';
  }

  @override
  String get noRunsToday => 'لم تُسجَّل أي رحلة اليوم بعد';

  @override
  String get errorUnexpectedResponse =>
      'أرسل الخادم استجابة غير متوقعة. حاول مرة أخرى.';

  @override
  String get errorSessionExpired =>
      'انتهت صلاحية جلستك. يرجى تسجيل الدخول مرة أخرى.';

  @override
  String get errorNotAllowed => 'ليست لديك صلاحية للقيام بذلك.';

  @override
  String get errorNotFound => 'تعذر العثور على ما تبحث عنه.';

  @override
  String get errorConflict =>
      'لا يمكن تنفيذ ذلك الآن. حدّث الصفحة وحاول مرة أخرى.';

  @override
  String get errorServer => 'حدثت مشكلة في الخادم. حاول مرة أخرى بعد قليل.';

  @override
  String get errorUnknown => 'حدث خطأ ما. حاول مرة أخرى.';

  @override
  String get signInSubtitle => 'سجّل الدخول لمتابعة رحلة طفلك المدرسية.';

  @override
  String get enterPhoneNumber => 'أدخل رقم الهاتف';

  @override
  String get enterPassword => 'أدخل كلمة المرور';

  @override
  String get showPassword => 'إظهار كلمة المرور';

  @override
  String get hidePassword => 'إخفاء كلمة المرور';

  @override
  String get accountsManagedBySchool =>
      'تُنشأ الحسابات لك من قِبل مسار البرهان. تواصل معنا إذا لم تتمكن من تسجيل الدخول.';

  @override
  String get signingIn => 'جارٍ تسجيل الدخول…';

  @override
  String get status => 'الحالة';

  @override
  String get liveUpdatesPaused =>
      'التحديثات المباشرة متوقفة — قد تكون هذه المعلومات قديمة';

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
  String get privacyPolicy => 'سياسة الخصوصية';

  @override
  String get privacyPolicyDescription => 'كيف نجمع بياناتك ونستخدمها ونحميها';

  @override
  String get couldNotOpenLink => 'تعذّر فتح الرابط';

  @override
  String get deleteAccount => 'حذف الحساب';

  @override
  String get deleteAccountDescription => 'إزالة حسابك وبياناتك نهائيًا';

  @override
  String get deleteAccountDialogTitle => 'حذف حسابك؟';

  @override
  String get deleteAccountDialogMessage =>
      'سيؤدي هذا إلى إزالة حسابك والبيانات المرتبطة به نهائيًا، ولا يمكن التراجع عن ذلك.';

  @override
  String get busRoute => 'مسار الحافلة';

  @override
  String get busId => 'معرف الحافلة';

  @override
  String get notAssigned => 'غير محدد';

  @override
  String get tripProgress => 'تقدّم الرحلة';

  @override
  String get etaWaiting => 'بانتظار التحديث';

  @override
  String get stepHome => 'المنزل';

  @override
  String get stepOnBus => 'في الحافلة';

  @override
  String get stepSchool => 'المدرسة';

  @override
  String get atHome => 'في المنزل';

  @override
  String get onBus => 'في الحافلة';

  @override
  String get inSchool => 'في المدرسة';

  @override
  String get undo => 'تراجع';

  @override
  String markedAbsent(String name) {
    return 'تم تسجيل $name غائبًا';
  }

  @override
  String get pastTrips => 'الرحلات السابقة';

  @override
  String get noPastTrips => 'لا توجد رحلات مسجلة في هذه الفترة';

  @override
  String historyIncomplete(int count) {
    return 'تعذّر تحميل $count من الأيام — اسحب للتحديث للمحاولة مرة أخرى';
  }

  @override
  String get present => 'حاضر';

  @override
  String get noRunRecorded => 'لم تُسجَّل رحلة';

  @override
  String get tripDetails => 'تفاصيل الرحلة';

  @override
  String get parentLabel => 'ولي الأمر';

  @override
  String get pickDate => 'اختر تاريخاً';

  @override
  String get loadEarlier => 'تحميل أيام أسبق';

  @override
  String get noTripOnDate => 'لم تُسجَّل رحلة في هذا التاريخ';

  @override
  String get allHome => 'الجميع في المنزل';

  @override
  String get noActiveTripsMessage =>
      'لا توجد رحلة جارية حالياً. سيظهر تقدّم الرحلة هنا فور بدء السائق للمسار.';

  @override
  String get studentStatus => 'حالة الطلاب';

  @override
  String get account => 'الحساب';

  @override
  String get support => 'الدعم';

  @override
  String get contactUs => 'تواصل معنا';

  @override
  String get contactUsDescription => 'لديك سؤال عن الرحلة؟ راسلنا على واتساب.';

  @override
  String get contactViaWhatsapp => 'تواصل معنا عبر واتساب';

  @override
  String get couldNotOpenWhatsapp => 'تعذّر فتح واتساب';

  @override
  String get endSessionDialogTitle => 'هل أنت متأكد؟';

  @override
  String get cancel => 'إلغاء';

  @override
  String get ok => 'موافق';

  @override
  String get startSession => 'بدء الرحلة';

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
      'الرحلة الصباحية: 6:00 - 9:00 صباحًا\nرحلة العودة: 1:00 - 4:00 عصرًا';

  @override
  String get attendanceTitle => 'تسجيل الحضور';

  @override
  String get attendanceHint =>
      'اضغط على الطالب عند صعوده إلى الباص، أو اسحب لليمين لتسجيله غائبًا.';

  @override
  String get startDropoffs => 'بدء التوصيل';

  @override
  String get nextPickup => 'الصعود التالي';

  @override
  String pickupRemaining(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count طلاب بانتظار الصعود',
      two: 'طالبان بانتظار الصعود',
      one: 'طالب واحد بانتظار الصعود',
      zero: 'لا يوجد طلاب للصعود',
    );
    return '$_temp0';
  }

  @override
  String get allPickedUp => 'تم صعود جميع الطلاب';

  @override
  String get nextDropoff => 'التوصيل التالي';

  @override
  String dropoffRemaining(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count طلاب ما زالوا في الباص',
      two: 'طالبان ما زالا في الباص',
      one: 'طالب واحد ما زال في الباص',
      zero: 'لا يوجد طلاب في الباص',
    );
    return '$_temp0';
  }

  @override
  String get upNext => 'التالي';

  @override
  String get allDroppedOff => 'تم توصيل جميع الطلاب';

  @override
  String get backToAttendance => 'العودة إلى تسجيل الحضور';

  @override
  String get routeMap => 'خريطة المسار';

  @override
  String get centreOnMe => 'توسيط على موقعي';

  @override
  String get fitRoute => 'عرض المسار كاملاً';

  @override
  String get mapNotConfigured => 'الخريطة غير مهيأة في هذه النسخة';

  @override
  String get noRouteGeometry => 'لا توجد بيانات خريطة لهذا المسار بعد';

  @override
  String get trackingNotificationTitle => 'رحلة جارية';

  @override
  String get trackingNotificationText =>
      'تتم مشاركة موقع الحافلة حتى انتهاء الرحلة';

  @override
  String get locationDisabled => 'خدمات الموقع غير مفعّلة';

  @override
  String get locationDenied => 'تم رفض إذن الموقع';

  @override
  String get locationUnavailable => 'الموقع غير متاح';

  @override
  String get locationNotReporting =>
      'لا يصل الموقع إلى الخادم. تحقّق من اتصالك — لا يمكن رؤية الحافلة حاليًا.';

  @override
  String get locationDisclosureTitle => 'مشاركة الموقع أثناء الرحلة';

  @override
  String get locationDisclosureMessage =>
      'أثناء هذه الرحلة، يجمع مسار البرهان موقعك الدقيق ويرسله إلى خوادمنا لمتابعة الحافلة. يستمر الإرسال عندما يكون التطبيق في الخلفية أو تكون الشاشة مقفلة، ويتوقف عند انتهاء الرحلة.';

  @override
  String get continueLabel => 'متابعة';

  @override
  String get back => 'رجوع';

  @override
  String get resumeRun => 'استئناف الرحلة';

  @override
  String get runInProgressNotice => 'هناك رحلة جارية';

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
  String get noStudentsLinked => 'لا يوجد طلاب مرتبطون بحسابك';

  @override
  String get retry => 'إعادة المحاولة';

  @override
  String get etaMinutesUnit => 'دقيقة';

  @override
  String get etaUntilPickup => 'حتى وصول الحافلة';

  @override
  String get etaUntilHome => 'حتى الوصول إلى المنزل';

  @override
  String etaArrivesBy(String time) {
    return 'يصل الساعة $time';
  }

  @override
  String etaKm(String km) {
    return '$km كم';
  }

  @override
  String etaMeters(int m) {
    return 'على بُعد $m م';
  }

  @override
  String etaStale(int m) {
    return 'آخر تقدير $m دقيقة، لم يُحدَّث';
  }

  @override
  String get allAtSchool => 'الجميع في المدرسة';

  @override
  String get notifications => 'الإشعارات';

  @override
  String get noNotifications => 'لا توجد إشعارات بعد';

  @override
  String get clearAll => 'مسح الكل';

  @override
  String get justNow => 'الآن';

  @override
  String minutesAgo(int count) {
    return 'قبل $count دقيقة';
  }

  @override
  String hoursAgo(int count) {
    return 'قبل $count ساعة';
  }

  @override
  String daysAgo(int count) {
    return 'قبل $count يوم';
  }

  @override
  String get openSettings => 'فتح الإعدادات';

  @override
  String get locationBlockedTitle => 'إذن الموقع مُعطَّل';

  @override
  String get locationBlockedMessage =>
      'يحتاج مسار البرهان إلى موقعك للإبلاغ عن مكان الحافلة أثناء الرحلة. فعِّل إذن الموقع لهذا التطبيق من الإعدادات، ثم ابدأ الرحلة مرة أخرى.';

  @override
  String get locationReducedAccuracy =>
      'خاصية الموقع الدقيق مُعطَّلة، لذا موقعك غير دقيق بما يكفي للإبلاغ عنه ولا تظهر الحافلة. فعِّل الموقع الدقيق لهذا التطبيق من الإعدادات.';

  @override
  String get absenceNotBookedLabel => 'غير محجوز';

  @override
  String get driverNotRiding => 'لن يركب اليوم';

  @override
  String driverNotRidingNote(String name) {
    return 'أحد الوالدين ألغى ركوب $name في رحلة هذا الصباح. لا تنتظر عند هذه المحطة.';
  }

  @override
  String get driverSkipStop => 'تخطَّ هذه المحطة';

  @override
  String get driverBoardAnyway => 'حضر — أركبه';

  @override
  String get absencePickMorning => 'أي صباح؟';

  @override
  String get absenceDayToday => 'هذا الصباح';

  @override
  String get absenceDayTomorrow => 'غداً';

  @override
  String get absenceTodayPassed => 'انتهت رحلة هذا الصباح';

  @override
  String absenceBookedOn(String name, String day) {
    return 'تم الحجز — لن يتم اصطحاب $name يوم $day.';
  }

  @override
  String absenceConfirmDayMessage(String name, String day) {
    return 'لن تتوقف الحافلة لـ $name يوم $day.';
  }

  @override
  String get absenceBookedLabel => 'محجوز';

  @override
  String get planAhead => 'جدولة مسبقة';

  @override
  String get manageAbsence => 'ركوب الحافلة';

  @override
  String get absenceConfirmTitle => 'تخطّي الحافلة؟';

  @override
  String get absenceConfirmAction => 'نعم، تخطِّ';

  @override
  String get absenceRangeConfirmTitle => 'تخطي هذه الأيام؟';

  @override
  String absenceRangeConfirmMessage(String name) {
    return 'لن تتوقف الحافلة لـ $name في الأيام التي اخترتها.';
  }

  @override
  String absenceBooked(String name) {
    return 'تم الحجز — لن يتم اصطحاب $name.';
  }

  @override
  String get absenceBookedLive => 'تم — أُبلغ السائق.';

  @override
  String absenceCancelled(String name) {
    return 'عاد $name إلى الحافلة.';
  }

  @override
  String absenceAlreadyBoarded(String name) {
    return '$name على متن الحافلة بالفعل. اتصل بالسائق إذا احتجت إنزاله.';
  }

  @override
  String get absenceRunFinished => 'انتهت رحلة هذا الصباح.';

  @override
  String get absenceRunStarted => 'بدأت رحلة هذا الصباح بالفعل. اتصل بالسائق.';

  @override
  String get absenceSkippedChip => 'لن يركب';

  @override
  String get absencePickDays => 'اختر الأيام';

  @override
  String get absenceUndo => 'إعادته إلى الحافلة';

  @override
  String absenceRangeTooLong(int count) {
    return 'اختر $count يوماً كحد أقصى في المرة الواحدة.';
  }

  @override
  String absencePartlyBooked(int booked, int total) {
    return 'تم حجز $booked من $total صباحاً.';
  }

  @override
  String absenceMorningOnly(String name) {
    return 'الرحلات الصباحية فقط. إذا تغيّرت الخطة، يمكن للسائق اصطحاب $name على أي حال.';
  }

  @override
  String absenceMorningsCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count صباح',
      many: '$count صباحاً',
      few: '$count صباحات',
      two: 'صباحان',
      one: 'صباح واحد',
      zero: 'لا صباحات',
    );
    return '$_temp0';
  }
}
