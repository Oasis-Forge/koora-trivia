import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:football_trivia/core/constants/app_strings.dart';
import 'package:football_trivia/domain/entities/category.dart';
import 'package:football_trivia/domain/entities/economy.dart';
import 'package:football_trivia/domain/entities/user_stats.dart';
import 'package:football_trivia/domain/repositories/app_info.dart';
import 'package:football_trivia/domain/repositories/backup_repository.dart';
import 'package:football_trivia/domain/repositories/error_log.dart';
import 'package:football_trivia/domain/repositories/link_opener.dart';
import 'package:football_trivia/presentation/providers/ads_provider.dart';
import 'package:football_trivia/presentation/providers/economy_provider.dart';
import 'package:football_trivia/presentation/providers/progress_provider.dart';
import 'package:football_trivia/presentation/providers/purchases_provider.dart';
import 'package:football_trivia/presentation/providers/quiz_provider.dart';
import 'package:football_trivia/presentation/providers/settings_provider.dart';
import 'package:football_trivia/presentation/providers/stats_provider.dart';
import 'package:football_trivia/presentation/screens/categories_screen.dart';
import 'package:football_trivia/presentation/screens/home_screen.dart';
import 'package:football_trivia/presentation/screens/levels_screen.dart';
import 'package:football_trivia/presentation/screens/quiz_screen.dart';
import 'package:football_trivia/presentation/screens/settings_screen.dart';
import 'package:football_trivia/presentation/screens/shop_screen.dart';
import 'package:football_trivia/presentation/screens/tasks_screen.dart';
import 'package:football_trivia/presentation/widgets/hearts_bar.dart';
import 'package:provider/provider.dart';

import 'fakes/fake_ad_service.dart';
import 'fakes/fake_billing_service.dart';
import 'fakes/fake_repositories.dart';
import 'fakes/score_screen_harness.dart';

/// أضيق مقاسات الهواتف المستهدفة.
const _sizes = [Size(320, 640), Size(360, 640)];

const _category =
    Category(slug: 'alpha', name: 'ألفا', idBlock: 1000, order: 1);

/// لا مستودع مزيّف مشترك للنسخ الاحتياطي؛ هذا أبسط تنفيذ ممكن للواجهة.
class _FakeBackupRepository implements BackupRepository {
  @override
  Future<String> export() async => 'code';

  @override
  Future<bool> import(String code) async => true;
}

/// يضبط مقاساً منطقياً صغيراً كالهاتف الفعلي، ويعيد الضبط بعد الاختبار.
void _setSize(WidgetTester tester, Size size) {
  tester.view.physicalSize = size;
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
}

/// إطار بلغة النصوص الحالية واتجاهها لكل الشاشات؛ أي تجاوز عرض (overflow) يُفشل
/// الاختبار تلقائياً. خط الاختبارات يرسم كل حرف بعرض سطر كامل تقريباً، فما يتسع
/// هنا يتسع على الهاتف الحقيقي.
Widget _app(Widget home) => MaterialApp(
      locale: Locale(AppStrings.languageCode),
      supportedLocales: [Locale(AppStrings.languageCode)],
      localizationsDelegates: GlobalMaterialLocalizations.delegates,
      home: home,
    );

Economy _freshEconomy({int hearts = 5, int coins = 0}) => Economy(
      hearts: hearts,
      coins: coins,
      lastRegenAtIso: DateTime.now().toIso8601String(),
    );

void main() {
  for (final language in const ['ar', 'en']) {
    group(language, () {
      setUp(() => AppText.use(language));
      tearDown(() => AppText.use('ar'));
      _screens();
    });
  }
}

/// كل شاشة بأضيق مقاسين، بالعربية ثم بالإنجليزية.
void _screens() {

  group('HomeScreen', () {
    for (final size in _sizes) {
      testWidgets('${size.width.toInt()}x${size.height.toInt()}',
          (tester) async {
        _setSize(tester, size);
        final quiz = QuizProvider(repository: FakeQuizRepository());
        final stats =
            StatsProvider(repository: FakeStatsRepository(const UserStats()));
        final economy =
            EconomyProvider(repository: FakeEconomyRepository(_freshEconomy()));
        await stats.init();
        await economy.init();

        await tester.pumpWidget(
          MultiProvider(
            providers: [
              ChangeNotifierProvider.value(value: quiz),
              ChangeNotifierProvider.value(value: stats),
              ChangeNotifierProvider.value(value: economy),
              ChangeNotifierProvider(
                create: (_) => AdsProvider(service: FakeAdService()),
              ),
            ],
            child: _app(const HomeScreen()),
          ),
        );
        // عدّاد تحدي الغد Timer.periodic لا ينتهي، فنستخدم pump بمدة محدودة
        // بدل pumpAndSettle حتى لا يعلّق الاختبار.
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 300));

        await tester.pumpWidget(const SizedBox());
      });
    }
  });

  group('CategoriesScreen', () {
    for (final size in _sizes) {
      testWidgets('${size.width.toInt()}x${size.height.toInt()}',
          (tester) async {
        _setSize(tester, size);
        final quiz = QuizProvider(repository: FakeQuizRepository());
        final progress = ProgressProvider(repository: FakeProgressRepository());
        await progress.init();

        await tester.pumpWidget(
          MultiProvider(
            providers: [
              ChangeNotifierProvider.value(value: quiz),
              ChangeNotifierProvider.value(value: progress),
              ChangeNotifierProvider(
                create: (_) => AdsProvider(service: FakeAdService()),
              ),
            ],
            child: _app(const CategoriesScreen()),
          ),
        );
        await tester.pumpAndSettle();
      });
    }
  });

  group('LevelsScreen', () {
    for (final size in _sizes) {
      testWidgets('${size.width.toInt()}x${size.height.toInt()}',
          (tester) async {
        _setSize(tester, size);
        final progress = ProgressProvider(repository: FakeProgressRepository());
        final economy =
            EconomyProvider(repository: FakeEconomyRepository(_freshEconomy()));
        await progress.init();
        await economy.init();

        await tester.pumpWidget(
          MultiProvider(
            providers: [
              ChangeNotifierProvider.value(value: progress),
              ChangeNotifierProvider.value(value: economy),
              ChangeNotifierProvider(
                create: (_) => QuizProvider(repository: FakeQuizRepository()),
              ),
              ChangeNotifierProvider(
                create: (_) => AdsProvider(service: FakeAdService()),
              ),
            ],
            child: _app(
              const LevelsScreen(category: _category),
            ),
          ),
        );
        await tester.pumpAndSettle();
      });
    }
  });

  group('QuizScreen', () {
    for (final size in _sizes) {
      testWidgets('${size.width.toInt()}x${size.height.toInt()}',
          (tester) async {
        _setSize(tester, size);
        final quiz = QuizProvider(repository: FakeQuizRepository());
        final economy =
            EconomyProvider(repository: FakeEconomyRepository(_freshEconomy()));
        final settings = SettingsProvider(
          repository: FakeSettingsRepository(),
          scheduler: FakeScheduler(),
        );
        await economy.init();
        await settings.init();
        // لعب سريع لا يخصم قلوباً ولا يحتاج تصنيفاً، ويُهجَر في النهاية فلا
        // يبقى مؤقّته يعمل بعد الاختبار.
        await quiz.startQuickPlay();

        await tester.pumpWidget(
          MultiProvider(
            providers: [
              ChangeNotifierProvider.value(value: quiz),
              ChangeNotifierProvider.value(value: economy),
              ChangeNotifierProvider.value(value: settings),
              ChangeNotifierProvider(
                create: (_) => AdsProvider(service: FakeAdService()),
              ),
            ],
            child: _app(const QuizScreen()),
          ),
        );
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 300));

        quiz.abandon();
        await tester.pumpWidget(const SizedBox());
        quiz.dispose();
      });
    }
  });

  group('SettingsScreen', () {
    for (final size in _sizes) {
      testWidgets('${size.width.toInt()}x${size.height.toInt()}, scrolled to bottom',
          (tester) async {
        _setSize(tester, size);
        final stats = StatsProvider(
          repository: FakeStatsRepository(
            const UserStats(
              currentStreak: 4,
              bestStreak: 9,
              bestScore: 1450,
              totalScore: 18430,
              gamesPlayed: 23,
            ),
          ),
        );
        final progress = ProgressProvider(repository: FakeProgressRepository());
        final quiz = QuizProvider(repository: FakeQuizRepository());
        final settings = SettingsProvider(
          repository: FakeSettingsRepository(),
          scheduler: FakeScheduler(),
        );
        final economy =
            EconomyProvider(repository: FakeEconomyRepository(_freshEconomy()));
        await stats.init();
        await progress.init();
        await quiz.loadCategories();
        await settings.init();
        await economy.init();

        await tester.pumpWidget(
          MultiProvider(
            providers: [
              ChangeNotifierProvider.value(value: stats),
              ChangeNotifierProvider.value(value: progress),
              ChangeNotifierProvider.value(value: quiz),
              ChangeNotifierProvider.value(value: settings),
              ChangeNotifierProvider(
                create: (_) => AdsProvider(service: FakeAdService()),
              ),
              Provider<BackupRepository>.value(value: _FakeBackupRepository()),
              Provider<AppInfo>.value(value: FakeAppInfo()),
              Provider<LinkOpener>.value(value: FakeLinkOpener()),
              Provider<ErrorLog>.value(value: FakeErrorLog()),
            ],
            child: _app(const SettingsScreen()),
          ),
        );
        await tester.pumpAndSettle();

        // الأقسام أسفل الشاشة: التصفير والحذف؛ اللائحة لا تبني ما هو خارج
        // المنطقة المرئية فلا بد من التمرير لفحصه.
        await tester.fling(find.byType(ListView), const Offset(0, -3000), 3000);
        await tester.pumpAndSettle();
      });
    }
  });

  group('ShopScreen', () {
    for (final size in _sizes) {
      testWidgets('${size.width.toInt()}x${size.height.toInt()}',
          (tester) async {
        _setSize(tester, size);
        final economy = EconomyProvider(
          repository: FakeEconomyRepository(_freshEconomy(hearts: 2, coins: 500)),
        );
        await economy.init();

        await tester.pumpWidget(
          MultiProvider(
            providers: [
              ChangeNotifierProvider.value(value: economy),
              ChangeNotifierProvider(
                create: (_) => AdsProvider(service: FakeAdService()),
              ),
              ChangeNotifierProvider(
                create: (_) => PurchasesProvider(
                  service: FakeBillingService(available: true),
                  grantCoins: (_) async {},
                  onAdsRemoved: () {},
                )..init(),
              ),
            ],
            child: _app(const ShopScreen()),
          ),
        );
        await tester.pumpAndSettle();
      });
    }
  });

  group('TasksScreen', () {
    for (final size in _sizes) {
      testWidgets('${size.width.toInt()}x${size.height.toInt()}',
          (tester) async {
        _setSize(tester, size);
        final economy =
            EconomyProvider(repository: FakeEconomyRepository(_freshEconomy()));
        await economy.init();

        await tester.pumpWidget(
          MultiProvider(
            providers: [
              ChangeNotifierProvider.value(value: economy),
              ChangeNotifierProvider(
                create: (_) => AdsProvider(service: FakeAdService()),
              ),
            ],
            child: _app(const TasksScreen()),
          ),
        );
        await tester.pumpAndSettle();
      });
    }
  });

  group('ScoreScreen', () {
    for (final size in _sizes) {
      testWidgets('${size.width.toInt()}x${size.height.toInt()}',
          (tester) async {
        _setSize(tester, size);
        final quiz = await pumpScoreScreen(tester, correct: 7);

        await tester.pumpWidget(const SizedBox());
        quiz.dispose();
      });
    }
  });

  group('NoHeartsDialog', () {
    for (final size in _sizes) {
      testWidgets('${size.width.toInt()}x${size.height.toInt()}',
          (tester) async {
        _setSize(tester, size);
        final quiz = QuizProvider(repository: FakeQuizRepository());
        final stats =
            StatsProvider(repository: FakeStatsRepository(const UserStats()));
        final economy = EconomyProvider(
          repository: FakeEconomyRepository(_freshEconomy(hearts: 0)),
        );
        await stats.init();
        await economy.init();

        await tester.pumpWidget(
          MultiProvider(
            providers: [
              ChangeNotifierProvider.value(value: quiz),
              ChangeNotifierProvider.value(value: stats),
              ChangeNotifierProvider.value(value: economy),
              ChangeNotifierProvider(
                create: (_) => AdsProvider(service: FakeAdService(ready: false)),
              ),
            ],
            child: _app(
              Scaffold(
                body: Builder(
                  builder: (context) => TextButton(
                    onPressed: () => NoHeartsDialog.show(context),
                    child: const Text('open'),
                  ),
                ),
              ),
            ),
          ),
        );
        await tester.tap(find.text('open'));
        await tester.pumpAndSettle();
      });
    }
  });
}
