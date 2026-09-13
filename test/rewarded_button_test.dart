import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:football_trivia/core/constants/app_strings.dart';
import 'package:football_trivia/domain/repositories/ad_service.dart';
import 'package:football_trivia/presentation/providers/ads_provider.dart';
import 'package:football_trivia/presentation/widgets/rewarded_button.dart';
import 'package:provider/provider.dart';

import 'fakes/fake_ad_service.dart';

const _label = 'شاهد إعلاناً';

Future<void> _pump(
  WidgetTester tester,
  AdsProvider ads, {
  bool dailyLimitReached = false,
  Future<void> Function()? onEarned,
}) async {
  await tester.pumpWidget(
    ChangeNotifierProvider.value(
      value: ads,
      child: MaterialApp(
        home: Directionality(
          textDirection: TextDirection.rtl,
          child: Scaffold(
            body: RewardedButton(
              label: _label,
              dailyLimitReached: dailyLimitReached,
              onEarned: onEarned ?? () async {},
            ),
          ),
        ),
      ),
    ),
  );
}

VoidCallback? _onPressed(WidgetTester tester) => tester
    .widget<FilledButton>(find.byWidgetPredicate((w) => w is FilledButton))
    .onPressed;

void main() {
  testWidgets('الزر يتفعّل وحده حين يكتمل تحميل الإعلان، ويتعطّل إن ضاع',
      (tester) async {
    final service = FakeAdService(ready: false);
    await _pump(tester, AdsProvider(service: service));

    expect(_onPressed(tester), isNull);
    expect(find.text(AppStrings.adUnavailable), findsOneWidget);

    // اكتمل التحميل دون أي سبب آخر لإعادة البناء — كان الزر يبقى معطّلاً هنا.
    service.setReady(true);
    await tester.pump();

    expect(_onPressed(tester), isNotNull);
    expect(find.text(AppStrings.adUnavailable), findsNothing);

    service.setReady(false);
    await tester.pump();

    expect(_onPressed(tester), isNull);
  });

  testWidgets('بلوغ الحد اليومي يعطّل الزر ولو كان الإعلان جاهزاً',
      (tester) async {
    await _pump(
      tester,
      AdsProvider(service: FakeAdService()),
      dailyLimitReached: true,
    );

    expect(_onPressed(tester), isNull);
    expect(find.text(AppStrings.adDailyLimitReached), findsOneWidget);
  });

  testWidgets('المكافأة تُمنح عند إكمال الإعلان', (tester) async {
    var earned = 0;
    await _pump(
      tester,
      AdsProvider(service: FakeAdService()),
      onEarned: () async => earned++,
    );

    await tester.tap(find.text(_label));
    await tester.pumpAndSettle();

    expect(earned, 1);
    expect(find.text(AppStrings.rewardGranted), findsOneWidget);
  });

  testWidgets('إغلاق الإعلان مبكراً لا يمنح المكافأة', (tester) async {
    var earned = 0;
    await _pump(
      tester,
      AdsProvider(service: FakeAdService(result: RewardResult.dismissed)),
      onEarned: () async => earned++,
    );

    await tester.tap(find.text(_label));
    await tester.pumpAndSettle();

    expect(earned, 0);
    expect(find.text(AppStrings.adDismissed), findsOneWidget);
  });
}
