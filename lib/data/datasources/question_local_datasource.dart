import 'dart:convert';

import 'package:flutter/services.dart' show rootBundle;

import '../../core/constants/app_strings.dart';
import '../models/category_model.dart';
import '../models/question_model.dart';

/// نتيجة تحميل بنك الأسئلة كاملاً.
class QuestionBank {
  const QuestionBank({required this.categories, required this.questions});

  final List<CategoryModel> categories;
  final List<QuestionModel> questions;
}

abstract class QuestionLocalDataSource {
  Future<QuestionBank> load();
}

/// يقرأ `categories.json` ثم ملف أسئلة لكل تصنيف (يعمل دون إنترنت)، بلغة التطبيق.
///
/// فصل الأسئلة إلى ملف لكل تصنيف يبقي كل ملف بحجم يمكن مراجعته يدوياً،
/// ويجعل إضافة تصنيف جديد مجرد ملف جديد + سطر في `categories.json`.
///
/// العربية في `assets/data` وكل لغة أخرى في مجلدها (`assets/data/en`) بالمعرّفات
/// نفسها. لكل لغة نسختها المحفوظة: البنك الواحد يحمل أسماء تصنيفاته داخل أسئلته،
/// فنسخة واحدة كانت ستُبقي الأسماء القديمة بعد تبديل اللغة.
class AssetQuestionDataSource implements QuestionLocalDataSource {
  AssetQuestionDataSource({String Function()? language})
      : _language = language ?? (() => AppStrings.languageCode);

  final String Function() _language;
  final Map<String, QuestionBank> _cache = {};

  /// مجلد بيانات اللغة: العربية الأصل في الجذر.
  static String rootFor(String language) =>
      language == 'ar' ? 'assets/data' : 'assets/data/$language';

  @override
  Future<QuestionBank> load() async {
    final language = _language();
    final cached = _cache[language];
    if (cached != null) return cached;

    final root = rootFor(language);
    final rawIndex = await rootBundle.loadString('$root/categories.json');
    final index = json.decode(rawIndex) as Map<String, dynamic>;

    final categories = (index['categories'] as List<dynamic>)
        .map((e) => CategoryModel.fromJson(e as Map<String, dynamic>))
        .toList()
      ..sort((a, b) => a.order.compareTo(b.order));

    final questions = <QuestionModel>[];
    for (final category in categories) {
      final raw = await rootBundle.loadString(
        '$root/questions/${category.slug}.json',
      );
      final decoded = json.decode(raw) as Map<String, dynamic>;

      final declared = decoded['category'] as String;
      if (declared != category.slug) {
        throw FormatException(
          'ملف ${category.slug}.json يعلن عن التصنيف "$declared"',
        );
      }

      questions.addAll(
        (decoded['questions'] as List<dynamic>).map(
          (e) => QuestionModel.fromJson(
            e as Map<String, dynamic>,
            category: category.slug,
            categoryName: category.name,
          ),
        ),
      );
    }

    final bank = QuestionBank(categories: categories, questions: questions);
    _cache[language] = bank;
    return bank;
  }
}
