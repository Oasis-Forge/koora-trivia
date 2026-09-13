import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:football_trivia/domain/entities/app_settings.dart';
import 'package:football_trivia/domain/entities/economy.dart';
import 'package:football_trivia/domain/entities/quiz_result.dart';
import 'package:football_trivia/domain/entities/reminder_plan.dart';
import 'package:football_trivia/domain/entities/user_stats.dart';
import 'package:football_trivia/domain/repositories/economy_repository.dart';
import 'package:football_trivia/domain/repositories/reminder_scheduler.dart';
import 'package:football_trivia/domain/repositories/settings_repository.dart';
import 'package:football_trivia/domain/repositories/stats_repository.dart';
import 'package:football_trivia/presentation/providers/ads_provider.dart';
import 'package:football_trivia/presentation/providers/economy_provider.dart';
import 'package:football_trivia/presentation/providers/settings_provider.dart';
import 'package:football_trivia/presentation/providers/stats_provider.dart';
import 'package:football_trivia/presentation/widgets/app_lifecycle_hooks.dart';
import 'package:provider/provider.dart';

import 'fakes/fake_ad_service.dart';

class _EconomyRepo implements EconomyRepository {
  _EconomyRepo(this.economy);
  Economy economy;

  @override
  Future<Economy> load() async => economy;

  @override
  Future<void> save(Economy value) async => economy = value;
}

class _StatsRepo implements StatsRepository {
  UserStats stats = const UserStats();

  @override
  Future<UserStats> load() async => stats;

  @override
  Future<void> save(UserStats value) async => stats = value;
}

/// يكشف هل بقي مستمع موصولاً بعد إزالة الغلاف.
class _Stats extends StatsProvider {
  _Stats() : super(repository: _StatsRepo());

  bool get listening => hasListeners;
}

class _SettingsRepo implements SettingsRepository {
  AppSettings settings = const AppSettings(reminderEnabled: true);

  @override
  Future<AppSettings> load() async => settings;

  @override
  Future<void> save(AppSettings value) async => settings = value;
}

class _Scheduler implements ReminderScheduler {
  final scheduled = <List<ReminderPlan>>[];

  @override
  Future<void> init() async {}

  @override
  Future<bool> hasPermission() async => true;

  @override
  Future<bool> requestPermission() async => true;

  @override
  Future<void> schedule(List<ReminderPlan> plans) async => scheduled.add(plans);

  @override
  Future<void> cancelAll() async {}
}

/// العاشرة صباح اليوم الحقيقي: `StatsProvider` يسجّل تحدي اليوم بالتاريخ الحقيقي.
final _today = DateTime.now();
final _t0 = DateTime(_today.year, _today.month, _today.day, 10);
final _tomorrowAt20 = DateTime(_t0.year, _t0.month, _t0.day + 1, 20);

class _Harness {
  final adService = FakeAdService(ready: false);
  final scheduler = _Scheduler();
  DateTime economyNow = _t0;
  DateTime settingsNow = _t0;

  late final AdsProvider ads;
  late final EconomyProvider economy;
  late final _Stats stats;
  late final SettingsProvider settings;

  Future<void> init() async {
    ads = AdsProvider(service: adService);
    economy = EconomyProvider(
      repository: _EconomyRepo(
        Economy(hearts: 2, lastRegenAtIso: _t0.toIso8601String()),
      ),
      clock: () => economyNow,
    );
    stats = _Stats();
    settings = SettingsProvider(
      repository: _SettingsRepo(),
      scheduler: scheduler,
      clock: () => settingsNow,
    );
    await economy.init();
    await stats.init();
    await settings.init();
  }

  Widget wrap(Widget child) => MultiProvider(
        providers: [
          ChangeNotifierProvider.value(value: ads),
          ChangeNotifierProvider.value(value: economy),
          ChangeNotifierProvider<StatsProvider>.value(value: stats),
          ChangeNotifierProvider.value(value: settings),
        ],
        child: child,
      );
}

/// يمرّ بالحالات الوسيطة كما يفعل أندرويد عند مغادرة التطبيق والعودة إليه.
void _leaveAndReturn(WidgetTester tester) {
  for (final state in [
    AppLifecycleState.inactive,
    AppLifecycleState.hidden,
    AppLifecycleState.paused,
    AppLifecycleState.hidden,
    AppLifecycleState.inactive,
    AppLifecycleState.resumed,
  ]) {
    tester.binding.handleAppLifecycleStateChanged(state);
  }
}

Future<_Harness> _pump(WidgetTester tester) async {
  final h = _Harness();
  await h.init();
  await tester.pumpWidget(
    h.wrap(const AppLifecycleHooks(child: SizedBox())),
  );
  await tester.pump();
  return h;
}

QuizResult _dailyResult() => QuizResult(
      answers: const [],
      score: 0,
      isDaily: true,
      playedAt: DateTime.now(),
    );

void main() {
  testWidgets('العودة إلى التطبيق: الإعلانات والقلوب والتنبيه', (tester) async {
    final h = await _pump(tester);
    final schedulesBefore = h.scheduler.scheduled.length;
    expect(h.economy.hearts, 2);

    // غاب اللاعب حتى صباح الغد: تجدّد قلب وتغيّر يوم التنبيه الأول.
    h.economyNow = _t0.add(const Duration(minutes: 31));
    h.settingsNow = _t0.add(const Duration(days: 1));
    _leaveAndReturn(tester);
    await tester.pump();

    expect(h.adService.resumeCalls, 1);
    expect(h.economy.hearts, 3);
    expect(h.scheduler.scheduled.length, schedulesBefore + 1);
    expect(h.scheduler.scheduled.last.first.at, _tomorrowAt20);
  });

  testWidgets('إنجاز تحدي اليوم يعيد جدولة التنبيه فوراً', (tester) async {
    final h = await _pump(tester);

    await h.stats.recordResult(_dailyResult());
    await tester.pump();

    final first = h.scheduler.scheduled.last.first;
    expect(first.at, _tomorrowAt20);
    expect(first.streak, 1);
  });

  testWidgets('بعد إزالة الغلاف لا يبقى مستمع معلّق', (tester) async {
    final h = await _pump(tester);
    await tester.pumpWidget(h.wrap(const SizedBox()));
    final schedulesBefore = h.scheduler.scheduled.length;

    await h.stats.recordResult(_dailyResult());
    _leaveAndReturn(tester);
    await tester.pump();

    expect(h.adService.resumeCalls, 0);
    expect(h.scheduler.scheduled.length, schedulesBefore);

    // مزوّدات .value لا تُتلف الكائن لكنها تفصل اشتراكها عند إزالتها؛ أي
    // مستمع باقٍ بعدها هو مستمع الغلاف.
    await tester.pumpWidget(const SizedBox());
    expect(h.stats.listening, isFalse);
  });
}
