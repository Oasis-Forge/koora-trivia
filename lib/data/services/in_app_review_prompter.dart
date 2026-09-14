import 'package:flutter/foundation.dart';
import 'package:in_app_review/in_app_review.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../domain/repositories/review_prompter.dart';

/// طلب التقييم عبر نافذة غوغل بلاي داخل التطبيق.
///
/// ليس ضمن النسخة الاحتياطية عمداً: حدّ غوغل لعدد مرات الظهور مرتبط بالحساب لا
/// بالتقدّم.
class InAppReviewPrompter implements ReviewPrompter {
  InAppReviewPrompter({DateTime Function()? clock})
      : _clock = clock ?? DateTime.now;

  static const String key = 'review_prompt_v1';

  final DateTime Function() _clock;

  @override
  Future<DateTime?> lastAskedAt() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(key);
    return raw == null ? null : DateTime.tryParse(raw);
  }

  @override
  Future<void> ask() async {
    // نسجّل الطلب قبل النافذة: إن فشلت لا نعيد المحاولة مع كل جولة حتى تنجح.
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(key, _clock().toIso8601String());

    try {
      // بلا `isAvailable()` قبله: كلاهما يطلب النافذة من Play فيتضاعف انتظار ظهورها.
      // حين لا تتوفر يرمي الطلب خطأً يُلتقط هنا.
      await InAppReview.instance.requestReview();
    } catch (e) {
      debugPrint('تعذّر طلب التقييم: $e');
    }
  }
}
