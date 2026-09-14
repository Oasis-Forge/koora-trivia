import 'package:flutter_test/flutter_test.dart';
import 'package:football_trivia/core/constants/app_config.dart';
import 'package:football_trivia/domain/entities/app_update_status.dart';
import 'package:football_trivia/presentation/providers/check_for_update.dart';

import 'fakes/fake_repositories.dart';

const _normal = AppUpdateStatus(
  available: true,
  immediateAllowed: true,
  flexibleAllowed: true,
);

void main() {
  test('بلا تحديث لا تُطلب أي نافذة', () async {
    final updater = FakeAppUpdater();

    expect(await CheckForUpdate(updater: updater)(), isFalse);
    expect(updater.immediateCalls + updater.flexibleCalls, 0);
  });

  test('تحديث عادي: نافذة مرنة، ولا تتكرر قبل المهلة', () async {
    final updater = FakeAppUpdater(status: _normal);
    final check = CheckForUpdate(updater: updater);

    expect(await check(), isTrue, reason: 'اكتمل التنزيل');
    expect(updater.flexibleCalls, 1);
    expect(updater.immediateCalls, 0);

    expect(await check(), isFalse);
    expect(updater.flexibleCalls, 1);
  });

  test('من رفض التحديث المرن لا يُسأل ثانية قبل المهلة', () async {
    final updater = FakeAppUpdater(status: _normal, downloadCompletes: false);
    final check = CheckForUpdate(updater: updater);

    expect(await check(), isFalse);
    expect(await check(), isFalse);
    expect(updater.flexibleCalls, 1);
  });

  test('إصدار عاجل يفرض شاشة التحديث الكاملة في كل مرة', () async {
    final updater = FakeAppUpdater(
      status: const AppUpdateStatus(
        available: true,
        immediateAllowed: true,
        flexibleAllowed: true,
        priority: AppConfig.forceUpdatePriority,
      ),
    );
    final check = CheckForUpdate(updater: updater);

    expect(await check(), isFalse);
    expect(await check(), isFalse);
    expect(updater.immediateCalls, 2);
    expect(updater.flexibleCalls, 0);
  });

  test('تحديث منزَّل ينتظر إعادة التشغيل دون نافذة جديدة', () async {
    final updater = FakeAppUpdater(
      status: const AppUpdateStatus(available: true, downloaded: true),
    );

    expect(await CheckForUpdate(updater: updater)(), isTrue);
    expect(updater.flexibleCalls, 0);
  });
}
