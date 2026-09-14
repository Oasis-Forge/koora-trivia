import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:share_plus/share_plus.dart';

import '../../core/constants/app_strings.dart';
import '../../core/theme/app_colors.dart';
import '../../core/constants/app_config.dart';
import '../../core/utils/arabic_count.dart';
import '../../domain/entities/quiz_result.dart';
import '../../domain/repositories/review_prompter.dart';
import '../../domain/usecases/build_share_text.dart';
import '../../domain/usecases/should_ask_for_review.dart';
import '../providers/ads_provider.dart';
import '../providers/economy_provider.dart';
import '../providers/progress_provider.dart';
import '../providers/quiz_provider.dart';
import '../providers/record_round.dart';
import '../providers/settings_provider.dart';
import '../providers/stats_provider.dart';
import '../widgets/hearts_bar.dart';
import '../widgets/koora_buttons.dart';
import '../widgets/pitch_background.dart';
import '../widgets/report_question_button.dart';
import '../widgets/stat_tile.dart';
import '../widgets/surface.dart';
import 'categories_screen.dart';
import 'levels_screen.dart';
import 'quiz_screen.dart';

class ScoreScreen extends StatefulWidget {
  const ScoreScreen({super.key});

  static const String routeName = '/score';

  @override
  State<ScoreScreen> createState() => _ScoreScreenState();
}

class _ScoreScreenState extends State<ScoreScreen>
    with SingleTickerProviderStateMixin {
  late final QuizResult _result;
  late final AnimationController _controller;
  late final Animation<double> _scoreAnimation;

  /// نتيجة المستوى — تبقى فارغة في اللعب السريع وتحدي اليوم.
  LevelOutcome? _levelOutcome;

  /// هل مُنح قلب مقابل إكمال تحدي اليوم؟
  bool _earnedHeart = false;

  /// مستوى لم يُجتز: ذهب قلب المحاولة الذي خُصم عند بدئها.
  bool _lostHeart = false;

  @override
  void initState() {
    super.initState();

    // نلتقط النتيجة مرة واحدة حتى لا تتأثر بإعادة تشغيل الجولة.
    _result = context.read<QuizProvider>().buildResult();

    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    );
    _scoreAnimation = CurvedAnimation(
      parent: _controller,
      curve: Curves.easeOutCubic,
    );
    _controller.forward();

    WidgetsBinding.instance.addPostFrameCallback((_) async {
      if (!mounted) return;

      // الحفظ أولاً وفي مكان واحد (`RecordRound`): لا يتوقف إن غادر اللاعب الشاشة،
      // ولا يضيع إن أُغلق التطبيق أثناء إعلان. الشاشة تعرض ما تغيّر فقط.
      final record = await RecordRound(
        stats: context.read<StatsProvider>(),
        economy: context.read<EconomyProvider>(),
        progress: context.read<ProgressProvider>(),
      )(_result);

      if (!mounted) return;
      setState(() {
        _earnedHeart = record.earnedHeart;
        _lostHeart = record.lostHeart;
        _levelOutcome = record.level;
      });
      if (record.level?.passed ?? false) {
        context.read<SettingsProvider>().feedback.levelPassed();
      }

      // إعلان بيني كل ثلاث جولات — **ولا إعلان بعد تحدي اليوم إطلاقاً**،
      // فهو الطقس اليومي الذي يجب أن يبقى نظيفاً.
      final ads = context.read<AdsProvider>();
      ads.recordRoundFinished();
      final adShown = !_result.isDaily && await ads.maybeShowInterstitial();

      // آخر خطوة: بعد حفظ السلسلة والنجوم التي يُبنى عليها القرار.
      if (!mounted) return;
      await _maybeAskForReview(adShown: adShown);
    });
  }

  /// طلب التقييم الجاري — أزرار بدء جولة جديدة تنتظر اكتماله.
  Future<void>? _pendingReview;

  /// طلب تقييم التطبيق بعد لحظة رضا فقط (انظر `ShouldAskForReview`).
  Future<void> _maybeAskForReview({required bool adShown}) async {
    final prompter = context.read<ReviewPrompter>();
    final streak = context.read<StatsProvider>().streak;
    final levelStars = _levelOutcome?.stars;

    final lastAskedAt = await prompter.lastAskedAt();
    // غادر اللاعب إلى جولة أخرى: نافذة Play فوقها تترك عدّاد السؤال يجري تحتها.
    if (!mounted || !(ModalRoute.of(context)?.isCurrent ?? false)) return;
    final shouldAsk = const ShouldAskForReview()(
      result: _result,
      streak: streak,
      levelStars: levelStars,
      adShown: adShown,
      lastAskedAt: lastAskedAt,
      now: DateTime.now(),
    );
    if (!shouldAsk) return;
    _pendingReview = prompter.ask();
    await _pendingReview;
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _share() async {
    final streak = context.read<StatsProvider>().streak;
    final box = context.findRenderObject() as RenderBox?;

    // اسم التصنيف بالعربية يأتي من السؤال نفسه لا من الـ slug.
    final categoryName =
        _result.answers.isEmpty ? null : _result.answers.first.question.categoryName;

    await Share.share(
      const BuildShareText()(
        _result,
        streak: streak,
        categoryName: categoryName,
      ),
      subject: AppStrings.appName,
      // مطلوب لعرض ورقة المشاركة بشكل صحيح على الأجهزة اللوحية (iPad).
      sharePositionOrigin:
          box == null ? null : box.localToGlobal(Offset.zero) & box.size,
    );
  }

  Future<void> _playAgain() async {
    // لا تبدأ جولة ونافذة التقييم ما زالت ستظهر فوقها.
    await _pendingReview;
    if (!mounted) return;
    final quiz = context.read<QuizProvider>();

    // في نمط المستويات نعيد نفس المستوى بدل جولة عشوائية — والمستوى يحتاج قلباً،
    // أما اللعب السريع فيبقى مجانياً وعلى التصنيف الذي اختاره اللاعب.
    if (_result.isLevel) {
      final started = await NoHeartsDialog.startLevel(
        context,
        categorySlug: _result.categorySlug!,
        level: _result.level!,
      );
      if (!started) return;
    } else {
      await quiz.startQuickPlay(categorySlug: quiz.quickPlayCategory);
    }

    if (!mounted) return;
    Navigator.of(context).pushReplacementNamed(QuizScreen.routeName);
  }

  Future<void> _playNextLevel() async {
    await _pendingReview;
    if (!mounted) return;
    final started = await NoHeartsDialog.startLevel(
      context,
      categorySlug: _result.categorySlug!,
      level: _result.level! + 1,
    );
    if (!started || !mounted) return;
    Navigator.of(context).pushReplacementNamed(QuizScreen.routeName);
  }

  /// زر "المستوى التالي" يظهر فقط عند اجتياز مستوى ليس الأخير.
  bool get _showNextLevelButton {
    final outcome = _levelOutcome;
    return outcome != null &&
        outcome.passed &&
        _result.level! < AppConfig.levelsPerCategory;
  }

  /// زر الإعادة **يُخفى بعد تحدي اليوم**: التحدي مرّة واحدة يومياً، وبطاقة
  /// الرئيسية تعطّله بالفعل. إبقاء الزر هنا كان يوحي بإمكان إعادته — بل كان
  /// يبدأ جولة "لعب سريع" عشوائية بصمت، فيظن اللاعب أنه يعيد التحدي.
  bool get _showReplayButton => !_result.isDaily;

  void _goHome() {
    context.read<QuizProvider>().abandon();
    Navigator.of(context).popUntil((route) => route.isFirst);
  }

  /// بعد تحدي اليوم: إلى التصنيفات لبدء مستوى — كانت الشاشة طريقاً مسدوداً لا
  /// يقدّم إلا الرئيسية.
  Future<void> _playLevel() async {
    await _pendingReview;
    if (!mounted) return;
    context.read<QuizProvider>().abandon();
    Navigator.of(context).pushReplacementNamed(CategoriesScreen.routeName);
  }

  @override
  Widget build(BuildContext context) {
    final stats = context.watch<StatsProvider>();

    return Scaffold(
      body: PitchBackground(
        child: SafeArea(
          child: ListView(
            padding: const EdgeInsets.fromLTRB(20, 20, 20, 28),
            children: [
              const SizedBox(height: 10),
              Center(
                child: Text(
                  _result.rankLabel,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
              const SizedBox(height: 22),
              _ScoreMedal(animation: _scoreAnimation, result: _result),
              if (_levelOutcome case final outcome?) ...[
                const SizedBox(height: 20),
                LevelStarsBanner(
                  stars: outcome.stars,
                  passed: outcome.passed,
                  unlockedNext: outcome.unlockedNextLevel,
                ),
              ],
              const SizedBox(height: 24),
              Row(
                children: [
                  Expanded(
                    child: StatTile(
                      icon: Icons.check_circle_rounded,
                      value: '${_result.correctCount}/${_result.total}',
                      label: AppStrings.correctAnswers,
                      accent: AppColors.correct,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: StatTile(
                      icon: Icons.percent_rounded,
                      value: '${_result.accuracyPercent}%',
                      label: AppStrings.accuracy,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: StatTile(
                      icon: Icons.whatshot_rounded,
                      value: '${stats.streak}',
                      label: AppStrings.streak,
                    ),
                  ),
                ],
              ),
              if (_earnedHeart || _lostHeart) ...[
                const SizedBox(height: 14),
                Surface(
                  padding: const EdgeInsets.all(14),
                  color: Color.alphaBlend(
                    AppColors.wrong.withValues(alpha: 0.12),
                    AppColors.cardSurface,
                  ),
                  border: Border.all(
                    color: AppColors.wrong.withValues(alpha: 0.5),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        _earnedHeart
                            ? Icons.favorite_rounded
                            : Icons.heart_broken_rounded,
                        color: AppColors.wrong,
                      ),
                      const SizedBox(width: 10),
                      Text(
                        _earnedHeart
                            ? AppStrings.heartEarned
                            : AppStrings.heartLost,
                        style: const TextStyle(fontWeight: FontWeight.w700),
                      ),
                    ],
                  ),
                ),
              ],
              if (_result.isDaily && stats.streak > 0) ...[
                const SizedBox(height: 14),
                Surface(
                  padding: const EdgeInsets.all(14),
                  color: Color.alphaBlend(
                    AppColors.gold.withValues(alpha: 0.12),
                    AppColors.cardSurface,
                  ),
                  border: Border.all(
                    color: AppColors.gold.withValues(alpha: 0.5),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        Icons.local_fire_department_rounded,
                        color: AppColors.gold,
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          AppStrings.streakKeptFor(
                            ArabicCount.format(
                              stats.streak,
                              ArabicNoun.day,
                              object: true,
                            ),
                          ),
                          style: const TextStyle(fontWeight: FontWeight.w700),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
              if (_result.isDaily) const _DailyReminderCard(),
              const SizedBox(height: 24),
              GoldButton(
                label: AppStrings.shareScore,
                icon: Icons.share_rounded,
                onPressed: _share,
              ),
              const SizedBox(height: 12),
              if (_result.isDaily) ...[
                SolidButton(
                  label: AppStrings.playLevel,
                  icon: Icons.sports_soccer_rounded,
                  onPressed: _playLevel,
                ),
                const SizedBox(height: 12),
              ],
              if (_showNextLevelButton) ...[
                SolidButton(
                  label: AppStrings.nextLevel,
                  icon: Icons.skip_next_rounded,
                  onPressed: _playNextLevel,
                ),
                const SizedBox(height: 12),
              ],
              if (_showReplayButton) ...[
                OutlineButton(
                  label: _result.isLevel
                      ? AppStrings.replayLevel
                      : AppStrings.playAgain,
                  icon: Icons.replay_rounded,
                  onPressed: _playAgain,
                ),
                const SizedBox(height: 12),
              ],
              TextButton.icon(
                onPressed: _goHome,
                icon: Icon(Icons.home_rounded, color: AppColors.chalkMuted),
                label: Text(
                  AppStrings.backHome,
                  style: TextStyle(color: AppColors.chalkMuted),
                ),
              ),
              // لا مراجعة للإجابات بعد المستوى (قرار المالك، 14 سبتمبر 2026)؛
              // تبقى بعد اللعب السريع وتحدي اليوم. الإبلاغ عن سؤال متاح في لوحة
              // الشرح أثناء الجولة.
              if (!_result.isLevel) ...[
                const SizedBox(height: 24),
                const Text(
                  AppStrings.reviewAnswers,
                  style: TextStyle(fontSize: 17, fontWeight: FontWeight.w800),
                ),
                const SizedBox(height: 12),
                for (final answer in _result.answers)
                  _ReviewRow(answer: answer),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

/// بعد تحدي اليوم: تذكير الغد بلمسة، والإذن يُطلب لحظتها. لا تظهر إن كان التنبيه
/// مفعّلاً من قبل، وتؤكّد الموعد بعد التفعيل.
class _DailyReminderCard extends StatefulWidget {
  const _DailyReminderCard();

  @override
  State<_DailyReminderCard> createState() => _DailyReminderCardState();
}

class _DailyReminderCardState extends State<_DailyReminderCard> {
  bool _enabledHere = false;
  bool _busy = false;

  Future<void> _enable() async {
    if (_busy) return;
    setState(() => _busy = true);
    final settings = context.read<SettingsProvider>();
    final messenger = ScaffoldMessenger.of(context);

    final granted = await settings.setReminderEnabled(true);
    if (!mounted) return;
    setState(() {
      _busy = false;
      _enabledHere = granted;
    });
    if (!granted) {
      messenger
        ..hideCurrentSnackBar()
        ..showSnackBar(
          const SnackBar(content: Text(AppStrings.reminderDenied)),
        );
    }
  }

  @override
  Widget build(BuildContext context) {
    final settings = context.watch<SettingsProvider>();
    if (settings.reminderEnabled && !_enabledHere) {
      return const SizedBox.shrink();
    }

    return Padding(
      padding: const EdgeInsets.only(top: 14),
      child: Surface(
        padding: const EdgeInsets.fromLTRB(14, 8, 14, 8),
        child: Row(
          children: [
            Icon(
              _enabledHere
                  ? Icons.notifications_active_rounded
                  : Icons.notifications_rounded,
              color: AppColors.gold,
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                _enabledHere
                    ? AppStrings.dailyReminderSet(settings.reminderLabel)
                    : AppStrings.dailyReminderAsk,
                style: const TextStyle(fontWeight: FontWeight.w700),
              ),
            ),
            if (!_enabledHere)
              TextButton(
                onPressed: _busy ? null : _enable,
                // لون الزر الافتراضي أخضر يذوب في البطاقة الخضراء (رُئي على المحاكي).
                style: TextButton.styleFrom(foregroundColor: AppColors.gold),
                child: const Text(
                  AppStrings.dailyReminderButton,
                  style: TextStyle(fontWeight: FontWeight.w800),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _ScoreMedal extends StatelessWidget {
  const _ScoreMedal({required this.animation, required this.result});

  final Animation<double> animation;
  final QuizResult result;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Container(
        width: 200,
        height: 200,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          gradient: AppColors.goldGradient,
          boxShadow: [
            BoxShadow(
              color: AppColors.gold.withValues(alpha: 0.35),
              blurRadius: 34,
              spreadRadius: 2,
            ),
          ],
        ),
        child: Center(
          child: Container(
            width: 172,
            height: 172,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: AppColors.pitchDark,
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  AppStrings.yourScore,
                  style: TextStyle(
                    color: AppColors.chalkMuted,
                    fontSize: 14,
                  ),
                ),
                const SizedBox(height: 4),
                AnimatedBuilder(
                  animation: animation,
                  builder: (context, _) => Text(
                    '${(result.score * animation.value).round()}',
                    style: TextStyle(
                      fontSize: 46,
                      fontWeight: FontWeight.w900,
                      color: AppColors.gold,
                      height: 1.1,
                    ),
                  ),
                ),
                Text(
                  ArabicCount.nounFor(result.score, ArabicNoun.point),
                  style: TextStyle(
                    color: AppColors.chalkMuted,
                    fontSize: 13,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _ReviewRow extends StatelessWidget {
  const _ReviewRow({required this.answer});

  final AnswerRecord answer;

  @override
  Widget build(BuildContext context) {
    final correct = answer.isCorrect;
    // التخطّي بمساعدة ليس خطأ: لا أحمر ولا علامة إلغاء.
    final skipped = answer.skipped;
    final color = correct
        ? AppColors.correct
        : skipped
            ? AppColors.gold
            : AppColors.wrong;

    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Surface(
      padding: const EdgeInsets.all(14),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            correct
                ? Icons.check_circle_rounded
                : skipped
                    ? Icons.skip_next_rounded
                    : Icons.cancel_rounded,
            color: color,
            size: 20,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  answer.question.text,
                  style: const TextStyle(
                    fontWeight: FontWeight.w700,
                    height: 1.4,
                  ),
                ),
                const SizedBox(height: 6),
                // ما حدث بلونه، والإجابة الصحيحة بالأخضر دائماً — كانت تُكتب بالأحمر
                // بعد الخطأ فتبدو كأنها الخطأ.
                if (!correct)
                  Text(
                    skipped
                        ? AppStrings.skippedAnswer
                        : answer.timedOut
                            ? AppStrings.timeUp
                            : AppStrings.yourAnswerIs(
                                answer.question.options[answer.selectedIndex],
                              ),
                    style: TextStyle(color: color, fontSize: 13),
                  ),
                Text(
                  correct
                      ? answer.question.correctAnswer
                      : AppStrings.correctIs(answer.question.correctAnswer),
                  style: TextStyle(color: AppColors.correct, fontSize: 13),
                ),
              ],
            ),
          ),
          ReportQuestionButton(question: answer.question, compact: true),
        ],
      ),
      ),
    );
  }
}
