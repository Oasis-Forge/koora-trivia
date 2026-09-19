import 'app_strings_en.dart';

/// نصوص التطبيق بلغته الحالية. الشاشات تكتب `AppStrings.x` كما كانت، واللغة
/// تُختار مرة واحدة في `app.dart` عبر `AppText.use` قبل بناء الواجهة.
// ignore: non_constant_identifier_names
AppText get AppStrings => AppText.current;

/// كل النصوص الظاهرة للمستخدم في مكان واحد. هذا الأصل العربي، و`EnglishText`
/// يطبّقه (`implements`) فيرفض المترجم أي نص إنجليزي ناقص.
class AppText {
  const AppText();

  /// اللغة الحالية: تبدأ عربية ولا تتغيّر إلا من `use`.
  static AppText current = const AppText();

  /// `en` للإنجليزية، وأي رمز آخر للعربية.
  static void use(String languageCode) =>
      current = languageCode == 'en' ? const EnglishText() : const AppText();

  String get languageCode => 'ar';

  String get appName => 'تحدي كرة القدم';

  // الرئيسية
  String get quickPlay => 'لعب سريع';

  /// صيغة اسمية تُستخدم في نص المشاركة، بخلاف تسمية الزر.
  String get quickRound => 'جولة سريعة';
  String get dailyChallenge => 'تحدي اليوم';
  String get dailyDone => 'أكملت تحدي اليوم ✅';
  String get chooseCategory => 'اختر الفئة';
  String get allCategories => 'كل الفئات';
  String get streak => 'سلسلة الأيام';
  String get bestStreak => 'أفضل سلسلة';
  String get bestScore => 'أفضل نتيجة';
  String get gamesPlayed => 'عدد الجولات';

  // الاختبار
  String get question => 'سؤال';
  String get of => 'من';
  String get next => 'التالي';
  String get finish => 'إنهاء';
  String get correct => 'إجابة صحيحة!';
  String get wrong => 'إجابة خاطئة';
  String get quitTitle => 'إنهاء الجولة؟';
  String get quitBody => 'ستفقد تقدمك في هذه الجولة.';
  String get quitConfirm => 'خروج';
  String get quitCancel => 'متابعة اللعب';
  String get quitBodyLevel =>
      'ستفقد تقدمك في هذا المستوى، والخروج يكلّفك قلباً.';
  String get quizPaused => 'الجولة متوقفة مؤقتاً';
  String get quizPausedHint =>
      'يعود السؤال والوقت كما تركتهما حين ترجع إلى التطبيق.';

  // المظهر
  String get themeSection => 'المظهر';
  String get themeGreen => 'ملعب أخضر';
  String get themeBlue => 'ليلي أزرق';
  String get themePurple => 'بنفسجي';
  String get themeRed => 'كلاسيكو أحمر';

  // اللغة — كل لغة باسمها في لغتها، فلا تُترجم هذه الأسماء.
  String get languageSection => 'اللغة';
  String get languageSystem => 'لغة الهاتف';
  Map<String, String> get languageNames => const {
    'ar': 'العربية',
    'en': 'English',
  };
  String languageName(String code) => languageNames[code] ?? code;

  // صيغ كانت مكتوبة داخل الودجات والكيانات — مكانها هنا حتى تُترجم يوماً.
  List<String> get optionLetters => const ['أ', 'ب', 'ج', 'د'];
  List<String> get monthNames => const [
    'يناير', 'فبراير', 'مارس', 'أبريل', 'مايو', 'يونيو',
    'يوليو', 'أغسطس', 'سبتمبر', 'أكتوبر', 'نوفمبر', 'ديسمبر',
  ];
  String get difficultyEasy => 'سهل';
  String get difficultyMedium => 'متوسط';
  String get difficultyHard => 'صعب';
  String levelLabel(int level) => 'المستوى $level';
  String levelsProgress(int done, int total) =>
      '$done من $total $levelsDone';
  String hoursMinutes(int hours, int minutes) => '$hours س و $minutes د';
  String hoursShort(int hours) => '$hours س';
  String minutesShort(int minutes) => '$minutes د';
  String get timeUp => 'انتهى الوقت!';

  // النتيجة
  String get yourScore => 'نتيجتك';
  String get correctAnswers => 'إجابات صحيحة';
  String get accuracy => 'نسبة الدقة';
  String get playAgain => 'العب مرة أخرى';
  String get backHome => 'الرئيسية';
  String get shareScore => 'شارك النتيجة';
  /// [days] مكتوبة بـ `ArabicCount` بصيغة المجرور بعد «لمدة»: «يومين».
  String streakKeptFor(String days) =>
      'حافظت على سلسلتك لمدة $days!';
  String get streakLabel => 'السلسلة';

  // رسائل الأداء
  String get rankLegend => 'أسطورة الملاعب! 🏆';
  String get rankPro => 'محترف حقيقي ⚽';
  String get rankGood => 'أداء جيد، واصل! 👏';
  String get rankRookie => 'بداية الطريق، تدرّب أكثر 💪';

  // المستويات
  String get levels => 'المستويات';
  String get chooseCategoryTitle => 'اختر التصنيف';
  String get level => 'المستوى';
  String get levelsDone => 'مستويات مكتملة';
  String get startLevel => 'ابدأ المستوى';
  String get lockedLevel => 'أكمل المستوى السابق لفتحه';
  String get levelPassed => 'اجتزت المستوى!';
  String get levelFailed => 'لم تجتز المستوى';
  /// [correctAnswers] مكتوبة بـ `ArabicCount`: «7 إجابات صحيحة».
  String levelFailedHint(String correctAnswers) =>
      'تحتاج $correctAnswers على الأقل';
  String get nextLevelUnlocked => 'فُتح المستوى التالي 🔓';

  /// عتبات المستوى قبل بدئه: «للاجتياز ⭐ 7 من 10 · ⭐⭐ 9 · ⭐⭐⭐ 10».
  String levelGoal({
    required int pass,
    required int twoStars,
    required int threeStars,
    required int total,
  }) =>
      'للاجتياز ⭐ $pass من $total  ·  ⭐⭐ $twoStars  ·  ⭐⭐⭐ $threeStars';
  String get levelHeartCost =>
      'تخسر قلباً إن لم تجتز المستوى أو خرجت منه';
  String get replayLevel => 'أعد المستوى';
  String get nextLevel => 'المستوى التالي';
  String get allLevelsDone => 'أكملت كل مستويات هذا التصنيف 🏆';
  String get totalStars => 'مجموع النجوم';

  // الإعدادات
  String get settings => 'الإعدادات';
  String get yourStats => 'إحصائياتك';
  String get dataSection => 'البيانات';
  String get aboutSection => 'عن التطبيق';
  String get totalScore => 'مجموع النقاط';
  String get completedLevels => 'مستويات مكتملة';
  String get resetStats => 'تصفير الإحصائيات';
  String get resetStatsBody =>
      'ستُحذف السلسلة وأفضل نتيجة وعدد الجولات نهائياً. لا يمكن التراجع.';
  String get resetProgress => 'تصفير تقدّم المستويات';
  String get resetProgressBody =>
      'ستُقفل كل المستويات من جديد وتُحذف كل النجوم. لا يمكن التراجع.';

  /// [stars] و[levels] مكتوبان بـ `ArabicCount` بصيغة المفعول: «نجمتين».
  String resetProgressLoss(String stars, String levels) =>
      'ستفقد $stars وتقدّم $levels.';
  String get confirmReset => 'تصفير';
  String get cancel => 'إلغاء';
  String get resetDone => 'تم التصفير';
  /// [version] من `AppInfo`، مثل «1.0.4 (5)».
  String appVersion(String version) => 'الإصدار $version';
  String get bankSummary => 'تصنيفات متنوّعة · مستويات متدرّجة لكل تصنيف';

  // التنبيه اليومي
  String get reminderSection => 'التنبيه اليومي';
  String get reminderToggle => 'تذكيري بتحدي اليوم';
  String get reminderToggleHint =>
      'تنبيه يومي في الوقت الذي تختاره حتى لا تنكسر سلسلتك.';
  String get reminderTime => 'وقت التنبيه';

  // بعد تحدي اليوم
  String get dailyReminderAsk => 'نذكّرك بتحدي الغد؟';
  String get dailyReminderButton => 'ذكّرني';
  String dailyReminderSet(String time) =>
      'سنذكّرك بتحدي الغد الساعة $time';
  String get playLevel => 'العب مستوى';
  String get reminderDenied =>
      'الإشعارات معطّلة. فعّلها من إعدادات النظام.';
  String get reminderChannelName => 'تحدي اليوم';
  String get reminderChannelDescription =>
      'تذكير يومي بلعب تحدي اليوم والحفاظ على السلسلة.';
  String get reminderTitle => 'تحدي اليوم بانتظارك ⚽';
  /// [questions] عدد أسئلة التحدي مكتوباً بـ `ArabicCount`: «7 أسئلة».
  String reminderBody(String questions) =>
      'العب الآن — $questions فقط!';

  /// [streak] مكتوبة بـ `ArabicCount`: «5 أيام».
  String reminderBodyStreak(String streak, String questions) =>
      'سلسلتك: $streak — لا تدعها تنكسر، $questions فقط!';

  // الاقتصاد
  String get hearts => 'القلوب';

  // تسميات قارئ الشاشة
  /// [nextIn] مثل «12 د» من `HeartsBar`.
  String heartsLabel(int hearts, int max, {String? nextIn}) =>
      nextIn == null
          ? 'القلوب: $hearts من $max'
          : 'القلوب: $hearts من $max، القلب التالي بعد $nextIn';
  String timeLeftLabel(int seconds) => 'الوقت المتبقي: $seconds';

  /// [earned] مكتوبة بـ `ArabicCount`: «نجمتان».
  String starsLabel(String earned, int total) => '$earned من $total';
  String get back => 'رجوع';
  String get quitRound => 'إنهاء الجولة';
  String get noHeartsTitle => 'نفدت قلوبك';
  String get noHeartsBody =>
      'انتظر حتى يتجدّد قلب، أو العب تحدي اليوم لتكسب قلباً مجانياً.';
  String get noHeartsBodyDailyDone =>
      'انتظر حتى يتجدّد قلب، أو احصل على قلب الآن بإعلان أو بالعملات.';
  String get nextHeartIn => 'القلب التالي بعد';
  String get playDailyForHeart => 'العب تحدي اليوم';
  String get heartLost => 'فقدت قلباً';
  String get heartEarned => 'كسبت قلباً! ❤️';
  String get hintFiftyFifty => 'حذف إجابتين';
  String get hintSkip => 'تخطّي السؤال';
  String get hintExtraTime => 'وقت إضافي';
  String get noHintsLeft => 'انتهت مساعداتك اليوم';
  String get watchAdForHint => 'شاهد إعلاناً واحصل على مساعدة';
  String get hintGranted => '+1 مساعدة';
  String get hintFiftyFiftyUsed => 'حذفت إجابتين من هذا السؤال بالفعل';
  String get hintExtraTimeUsed => 'الوقت الإضافي مرة واحدة لكل سؤال';
  String get skippedAnswer => 'تخطّيت هذا السؤال';

  /// تحت السؤال بعد كشف الإجابة.
  String correctAnswerIs(String answer) => 'الإجابة الصحيحة: $answer';

  // المهام والمتجر
  String get tasks => 'المهام اليومية';
  /// [count] الهدف مكتوباً بـ `ArabicCount` بصيغة المفعول: «10 إجابات صحيحة».
  String taskAnswers(String count) => 'أجب $count';
  String get taskDaily => 'أكمل تحدي اليوم';
  String get taskLevel => 'اجتز مستوى واحداً';
  String get claim => 'استلم';
  String get claimed => 'استُلمت';
  String get chestHint => 'يُفتح الصندوق بعد استلام كل المهام';
  String get openChest => 'افتح';
  String get chestOpened => 'فُتح الصندوق!';
  String get tasksResetHint => 'تتجدّد المهام كل يوم عند منتصف الليل';
  String get shop => 'المتجر';
  String coinsOpenShop(String coins) => 'رصيدك $coins — افتح المتجر';
  String get refillHearts => 'ملء القلوب';
  String get hintsPack => 'حزمة مساعدات';
  String get notEnoughCoins => 'عملاتك لا تكفي';
  String get heartsAlreadyFull => 'قلوبك ممتلئة';
  String get purchased => 'تم الشراء';
  String get comingSoon => 'قريباً';
  String get watchAdForCoins => 'شاهد إعلاناً واكسب عملات';
  String get watchAdForHeart => 'شاهد إعلاناً واحصل على قلب';
  String get removeAds => 'إزالة الإعلانات';
  String removeAdsBundle(String coins) => 'إزالة الإعلانات + $coins';
  String get removeAdsHint =>
      'بلا شريط سفلي ولا إعلانات بين الجولات، بشراء واحد';
  String get removeAdsActive => 'مفعّلة';
  String coinsPack(String coins) => 'حزمة $coins';
  String get coinsPackHint => 'لملء القلوب وشراء المساعدات';
  String get restorePurchases => 'استعادة المشتريات';
  String get purchaseDone => 'تم الشراء — شكراً لدعمك!';
  String get purchasePending =>
      'الشراء قيد المعالجة، وسيصلك ما اشتريته فور اكتماله';
  String get purchaseFailed => 'تعذّر إتمام الشراء';
  String get purchasesRestored => 'تمت استعادة مشترياتك';
  String get noPurchasesToRestore => 'لا توجد مشتريات سابقة على هذا الحساب';
  String get adUnavailable => 'يتطلب اتصالاً بالإنترنت';
  String get adDailyLimitReached => 'استنفدت إعادة التعبئة اليوم';
  String get adDismissed => 'يجب إكمال الإعلان للحصول على المكافأة';
  String get adLoading => 'جارٍ التحميل…';
  String get rewardGranted => 'تم!';

  // المؤثرات والنسخ الاحتياطي
  String get effectsSection => 'المؤثرات';
  String get soundToggle => 'أصوات';
  String get hapticsToggle => 'اهتزاز';
  String get backupSection => 'نقل التقدّم';
  String get backupHint =>
      'تقدّمك محفوظ على هذا الجهاز فقط. انسخ الرمز واحتفظ به لنقله إلى جهاز آخر.';
  String get exportBackup => 'نسخ رمز التقدّم';
  String get importBackup => 'استيراد رمز';
  String get backupCopied => 'نُسخ الرمز';
  String get importTitle => 'استيراد التقدّم';
  String get importBody =>
      'الصق الرمز هنا. سيُستبدل تقدّمك الحالي بالكامل.';
  String get importSuccess => 'تم الاستيراد';
  String get importFailed => 'رمز غير صالح';
  String get importConfirm => 'استيراد';

  // الخصوصية
  String get privacySection => 'الخصوصية';
  String get adPrivacyOptions => 'خيارات خصوصية الإعلانات';
  String get privacyPolicy => 'سياسة الخصوصية';
  String get privacyOptionsFailed =>
      'تعذّر فتح خيارات الخصوصية. حاول لاحقاً.';
  String get linkOpenFailed => 'تعذّر فتح الرابط';

  // شاشة الترحيب
  String get onboardSkip => 'تخطٍّ';
  String get onboardNext => 'التالي';
  String get onboardStart => 'ابدأ اللعب';
  String get onboard1Title => 'عالم كرة القدم بين يديك';
  String get onboard1Body =>
      'تصنيفات متنوّعة ومستويات تتصاعد صعوبتها معك كلما تقدّمت. اختبر معلوماتك وارتقِ بمستواك.';
  String get onboard2Title => 'قلوب ومساعدات';
  String get onboard2Body =>
      'المستوى الذي لا تجتازه يكلّفك قلباً، والقلوب تتجدّد مع الوقت. استعن بالمساعدات عند الحاجة — تحدي اليوم واللعب السريع مجانيان دائماً.';
  String get onboard3Title => 'حافظ على سلسلتك';
  String get onboard3Body =>
      'العب تحدي اليوم يومياً لتنمو سلسلتك وتكسب قلباً وعملات. أكمل المهام اليومية لتفتح الصندوق.';

  String get noQuestions => 'لا توجد أسئلة متاحة حالياً.';
  String get errorTitle => 'حدث خطأ';
  String get retry => 'إعادة المحاولة';
  String get more => 'المزيد';
  String get dailyStart => 'ابدأ التحدي';

  /// سطر بطاقة تحدي اليوم: «نقاط ×1.5 • يتجدد بعد 7 س و 4 د».
  String dailyMeta(String multiplier, String time) =>
      'نقاط ×$multiplier • يتجدد بعد $time';
  String get updateDownloaded => 'نُزّل تحديث جديد للتطبيق';
  String get updateRestart => 'إعادة التشغيل';
  String get loadCategoriesFailed =>
      'تعذّر تحميل التصنيفات. حاول مرة أخرى.';
  String get ok => 'حسناً';
  String get loadQuestionsFailed =>
      'تعذّر تحميل الأسئلة. حاول مرة أخرى.';

  // الملاحظات والبلاغات
  String get sendFeedback => 'أرسل ملاحظاتك';
  String get sendFeedbackHint =>
      'رسالة بريد إلى المطوّر، ترى محتواها كاملاً قبل إرسالها.';
  String noEmailApp(String email) =>
      'تعذّر فتح تطبيق البريد. راسلنا على $email';
  String get feedbackSubject => 'ملاحظات على تطبيق $appName';
  String get feedbackBodyPrompt => 'اكتب ملاحظتك هنا:';
  String get feedbackDiagnostics => '— معلومات تساعدنا على الإصلاح —';
  String get versionLabel => 'الإصدار';
  String get recentErrors => 'آخر الأخطاء';
  String get noRecentErrors => 'لا أخطاء مسجّلة';
  String get reportQuestion => 'أبلغ عن خطأ';
  String get reportQuestionTitle => 'ما المشكلة في هذا السؤال؟';
  String get reportWrongAnswer => 'الإجابة المعتمدة خاطئة';
  String get reportTwoCorrect => 'أكثر من إجابة صحيحة';
  String get reportTypo => 'خطأ إملائي أو في الصياغة';
  String get reportOther => 'مشكلة أخرى';
  String reportSubject(int questionId) => 'بلاغ عن السؤال $questionId';
  String get reportReasonLabel => 'السبب';
  String get reportQuestionLabel => 'السؤال';
  String get reportOptionsLabel => 'الخيارات';
  String get reportNotePrompt => 'تفاصيل إضافية (اختياري):';
}
