import 'package:flutter_test/flutter_test.dart';
import 'package:football_trivia/core/constants/app_config.dart';
import 'package:football_trivia/domain/entities/question.dart';
import 'package:football_trivia/domain/entities/quiz_result.dart';
import 'package:football_trivia/domain/usecases/build_share_text.dart';

Question _question(int id) => Question(
      id: id,
      category: 'world_cup',
      categoryName: 'كأس العالم',
      level: 1,
      text: 'سؤال سرّي رقم $id',
      options: const ['إجابة صحيحة', 'خطأ ١', 'خطأ ٢', 'خطأ ٣'],
      answerIndex: 0,
    );

/// [pattern] حرف لكل سؤال: c صحيح · w خطأ · m متجاوَز أو منتهي الوقت.
QuizResult _result(
  String pattern, {
  bool isDaily = false,
  String? categorySlug,
  int? level,
}) {
  final answers = <AnswerRecord>[];
  for (var i = 0; i < pattern.length; i++) {
    final kind = pattern[i];
    answers.add(
      AnswerRecord(
        question: _question(1001 + i),
        selectedIndex: switch (kind) { 'c' => 0, 'w' => 1, _ => -1 },
        earnedPoints: kind == 'c' ? 150 : 0,
        secondsLeft: 10,
        skipped: kind == 'm',
      ),
    );
  }

  return QuizResult(
    answers: answers,
    score: answers.fold(0, (s, a) => s + a.earnedPoints),
    isDaily: isDaily,
    playedAt: DateTime(2026, 8, 4),
    categorySlug: categorySlug,
    level: level,
  );
}

void main() {
  const build = BuildShareText();

  test('الشبكة تعكس نمط الإجابات بالترتيب', () {
    expect(build.grid(_result('ccwcm')), '🟩🟩🟥🟩⬜');
  });

  test('تحدي اليوم يحمل تاريخه لأن أسئلته موحّدة للجميع', () {
    final text = build(_result('ccwcccw', isDaily: true), streak: 12);

    expect(text, contains('4 أغسطس'));
    expect(text, contains('🟩🟩🟥🟩🟩🟩🟥'));
    expect(text, contains('5/7'));
    expect(text, contains('🔥 السلسلة: 12 يوماً'));
  });

  test('المستوى يعرض التصنيف ورقم المستوى', () {
    final text = build(
      _result('cccccccccw', categorySlug: 'world_cup', level: 8),
      streak: 0,
      categoryName: 'كأس العالم',
    );

    expect(text, contains('كأس العالم'));
    expect(text, contains('المستوى 8'));
    expect(text, contains('9/10'));
  });

  test('اللعب السريع لا يحمل تاريخاً ولا مستوى', () {
    final text = build(_result('ccw'), streak: 0);

    expect(text, contains('جولة سريعة'));
    expect(text, isNot(contains('أغسطس')));
    expect(text, isNot(contains('المستوى')));
  });

  test('السلسلة تُحذف إذا كانت صفراً', () {
    expect(build(_result('cc'), streak: 0), isNot(contains('🔥')));
  });

  test('العدد مع «يوم» يُكتب بصيغته الصحيحة', () {
    expect(build(_result('c'), streak: 1), contains('السلسلة: يوم واحد'));
    expect(build(_result('c'), streak: 2), contains('السلسلة: يومان'));
    expect(build(_result('c'), streak: 5), contains('السلسلة: 5 أيام'));
    expect(build(_result('c'), streak: 11), contains('السلسلة: 11 يوماً'));
    expect(build(_result('c'), streak: 12), isNot(contains('أيام')));
  });

  test('النص لا يكشف أي سؤال أو إجابة', () {
    // هذا هو الشرط الذي يجعل المشاركة آمنة قبل أن يلعب الأصدقاء.
    final result = _result('cwm', isDaily: true);
    final text = build(result, streak: 3);

    for (final answer in result.answers) {
      expect(text, isNot(contains(answer.question.text)));
      for (final option in answer.question.options) {
        expect(text, isNot(contains(option)));
      }
    }
  });

  test('رابط التطبيق في آخر سطر وحده، ومعه مصدر التثبيت', () {
    for (final result in [
      _result('ccwcccw', isDaily: true),
      _result('ccw'),
    ]) {
      final lines = build(result, streak: 4).split('\n');

      expect(lines.last, BuildShareText.shareLink);
    }

    expect(BuildShareText.shareLink, startsWith(AppConfig.playStoreUrl));
    expect(
      Uri.parse(BuildShareText.shareLink).queryParameters['referrer'],
      AppConfig.shareReferrer,
    );
  });

  test('طول الشبكة يساوي عدد الأسئلة دائماً', () {
    expect(build.grid(_result('c' * 7)).runes.length, 7);
    expect(build.grid(_result('w' * 10)).runes.length, 10);
  });
}
