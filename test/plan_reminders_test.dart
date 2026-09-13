import 'package:flutter_test/flutter_test.dart';
import 'package:football_trivia/core/constants/app_config.dart';
import 'package:football_trivia/domain/entities/reminder_plan.dart';
import 'package:football_trivia/domain/usecases/plan_reminders.dart';

void main() {
  const planReminders = PlanReminders();

  List<ReminderPlan> plan(
    DateTime now, {
    bool done = false,
    int streak = 0,
    int hour = 20,
    int minute = 0,
  }) =>
      planReminders(
        now: now,
        hour: hour,
        minute: minute,
        dailyDoneToday: done,
        streak: streak,
      );

  test('قبل موعد اليوم ولم يُنجز التحدي: يبدأ اليوم ويذكر السلسلة', () {
    final plans = plan(DateTime(2026, 9, 13, 10), streak: 3);

    expect(plans.first.at, DateTime(2026, 9, 13, 20));
    expect(plans.first.streak, 3);
  });

  test('أُنجز تحدي اليوم: يبدأ غداً ويذكر السلسلة', () {
    final plans = plan(DateTime(2026, 9, 13, 10), done: true, streak: 3);

    expect(plans.first.at, DateTime(2026, 9, 14, 20));
    expect(plans.first.streak, 3);
  });

  test('مضى موعد اليوم ولم يُنجز: يبدأ غداً بنص عام', () {
    // السلسلة تنقطع غداً ما لم يلعب اليوم، وإن لعب تُعاد الجدولة.
    final plans = plan(DateTime(2026, 9, 13, 21), streak: 3);

    expect(plans.first.at, DateTime(2026, 9, 14, 20));
    expect(plans.first.streak, isNull);
  });

  test('اللحظة نفسها بالضبط تُعدّ ماضية', () {
    final plans = plan(DateTime(2026, 9, 13, 20));

    expect(plans.first.at, DateTime(2026, 9, 14, 20));
  });

  test('بلا سلسلة: لا ذكر لها', () {
    expect(plan(DateTime(2026, 9, 13, 10)).first.streak, isNull);
  });

  test('أيام متتالية بالموعد نفسه، والسلسلة في أولها فقط', () {
    final plans = plan(DateTime(2026, 9, 13, 10), streak: 3);

    expect(plans, hasLength(AppConfig.reminderDaysAhead));
    for (var i = 0; i < plans.length; i++) {
      expect(plans[i].at, DateTime(2026, 9, 13 + i, 20));
      if (i > 0) expect(plans[i].streak, isNull, reason: 'اليوم ${i + 1}');
    }
  });

  test('نهاية الشهر تنتقل إلى الشهر التالي', () {
    final plans = plan(DateTime(2026, 9, 30, 21));

    expect(plans.first.at, DateTime(2026, 10, 1, 20));
    expect(plans[1].at, DateTime(2026, 10, 2, 20));
  });

  test('الدقائق تُحترم', () {
    final plans = plan(DateTime(2026, 9, 13, 7, 30), hour: 7, minute: 45);

    expect(plans.first.at, DateTime(2026, 9, 13, 7, 45));
  });
}
