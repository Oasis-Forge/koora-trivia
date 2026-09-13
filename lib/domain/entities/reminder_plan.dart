/// تنبيه واحد مجدول ليوم محدد.
class ReminderPlan {
  const ReminderPlan({required this.at, this.streak});

  /// لحظة التنبيه بالتوقيت المحلي.
  final DateTime at;

  /// السلسلة التي يذكرها التنبيه، أو `null` لنص عام.
  final int? streak;
}
