import 'dart:async';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/constants/app_config.dart';
import '../../core/constants/app_strings.dart';
import '../../core/theme/app_colors.dart';
import '../../core/utils/arabic_count.dart';
import '../../domain/entities/question.dart';
import '../providers/economy_provider.dart';
import '../providers/quiz_provider.dart';
import '../providers/settings_provider.dart';
import '../widgets/answer_option.dart';
import '../widgets/banner_slot.dart';
import '../widgets/hint_bar.dart';
import '../widgets/koora_app_bar.dart';
import '../widgets/koora_buttons.dart';
import '../widgets/surface.dart';
import '../widgets/pitch_background.dart';
import '../widgets/report_question_button.dart';
import '../widgets/timer_ring.dart';
import 'score_screen.dart';

class QuizScreen extends StatefulWidget {
  const QuizScreen({super.key});

  static const String routeName = '/quiz';

  @override
  State<QuizScreen> createState() => _QuizScreenState();
}

class _QuizScreenState extends State<QuizScreen> with WidgetsBindingObserver {
  bool _navigated = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  /// مغادرة التطبيق (مكالمة، تطبيق البريد، نافذة التقييم) توقف العدّاد وتخفي
  /// السؤال حتى العودة، فلا يضيع السؤال ولا يُبحث عن إجابته في الأثناء.
  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    final quiz = context.read<QuizProvider>();
    if (state == AppLifecycleState.resumed) {
      quiz.resume();
    } else {
      quiz.pause();
    }
  }

  Future<bool> _confirmQuit() async {
    // الخروج من مستوى يُحسب محاولة لم تُجتز، فيذهب قلبها.
    final isLevel = context.read<QuizProvider>().isLevelMode;
    final leave = await showDialog<bool>(
      context: context,
      barrierColor: const Color(0xB8031410),
      builder: (context) => Dialog(
        backgroundColor: AppColors.cardSurface,
        insetPadding: const EdgeInsets.symmetric(horizontal: 20),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(28),
          side: BorderSide(color: AppColors.cardBorder),
        ),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 22, 16, 12),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                AppStrings.quitTitle,
                style: TextStyle(fontSize: 22, fontWeight: FontWeight.w800),
              ),
              const SizedBox(height: 10),
              Text(
                isLevel ? AppStrings.quitBodyLevel : AppStrings.quitBody,
                style: TextStyle(
                  fontSize: 14.5,
                  height: 1.5,
                  fontWeight: FontWeight.w600,
                  color: AppColors.chalkMuted,
                ),
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  _DialogButton(
                    label: AppStrings.quitCancel,
                    color: AppColors.chalk,
                    filled: true,
                    onPressed: () => Navigator.of(context).pop(false),
                  ),
                  const SizedBox(width: 8),
                  _DialogButton(
                    label: AppStrings.quitConfirm,
                    color: AppColors.wrong,
                    onPressed: () => Navigator.of(context).pop(true),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
    return leave ?? false;
  }

  /// اختيار إجابة. الخطأ لا يخصم قلباً: المحاولة كلها تكلّف قلباً واحداً يُخصم
  /// عند بدئها ويعود عند الاجتياز (`NoHeartsDialog.startLevel`).
  Future<void> _answer(int index) async {
    final quiz = context.read<QuizProvider>();
    final question = quiz.currentQuestion;
    if (question == null) return;

    final correct = question.isCorrect(index);
    final feedback = context.read<SettingsProvider>().feedback;

    // لمسة ثانية قبل إعادة البناء، أو لمسة في إطار انتهاء الوقت، لا تُسجَّل.
    if (!quiz.selectAnswer(index)) return;
    if (correct) {
      feedback.correct();
    } else {
      feedback.wrong();
    }
    if (!mounted) return;

    // مهمة الإجابات الصحيحة تُحتسب في كل الأنماط.
    if (correct) await context.read<EconomyProvider>().recordCorrectAnswer();
  }

  /// يؤكّد الخروج ثم يلغي الجولة ويعود للشاشة السابقة.
  Future<void> _handleQuit() async {
    if (!await _confirmQuit()) return;
    if (!mounted) return;

    context.read<QuizProvider>().abandon();
    if (!mounted) return;
    Navigator.of(context).pop();
  }

  void _goToScore() {
    if (_navigated) return;
    _navigated = true;
    // ننتقل بعد اكتمال إطار البناء الحالي لتفادي التنقّل أثناء البناء.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      Navigator.of(context).pushReplacementNamed(ScoreScreen.routeName);
    });
  }

  @override
  Widget build(BuildContext context) {
    final quiz = context.watch<QuizProvider>();

    if (quiz.status == QuizStatus.finished) {
      _goToScore();
    }

    final question = quiz.currentQuestion;

    // الشاشات القصيرة (360×640 مثلاً) لا تتسع لبطاقة السؤال والخيارات الأربعة
    // بالمقاسات العادية، فيختفي الخيار الرابع أسفل الشاشة والوقت يجري.
    final compact =
        MediaQuery.sizeOf(context).height < AppConfig.compactLayoutMaxHeight;

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) {
        if (didPop) return;
        _handleQuit();
      },
      child: Scaffold(
        // الشريط الإعلاني أسفل المحتوى دائماً، لا داخل التمرير.
        bottomNavigationBar: const BannerSlot(),
        body: PitchBackground(
          child: SafeArea(
            child: question == null
                ? const Center(child: CircularProgressIndicator())
                : Column(
                    children: [
                      _TopBar(quiz: quiz, onQuit: _handleQuit),
                      // `SliverFillRemaining` يجعل المحتوى يملأ الشاشة فعلياً
                      // ثم يتحول إلى تمرير إن طال. `ConstrainedBox` وحده لا
                      // يمدّد الـ Column، فيبقى ملتصقاً بالأعلى مع فراغ أسفله.
                      Expanded(
                        child: quiz.isPaused
                            ? const _PausedView()
                            : CustomScrollView(
                          // موضع تمرير جديد لكل سؤال: لوحة الشرح تمرّر الشاشة
                          // إلى أسفل، وبدون مفتاح يبقى ذلك الإزاح فيبدأ السؤال
                          // التالي مقصوص الأعلى والوقت يجري.
                          key: ValueKey(quiz.index),
                          slivers: [
                            SliverFillRemaining(
                              hasScrollBody: false,
                              child: Padding(
                                padding: const EdgeInsets.fromLTRB(
                                  20,
                                  8,
                                  20,
                                  16,
                                ),
                                child: Column(
                                  children: [
                                    // المساحة الحرة تذهب فوق الخيارات لا
                                    // تحتها: توزيعها بالتساوي كان يترك فراغاً
                                    // بين آخر خيار وشريط المساعدات على الشاشات
                                    // الطويلة، والخيارات مكانها قرب الإبهام.
                                    const Spacer(),
                                    _QuestionCard(
                                      question: question,
                                      compact: compact,
                                    ),
                                    SizedBox(height: compact ? 12 : 16),
                                    const Spacer(flex: 2),
                                    Column(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        for (var i = 0;
                                            i < question.options.length;
                                            i++)
                                          AnswerOption(
                                            label: question.options[i],
                                            index: i,
                                            compact: compact,
                                            revealed: quiz.isAnswerRevealed,
                                            isCorrect:
                                                i == question.answerIndex,
                                            isSelected:
                                                quiz.selectedIndex == i,
                                            isEliminated: quiz
                                                .eliminatedOptions
                                                .contains(i),
                                            onTap: quiz.isAnswerRevealed ||
                                                    quiz.eliminatedOptions
                                                        .contains(i)
                                                ? null
                                                : () => _answer(i),
                                          ),
                                        if (quiz.isAnswerRevealed)
                                          _FeedbackPanel(
                                            quiz: quiz,
                                            question: question,
                                          ),
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      // المساعدات في نمط المستويات وحده — الأنماط الأخرى مجانية.
                      if (quiz.isLevelMode &&
                          !quiz.isAnswerRevealed &&
                          !quiz.isPaused)
                        const HintBar(),
                      if (quiz.isAnswerRevealed)
                        Padding(
                          padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
                          child: GoldButton(
                            label: quiz.isLastQuestion
                                ? AppStrings.finish
                                : AppStrings.next,
                            icon: quiz.isLastQuestion
                                ? Icons.flag_rounded
                                : Icons.arrow_forward_rounded,
                            onPressed: () =>
                                context.read<QuizProvider>().next(),
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

/// ما يظهر مكان السؤال والخيارات أثناء الإيقاف المؤقت.
class _PausedView extends StatelessWidget {
  const _PausedView();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.pause_circle_rounded, size: 64, color: AppColors.gold),
            SizedBox(height: 16),
            Text(
              AppStrings.quizPaused,
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800),
            ),
            SizedBox(height: 8),
            Text(
              AppStrings.quizPausedHint,
              textAlign: TextAlign.center,
              style: TextStyle(color: AppColors.chalkMuted, height: 1.5),
            ),
          ],
        ),
      ),
    );
  }
}

class _TopBar extends StatelessWidget {
  const _TopBar({required this.quiz, required this.onQuit});

  final QuizProvider quiz;
  final Future<void> Function() onQuit;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 18, 20, 4),
      child: Column(
        children: [
          Row(
            children: [
              RoundIconButton(
                icon: Icons.close_rounded,
                tooltip: AppStrings.quitRound,
                onPressed: onQuit,
              ),
              Expanded(
                child: Column(
                  children: [
                    Text(
                      '${AppStrings.question} ${quiz.index + 1} ${AppStrings.of} ${quiz.total}',
                      style: const TextStyle(
                        fontWeight: FontWeight.w800,
                        fontSize: 16,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      ArabicCount.format(quiz.score, ArabicNoun.point),
                      style: TextStyle(
                        color: AppColors.gold,
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              ),
              TimerRing(secondsLeft: quiz.secondsLeft),
            ],
          ),
          const SizedBox(height: 12),
          // شريط التقدّم ذهبي رفيع يكتمل مع آخر سؤال.
          ClipRRect(
            borderRadius: BorderRadius.circular(999),
            child: SizedBox(
              height: 5,
              child: Stack(
                children: [
                  Positioned.fill(
                    child: ColoredBox(
                      color: Colors.white.withValues(alpha: 0.12),
                    ),
                  ),
                  FractionallySizedBox(
                    widthFactor: quiz.progress.clamp(0, 1),
                    child: DecoratedBox(
                      decoration: BoxDecoration(
                        gradient: AppColors.goldGradient,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _QuestionCard extends StatelessWidget {
  const _QuestionCard({required this.question, required this.compact});

  final Question question;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    // عرض كامل صراحةً: صف الوسوم كان يمدّ البطاقة ضمناً، و`Wrap` لا يفعل،
    // فتضيق بطاقة السؤال القصير عن الخيارات تحتها.
    return SizedBox(
      width: double.infinity,
      child: Surface(
        padding: EdgeInsets.symmetric(
          horizontal: 14,
          vertical: compact ? 14 : 16,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // `Wrap` لا `Row`: اسم تصنيف طويل مع خط نظام كبير لا يتسع لسطر واحد.
            Wrap(
              spacing: 8,
              runSpacing: 6,
              children: [
                _Tag(text: question.categoryName, gold: false),
                _Tag(text: question.difficulty.arabicLabel, gold: true),
              ],
            ),
            SizedBox(height: compact ? 10 : 12),
            Text(
              question.text,
              style: TextStyle(
                fontSize: compact ? 18 : 21,
                fontWeight: FontWeight.w800,
                height: 1.45,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// وسم صغير في بطاقة السؤال: التصنيف باهت، والصعوبة ذهبية.
class _Tag extends StatelessWidget {
  const _Tag({required this.text, required this.gold});

  final String text;
  final bool gold;

  @override
  Widget build(BuildContext context) {
    // بعرض النص: `alignment` في Container كان يمدّ الوسم على عرض البطاقة كله.
    return Container(
      height: 32,
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(999),
        border: Border.all(
          color: gold
              ? AppColors.gold.withValues(alpha: 0.6)
              : AppColors.cardBorder,
        ),
      ),
      child: Center(
        widthFactor: 1,
        child: Text(
          text,
          style: TextStyle(
            color: gold ? AppColors.gold : AppColors.chalkMuted,
            fontSize: 12,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
    );
  }
}

/// زر حوار الخروج: «متابعة اللعب» بتعبئة خفيفة، و«خروج» نصاً أحمر.
class _DialogButton extends StatelessWidget {
  const _DialogButton({
    required this.label,
    required this.color,
    required this.onPressed,
    this.filled = false,
  });

  final String label;
  final Color color;
  final VoidCallback onPressed;
  final bool filled;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: filled ? Colors.white.withValues(alpha: 0.07) : Colors.transparent,
      borderRadius: BorderRadius.circular(999),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onPressed,
        child: SizedBox(
          height: 48,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 18),
            child: Center(
              child: Text(
                label,
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w800,
                  color: color,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _FeedbackPanel extends StatefulWidget {
  const _FeedbackPanel({required this.quiz, required this.question});

  final QuizProvider quiz;
  final Question question;

  @override
  State<_FeedbackPanel> createState() => _FeedbackPanelState();
}

class _FeedbackPanelState extends State<_FeedbackPanel> {
  Timer? _scrollTimer;

  @override
  void initState() {
    super.initState();
    // اللوحة تظهر أسفل الخيارات، وعلى الشاشات القصيرة خارج المنطقة المرئية،
    // فلا يرى اللاعب الإجابة الصحيحة ولا الشرح. ننتظر انتهاء حركة إطارات
    // الخيارات (220ms) لأنها تغيّر ارتفاعها، ثم نمرّر حتى تظهر اللوحة كاملة.
    _scrollTimer = Timer(const Duration(milliseconds: 240), _scrollIntoView);
  }

  void _scrollIntoView() {
    if (!mounted) return;
    final viewport = Scrollable.of(context).position.viewportDimension;
    // لوحة أطول من المنطقة المرئية (خط نظام كبير على شاشة قصيرة): نُظهر أعلاها،
    // ففيه الحكم والإجابة الصحيحة. محاذاة أسفلها كانت تدفعهما خارج الشاشة.
    final tooTall = (context.size?.height ?? 0) > viewport;
    Scrollable.ensureVisible(
      context,
      duration: const Duration(milliseconds: 250),
      curve: Curves.easeOut,
      alignment: 0,
      // وإلا فلا تمرير إن كانت اللوحة ظاهرة أصلاً.
      alignmentPolicy: tooTall
          ? ScrollPositionAlignmentPolicy.explicit
          : ScrollPositionAlignmentPolicy.keepVisibleAtEnd,
    );
  }

  @override
  void dispose() {
    _scrollTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final quiz = widget.quiz;
    final question = widget.question;

    final selected = quiz.selectedIndex ?? -1;
    // مساعدة التخطّي لا تُعرض كانتهاء وقت: اللاعب اختارها ولم يُخطئ.
    final skipped = quiz.answers.isNotEmpty && quiz.answers.last.skipped;
    final correct = selected >= 0 && question.isCorrect(selected);
    final color = correct
        ? AppColors.correct
        : skipped
            ? AppColors.gold
            : AppColors.wrong;

    final title = correct
        ? AppStrings.correct
        : skipped
            ? AppStrings.skippedAnswer
            : selected < 0
                ? AppStrings.timeUp
                : AppStrings.wrong;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: color.withValues(alpha: 0.6)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                correct
                    ? Icons.emoji_events_rounded
                    : skipped
                        ? Icons.skip_next_rounded
                        : Icons.info_rounded,
                color: color,
              ),
              const SizedBox(width: 8),
              // `Expanded` لا `Spacer`: عنوان «تخطّيت هذا السؤال» أطول من غيره،
              // ومع خط نظام كبير على شاشة ضيقة كان يفيض عن السطر.
              Expanded(
                child: Text(
                  title,
                  style: TextStyle(
                    color: color,
                    fontWeight: FontWeight.w800,
                    fontSize: 16,
                  ),
                ),
              ),
              if (correct)
                Text(
                  '+${quiz.answers.last.earnedPoints}',
                  style: TextStyle(
                    color: AppColors.gold,
                    fontWeight: FontWeight.w800,
                  ),
                ),
            ],
          ),
          if (!correct) ...[
            const SizedBox(height: 8),
            Text(
              AppStrings.correctAnswerIs(question.correctAnswer),
              style: const TextStyle(fontWeight: FontWeight.w700),
            ),
          ],
          if (question.explanation != null) ...[
            const SizedBox(height: 8),
            Text(
              question.explanation!,
              style: TextStyle(
                color: AppColors.chalkMuted,
                height: 1.5,
                fontSize: 13,
              ),
            ),
          ],
          // بعد كشف الإجابة فقط: الآن يعرف اللاعب إن كان يرى خطأً في السؤال،
          // والمؤقّت متوقف فلا يخسر وقتاً.
          Align(
            alignment: AlignmentDirectional.centerEnd,
            child: ReportQuestionButton(question: question),
          ),
        ],
      ),
    );
  }
}
