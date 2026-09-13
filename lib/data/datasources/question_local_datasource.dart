import 'dart:convert';

import 'package:flutter/services.dart' show rootBundle;

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

/// يقرأ `categories.json` ثم ملف أسئلة لكل تصنيف (يعمل دون إنترنت).
///
/// فصل الأسئلة إلى ملف لكل تصنيف يبقي كل ملف بحجم يمكن مراجعته يدوياً،
/// ويجعل إضافة تصنيف جديد مجرد ملف جديد + سطر في `categories.json`.
class AssetQuestionDataSource implements QuestionLocalDataSource {
  AssetQuestionDataSource({
    this.categoriesAsset = 'assets/data/categories.json',
    this.questionsDir = 'assets/data/questions',
  });

  final String categoriesAsset;
  final String questionsDir;

  QuestionBank? _cache;

  @override
  Future<QuestionBank> load() async {
    final cached = _cache;
    if (cached != null) return cached;

    final rawIndex = await rootBundle.loadString(categoriesAsset);
    final index = json.decode(rawIndex) as Map<String, dynamic>;

    final categories = (index['categories'] as List<dynamic>)
        .map((e) => CategoryModel.fromJson(e as Map<String, dynamic>))
        .toList()
      ..sort((a, b) => a.order.compareTo(b.order));

    final questions = <QuestionModel>[];
    for (final category in categories) {
      final raw = await rootBundle.loadString(
        '$questionsDir/${category.slug}.json',
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
    _cache = bank;
    return bank;
  }
}
