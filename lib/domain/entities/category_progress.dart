/// تقدّم المستخدم داخل تصنيف واحد.
///
/// [stars] قائمة طولها [levelCount]، العنصر رقم `i` يمثّل نجوم المستوى `i+1`
/// (من 0 إلى 3). القيمة صفر تعني أن المستوى لم يُجتَز بعد.
class CategoryProgress {
  const CategoryProgress({required this.slug, required this.stars});

  factory CategoryProgress.empty(String slug, int levelCount) {
    return CategoryProgress(
      slug: slug,
      stars: List<int>.filled(levelCount, 0),
    );
  }

  final String slug;
  final List<int> stars;

  int get levelCount => stars.length;

  int starsFor(int level) =>
      (level >= 1 && level <= levelCount) ? stars[level - 1] : 0;

  bool isCompleted(int level) => starsFor(level) > 0;

  /// عدد المستويات المجتازة.
  int get completedLevels => stars.where((s) => s > 0).length;

  int get totalStars => stars.fold(0, (a, b) => a + b);

  int get maxStars => levelCount * 3;

  bool get isFullyCompleted => completedLevels == levelCount;

  /// أعلى مستوى مفتوح للّعب.
  ///
  /// الفتح تدريجي: المستوى الأول مفتوح دائماً، وكل مستوى يُفتح باجتياز ما قبله.
  /// نعتمد على أول مستوى غير مجتاز بدل عدّ المجتازة، حتى لا يؤدي تخطٍّ غير
  /// متوقّع في البيانات إلى فتح سلسلة كاملة.
  int get highestUnlockedLevel {
    for (var level = 1; level <= levelCount; level++) {
      if (!isCompleted(level)) return level;
    }
    return levelCount;
  }

  bool isUnlocked(int level) => level <= highestUnlockedLevel;

  /// نسخة بعد تسجيل نتيجة مستوى — النجوم لا تتناقص أبداً.
  CategoryProgress withLevelStars(int level, int earned) {
    if (level < 1 || level > levelCount) return this;
    if (earned <= starsFor(level)) return this;

    final next = List<int>.of(stars);
    next[level - 1] = earned;
    return CategoryProgress(slug: slug, stars: next);
  }
}
