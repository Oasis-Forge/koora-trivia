import 'dart:async';

import 'package:football_trivia/domain/entities/app_settings.dart';
import 'package:football_trivia/domain/entities/app_update_status.dart';
import 'package:football_trivia/domain/repositories/app_updater.dart';
import 'package:football_trivia/domain/entities/category.dart';
import 'package:football_trivia/domain/entities/category_progress.dart';
import 'package:football_trivia/domain/entities/economy.dart';
import 'package:football_trivia/domain/entities/error_entry.dart';
import 'package:football_trivia/domain/entities/question.dart';
import 'package:football_trivia/domain/entities/reminder_plan.dart';
import 'package:football_trivia/domain/entities/user_stats.dart';
import 'package:football_trivia/domain/repositories/app_info.dart';
import 'package:football_trivia/domain/repositories/economy_repository.dart';
import 'package:football_trivia/domain/repositories/error_log.dart';
import 'package:football_trivia/domain/repositories/link_opener.dart';
import 'package:football_trivia/domain/repositories/progress_repository.dart';
import 'package:football_trivia/domain/repositories/quiz_repository.dart';
import 'package:football_trivia/domain/repositories/reminder_scheduler.dart';
import 'package:football_trivia/domain/repositories/review_prompter.dart';
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
    Set<int> avoid = const {},
    bool Function(Question question)? prefer,
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

class FakeAppInfo implements AppInfo {
  FakeAppInfo([this.value = '1.0.4 (5)']);
  final String value;

  @override
  Future<String> version() async => value;
}

class FakeErrorLog implements ErrorLog {
  FakeErrorLog([List<ErrorEntry>? entries]) : entries = entries ?? [];

  /// الأحدث أولاً، كالسجل الحقيقي.
  final List<ErrorEntry> entries;

  @override
  Future<void> record(Object error, StackTrace? stack) async =>
      entries.insert(0, ErrorEntry(at: DateTime.now(), message: '$error'));

  @override
  Future<List<ErrorEntry>> recent() async => List.of(entries);
}

class FakeReviewPrompter implements ReviewPrompter {
  FakeReviewPrompter({this.last, this.lastAskedGate, this.askGate});

  DateTime? last;
  int asks = 0;

  /// إن وُجدا: لا تكتمل قراءة آخر طلب أو نافذة التقييم حتى يُكملهما الاختبار.
  final Completer<void>? lastAskedGate;
  final Completer<void>? askGate;

  @override
  Future<DateTime?> lastAskedAt() async {
    await lastAskedGate?.future;
    return last;
  }

  @override
  Future<void> ask() async {
    asks++;
    last = DateTime.now();
    await askGate?.future;
  }
}

class FakeLinkOpener implements LinkOpener {
  FakeLinkOpener({this.result = true, this.gate});

  final bool result;
  final opened = <Uri>[];

  /// إن وُجد: لا يكتمل الفتح حتى يُكمله الاختبار.
  final Completer<bool>? gate;

  @override
  Future<bool> open(Uri uri) async {
    opened.add(uri);
    final pending = gate;
    if (pending != null) return pending.future;
    return result;
  }
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

/// تحديث Play مزيّف: حالة يضبطها الاختبار، ويسجّل ما طُلب منه.
class FakeAppUpdater implements AppUpdater {
  FakeAppUpdater({this.status = AppUpdateStatus.none, this.downloadCompletes = true});

  AppUpdateStatus status;
  bool downloadCompletes;
  DateTime? lastAsked;
  int checks = 0;
  int immediateCalls = 0;
  int flexibleCalls = 0;
  int completeCalls = 0;

  @override
  Future<AppUpdateStatus> check() async {
    checks++;
    return status;
  }

  @override
  Future<void> updateImmediately() async {
    immediateCalls++;
  }

  @override
  Future<bool> startFlexibleUpdate() async {
    flexibleCalls++;
    return downloadCompletes;
  }

  @override
  Future<void> completeFlexibleUpdate() async {
    completeCalls++;
  }

  @override
  Future<DateTime?> lastFlexibleAskAt() async => lastAsked;

  @override
  Future<void> recordFlexibleAsk() async {
    lastAsked = DateTime.now();
  }
}
