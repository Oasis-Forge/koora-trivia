import '../constants/app_strings.dart';

/// أدوات التعامل مع "اليوم" كمفتاح ثابت للتحدي اليومي والسلسلة.
///
/// نستخدم التاريخ المحلي (بدون وقت) حتى يبدأ اليوم عند منتصف الليل لدى المستخدم.
class DayKey {
  const DayKey._();

  /// يحوّل التاريخ إلى مفتاح نصي `yyyy-MM-dd`.
  static String from(DateTime date) {
    final y = date.year.toString().padLeft(4, '0');
    final m = date.month.toString().padLeft(2, '0');
    final d = date.day.toString().padLeft(2, '0');
    return '$y-$m-$d';
  }

  static String today([DateTime? now]) => from(now ?? DateTime.now());

  static DateTime parse(String key) => DateTime.parse(key);

  /// عدد الأيام الكاملة بين مفتاحين (b - a).
  static int daysBetween(String a, String b) {
    final da = parse(a);
    final db = parse(b);
    // بتوقيت UTC: يوم تغيير الساعة محلياً طوله 23 ساعة، فكان `inDays` يعدّه صفراً
    // وتنقطع السلسلة في البلدان التي تغيّر ساعتها.
    return DateTime.utc(db.year, db.month, db.day)
        .difference(DateTime.utc(da.year, da.month, da.day))
        .inDays;
  }

  /// رقم اليوم منذ حقبة يونكس — يُستخدم كبذرة عشوائية ثابتة لكل يوم.
  ///
  /// يُحسب من مكوّنات التاريخ بتوقيت UTC: طرح التاريخ المحلي من منتصف ليل UTC
  /// كان يُنقص يوماً شرق غرينتش، فيحصل بلدان مختلفان على تحدٍّ مختلف في نفس التاريخ.
  static int epochDay(String key) {
    final date = parse(key);
    return DateTime.utc(date.year, date.month, date.day)
        .difference(DateTime.utc(1970))
        .inDays;
  }

  /// تاريخ مقروء بلغة التطبيق مثل «4 أغسطس» أو «4 August»، يُستخدم في نص المشاركة.
  static String shortDate([DateTime? date]) {
    final d = date ?? DateTime.now();
    return '${d.day} ${AppStrings.monthNames[d.month - 1]}';
  }

  /// الوقت المتبقي حتى منتصف الليل المحلي.
  static Duration untilTomorrow([DateTime? now]) {
    final n = now ?? DateTime.now();
    final midnight = DateTime(n.year, n.month, n.day).add(
      const Duration(days: 1),
    );
    return midnight.difference(n);
  }
}
