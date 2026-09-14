import 'package:fake_async/fake_async.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:football_trivia/core/constants/app_config.dart';
import 'package:football_trivia/core/constants/app_strings.dart';
import 'package:football_trivia/data/datasources/question_local_datasource.dart';
import 'package:football_trivia/data/models/category_model.dart';
import 'package:football_trivia/data/models/question_model.dart';
import 'package:football_trivia/data/repositories/quiz_repository_impl.dart';
import 'package:football_trivia/domain/entities/question.dart';
import 'package:football_trivia/presentation/providers/quiz_provider.dart';

/// بنك وهمي: تصنيفان × 10 مستويات × 10 أسئلة، أو بنك فارغ لاختبار الأخطاء.
class _FakeDataSource implements QuestionLocalDataSource {
  _FakeDataSource({this.empty = false});

  final bool empty;

  @override
  Future<QuestionBank> load() async {
    const categories = [
      CategoryModel(slug: 'alpha', name: 'ألفا', idBlock: 1000, order: 1),
      CategoryModel(slug: 'beta', name: 'بيتا', idBlock: 2000, order: 2),
    ];

    if (empty) {
      return const QuestionBank(categories: categories, questions: []);
    }

    final questions = <QuestionModel>[];
    for (final c in categories) {
      for (var i = 1; i <= 100; i++) {
        questions.add(
          QuestionModel(
            id: c.idBlock + i,
            category: c.slug,
            categoryName: c.name,
            level: ((i - 1) ~/ 10) + 1,
            text: 'سؤال ${c.slug} رقم $i',
            options: ['خيار$i-أ', 'خيار$i-ب', 'خيار$i-ج', 'خيار$i-د'],
            answerIndex: i % 4,
          ),
        );
      }
    }
    return QuestionBank(categories: categories, questions: questions);
  }
}

/// بنك تالف: التحميل يرمي.
class _ThrowingDataSource implements QuestionLocalDataSource {
  @override
  Future<QuestionBank> load() async => throw StateError('ملف أسئلة تالف');
}

QuizProvider _provider({bool empty = false}) => QuizProvider(
      repository: QuizRepositoryImpl(_FakeDataSource(empty: empty)),
    );

/// يبدأ مستوى داخل بيئة زمن وهمي ويعيد المزوّد جاهزاً للّعب.
QuizProvider _startedLevel(FakeAsync async, {int level = 1}) {
  final quiz = _provider();
  quiz.startLevel(categorySlug: 'alpha', level: level);
  async.flushMicrotasks();
  return quiz;
}

/// فهرس إجابة خاطئة مضمونة للسؤال الحالي.
int _wrongIndex(QuizProvider quiz) =>
    (quiz.currentQuestion!.answerIndex + 1) % 4;

int _rightIndex(QuizProvider quiz) => quiz.currentQuestion!.answerIndex;

void main() {
  group('بدء الجولة', () {
    test('المستوى يبدأ بعشرة أسئلة وعدّاد ممتلئ', () {
      fakeAsync((async) {
        final quiz = _startedLevel(async);

        expect(quiz.status, QuizStatus.playing);
        expect(quiz.total, AppConfig.questionsPerLevel);
        expect(quiz.index, 0);
        expect(quiz.score, 0);
        expect(quiz.secondsLeft, AppConfig.secondsPerQuestion);
        expect(quiz.activeCategory, 'alpha');
        expect(quiz.activeLevel, 1);
        expect(quiz.isDaily, isFalse);

        quiz.dispose();
      });
    });

    test('بنك فارغ ينتج حالة خطأ لا انهياراً', () {
      fakeAsync((async) {
        final quiz = _provider(empty: true);
        quiz.startQuickPlay();
        async.flushMicrotasks();

        expect(quiz.status, QuizStatus.error);
        expect(quiz.errorMessage, AppStrings.noQuestions);

        quiz.dispose();
      });
    });

    test('خطأ التحميل يظهر برسالة مفهومة وتذهب تفاصيله إلى سجل الأخطاء', () {
      final reported = <FlutterErrorDetails>[];
      final original = FlutterError.onError;
      FlutterError.onError = reported.add;
      addTearDown(() => FlutterError.onError = original);

      fakeAsync((async) {
        final quiz = QuizProvider(
          repository: QuizRepositoryImpl(_ThrowingDataSource()),
        );
        quiz.startQuickPlay();
        async.flushMicrotasks();

        expect(quiz.status, QuizStatus.error);
        // كان نص الاستثناء الخام يظهر للاعب.
        expect(quiz.errorMessage, AppStrings.loadQuestionsFailed);
        expect(reported.single.exception, isA<StateError>());
        expect(reported.single.stack, isNotNull);

        quiz.dispose();
      });
    });

    test('اللعب السريع لا يحمل تصنيفاً ولا مستوى', () {
      fakeAsync((async) {
        final quiz = _provider();
        quiz.startQuickPlay();
        async.flushMicrotasks();

        expect(quiz.activeCategory, isNull);
        expect(quiz.activeLevel, isNull);
        expect(quiz.total, AppConfig.quickPlayQuestionCount);

        quiz.dispose();
      });
    });
  });

  group('حساب النقاط', () {
    test('إجابة صحيحة فورية في مستوى سهل تمنح 150 نقطة', () {
      fakeAsync((async) {
        // المستوى 1 ⇒ سهل ⇒ 100 × 1.0 + مكافأة سرعة كاملة 50.
        final quiz = _startedLevel(async, level: 1);
        expect(quiz.currentQuestion!.difficulty, Difficulty.easy);

        quiz.selectAnswer(_rightIndex(quiz));

        expect(quiz.score, 150);
        expect(quiz.answers.single.earnedPoints, 150);
        expect(quiz.answers.single.isCorrect, isTrue);

        quiz.dispose();
      });
    });

    test('مضاعف الصعوبة يرفع نقاط المستوى المتوسط إلى 175', () {
      fakeAsync((async) {
        // المستوى 5 ⇒ متوسط ⇒ 100 × 1.25 + 50.
        final quiz = _startedLevel(async, level: 5);
        expect(quiz.currentQuestion!.difficulty, Difficulty.medium);

        quiz.selectAnswer(_rightIndex(quiz));

        expect(quiz.score, 175);
        quiz.dispose();
      });
    });

    test('مضاعف الصعوبة يرفع نقاط المستوى الصعب إلى 200', () {
      fakeAsync((async) {
        // المستوى 9 ⇒ صعب ⇒ 100 × 1.5 + 50.
        final quiz = _startedLevel(async, level: 9);
        expect(quiz.currentQuestion!.difficulty, Difficulty.hard);

        quiz.selectAnswer(_rightIndex(quiz));

        expect(quiz.score, 200);
        quiz.dispose();
      });
    });

    test('مكافأة السرعة تتناقص مع مرور الوقت', () {
      fakeAsync((async) {
        final quiz = _startedLevel(async, level: 1);

        // بعد عشر ثوانٍ يتبقى نصف الوقت ⇒ نصف المكافأة (25).
        async.elapse(const Duration(seconds: 10));
        expect(quiz.secondsLeft, 10);

        quiz.selectAnswer(_rightIndex(quiz));

        expect(quiz.score, 125);
        quiz.dispose();
      });
    });

    test('مضاعف تحدي اليوم يرفع النقاط بنسبة النصف', () {
      fakeAsync((async) {
        final quiz = _provider();
        quiz.startDaily();
        async.flushMicrotasks();

        expect(quiz.isDaily, isTrue);
        final difficulty = quiz.currentQuestion!.difficulty;
        quiz.selectAnswer(_rightIndex(quiz));

        final base = AppConfig.pointsPerCorrect * difficulty.multiplier;
        final expected =
            ((base + AppConfig.maxSpeedBonus) * AppConfig.dailyMultiplier)
                .round();

        expect(quiz.score, expected);
        quiz.dispose();
      });
    });

    test('الإجابة الخاطئة لا تمنح أي نقاط', () {
      fakeAsync((async) {
        final quiz = _startedLevel(async);

        quiz.selectAnswer(_wrongIndex(quiz));

        expect(quiz.score, 0);
        expect(quiz.answers.single.earnedPoints, 0);
        expect(quiz.answers.single.isCorrect, isFalse);

        quiz.dispose();
      });
    });

    test('النقاط تتراكم عبر الأسئلة', () {
      fakeAsync((async) {
        final quiz = _startedLevel(async);

        quiz.selectAnswer(_rightIndex(quiz));
        quiz.next();
        quiz.selectAnswer(_rightIndex(quiz));

        expect(quiz.score, 300);
        expect(quiz.answers.length, 2);

        quiz.dispose();
      });
    });
  });

  group('انتهاء الوقت', () {
    test('نفاد العدّاد يسجّل إجابة متجاوَزة بلا نقاط', () {
      fakeAsync((async) {
        final quiz = _startedLevel(async);

        async.elapse(Duration(seconds: AppConfig.secondsPerQuestion));

        expect(quiz.status, QuizStatus.revealing);
        expect(quiz.secondsLeft, 0);
        expect(quiz.selectedIndex, -1);
        expect(quiz.answers.single.timedOut, isTrue);
        expect(quiz.answers.single.isCorrect, isFalse);
        expect(quiz.score, 0);

        quiz.dispose();
      });
    });

    test('العدّاد يتوقف بعد الإجابة فلا يقع تجاوز للوقت', () {
      fakeAsync((async) {
        final quiz = _startedLevel(async);
        quiz.selectAnswer(_rightIndex(quiz));

        async.elapse(const Duration(seconds: 30));

        // إجابة واحدة فقط: لم يُضف سجل تجاوز الوقت بعد الكشف.
        expect(quiz.answers.length, 1);
        expect(quiz.status, QuizStatus.revealing);

        quiz.dispose();
      });
    });

    test('العدّاد يُعاد ضبطه مع كل سؤال جديد', () {
      fakeAsync((async) {
        final quiz = _startedLevel(async);

        async.elapse(const Duration(seconds: 8));
        quiz.selectAnswer(_rightIndex(quiz));
        quiz.next();

        expect(quiz.secondsLeft, AppConfig.secondsPerQuestion);

        quiz.dispose();
      });
    });
  });

  group('تسلسل الأسئلة', () {
    test('next ينتقل للسؤال التالي ويمسح الاختيار', () {
      fakeAsync((async) {
        final quiz = _startedLevel(async);
        final firstId = quiz.currentQuestion!.id;

        quiz.selectAnswer(_rightIndex(quiz));
        quiz.next();

        expect(quiz.index, 1);
        expect(quiz.status, QuizStatus.playing);
        expect(quiz.selectedIndex, isNull);
        expect(quiz.currentQuestion!.id, isNot(firstId));

        quiz.dispose();
      });
    });

    test('إنهاء آخر سؤال ينقل الحالة إلى finished', () {
      fakeAsync((async) {
        final quiz = _startedLevel(async);

        for (var i = 0; i < AppConfig.questionsPerLevel; i++) {
          expect(quiz.isLastQuestion, i == AppConfig.questionsPerLevel - 1);
          quiz.selectAnswer(_rightIndex(quiz));
          quiz.next();
        }

        expect(quiz.status, QuizStatus.finished);
        expect(quiz.answers.length, AppConfig.questionsPerLevel);

        quiz.dispose();
      });
    });

    test('التقدّم يعكس موضع السؤال الحالي', () {
      fakeAsync((async) {
        final quiz = _startedLevel(async);

        expect(quiz.progress, closeTo(0.1, 0.001));
        quiz.selectAnswer(_rightIndex(quiz));
        quiz.next();
        expect(quiz.progress, closeTo(0.2, 0.001));

        quiz.dispose();
      });
    });
  });

  group('حماية الحالة', () {
    test('اختيار إجابة ثانية بعد الكشف يُتجاهل', () {
      fakeAsync((async) {
        final quiz = _startedLevel(async);

        quiz.selectAnswer(_rightIndex(quiz));
        final scoreAfterFirst = quiz.score;

        quiz.selectAnswer(_rightIndex(quiz));

        expect(quiz.score, scoreAfterFirst);
        expect(quiz.answers.length, 1);

        quiz.dispose();
      });
    });

    test('next أثناء اللعب لا يفعل شيئاً', () {
      fakeAsync((async) {
        final quiz = _startedLevel(async);

        quiz.next();

        expect(quiz.index, 0);
        expect(quiz.status, QuizStatus.playing);

        quiz.dispose();
      });
    });

    test('abandon يعيد المزوّد إلى الحالة الخاملة', () {
      fakeAsync((async) {
        final quiz = _startedLevel(async);
        quiz.selectAnswer(_rightIndex(quiz));

        quiz.abandon();

        expect(quiz.status, QuizStatus.idle);
        expect(quiz.total, 0);
        expect(quiz.answers, isEmpty);
        expect(quiz.score, 0);
        expect(quiz.currentQuestion, isNull);

        // لا مؤقّت معلّق بعد الإلغاء.
        async.elapse(const Duration(seconds: 30));

        quiz.dispose();
      });
    });
  });

  group('بناء النتيجة', () {
    test('نتيجة المستوى تحمل التصنيف والمستوى', () {
      fakeAsync((async) {
        final quiz = _startedLevel(async, level: 4);

        quiz.selectAnswer(_rightIndex(quiz));
        quiz.next();
        quiz.selectAnswer(_wrongIndex(quiz));

        final result = quiz.buildResult();

        expect(result.isLevel, isTrue);
        expect(result.categorySlug, 'alpha');
        expect(result.level, 4);
        expect(result.total, 2);
        expect(result.correctCount, 1);
        expect(result.accuracyPercent, 50);

        quiz.dispose();
      });
    });

    test('نتيجة اللعب السريع لا تُحسب كمستوى', () {
      fakeAsync((async) {
        final quiz = _provider();
        quiz.startQuickPlay();
        async.flushMicrotasks();

        quiz.selectAnswer(_rightIndex(quiz));

        final result = quiz.buildResult();

        expect(result.isLevel, isFalse);
        expect(result.categorySlug, isNull);
        expect(result.isDaily, isFalse);

        quiz.dispose();
      });
    });

    test('النتيجة الكاملة تحسب الدقة بدقة', () {
      fakeAsync((async) {
        final quiz = _startedLevel(async);

        // سبع صحيحة وثلاث خاطئة ⇒ 70%.
        for (var i = 0; i < AppConfig.questionsPerLevel; i++) {
          quiz.selectAnswer(
            i < 7 ? _rightIndex(quiz) : _wrongIndex(quiz),
          );
          quiz.next();
        }

        final result = quiz.buildResult();

        expect(result.correctCount, 7);
        expect(result.total, 10);
        expect(result.accuracyPercent, 70);

        quiz.dispose();
      });
    });
  });
}
