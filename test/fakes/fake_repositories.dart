import 'package:football_trivia/domain/entities/app_settings.dart';
import 'package:football_trivia/domain/entities/category.dart';
import 'package:football_trivia/domain/entities/category_progress.dart';
import 'package:football_trivia/domain/entities/economy.dart';
import 'package:football_trivia/domain/entities/question.dart';
import 'package:football_trivia/domain/entities/reminder_plan.dart';
import 'package:football_trivia/domain/entities/user_stats.dart';
import 'package:football_trivia/domain/repositories/economy_repository.dart';
import 'package:football_trivia/domain/repositories/progress_repository.dart';
import 'package:football_trivia/domain/repositories/quiz_repository.dart';
import 'package:football_trivia/domain/repositories/reminder_scheduler.dart';
import 'package:football_trivia/domain/repositories/settings_repository.dart';
import 'package:football_trivia/domain/repositories/stats_repository.dart';

/// مستودعات مزيّفة في الذاكرة، مشتركة بين اختبارات الشاشات.

/// أسئلة مزيّفة من تصنيف واحد، الإجابة الصحيحة دائماً الخيار الأول.
List<Question> fakeQuestions(int count) => [
      for (var i = 1; i <= count; i++)
        Question(
          id: 1000 + i,
          category: 'alpha',
          categoryName: 'ألفا',
          level: 1,
          text: 'سؤال $i',
          options: const ['أ', 'ب', 'ج', 'د'],
          answerIndex: 0,
        ),
    ];

class FakeQuizRepository implements QuizRepository {
  @override
  Future<List<Category>> getCategories() async => const [
        Category(slug: 'alpha', name: 'ألفا', idBlock: 1000, order: 1),
      ];

  @override
  Future<List<Question>> getLevelQuestions({
    required String categorySlug,
    required int level,
  }) async =>
      fakeQuestions(10);

  @override
  Future<int> getLevelCount(String categorySlug) async => 10;

  @override
  Future<List<Question>> getRandomQuestions({
    required int count,
    String? categorySlug,
  }) async =>
      fakeQuestions(count);

  @override
  Future<List<Question>> getDailyQuestions({
    required String dayKey,
    required int count,
  }) async =>
      fakeQuestions(count);
}

class FakeEconomyRepository implements EconomyRepository {
  FakeEconomyRepository([this.economy = const Economy()]);
  Economy economy;

  @override
  Future<Economy> load() async => economy;

  @override
  Future<void> save(Economy value) async => economy = value;
}

class FakeStatsRepository implements StatsRepository {
  FakeStatsRepository([this.stats = const UserStats()]);
  UserStats stats;

  @override
  Future<UserStats> load() async => stats;

  @override
  Future<void> save(UserStats value) async => stats = value;
}

class FakeProgressRepository implements ProgressRepository {
  FakeProgressRepository([Map<String, CategoryProgress>? data])
      : data = data ?? {};

  Map<String, CategoryProgress> data;

  @override
  Future<Map<String, CategoryProgress>> loadAll() async => data;

  @override
  Future<void> save(CategoryProgress progress) async =>
      data[progress.slug] = progress;

  @override
  Future<void> clear() async => data = {};
}

class FakeSettingsRepository implements SettingsRepository {
  FakeSettingsRepository([this.settings = const AppSettings()]);
  AppSettings settings;

  @override
  Future<AppSettings> load() async => settings;

  @override
  Future<void> save(AppSettings value) async => settings = value;
}

class FakeScheduler implements ReminderScheduler {
  @override
  Future<void> init() async {}

  @override
  Future<bool> hasPermission() async => true;

  @override
  Future<bool> requestPermission() async => true;

  @override
  Future<void> schedule(List<ReminderPlan> plans) async {}

  @override
  Future<void> cancelAll() async {}
}
