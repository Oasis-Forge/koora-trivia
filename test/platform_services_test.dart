import 'package:flutter_test/flutter_test.dart';
import 'package:football_trivia/data/services/in_app_review_prompter.dart';
import 'package:football_trivia/data/services/package_app_info.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('InAppReviewPrompter', () {
    setUp(() => SharedPreferences.setMockInitialValues({}));

    test('لم يُطلب التقييم قط: لا تاريخ', () async {
      expect(await InAppReviewPrompter().lastAskedAt(), isNull);
    });

    test('الطلب يُسجَّل وقته حتى إن تعذّرت نافذة غوغل بلاي', () async {
      final at = DateTime(2026, 9, 14, 21);

      // لا منصة في الاختبار: استدعاء النافذة يفشل ويُلتقط الخطأ.
      await InAppReviewPrompter(clock: () => at).ask();

      expect(await InAppReviewPrompter().lastAskedAt(), at);
    });
  });

  test('PackageAppInfo: رقم الإصدار ورقم البناء من الحزمة المبنية', () async {
    PackageInfo.setMockInitialValues(
      appName: 'تحدي كرة القدم',
      packageName: 'com.oasisforge.kooratrivia',
      version: '1.0.4',
      buildNumber: '5',
      buildSignature: '',
    );

    expect(await PackageAppInfo().version(), '1.0.4 (5)');
  });
}
