import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:football_trivia/presentation/providers/ads_provider.dart';
import 'package:football_trivia/presentation/widgets/app_lifecycle_hooks.dart';
import 'package:provider/provider.dart';

import 'fakes/fake_ad_service.dart';

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

void main() {
  testWidgets('العودة إلى التطبيق تعيد محاولة تحميل الإعلان', (tester) async {
    final service = FakeAdService(ready: false);
    final ads = AdsProvider(service: service);

    await tester.pumpWidget(
      ChangeNotifierProvider.value(
        value: ads,
        child: const AppLifecycleHooks(child: SizedBox()),
      ),
    );
    expect(service.resumeCalls, 0);

    _leaveAndReturn(tester);
    expect(service.resumeCalls, 1);

    // بعد إزالة الغلاف لا يبقى مستمع معلّق.
    await tester.pumpWidget(
      ChangeNotifierProvider.value(value: ads, child: const SizedBox()),
    );
    _leaveAndReturn(tester);
    expect(service.resumeCalls, 1);
  });
}
