import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:football_trivia/core/constants/app_config.dart';
import 'package:football_trivia/core/constants/app_strings.dart';
import 'package:football_trivia/domain/entities/category.dart';
import 'package:football_trivia/domain/entities/category_progress.dart';
import 'package:football_trivia/domain/entities/economy.dart';
import 'package:football_trivia/domain/usecases/evaluate_level.dart';
import 'package:football_trivia/presentation/providers/ads_provider.dart';
import 'package:football_trivia/presentation/providers/economy_provider.dart';
import 'package:football_trivia/presentation/providers/progress_provider.dart';
import 'package:football_trivia/presentation/providers/quiz_provider.dart';
import 'package:football_trivia/presentation/screens/levels_screen.dart';
import 'package:football_trivia/presentation/widgets/koora_buttons.dart';
import 'package:football_trivia/presentation/widgets/level_tile.dart';
import 'package:provider/provider.dart';

import 'fakes/fake_ad_service.dart';
import 'fakes/fake_repositories.dart';

const _category = Category(slug: 'alpha', name: 'ألفا', idBlock: 1000, order: 1);

Future<void> _pumpLevels(
  WidgetTester tester, {
  List<int> stars = const [],
  Size size = const Size(800, 1400),
}) async {
  tester.view.physicalSize = size;
  tester.view.devicePixelRatio = 1;
  // شريط الحالة يقتطع من الطول كما على الجهاز.
  tester.view.padding = const FakeViewPadding(top: 24);
  addTearDown(tester.view.reset);

  final progress = ProgressProvider(
    repository: FakeProgressRepository({
      if (stars.isNotEmpty)
        'alpha': CategoryProgress(
          slug: 'alpha',
          stars: [
            ...stars,
            ...List.filled(AppConfig.levelsPerCategory - stars.length, 0),
          ],
        ),
    }),
  );
  final economy = EconomyProvider(
    repository: FakeEconomyRepository(
      Economy(lastRegenAtIso: DateTime.now().toIso8601String()),
    ),
  );
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
      child: const MaterialApp(
        home: Directionality(
          textDirection: TextDirection.rtl,
          child: LevelsScreen(category: _category),
        ),
      ),
    ),
  );
  await tester.pumpAndSettle();
}

Finder _tile(int level) =>
    find.byWidgetPredicate((w) => w is LevelTile && w.level == level);

LevelTile _tileWidget(WidgetTester tester, int level) =>
    tester.widget<LevelTile>(_tile(level));

void main() {
  testWidgets('المجتاز مكتمل والتالي متاح والباقي مقفل، والمتاح محدّد تلقائياً',
      (tester) async {
    await _pumpLevels(tester, stars: [3, 1]);

    expect(_tileWidget(tester, 1).state, LevelState.completed);
    expect(_tileWidget(tester, 2).state, LevelState.completed);
    expect(_tileWidget(tester, 3).state, LevelState.available);
    for (var level = 4; level <= AppConfig.levelsPerCategory; level++) {
      expect(
        _tileWidget(tester, level).state,
        LevelState.locked,
        reason: 'المستوى $level',
      );
    }
    expect(_tileWidget(tester, 3).isSelected, isTrue);
  });

  testWidgets('بلا تقدّم: الأول وحده متاح ومحدّد', (tester) async {
    await _pumpLevels(tester);

    expect(_tileWidget(tester, 1).state, LevelState.available);
    expect(_tileWidget(tester, 1).isSelected, isTrue);
    expect(_tileWidget(tester, 2).state, LevelState.locked);
  });

  testWidgets('لمس مستوى مقفل يشرح السبب ولا يغيّر الاختيار، والمتاح يُختار',
      (tester) async {
    await _pumpLevels(tester, stars: [3, 1]);

    await tester.tap(_tile(5));
    await tester.pumpAndSettle();
    expect(find.text(AppStrings.lockedLevel), findsOneWidget);
    expect(_tileWidget(tester, 3).isSelected, isTrue);
    expect(_tileWidget(tester, 5).isSelected, isFalse);

    await tester.tap(_tile(1));
    await tester.pumpAndSettle();
    expect(_tileWidget(tester, 1).isSelected, isTrue);
    expect(_tileWidget(tester, 3).isSelected, isFalse);
  });

  testWidgets('الشريط السفلي يعرض عتبات الاجتياز والنجوم وكلفة المحاولة',
      (tester) async {
    await _pumpLevels(tester);

    const evaluate = EvaluateLevel();
    const total = AppConfig.questionsPerLevel;
    expect(
      find.text(AppStrings.levelGoal(
        pass: evaluate.minCorrectFor(1, total: total),
        twoStars: evaluate.minCorrectFor(2, total: total),
        threeStars: evaluate.minCorrectFor(3, total: total),
        total: total,
      )),
      findsOneWidget,
    );
    expect(find.text(AppStrings.levelHeartCost), findsOneWidget);
  });

  for (final size in const [Size(360, 640), Size(411, 731)]) {
    testWidgets(
        'على ${size.width.toInt()}×${size.height.toInt()} يظهر المستوى الأخير '
        'كاملاً فوق الشريط السفلي', (tester) async {
      await _pumpLevels(tester, size: size);

      final lastTile = tester.getRect(_tile(AppConfig.levelsPerCategory));
      final grid = tester.getRect(find.byType(GridView));
      final startButton = tester.getRect(
        find.ancestor(
          of: find.text(AppStrings.startLevel),
          matching: find.byType(GoldButton),
        ),
      );

      // داخل منطقة الشبكة المرئية لا مقصوصاً أسفلها.
      expect(lastTile.bottom, lessThanOrEqualTo(grid.bottom + 0.01));
      expect(grid.bottom, lessThanOrEqualTo(startButton.top));
      expect(startButton.bottom, lessThanOrEqualTo(size.height));
    });
  }
}
