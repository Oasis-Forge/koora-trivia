import '../../domain/entities/question.dart';

class QuestionModel extends Question {
  const QuestionModel({
    required super.id,
    required super.category,
    required super.categoryName,
    required super.level,
    required super.text,
    required super.options,
    required super.answerIndex,
    super.explanation,
  });

  /// [category] يأتي من الملف الحاوي، لا من السؤال نفسه — فلا يتكرر 100 مرة.
  factory QuestionModel.fromJson(
    Map<String, dynamic> json, {
    required String category,
    required String categoryName,
  }) {
    final id = json['id'] as int;

    final options = (json['options'] as List<dynamic>)
        .map((e) => e as String)
        .toList(growable: false);

    final answerIndex = json['answerIndex'] as int;
    if (answerIndex < 0 || answerIndex >= options.length) {
      throw FormatException('answerIndex خارج النطاق في السؤال $id');
    }

    final level = json['level'] as int;
    if (level < 1 || level > 10) {
      throw FormatException('المستوى $level خارج النطاق في السؤال $id');
    }

    return QuestionModel(
      id: id,
      category: category,
      categoryName: categoryName,
      level: level,
      text: json['question'] as String,
      options: options,
      answerIndex: answerIndex,
      explanation: json['explanation'] as String?,
    );
  }
}
