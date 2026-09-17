import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:football_trivia/presentation/providers/ads_provider.dart';
import 'package:football_trivia/presentation/widgets/banner_slot.dart';
import 'package:provider/provider.dart';

import 'fakes/fake_ad_service.dart';

/// يبني الشريط داخل Scaffold كما تفعل الشاشات تماماً.
Future<void> _pump(WidgetTester tester, AdsProvider ads) async {
  await tester.pumpWidget(
    ChangeNotifierProvider.value(
      value: ads,
      child: const MaterialApp(
        home: Scaffold(
          bottomNavigationBar: BannerSlot(),
          body: SizedBox.expand(),
        ),
      ),
    ),
  );
  await tester.pump();
}

double _height(WidgetTester tester) =>
    tester.getSize(find.byType(BannerSlot)).height;

void main() {
  setUp(() => BannerSlot.testAdBuilder = (_) => const SizedBox.expand());
  tearDown(() => BannerSlot.testAdBuilder = null);

  group('الشريط الإعلاني', () {
    testWidgets('لا يحجز مكاناً قبل الموافقة', (tester) async {
      final ads = AdsProvider(service: FakeAdService(bannersAllowed: false));

      await _pump(tester, ads);

      expect(_height(tester), 0);
    });

    testWidgets('يحجز ارتفاعه كاملاً حالما يُسمح به', (tester) async {
      // الحجز قبل وصول الإعلان لا بعده: الانزياح المتأخر يجعل اللاعب ينقر
      // الإعلان بدل الزر الذي كان تحت إصبعه.
      final ads = AdsProvider(service: FakeAdService(bannersAllowed: true));

      await _pump(tester, ads);

      expect(_height(tester), BannerSlot.totalHeight);
    });

    testWidgets('يختفي فور شراء إزالة الإعلانات', (tester) async {
      final service = FakeAdService(bannersAllowed: true);
      final ads = AdsProvider(service: service);
      await _pump(tester, ads);
      expect(_height(tester), BannerSlot.totalHeight);

      ads.adsRemoved = true;
      await tester.pump();

      expect(_height(tester), 0);
    });
  });
}
