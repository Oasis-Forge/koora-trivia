import 'package:flutter_test/flutter_test.dart';
import 'package:football_trivia/core/constants/app_config.dart';
import 'package:football_trivia/domain/entities/app_update_status.dart';
import 'package:football_trivia/domain/usecases/choose_update_mode.dart';

void main() {
  const choose = ChooseUpdateMode();
  final now = DateTime(2026, 9, 20, 12);

  const flexible = AppUpdateStatus(
    available: true,
    immediateAllowed: true,
    flexibleAllowed: true,
  );
  const urgent = AppUpdateStatus(
    available: true,
    immediateAllowed: true,
    flexibleAllowed: true,
    priority: AppConfig.forceUpdatePriority,
  );

  test('بلا تحديث لا شيء', () {
    expect(choose(status: AppUpdateStatus.none, now: now), UpdateMode.none);
  });

  test('التحديث العادي مرن لا إلزامي', () {
    expect(choose(status: flexible, now: now), UpdateMode.flexible);
  });

  test('أولوية الإصلاح العاجل تفرض التحديث، ودونها مرن', () {
    expect(choose(status: urgent, now: now), UpdateMode.immediate);

    const almost = AppUpdateStatus(
      available: true,
      immediateAllowed: true,
      flexibleAllowed: true,
      priority: AppConfig.forceUpdatePriority - 1,
    );
    expect(choose(status: almost, now: now), UpdateMode.flexible);
  });

  test('عاجل لا يسمح به Play إلزامياً يُعرض مرناً', () {
    const flexibleOnly = AppUpdateStatus(
      available: true,
      flexibleAllowed: true,
      priority: 5,
    );
    expect(choose(status: flexibleOnly, now: now), UpdateMode.flexible);
  });

  test('تحديث إلزامي لم يكتمل يُستأنف', () {
    const resumed = AppUpdateStatus(inProgress: true);
    expect(choose(status: resumed, now: now), UpdateMode.immediate);
  });

  test('المرن لا يُعرض ثانية قبل انقضاء المهلة، والإلزامي لا ينتظرها', () {
    const days = AppConfig.flexibleUpdateAskEveryDays;
    final recently = now.subtract(const Duration(days: days, hours: -1));
    final longAgo = now.subtract(const Duration(days: days));

    expect(choose(status: flexible, now: now, lastAskedAt: recently),
        UpdateMode.none);
    expect(choose(status: flexible, now: now, lastAskedAt: longAgo),
        UpdateMode.flexible);
    expect(choose(status: urgent, now: now, lastAskedAt: recently),
        UpdateMode.immediate);
  });
}
