import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/foundation.dart';

import '../../core/services/sound_effects.dart';

/// المؤثرات عبر audioplayers: مشغّل لكل مؤثر بنمط الاستجابة السريعة
/// (SoundPool على أندرويد)، فالمقطع القصير يبدأ لحظة اللمس لا بعدها.
class AudioSoundEffects implements SoundEffects {
  final Map<Sfx, AudioPlayer> _players = {};
  Future<void>? _configured;

  /// لا نأخذ «تركيز الصوت»: موسيقى اللاعب في تطبيق آخر تستمر تحت مؤثراتنا بدل
  /// أن تتوقف مع كل إجابة. والصوت يتبع مستوى الوسائط في الهاتف كبقية الألعاب.
  Future<void> _configure() =>
      _configured ??= AudioPlayer.global.setAudioContext(
        AudioContextConfig(focus: AudioContextConfigFocus.mixWithOthers)
            .build(),
      );

  @override
  Future<void> play(Sfx sfx) async {
    try {
      await _configure();
      final player = _players[sfx] ??= AudioPlayer(playerId: 'sfx_${sfx.name}');
      // المؤثر نفسه مرة ثانية (دقّة العدّاد كل ثانية) يبدأ من أوله.
      await player.stop();
      await player.play(
        AssetSource('sounds/${sfx.file}'),
        volume: sfx.volume,
        mode: PlayerMode.lowLatency,
      );
    } catch (e) {
      // صوت لم يُشغَّل لا يستحق إيقاف اللعب ولا سجل الأخطاء: قد يكون الهاتف بلا
      // مخرج صوت متاح لحظتها.
      debugPrint('Sound ${sfx.name} failed: $e');
    }
  }

  @override
  Future<void> stopAll() async {
    for (final player in _players.values) {
      try {
        await player.stop();
      } catch (_) {}
    }
  }
}
