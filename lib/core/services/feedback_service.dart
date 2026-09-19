import 'package:flutter/services.dart';

import 'sound_effects.dart';

/// مؤثرات اللمس والصوت أثناء اللعب.
///
/// أصوات خفيفة لما يتكرر (الإجابة، العدّاد، العملات) وأصوات ملعب للحظات الكبيرة
/// (الصافرة، الهتاف) — اختيار المالك، 19 سبتمبر 2026. مفتاحا «الصوت» و«الاهتزاز»
/// في الإعدادات يحكمان كل شيء هنا، ولا صوت على اللمسات العادية للأزرار.
class FeedbackService {
  const FeedbackService({
    required this.sound,
    required this.haptics,
    this.effects = const SilentSoundEffects(),
  });

  final bool sound;
  final bool haptics;
  final SoundEffects effects;

  Future<void> _play(Sfx sfx) async {
    if (sound) await effects.play(sfx);
  }

  /// الصوت والاهتزاز معاً، والصوت يبدأ أولاً: انتظار الاهتزاز قبله كان يؤخر
  /// الصوت عن لحظة اللمس.
  Future<void> _both(Sfx sfx, Future<void> Function() haptic) =>
      Future.wait([_play(sfx), if (haptics) haptic()]);

  Future<void> correct() => _both(Sfx.correct, HapticFeedback.lightImpact);

  /// اهتزاز أقوى للخطأ حتى يُحسّ الفرق دون النظر إلى الشاشة.
  Future<void> wrong() => _both(Sfx.wrong, HapticFeedback.heavyImpact);

  /// كل ثانية من آخر ثوانٍ السؤال.
  Future<void> tick() => _play(Sfx.tick);

  /// انتهاء وقت السؤال، وانطلاق تحدي اليوم.
  Future<void> whistle() => _play(Sfx.whistle);

  Future<void> levelPassed() => _both(Sfx.cheer, HapticFeedback.mediumImpact);

  /// ثلاث نجوم أو رقم قياسي جديد: البوق والهتاف الكبير.
  Future<void> celebrate() => _both(Sfx.bigCheer, HapticFeedback.heavyImpact);

  Future<void> select() async {
    if (haptics) await HapticFeedback.selectionClick();
  }

  /// وصول عملات: مهمة أو صندوق أو إعلان أو شراء أو مكافأة سلسلة.
  Future<void> reward() => _both(Sfx.coins, HapticFeedback.mediumImpact);
}
