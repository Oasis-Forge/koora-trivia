import 'package:football_trivia/core/services/sound_effects.dart';

/// يسجّل ما شُغّل بدل تشغيله.
class FakeSoundEffects implements SoundEffects {
  final List<Sfx> played = [];
  int stops = 0;

  @override
  Future<void> play(Sfx sfx) async => played.add(sfx);

  @override
  Future<void> stopAll() async => stops++;
}
