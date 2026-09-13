import '../../core/constants/app_config.dart';
import '../entities/reminder_plan.dart';

/// يقرر أيام التنبيه ونصّها للأيام القادمة.
///
/// التنبيه اليومي المتكرر لا يُتخطّى منه يوم، فكان يذكّر من أنهى تحدي اليوم
/// ويَعِد بسلسلة ربما انقطعت. بدلاً منه يُجدول تنبيه مستقل لكل يوم، وتُعاد
/// الجدولة كلما تغيّرت حالة التحدي أو فُتح التطبيق.
///
/// ولا يمكن الجمع بين تنبيه مستقل اليوم وتنبيه متكرر يبدأ بعده: الحزمة تتجاهل
/// تاريخ التنبيه المتكرر وتضعه عند أقرب موعد للساعة، فيُطلقان في اليوم نفسه
/// (ثبت ذلك على المحاكي).
class PlanReminders {
  const PlanReminders();

  List<ReminderPlan> call({
    required DateTime now,
    required int hour,
    required int minute,
    required bool dailyDoneToday,
    required int streak,
    int days = AppConfig.reminderDaysAhead,
  }) {
    final todayAt = DateTime(now.year, now.month, now.day, hour, minute);
    // اليوم مستبعد إن أُنجز تحديه أو مضى موعد تنبيهه.
    final startsToday = !dailyDoneToday && todayAt.isAfter(now);

    // السلسلة تُذكر في أول تنبيه فقط، وحين تكون قائمة يومه: اليوم قبل إنجازه،
    // أو غداً بعد إنجاز اليوم. ما بعده مجهول فنصّه عام.
    final firstStreak =
        (startsToday || dailyDoneToday) && streak > 0 ? streak : null;

    return [
      for (var i = 0; i < days; i++)
        ReminderPlan(
          // مكوّنات التاريخ لا إضافة 24 ساعة، حتى لا يزيح التوقيت الصيفي الموعد.
          at: DateTime(
            now.year,
            now.month,
            now.day + (startsToday ? i : i + 1),
            hour,
            minute,
          ),
          streak: i == 0 ? firstStreak : null,
        ),
    ];
  }
}
