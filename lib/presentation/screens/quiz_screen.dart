import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

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
                                  // المساحة الحرة تتوزّع بين بطاقة السؤال
                                  // وكتلة الخيارات لا بين كل خيار وآخر.
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceEvenly,
                                  children: [
                                    _QuestionCard(question: question),
                                    Column(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        for (var i = 0;
                                            i < question.options.length;
                                            i++)
                                          AnswerOption(
                                            label: question.options[i],
                                            index: i,
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
  const _QuestionCard({required this.question});

  final Question question;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.cardSurface,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: AppColors.cardBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              _Tag(text: question.categoryName, color: AppColors.pitchLight),
              const SizedBox(width: 8),
              _Tag(
                text: question.difficulty.arabicLabel,
                color: AppColors.gold,
              ),
            ],
          ),
          const SizedBox(height: 16),
          Text(
            question.text,
            style: const TextStyle(
              fontSize: 21,
              fontWeight: FontWeight.w800,
              height: 1.55,
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

class _FeedbackPanel extends StatelessWidget {
  const _FeedbackPanel({required this.quiz, required this.question});

  final QuizProvider quiz;
  final Question question;

  @override
  Widget build(BuildContext context) {
    final selected = quiz.selectedIndex ?? -1;
    final timedOut = selected < 0;
    final correct = !timedOut && question.isCorrect(selected);
    final color = correct ? AppColors.correct : AppColors.wrong;

    final title = correct
        ? AppStrings.correct
        : timedOut
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
                correct ? Icons.emoji_events_rounded : Icons.info_rounded,
                color: color,
              ),
              const SizedBox(width: 8),
              Text(
                title,
                style: TextStyle(
                  color: color,
                  fontWeight: FontWeight.w800,
                  fontSize: 16,
                ),
              ),
              const Spacer(),
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
              'الإجابة الصحيحة: ${question.correctAnswer}',
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
        ],
      ),
    );
  }
}
