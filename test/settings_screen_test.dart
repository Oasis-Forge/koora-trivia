import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:football_trivia/core/constants/app_strings.dart';
import 'package:football_trivia/domain/entities/app_settings.dart';
import 'package:football_trivia/domain/entities/category_progress.dart';
import 'package:football_trivia/domain/entities/user_stats.dart';
import 'package:football_trivia/domain/repositories/reminder_scheduler.dart';
import 'package:football_trivia/domain/repositories/settings_repository.dart';
import 'package:football_trivia/presentation/providers/settings_provider.dart';
import 'package:football_trivia/domain/repositories/progress_repository.dart';
import 'package:football_trivia/domain/repositories/quiz_repository.dart';
import 'package:football_trivia/domain/entities/category.dart';
import 'package:football_trivia/domain/entities/question.dart';
import 'package:football_trivia/domain/repositories/stats_repository.dart';
import 'package:football_trivia/presentation/providers/progress_provider.dart';
import 'package:football_trivia/presentation/providers/quiz_provider.dart';
import 'package:football_trivia/presentation/providers/stats_provider.dart';
import 'package:football_trivia/presentation/screens/settings_screen.dart';
import 'package:provider/provider.dart';

class _FakeStatsRepository implements StatsRepository {
  _FakeStatsRepository(this.stats);

  UserStats stats;
  int saveCount = 0;

  @override
  Future<UserStats> load() async => stats;

  @override
  Future<void> save(UserStats value) async {
    stats = value;
    saveCount++;
  }
}

class _FakeProgressRepository implements ProgressRepository {
  _FakeProgressRepository(this.data);

  Map<String, CategoryProgress> data;
  bool cleared = false;

  @override
  Future<Map<String, CategoryProgress>> loadAll() async => data;

  @override
  Future<void> save(CategoryProgress progress) async {
    data[progress.slug] = progress;
  }

  @override
  Future<void> clear() async {
    data = {};
    cleared = true;
  }
}

class _FakeSettingsRepository implements SettingsRepository {
  AppSettings settings = const AppSettings();

  @override
  Future<AppSettings> load() async => settings;

  @override
  Future<void> save(AppSettings value) async => settings = value;
}

class _FakeScheduler implements ReminderScheduler {
  @override
  Future<void> init() async {}

  @override
  Future<bool> hasPermission() async => true;

  @override
  Future<bool> requestPermission() async => true;

  @override
  Future<void> scheduleDaily({required int hour, required int minute}) async {}

  @override
  Future<void> cancelDaily() async {}
}

class _FakeQuizRepository implements QuizRepository {
  @override
  Future<List<Category>> getCategories() async => const [
        Category(slug: 'alpha', name: 'ألفا', idBlock: 1000, order: 1),
      ];

  @override
  Future<List<Question>> getLevelQuestions({
    required String categorySlug,
    required int level,
  }) async =>
      const [];

  @override
  Future<int> getLevelCount(String categorySlug) async => 10;

  @override
  Future<List<Question>> getRandomQuestions({
    required int count,
    String? categorySlug,
  }) async =>
      const [];

  @override
  Future<List<Question>> getDailyQuestions({
    required String dayKey,
    required int count,
  }) async =>
      const [];
}

Future<void> _pumpSettings(
  WidgetTester tester, {
  required _FakeStatsRepository statsRepo,
  required _FakeProgressRepository progressRepo,
}) async {
  final stats = StatsProvider(repository: statsRepo);
  final progress = ProgressProvider(repository: progressRepo);
  final quiz = QuizProvider(repository: _FakeQuizRepository());
  final settings = SettingsProvider(
    repository: _FakeSettingsRepository(),
    scheduler: _FakeScheduler(),
  );

  await stats.init();
  await progress.init();
  await quiz.loadCategories();
  await settings.init();

  await tester.pumpWidget(
    MultiProvider(
      providers: [
        ChangeNotifierProvider.value(value: stats),
        ChangeNotifierProvider.value(value: progress),
        ChangeNotifierProvider.value(value: quiz),
        ChangeNotifierProvider.value(value: settings),
      ],
      child: const MaterialApp(
        locale: Locale('ar'),
        home: Directionality(
          textDirection: TextDirection.rtl,
          child: SettingsScreen(),
        ),
      ),
    ),
  );
  await tester.pumpAndSettle();
}

/// أزرار التصفير أسفل الشاشة، وListView لا يبني ما هو خارج المنطقة المرئية.
Future<void> _scrollToBottom(WidgetTester tester) async {
  await tester.drag(find.byType(ListView), const Offset(0, -600));
  await tester.pumpAndSettle();
}

Future<void> _scrollToTop(WidgetTester tester) async {
  await tester.drag(find.byType(ListView), const Offset(0, 600));
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('تعرض الإحصائيات المحفوظة', (tester) async {
    final statsRepo = _FakeStatsRepository(
      const UserStats(
        currentStreak: 4,
        bestStreak: 9,
        bestScore: 1450,
        totalScore: 18430,
        gamesPlayed: 23,
        lastDailyDayKey: '2026-08-04',
      ),
    );
    final progressRepo = _FakeProgressRepository({
      'alpha': const CategoryProgress(
        slug: 'alpha',
        stars: [3, 3, 2, 0, 0, 0, 0, 0, 0, 0],
      ),
    });

    await _pumpSettings(
      tester,
      statsRepo: statsRepo,
      progressRepo: progressRepo,
    );

    expect(find.text('18430'), findsOneWidget); // مجموع النقاط
    expect(find.text('23'), findsOneWidget); // عدد الجولات
    expect(find.text('1450'), findsOneWidget); // أفضل نتيجة
    expect(find.text('3 / 10'), findsOneWidget); // مستويات مكتملة
    expect(find.text('8 / 30'), findsOneWidget); // مجموع النجوم
  });

  testWidgets('أزرار التصفير معطّلة حين لا يوجد ما يُصفَّر', (tester) async {
    await _pumpSettings(
      tester,
      statsRepo: _FakeStatsRepository(const UserStats()),
      progressRepo: _FakeProgressRepository({}),
    );
    await _scrollToBottom(tester);
    await _scrollToBottom(tester);

    // نستهدف زرّي التصفير بنصّهما لا بعدّ كل أزرار الشاشة، حتى لا يكسر
    // الاختبارَ أي زر جديد يُضاف لاحقاً.
    for (final label in [AppStrings.resetStats, AppStrings.resetProgress]) {
      final button = tester.widget<OutlinedButton>(
        find.ancestor(
          of: find.text(label),
          matching: find.byType(OutlinedButton),
        ),
      );
      expect(button.onPressed, isNull, reason: 'الزر "$label" يجب أن يكون معطّلاً');
    }
  });

  testWidgets('إلغاء الحوار لا يصفّر التقدّم', (tester) async {
    final progressRepo = _FakeProgressRepository({
      'alpha': const CategoryProgress(
        slug: 'alpha',
        stars: [3, 3, 3, 0, 0, 0, 0, 0, 0, 0],
      ),
    });

    await _pumpSettings(
      tester,
      statsRepo: _FakeStatsRepository(const UserStats(gamesPlayed: 5)),
      progressRepo: progressRepo,
    );

    await _scrollToBottom(tester);
    await tester.tap(find.text(AppStrings.resetProgress));
    await tester.pumpAndSettle();

    await tester.tap(find.text(AppStrings.cancel));
    await tester.pumpAndSettle();

    expect(progressRepo.cleared, isFalse);

    await _scrollToTop(tester);
    expect(find.text('9 / 30'), findsOneWidget);
  });

  testWidgets('التأكيد يصفّر التقدّم ويحدّث الشاشة', (tester) async {
    final progressRepo = _FakeProgressRepository({
      'alpha': const CategoryProgress(
        slug: 'alpha',
        stars: [3, 3, 3, 0, 0, 0, 0, 0, 0, 0],
      ),
    });

    await _pumpSettings(
      tester,
      statsRepo: _FakeStatsRepository(const UserStats(gamesPlayed: 5)),
      progressRepo: progressRepo,
    );

    expect(find.text('9 / 30'), findsOneWidget);

    await _scrollToBottom(tester);
    await tester.tap(find.text(AppStrings.resetProgress));
    await tester.pumpAndSettle();

    // الحوار يذكر الخسارة بالأرقام قبل التأكيد.
    expect(find.textContaining('9 نجمة'), findsOneWidget);

    await tester.tap(find.text(AppStrings.confirmReset));
    await tester.pumpAndSettle();

    expect(progressRepo.cleared, isTrue);

    await _scrollToTop(tester);
    expect(find.text('0 / 30'), findsOneWidget);
  });

  testWidgets('تصفير الإحصائيات يحفظ حالة فارغة', (tester) async {
    final statsRepo = _FakeStatsRepository(
      const UserStats(currentStreak: 4, gamesPlayed: 23, bestScore: 1450),
    );

    await _pumpSettings(
      tester,
      statsRepo: statsRepo,
      progressRepo: _FakeProgressRepository({}),
    );

    await _scrollToBottom(tester);
    await tester.tap(find.text(AppStrings.resetStats));
    await tester.pumpAndSettle();
    await tester.tap(find.text(AppStrings.confirmReset));
    await tester.pumpAndSettle();

    expect(statsRepo.saveCount, 1);
    expect(statsRepo.stats.gamesPlayed, 0);
    expect(statsRepo.stats.bestScore, 0);
    expect(statsRepo.stats.currentStreak, 0);
  });
}
