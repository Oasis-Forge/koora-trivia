enum Difficulty { easy, medium, hard }

extension DifficultyLabel on Difficulty {
  String get arabicLabel => switch (this) {
        Difficulty.easy => 'سهل',
        Difficulty.medium => 'متوسط',
        Difficulty.hard => 'صعب',
      };

  /// مضاعف النقاط حسب الصعوبة.
  double get multiplier => switch (this) {
        Difficulty.easy => 1.0,
        Difficulty.medium => 1.25,
        Difficulty.hard => 1.5,
      };
}

class Question {
  const Question({
    required this.id,
    required this.category,
    required this.categoryName,
    required this.level,
    required this.text,
    required this.options,
    required this.answerIndex,
    this.explanation,
  });

  final int id;

  /// المعرّف البرمجي للتصنيف (مثل `world_cup`) — يُستخدم في الحفظ والمنطق.
  final String category;

  /// اسم التصنيف بالعربية — للعرض فقط.
  final String categoryName;

  /// المستوى من 1 إلى 10 داخل التصنيف.
  final int level;

  final String text;
  final List<String> options;
  final int answerIndex;
  final String? explanation;

  /// الصعوبة مشتقّة من المستوى — مصدر واحد للحقيقة، فلا يمكن أن تتناقض معه.
  Difficulty get difficulty => difficultyForLevel(level);

  static Difficulty difficultyForLevel(int level) {
    if (level <= 3) return Difficulty.easy;
    if (level <= 7) return Difficulty.medium;
    return Difficulty.hard;
  }

  String get correctAnswer => options[answerIndex];

  bool isCorrect(int selectedIndex) => selectedIndex == answerIndex;

  /// نسخة بخيارات مُعاد ترتيبها مع تصحيح موضع الإجابة الصحيحة.
  Question withOptionsOrder(List<String> reordered) {
    return Question(
      id: id,
      category: category,
      categoryName: categoryName,
      level: level,
      text: text,
      options: reordered,
      answerIndex: reordered.indexOf(options[answerIndex]),
      explanation: explanation,
    );
  }
}
