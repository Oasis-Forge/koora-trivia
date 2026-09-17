import '../constants/app_strings.dart';

/// اسم معدود بصيغه العربية، ومعه صيغتا الإنجليزية.
///
/// العدد يغيّر صيغة الاسم في العربية: «يوم واحد» · «يومان» · «5 أيام» ·
/// «11 يوماً». كتابة «N يوم» لكل الأعداد خطأ نحوي يراه كل لاعب.
class ArabicNoun {
  const ArabicNoun({
    required this.singular,
    required this.one,
    required this.dual,
    required this.dualObject,
    required this.plural,
    required this.accusative,
    required this.english,
    required this.englishPlural,
  });

  /// المفرد بعد الصفر ومضاعفات المئة: «0 يوم» · «100 يوم».
  final String singular;

  /// الواحد مكتوباً بالكلمة: «يوم واحد».
  final String one;

  /// المثنى مرفوعاً، مبتدأً أو بعد نقطتين: «يومان».
  final String dual;

  /// المثنى منصوباً أو مجروراً، بعد فعل أو مضاف: «ستفقد نجمتين».
  final String dualObject;

  /// الجمع بعد 3–10: «أيام».
  final String plural;

  /// المفرد المنصوب بعد 11–99: «يوماً».
  final String accusative;

  /// الإنجليزية: المفرد مع 1 وحده، والجمع مع كل عدد آخر (0 days · 1 day · 2 days).
  final String english;
  final String englishPlural;

  static const day = ArabicNoun(
    singular: 'يوم',
    one: 'يوم واحد',
    dual: 'يومان',
    dualObject: 'يومين',
    plural: 'أيام',
    accusative: 'يوماً',
    english: 'day',
    englishPlural: 'days',
  );

  static const heart = ArabicNoun(
    singular: 'قلب',
    one: 'قلب واحد',
    dual: 'قلبان',
    dualObject: 'قلبين',
    plural: 'قلوب',
    accusative: 'قلباً',
    english: 'heart',
    englishPlural: 'hearts',
  );

  static const star = ArabicNoun(
    singular: 'نجمة',
    one: 'نجمة واحدة',
    dual: 'نجمتان',
    dualObject: 'نجمتين',
    plural: 'نجوم',
    accusative: 'نجمة',
    english: 'star',
    englishPlural: 'stars',
  );

  static const point = ArabicNoun(
    singular: 'نقطة',
    one: 'نقطة واحدة',
    dual: 'نقطتان',
    dualObject: 'نقطتين',
    plural: 'نقاط',
    accusative: 'نقطة',
    english: 'point',
    englishPlural: 'points',
  );

  static const level = ArabicNoun(
    singular: 'مستوى',
    one: 'مستوى واحد',
    dual: 'مستويان',
    dualObject: 'مستويين',
    plural: 'مستويات',
    accusative: 'مستوىً',
    english: 'level',
    englishPlural: 'levels',
  );

  static const question = ArabicNoun(
    singular: 'سؤال',
    one: 'سؤال واحد',
    dual: 'سؤالان',
    dualObject: 'سؤالين',
    plural: 'أسئلة',
    accusative: 'سؤالاً',
    english: 'question',
    englishPlural: 'questions',
  );

  static const correctAnswer = ArabicNoun(
    singular: 'إجابة صحيحة',
    one: 'إجابة صحيحة واحدة',
    dual: 'إجابتان صحيحتان',
    dualObject: 'إجابتين صحيحتين',
    plural: 'إجابات صحيحة',
    accusative: 'إجابة صحيحة',
    english: 'correct answer',
    englishPlural: 'correct answers',
  );
}

/// يكتب العدد مع اسمه بالصيغة الصحيحة في لغة التطبيق الحالية.
class ArabicCount {
  const ArabicCount._();

  /// العدد مع اسمه: «يوم واحد» · «يومان» · «5 أيام» · «11 يوماً» · «5 days».
  ///
  /// [object] يختار المثنى المنصوب حين يأتي بعد فعل أو مضاف: «ستفقد نجمتين».
  static String format(int count, ArabicNoun noun, {bool object = false}) {
    if (_english) return '$count ${nounFor(count, noun)}';
    final n = count.abs();
    if (n == 1) return noun.one;
    if (n == 2) return object ? noun.dualObject : noun.dual;
    return '$count ${nounFor(count, noun)}';
  }

  /// صيغة الاسم وحده حين يُعرض الرقم منفصلاً عنه (رقم كبير فوق كلمة «نقطة»).
  ///
  /// الصيغة تتبع آخر رقمين: 3–10 جمع، 11–99 مفرد منصوب، وما عداها مفرد.
  static String nounFor(int count, ArabicNoun noun) {
    if (_english) return count.abs() == 1 ? noun.english : noun.englishPlural;
    final lastTwo = count.abs() % 100;
    if (lastTwo >= 3 && lastTwo <= 10) return noun.plural;
    if (lastTwo >= 11) return noun.accusative;
    return noun.singular;
  }

  static bool get _english => AppStrings.languageCode == 'en';
}
