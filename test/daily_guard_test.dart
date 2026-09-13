import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:football_trivia/data/datasources/stats_local_datasource.dart';
import 'package:football_trivia/data/repositories/stats_repository_impl.dart';
import 'package:football_trivia/domain/entities/question.dart';
import 'package:football_trivia/domain/entities/quiz_result.dart';
import 'package:football_trivia/presentation/providers/stats_provider.dart';

/// يحرس قاعدة «تحدي اليوم مرّة واحدة يومياً»: بعد إكماله يجب أن يصبح
/// `isDailyDone` صحيحاً ويبقى كذلك بعد إعادة تشغيل التطبيق — فبطاقة الرئيسية
/// تعطّل زر اللعب اعتماداً عليه.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  QuizResult dailyResult({int correct = 5, int total = 7}) {
    final answers = <AnswerRecord>[];
    for (var i = 0; i < total; i++) {
      answers.add(AnswerRecord(
        question: Question(
          id: 1000 + i,
          category: 'world_cup',
          categoryName: 'كأس العالم',
          level: 1,
          text: 'سؤال $i',
          options: const ['أ', 'ب', 'ج', 'د'],
          answerIndex: 0,
        ),
        selectedIndex: i < correct ? 0 : 1,
        earnedPoints: i < correct ? 100 : 0,
        secondsLeft: 5,
      ));
    }
    return QuizResult(
      answers: answers,
      score: correct * 100,
      isDaily: true,
      playedAt: DateTime.now(),
    );
  }

  StatsProvider makeProvider() =>
      StatsProvider(repository: StatsRepositoryImpl(PrefsStatsDataSource()));

  setUp(() => SharedPreferences.setMockInitialValues({}));

  test('قبل اللعب: تحدي اليوم غير مكتمل', () async {
    final p = makeProvider();
    await p.init();
    expect(p.isDailyDone, isFalse);
  });

  test('بعد إكمال تحدي اليوم يصبح مكتملاً (فيُعطَّل زر اللعب)', () async {
    final p = makeProvider();
    await p.init();

    await p.recordResult(dailyResult());

    expect(p.isDailyDone, isTrue,
        reason: 'بطاقة الرئيسية تعتمد على هذه القيمة لتعطيل الإعادة');
    expect(p.streak, 1);
  });

  test('حالة الإكمال تنجو من إعادة تشغيل التطبيق', () async {
    final first = makeProvider();
    await first.init();
    await first.recordResult(dailyResult());
    expect(first.isDailyDone, isTrue);

    final second = makeProvider();
    await second.init();
    expect(second.isDailyDone, isTrue,
        reason: 'لولا ذلك لأمكن إعادة لعب التحدي بعد إعادة التشغيل');
  });

  test('إعادة تسجيل تحدي اليوم مرة ثانية لا تزيد السلسلة', () async {
    final p = makeProvider();
    await p.init();

    await p.recordResult(dailyResult());
    final streakAfterFirst = p.streak;
    await p.recordResult(dailyResult());

    expect(p.streak, streakAfterFirst,
        reason: 'تحدي اليوم يُحتسب مرة واحدة فقط في اليوم');
    expect(p.isDailyDone, isTrue);
  });

  test('اللعب السريع لا يُعلّم تحدي اليوم كمكتمل', () async {
    final p = makeProvider();
    await p.init();

    await p.recordResult(QuizResult(
      answers: const [],
      score: 0,
      isDaily: false,
      playedAt: DateTime.now(),
    ));

    expect(p.isDailyDone, isFalse);
  });
}
