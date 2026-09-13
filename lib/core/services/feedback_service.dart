import 'package:flutter/services.dart';

/// مؤثرات اللمس والصوت أثناء اللعب.
///
/// نعتمد على أصوات النظام واهتزازه فقط — **بلا ملفات صوتية**. هذا يُبقي حجم
/// التطبيق كما هو ويعمل على كل الأجهزة، لكنه ليس بديلاً عن مؤثرات صوتية حقيقية
/// إن أردتها لاحقاً (تحتاج ملفات `.mp3` وحزمة تشغيل صوت).
class FeedbackService {
  const FeedbackService({required this.sound, required this.haptics});

  final bool sound;
  final bool haptics;

  Future<void> correct() async {
    if (haptics) await HapticFeedback.lightImpact();
    if (sound) await SystemSound.play(SystemSoundType.click);
  }

  Future<void> wrong() async {
    // اهتزاز أقوى للخطأ حتى يُحسّ الفرق دون النظر إلى الشاشة.
    if (haptics) await HapticFeedback.heavyImpact();
  }

  Future<void> levelPassed() async {
    if (haptics) await HapticFeedback.mediumImpact();
    if (sound) await SystemSound.play(SystemSoundType.click);
  }

  Future<void> select() async {
    if (haptics) await HapticFeedback.selectionClick();
  }

  Future<void> reward() async {
    if (haptics) await HapticFeedback.mediumImpact();
    if (sound) await SystemSound.play(SystemSoundType.click);
  }
}
