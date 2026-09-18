import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:football_trivia/core/constants/app_strings.dart';
import 'package:football_trivia/presentation/providers/ads_provider.dart';
import 'package:football_trivia/presentation/providers/purchases_provider.dart';
import 'package:football_trivia/presentation/screens/shop_screen.dart';
import 'package:football_trivia/presentation/widgets/banner_slot.dart';
import 'package:provider/provider.dart';

import 'fakes/fake_ad_service.dart';
import 'fakes/fake_billing_service.dart';

/// يبني الشريط داخل Scaffold كما تفعل الشاشات تماماً.
Future<void> _pump(
  WidgetTester tester,
  AdsProvider ads, {
  bool storeAvailable = false,
  BannerSlot slot = const BannerSlot(),
}) async {
  final purchases = PurchasesProvider(
    service: FakeBillingService(available: storeAvailable),
    grantCoins: (_) async {},
    onAdsRemoved: () {},
  );
  await tester.pumpWidget(
    MultiProvider(
      providers: [
        ChangeNotifierProvider.value(value: ads),
        ChangeNotifierProvider.value(value: purchases),
      ],
      child: MaterialApp(
        routes: {ShopScreen.routeName: (_) => const Text('shop')},
        home: Scaffold(
          bottomNavigationBar: slot,
          body: const SizedBox.expand(),
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
  tearDown(() {
    BannerSlot.testAdBuilder = null;
    BannerSlot.testAdHeight = null;
  });

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

    testWidgets('يأخذ ارتفاع المقاس المتكيّف حين يُعرف', (tester) async {
      BannerSlot.testAdHeight = 64;
      final ads = AdsProvider(service: FakeAdService(bannersAllowed: true));

      await _pump(tester, ads);

      expect(_height(tester), 64 + BannerSlot.gap);
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

  group('رابط «إزالة الإعلانات»', () {
    testWidgets('يظهر فوق الشريط ويفتح المتجر', (tester) async {
      final ads = AdsProvider(service: FakeAdService(bannersAllowed: true));
      await _pump(tester, ads, storeAvailable: true);

      expect(find.text(AppStrings.removeAds), findsOneWidget);
      expect(
        _height(tester),
        BannerSlot.linkHeight + BannerSlot.totalHeight,
      );

      await tester.tap(find.text(AppStrings.removeAds));
      await tester.pumpAndSettle();

      expect(find.text('shop'), findsOneWidget);
    });

    testWidgets('لا يظهر قبل أن يمكن الشراء', (tester) async {
      // بلا منتجات من المتجر يقود الرابط إلى «قريباً» فقط.
      final ads = AdsProvider(service: FakeAdService(bannersAllowed: true));
      await _pump(tester, ads, storeAvailable: false);

      expect(find.text(AppStrings.removeAds), findsNothing);
      expect(_height(tester), BannerSlot.totalHeight);
    });

    testWidgets('لا يظهر حيث يُطفأ (شاشة السؤال والمتجر)', (tester) async {
      final ads = AdsProvider(service: FakeAdService(bannersAllowed: true));
      await _pump(
        tester,
        ads,
        storeAvailable: true,
        slot: const BannerSlot(removeAdsLink: false),
      );

      expect(find.text(AppStrings.removeAds), findsNothing);
    });

    testWidgets('يلتزم بحدّ الارتفاع فيعود إلى المقاس الثابت', (tester) async {
      // شاشة 600 بحدّ 10% = 60: شريط 90 يتجاوزه فيصبح 50.
      tester.view.physicalSize = const Size(360, 600);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);
      BannerSlot.testAdHeight = 90;
      final ads = AdsProvider(service: FakeAdService(bannersAllowed: true));

      await _pump(
        tester,
        ads,
        slot: const BannerSlot(removeAdsLink: false, maxHeightFraction: 0.1),
      );

      expect(_height(tester), BannerSlot.adHeight + BannerSlot.gap);
    });
  });
}
