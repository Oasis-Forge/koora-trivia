/// المؤثرات الصوتية وملفاتها في `assets/sounds/`؛ مصادرها ورخصها في HOW_IT_WORKS.md.
///
/// الصوت مضبوط لكل مؤثر: ما يتكرر كثيراً (الإجابة، العدّاد) أهدأ مما يُسمع مرة
/// في الجولة (الهتاف)، وإلا صار المتكرر مزعجاً بعد جولتين.
enum Sfx {
  correct('correct.ogg', 0.6),
  wrong('wrong.ogg', 0.6),
  tick('tick.ogg', 0.35),
  whistle('whistle.ogg', 0.7),
  cheer('cheer.ogg', 0.8),
  bigCheer('big_cheer.ogg', 0.9),
  coins('coins.ogg', 0.9);

  const Sfx(this.file, this.volume);

  final String file;
  final double volume;
}

/// تشغيل المؤثرات — خلف عقد حتى تعمل الاختبارات بلا منصة صوت.
abstract class SoundEffects {
  Future<void> play(Sfx sfx);

  /// إيقاف كل ما يُسمع — قبل إعلان بملء الشاشة، فلا يختلط الهتاف بصوت الإعلان.
  Future<void> stopAll();
}

/// بلا صوت: للاختبارات، والافتراضي حيث لا تُمرَّر خدمة حقيقية.
class SilentSoundEffects implements SoundEffects {
  const SilentSoundEffects();

  @override
  Future<void> play(Sfx sfx) async {}

  @override
  Future<void> stopAll() async {}
}
