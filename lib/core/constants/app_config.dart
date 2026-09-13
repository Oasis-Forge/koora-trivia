/// إعدادات اللعبة القابلة للضبط.
class AppConfig {
  const AppConfig._();

  /// عدد الأسئلة في الجولة السريعة.
  static const int quickPlayQuestionCount = 10;

  /// عدد أسئلة تحدي اليوم.
  static const int dailyQuestionCount = 7;

  /// عدد المستويات في كل تصنيف.
  ///
  /// يجب أن يطابق `levelsPerCategory` في `assets/data/categories.json`،
  /// ويحرس التطابقَ اختبارٌ في `question_bank_test.dart`.
  static const int levelsPerCategory = 10;

  /// عدد الأسئلة في المستوى الواحد.
  static const int questionsPerLevel = 10;

  /// المدة المتاحة للسؤال بالثواني.
  static const int secondsPerQuestion = 20;

  /// نقاط الإجابة الصحيحة.
  static const int pointsPerCorrect = 100;

  /// أقصى مكافأة سرعة تُضاف للإجابة الصحيحة الفورية.
  static const int maxSpeedBonus = 50;

  /// مضاعف نقاط تحدي اليوم.
  static const double dailyMultiplier = 1.5;

  // ── عتبات اجتياز المستوى ──

  /// أقل نسبة إجابات صحيحة لاجتياز المستوى وفتح ما بعده (نجمة واحدة).
  static const double passRatio = 0.7;

  /// نسبة نجمتين.
  static const double twoStarRatio = 0.9;

  /// نسبة ثلاث نجوم.
  static const double threeStarRatio = 1.0;

  // ── الاقتصاد: القلوب ──
  // القلوب تُستهلك في نمط المستويات فقط. تحدي اليوم واللعب السريع مجانيان
  // دائماً حتى لا ينكسر تسلسل المستخدم بسبب نظام تحقيق الدخل.

  static const int maxHearts = 5;

  /// دقائق تجديد القلب الواحد.
  static const int heartRegenMinutes = 30;

  /// حد يومي لعدد مرات إعادة التعبئة بالإعلان.
  static const int maxRewardedRefillsPerDay = 4;

  /// قلب مجاني عند إكمال تحدي اليوم — يربط النمط المجاني بنمط المستويات.
  static const int heartsForDailyChallenge = 1;

  // ── الاقتصاد: المساعدات ──

  static const int freeHintsPerDay = 3;

  /// ثوانٍ تُضاف عند استخدام مساعدة الوقت الإضافي.
  static const int extraTimeSeconds = 10;

  // ── الاقتصاد: العملة ──
  // العملة طبقة وسيطة بين الكسب والإنفاق: أي فعل يمنح عملات، والعملات تشتري
  // قلوباً أو مساعدات. هذا يسمح بمكافأة أفعال متعددة بعملة واحدة.

  // ⚖️ قاعدة الضبط: **الدخل اليومي الكامل يجب أن يبقى أقل من سعر شراء واحد.**
  // بذلك يشتري اللاعب المواظب كل يوم ونصف تقريباً، وتبقى الفجوة هي المكان
  // الذي يملؤه الإعلان المكافأ أو الشراء الحقيقي.
  // المجموع اليومي 130 مقابل سعر 200 ⇒ نحو 1.5 يوم لكل عملية شراء.

  /// مكافآت المهام اليومية.
  static const int coinsTaskAnswers = 20;
  static const int coinsTaskDaily = 40;
  static const int coinsTaskLevel = 30;

  /// مكافأة الصندوق عند إتمام كل المهام.
  static const int coinsChestBonus = 40;

  /// عدد الإجابات الصحيحة المطلوبة لمهمة الإجابات.
  static const int taskAnswersTarget = 10;

  /// أسعار المتجر بالعملات.
  static const int priceHeartsRefill = 200;
  static const int priceHintsPack = 200;

  /// عدد المساعدات في الحزمة المشتراة.
  static const int hintsPerPack = 3;

  // ── الإعلانات ──

  /// قلوب تُمنح مقابل مشاهدة إعلان مكافأ. قلب واحد يبقي الندرة قائمة.
  static const int heartsPerRewardedAdWatch = 1;

  /// عملات تُمنح مقابل مشاهدة إعلان مكافأ.
  ///
  /// 70 عملة تسدّ تماماً الفجوة بين دخل اليوم (130) وسعر الشراء (200)،
  /// فيصبح الإعلان هو الطريق الطبيعي لإنهاء الادخار في اليوم نفسه.
  static const int coinsPerRewardedAd = 70;

  /// هل الإعلانات البينية مفعّلة؟
  ///
  /// **مطفأة عند الإطلاق عمداً.** تقييمات الأيام الأولى في غوغل بلاي لها وزن
  /// كبير، والإعلان البيني هو أكثر ما يخفضها. أطلق نظيفاً، اجمع تقييمات جيدة،
  /// ثم فعّلها في تحديث لاحق. الإعلان المكافأ يبقى يعمل من اليوم الأول لأنه
  /// اختياري ولا يزعج أحداً.
  static const bool interstitialsEnabled = false;

  /// عدد الجولات أو المستويات بين إعلانين بينيين.
  static const int roundsBetweenInterstitials = 3;

  /// سقف زمني صارم بين إعلانين بينيين مهما بلغ عدد الجولات.
  static const int minSecondsBetweenInterstitials = 180;

  /// مهل إعادة محاولة تحميل إعلان فشل، بالثواني. آخر قيمة تتكرر كسقف.
  ///
  /// تصاعدية حتى لا نُغرق الشبكة أثناء انقطاع طويل، والعودة إلى التطبيق
  /// تعيد المحاولة فوراً دون انتظار المهلة.
  static const List<int> adRetryDelaysSeconds = [15, 30, 60, 120, 300];

  /// ثوانٍ بين إعادة احتساب القلوب على الشاشة ما دامت ناقصة.
  static const int heartsRefreshSeconds = 30;

  // ── التنبيه اليومي ──

  /// عدد الأيام القادمة التي تُجدول تنبيهاتها مسبقاً.
  ///
  /// الجدولة تُعاد عند كل فتح للتطبيق وكل إنجاز للتحدي، فمن غاب أسبوعاً كاملاً
  /// يتوقف تذكيره بدل أن يُلاحَق بتنبيه يومي بلا نهاية.
  ///
  /// ⚠️ قبل أندرويد 12 قد يتأخر التنبيه غير الدقيق حتى ثلاثة أرباع المدة الباقية
  /// على موعده، فالتنبيهات البعيدة (للاعب لم يفتح التطبيق منذ أيام) قد تصل متأخرة
  /// ساعات. زيادة هذا الرقم تزيد التأخير الممكن.
  static const int reminderDaysAhead = 7;

  // ── الروابط ──

  /// صفحة سياسة الخصوصية المنشورة.
  ///
  /// ⚠️ نقل مستودع الصفحة أو تغيير اسمه يغيّر الرابط دون تحويل — حدّثه هنا وفي
  /// Play Console معاً.
  static const String privacyPolicyUrl =
      'https://oasis-forge.github.io/koora-trivia-privacy/';
}
