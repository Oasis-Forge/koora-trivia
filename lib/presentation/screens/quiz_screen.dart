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
import '../widgets/hearts_bar.dart';
import '../widgets/hint_bar.dart';
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

class _QuizScreenState extends State<QuizScreen> {
  bool _navigated = false;

  Future<bool> _confirmQuit() async {
    final leave = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppColors.cardSurface,
        title: const Text(AppStrings.quitTitle),
        content: const Text(AppStrings.quitBody),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text(AppStrings.quitCancel),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text(
              AppStrings.quitConfirm,
              style: TextStyle(color: AppColors.wrong),
            ),
          ),
        ],
      ),
    );
    return leave ?? false;
  }

  /// اختيار إجابة، مع خصم قلب عند الخطأ في نمط المستويات وحده.
  Future<void> _answer(int index) async {
    final quiz = context.read<QuizProvider>();
    final wasLevelMode = quiz.isLevelMode;
    final question = quiz.currentQuestion;
    if (question == null) return;

    final correct = question.isCorrect(index);
    final feedback = context.read<SettingsProvider>().feedback;

    quiz.selectAnswer(index);
    if (correct) {
      feedback.correct();
    } else {
      feedback.wrong();
    }
    if (!mounted) return;

    final economy = context.read<EconomyProvider>();

    // مهمة الإجابات الصحيحة تُحتسب في كل الأنماط.
    if (correct) {
      await economy.recordCorrectAnswer();
    } else if (wasLevelMode) {
      await economy.consumeHeart();
    }
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
                        child: CustomScrollView(
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
                      if (quiz.isLevelMode && !quiz.isAnswerRevealed)
                        const HintBar(),
                      if (quiz.isAnswerRevealed)
                        Padding(
                          padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
                          child: FilledButton.icon(
                            onPressed: () =>
                                context.read<QuizProvider>().next(),
                            icon: Icon(
                              quiz.isLastQuestion
                                  ? Icons.flag_rounded
                                  : Icons.arrow_back_rounded,
                            ),
                            label: Text(
                              quiz.isLastQuestion
                                  ? AppStrings.finish
                                  : AppStrings.next,
                            ),
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

class _TopBar extends StatelessWidget {
  const _TopBar({required this.quiz, required this.onQuit});

  final QuizProvider quiz;
  final Future<void> Function() onQuit;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 4),
      child: Column(
        children: [
          Row(
            children: [
              IconButton(
                onPressed: onQuit,
                icon: const Icon(Icons.close_rounded),
                color: AppColors.chalkMuted,
              ),
              if (quiz.isLevelMode) const HeartsBar(compact: true),
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
                      style: const TextStyle(
                        color: AppColors.gold,
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              ),
              TimerRing(secondsLeft: quiz.secondsLeft),
            ],
          ),
          const SizedBox(height: 10),
          ClipRRect(
            borderRadius: BorderRadius.circular(999),
            child: LinearProgressIndicator(
              value: quiz.progress,
              minHeight: 7,
              backgroundColor: Colors.white.withValues(alpha: 0.10),
              valueColor:
                  const AlwaysStoppedAnimation<Color>(AppColors.pitchLight),
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
    return Container(
      // عرض كامل صراحةً: صف الوسوم كان يمدّ البطاقة ضمناً، و`Wrap` لا يفعل،
      // فتضيق بطاقة السؤال القصير عن الخيارات تحتها.
      width: double.infinity,
      padding: EdgeInsets.all(compact ? 16 : 20),
      decoration: BoxDecoration(
        color: AppColors.cardSurface,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: AppColors.cardBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // `Wrap` لا `Row`: اسم تصنيف طويل مع خط نظام كبير لا يتسع لسطر واحد.
          Wrap(
            spacing: 8,
            runSpacing: 6,
            children: [
              _Tag(text: question.categoryName, color: AppColors.pitchLight),
              _Tag(
                text: question.difficulty.arabicLabel,
                color: AppColors.gold,
              ),
            ],
          ),
          SizedBox(height: compact ? 10 : 16),
          Text(
            question.text,
            style: TextStyle(
              fontSize: compact ? 18 : 21,
              fontWeight: FontWeight.w800,
              height: compact ? 1.45 : 1.55,
            ),
          ),
        ],
      ),
    );
  }
}

class _Tag extends StatelessWidget {
  const _Tag({required this.text, required this.color});

  final String text;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.18),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: color.withValues(alpha: 0.5)),
      ),
      child: Text(
        text,
        style: TextStyle(
          color: color,
          fontSize: 12,
          fontWeight: FontWeight.w700,
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
                  style: const TextStyle(
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
              style: const TextStyle(
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
