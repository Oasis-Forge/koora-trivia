import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:football_trivia/data/services/local_notification_scheduler.dart';

/// إعدادات أندرويد التي لا يكشف غيابها إلا جهاز حقيقي.
void main() {
  const res = 'android/app/src/main/res';
  final manifest =
      File('android/app/src/main/AndroidManifest.xml').readAsStringSync();

  test('مستقبِلا التنبيه المجدول وإعادة التشغيل مُعلنان', () {
    // بدونهما جُدول التنبيه اليومي حتى الإصدار 1.0.3 ولم يُطلق مرة واحدة.
    expect(
      manifest,
      contains(
        'com.dexterous.flutterlocalnotifications.ScheduledNotificationReceiver"',
      ),
    );
    expect(
      manifest,
      contains(
        'com.dexterous.flutterlocalnotifications.ScheduledNotificationBootReceiver',
      ),
    );
    expect(manifest, contains('android.intent.action.BOOT_COMPLETED'));
    expect(manifest, contains('android.permission.RECEIVE_BOOT_COMPLETED'));
    expect(
      manifest,
      isNot(contains('<action android:name="android.intent.action.MY_PACKAGE_REPLACED"')),
      reason: 'يعيد تنبيه الإصدار 1.0.3 المخزّن قبل أن يُفتح الإصدار الجديد',
    );
  });

  test('أيقونة شريط الحالة موجودة بكل الكثافات', () {
    for (final density in ['mdpi', 'hdpi', 'xhdpi', 'xxhdpi', 'xxxhdpi']) {
      final icon = File(
        '$res/drawable-$density/${LocalNotificationScheduler.statusBarIcon}.png',
      );
      expect(icon.existsSync(), isTrue, reason: 'drawable-$density');
    }
  });

  test('ضاغط الموارد لا يحذف أيقونة شريط الحالة', () {
    final keep = File('$res/raw/keep.xml').readAsStringSync();

    expect(
      keep,
      contains('@drawable/${LocalNotificationScheduler.statusBarIcon}'),
    );
  });
}
