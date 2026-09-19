import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:football_trivia/core/constants/app_strings.dart';
import 'package:football_trivia/domain/entities/app_settings.dart';
import 'package:football_trivia/domain/entities/app_update_status.dart';
import 'package:football_trivia/domain/entities/category.dart' as domain;
import 'package:football_trivia/domain/repositories/app_updater.dart';
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
import 'package:football_trivia/presentation/providers/purchases_provider.dart';
import 'package:football_trivia/presentation/providers/quiz_provider.dart';
import 'package:football_trivia/presentation/providers/settings_provider.dart';
import 'package:football_trivia/presentation/providers/stats_provider.dart';
import 'package:football_trivia/l10n/app_localizations.dart';
import 'package:football_trivia/presentation/widgets/app_language_scope.dart';
import 'package:football_trivia/presentation/widgets/app_lifecycle_hooks.dart';
import 'package:provider/provider.dart';

import 'fakes/fake_ad_service.dart';
import 'fakes/fake_billing_service.dart';
import 'fakes/fake_repositories.dart';

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

/// نص ثابت يُقرأ من `AppStrings`؛ لا يُبنى من جديد إلا بإعادة البناء الشاملة.
class _QuickPlayLabel extends StatelessWidget {
  const _QuickPlayLabel();

  @override
  Widget build(BuildContext context) => Text(AppStrings.quickPlay);
}

/// يعدّ طلبات التصنيفات: تبديل اللغة يعيد تحميلها بأسمائها الجديدة.
class _CountingQuizRepository extends FakeQuizRepository {
  int categoryLoads = 0;

  @override
  Future<List<domain.Category>> getCategories() {
    categoryLoads++;
    return super.getCategories();
  }
}

/// العاشرة صباح اليوم الحقيقي: `StatsProvider` يسجّل تحدي اليوم بالتاريخ الحقيقي.
final _today = DateTime.now();
final _t0 = DateTime(_today.year, _today.month, _today.day, 10);
final _tomorrowAt20 = DateTime(_t0.year, _t0.month, _t0.day + 1, 20);

class _Harness {
  final adService = FakeAdService(ready: false);
  final billing = FakeBillingService();
  late final purchases = PurchasesProvider(
    service: billing,
    grantCoins: (_) async {},
    onAdsRemoved: () {},
  );
  final scheduler = _Scheduler();
  final updater = FakeAppUpdater();
  final quizRepository = _CountingQuizRepository();
  late final QuizProvider quiz = QuizProvider(repository: quizRepository);
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
          ChangeNotifierProvider.value(value: purchases),
          ChangeNotifierProvider.value(value: economy),
          ChangeNotifierProvider<StatsProvider>.value(value: stats),
          ChangeNotifierProvider.value(value: settings),
          ChangeNotifierProvider.value(value: quiz),
          Provider<AppUpdater>.value(value: updater),
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
  testWidgets('العودة إلى التطبيق: الإعلانات والمتجر والقلوب والتنبيه', (tester) async {
    final h = await _pump(tester);
    final schedulesBefore = h.scheduler.scheduled.length;
    expect(h.economy.hearts, 2);

    // غاب اللاعب حتى صباح الغد: تجدّد قلب وتغيّر يوم التنبيه الأول.
    h.economyNow = _t0.add(const Duration(minutes: 31));
    h.settingsNow = _t0.add(const Duration(days: 1));
    _leaveAndReturn(tester);
    await tester.pump();

    expect(h.adService.resumeCalls, 1);
    // منتجات لم تصل عند الإقلاع تُطلب ثانية عند العودة.
    expect(h.billing.refreshCalls, 1);
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

  testWidgets('يُسأل Play عن تحديث عند الإقلاع وعند العودة إلى التطبيق',
      (tester) async {
    final h = await _pump(tester);
    expect(h.updater.checks, 1);

    _leaveAndReturn(tester);
    await tester.pump();
    expect(h.updater.checks, 2);
  });

  testWidgets('تحديث منزَّل يعرض «إعادة التشغيل» ويثبّته عند اللمس',
      (tester) async {
    final h = _Harness();
    await h.init();
    h.updater.status = const AppUpdateStatus(available: true, downloaded: true);

    await tester.pumpWidget(
      h.wrap(
        MaterialApp(
          builder: (context, child) =>
              AppLifecycleHooks(child: child ?? const SizedBox.shrink()),
          home: const Scaffold(),
        ),
      ),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 750));

    expect(find.text(AppStrings.updateDownloaded), findsOneWidget);
    await tester.tap(find.text(AppStrings.updateRestart));
    await tester.pumpAndSettle();
    expect(h.updater.completeCalls, 1);
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

  testWidgets(
      'لغة MaterialApp تُطبَّق على النصوص وتعيد بناء الشاشة وتحميل التصنيفات وجدولة التنبيه',
      (tester) async {
    final h = _Harness();
    await h.init();
    addTearDown(() => AppText.use('ar'));

    // كما في `app.dart`: اللغة تُطبَّق في `builder` تحت `Localizations`.
    Widget app(String language) => h.wrap(
          MaterialApp(
            locale: Locale(language),
            supportedLocales: AppLocalizations.supportedLocales,
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            builder: (context, child) => AppLanguageScope(
              child: AppLifecycleHooks(child: child ?? const SizedBox.shrink()),
            ),
            home: const _QuickPlayLabel(),
          ),
        );

    await tester.pumpWidget(app('ar'));
    await tester.pump();
    expect(find.text('لعب سريع'), findsOneWidget);
    final loadsBefore = h.quizRepository.categoryLoads;
    final schedulesBefore = h.scheduler.scheduled.length;

    // إعادة بناء بلا تغيير لغة: لا تحميل ولا جدولة.
    await tester.pumpWidget(app('ar'));
    await tester.pump();
    expect(h.quizRepository.categoryLoads, loadsBefore);
    expect(h.scheduler.scheduled.length, schedulesBefore);

    await tester.pumpWidget(app('en'));
    await tester.pump();
    await tester.pump();
    // ودجة ثابتة (`const`) تُبنى من جديد بالنص الإنجليزي دون إغلاق الشاشة.
    expect(find.text('Quick play'), findsOneWidget);
    expect(h.quizRepository.categoryLoads, loadsBefore + 1);
    expect(h.scheduler.scheduled.length, schedulesBefore + 1);
  });
}
