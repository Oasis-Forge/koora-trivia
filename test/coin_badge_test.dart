import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:football_trivia/domain/entities/economy.dart';
import 'package:football_trivia/presentation/providers/economy_provider.dart';
import 'package:football_trivia/presentation/screens/shop_screen.dart';
import 'package:football_trivia/presentation/widgets/coin_badge.dart';
import 'package:provider/provider.dart';

import 'fakes/fake_repositories.dart';

Future<void> _pump(WidgetTester tester, CoinBadge badge) async {
  final economy = EconomyProvider(
    repository: FakeEconomyRepository(
      Economy(coins: 120, lastRegenAtIso: DateTime.now().toIso8601String()),
    ),
  );
  await economy.init();

  await tester.pumpWidget(
    ChangeNotifierProvider.value(
      value: economy,
      child: MaterialApp(
        routes: {ShopScreen.routeName: (_) => const Text('shop')},
        home: Scaffold(body: Center(child: badge)),
      ),
    ),
  );
}

void main() {
  group('شارة العملات', () {
    testWidgets('تفتح المتجر من أي شاشة، بعلامة «+»', (tester) async {
      // كانت تبدو زراً ولا تعمل إلا في الرئيسية (شاشة المهام مثلاً).
      await _pump(tester, const CoinBadge());

      expect(find.text('120'), findsOneWidget);
      expect(find.byIcon(Icons.add_circle_rounded), findsOneWidget);

      await tester.tap(find.byType(CoinBadge));
      await tester.pumpAndSettle();

      expect(find.text('shop'), findsOneWidget);
    });

    testWidgets('داخل المتجر رصيد فقط', (tester) async {
      await _pump(tester, const CoinBadge(opensShop: false));

      expect(find.byIcon(Icons.add_circle_rounded), findsNothing);

      await tester.tap(find.byType(CoinBadge));
      await tester.pumpAndSettle();

      expect(find.text('shop'), findsNothing);
    });
  });
}
