import '../../core/constants/app_config.dart';
import '../../core/services/feedback_service.dart';
import 'quiz_provider.dart';

/// أصوات الجولة التي لا تأتي من لمسة: دقّات آخر الثواني، وصافرة انتهاء الوقت،
/// وصافرة انطلاق تحدي اليوم.
///
/// تستمع إلى `QuizProvider` وتقارن حالته بما قبلها، فلا يعرف المزوّد شيئاً عن
/// الصوت ولا تتغيّر اختباراته. تُربط بشاشة السؤال وتُفك معها.
class QuizSoundCues {
  QuizSoundCues({
    required QuizProvider quiz,
    required FeedbackService Function() feedback,
  })  : _quiz = quiz,
        _feedback = feedback;

  final QuizProvider _quiz;

  /// تُقرأ عند كل صوت لا مرة واحدة: إطفاء الصوت من الإعدادات يسري فوراً.
  final FeedbackService Function() _feedback;

  QuizStatus _status = QuizStatus.idle;
  int _seconds = AppConfig.secondsPerQuestion;

  void attach() {
    // الجولة قد تكون بدأت قبل أن تُبنى الشاشة (الأسئلة المحمّلة تصل في الإطار
    // نفسه)، فالانطلاق يُفحص هنا أيضاً لا عند التغيّر وحده.
    if (_isKickOff(QuizStatus.loading)) _feedback().whistle();
    _remember();
    _quiz.addListener(_onChange);
  }

  void detach() => _quiz.removeListener(_onChange);

  void _remember() {
    _status = _quiz.status;
    _seconds = _quiz.secondsLeft;
  }

  /// أول سؤال في تحدي اليوم يبدأ الآن، بعدّاد لم ينقص بعد.
  bool _isKickOff(QuizStatus before) =>
      _quiz.isDaily &&
      before != QuizStatus.playing &&
      _quiz.status == QuizStatus.playing &&
      _quiz.index == 0 &&
      _quiz.answers.isEmpty &&
      _quiz.secondsLeft == AppConfig.secondsPerQuestion;

  void _onChange() {
    final seconds = _quiz.secondsLeft;
    final status = _quiz.status;

    if (_isKickOff(_status)) {
      _feedback().whistle();
    } else if (_status == QuizStatus.playing &&
        status == QuizStatus.revealing &&
        _quiz.answers.isNotEmpty &&
        _quiz.answers.last.timedOut) {
      _feedback().whistle();
    } else if (status == QuizStatus.playing &&
        !_quiz.isPaused &&
        seconds < _seconds &&
        seconds >= 1 &&
        seconds <= AppConfig.tickFromSeconds) {
      // نقصان فقط: الوقت الإضافي يرفع الثواني فلا يدقّ.
      _feedback().tick();
    }
    _remember();
  }
}
