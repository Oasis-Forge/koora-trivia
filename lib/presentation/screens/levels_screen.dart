import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/constants/app_strings.dart';
import '../../core/theme/app_colors.dart';
import '../../domain/entities/category.dart';
import '../../domain/entities/question.dart';
import '../providers/progress_provider.dart';
import '../providers/quiz_provider.dart';
import '../widgets/hearts_bar.dart';
import '../widgets/level_tile.dart';
import '../widgets/pitch_background.dart';
import '../widgets/star_row.dart';
import 'quiz_screen.dart';

class LevelsScreen extends StatefulWidget {
  const LevelsScreen({super.key, required this.category});

  static const String routeName = '/levels';

  final Category category;

  @override
  State<LevelsScreen> createState() => _LevelsScreenState();
}

class _LevelsScreenState extends State<LevelsScreen> {
  int? _selected;
  bool _starting = false;

  @override
  void initState() {
    super.initState();
    // نختار تلقائياً أول مستوى غير مكتمل ليجد اللاعب نفسه عند نقطة توقّفه.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final progress = context.read<ProgressProvider>();
      setState(() {
        _selected = progress.forCategory(widget.category.slug)
            .highestUnlockedLevel;
      });
    });
  }

  Future<void> _start(int level) async {
    if (_starting) return;

    // القلوب تُفحص قبل بدء المستوى فقط — لا تمس تحدي اليوم ولا اللعب السريع.
    if (!await NoHeartsDialog.ensureHearts(context)) return;
    if (!mounted) return;

    setState(() => _starting = true);
    final quiz = context.read<QuizProvider>();
    await quiz.startLevel(categorySlug: widget.category.slug, level: level);

    if (!mounted) return;
    setState(() => _starting = false);

    if (quiz.status == QuizStatus.error) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(quiz.errorMessage ?? AppStrings.errorTitle)),
      );
      return;
    }
    Navigator.of(context).pushNamed(QuizScreen.routeName);
  }

  @override
  Widget build(BuildContext context) {
    final progress = context.watch<ProgressProvider>();
    final categoryProgress = progress.forCategory(widget.category.slug);
    final levelCount = categoryProgress.levelCount;

    final selected = _selected;
    final canStart = selected != null && categoryProgress.isUnlocked(selected);

    return Scaffold(
      body: PitchBackground(
        child: SafeArea(
          child: Column(
            children: [
              _Header(
                title: widget.category.name,
                done: categoryProgress.completedLevels,
                total: levelCount,
                stars: categoryProgress.totalStars,
                maxStars: categoryProgress.maxStars,
              ),
              // شبكة المستويات موسّطة عمودياً: ثلاثة أعمدة تملأ الطول أفضل من
              // أربعة (التي تترك صفوفاً قليلة وفراغاً كبيراً أسفلها)، والتوسيط
              // يوزّع أي مساحة فائضة بدل تكديس البطاقات في الأعلى.
              Expanded(
                child: Center(
                  child: GridView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  padding: const EdgeInsets.fromLTRB(20, 8, 20, 16),
                  gridDelegate:
                      const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 3,
                    crossAxisSpacing: 14,
                    mainAxisSpacing: 14,
                    childAspectRatio: 0.95,
                  ),
                  itemCount: levelCount,
                  itemBuilder: (context, i) {
                    final level = i + 1;
                    final stars = categoryProgress.starsFor(level);
                    final unlocked = categoryProgress.isUnlocked(level);

                    final state = !unlocked
                        ? LevelState.locked
                        : stars > 0
                            ? LevelState.completed
                            : LevelState.available;

                    return LevelTile(
                      level: level,
                      state: state,
                      stars: stars,
                      isSelected: selected == level,
                      onTap: unlocked
                          ? () => setState(() => _selected = level)
                          : () => _showLockedHint(),
                    );
                  },
                  ),
                ),
              ),
              _Footer(
                level: selected,
                canStart: canStart,
                starting: _starting,
                allDone: categoryProgress.isFullyCompleted,
                onStart: canStart ? () => _start(selected) : null,
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showLockedHint() {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        const SnackBar(
          content: Text(AppStrings.lockedLevel),
          duration: Duration(seconds: 2),
        ),
      );
  }
}

class _Header extends StatelessWidget {
  const _Header({
    required this.title,
    required this.done,
    required this.total,
    required this.stars,
    required this.maxStars,
  });

  final String title;
  final int done;
  final int total;
  final int stars;
  final int maxStars;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(8, 8, 20, 4),
      child: Column(
        children: [
          Row(
            children: [
              IconButton(
                onPressed: () => Navigator.of(context).pop(),
                icon: const Icon(Icons.arrow_forward_rounded),
                color: AppColors.chalk,
              ),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        fontSize: 21,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '$done من $total ${AppStrings.levelsDone}',
                      style: const TextStyle(
                        fontSize: 12.5,
                        color: AppColors.chalkMuted,
                      ),
                    ),
                  ],
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  const HeartsBar(compact: true),
                  const SizedBox(height: 4),
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.star_rounded,
                          size: 15, color: AppColors.gold),
                      const SizedBox(width: 3),
                      Text(
                        '$stars / $maxStars',
                        style: const TextStyle(
                          color: AppColors.gold,
                          fontWeight: FontWeight.w800,
                          fontSize: 13,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _Footer extends StatelessWidget {
  const _Footer({
    required this.level,
    required this.canStart,
    required this.starting,
    required this.allDone,
    required this.onStart,
  });

  final int? level;
  final bool canStart;
  final bool starting;
  final bool allDone;
  final VoidCallback? onStart;

  @override
  Widget build(BuildContext context) {
    final difficulty =
        level == null ? null : Question.difficultyForLevel(level!);

    return Container(
      padding: const EdgeInsets.fromLTRB(20, 14, 20, 20),
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.22),
        border: const Border(top: BorderSide(color: AppColors.cardBorder)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (allDone) ...[
            const Text(
              AppStrings.allLevelsDone,
              style: TextStyle(
                color: AppColors.gold,
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 10),
          ],
          if (level != null && difficulty != null)
            Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: Text(
                '${AppStrings.level} $level  ·  ${difficulty.arabicLabel}'
                '  ·  10 أسئلة',
                style: const TextStyle(
                  color: AppColors.chalkMuted,
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          FilledButton.icon(
            onPressed: starting ? null : onStart,
            icon: starting
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(strokeWidth: 2.4),
                  )
                : const Icon(Icons.play_arrow_rounded),
            label: const Text(AppStrings.startLevel),
          ),
        ],
      ),
    );
  }
}

/// نجوم مصغّرة تُعرض في شاشة النتيجة عند إنهاء مستوى.
class LevelStarsBanner extends StatelessWidget {
  const LevelStarsBanner({
    super.key,
    required this.stars,
    required this.passed,
    required this.unlockedNext,
  });

  final int stars;
  final bool passed;
  final bool unlockedNext;

  @override
  Widget build(BuildContext context) {
    final color = passed ? AppColors.gold : AppColors.wrong;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: color.withValues(alpha: 0.55)),
      ),
      child: Column(
        children: [
          StarRow(earned: stars, size: 32),
          const SizedBox(height: 10),
          Text(
            passed ? AppStrings.levelPassed : AppStrings.levelFailed,
            style: TextStyle(
              color: color,
              fontWeight: FontWeight.w800,
              fontSize: 16,
            ),
          ),
          if (!passed) ...[
            const SizedBox(height: 4),
            const Text(
              AppStrings.levelFailedHint,
              style: TextStyle(color: AppColors.chalkMuted, fontSize: 13),
            ),
          ],
          if (unlockedNext) ...[
            const SizedBox(height: 6),
            const Text(
              AppStrings.nextLevelUnlocked,
              style: TextStyle(
                color: AppColors.correct,
                fontWeight: FontWeight.w700,
                fontSize: 13,
              ),
            ),
          ],
        ],
      ),
    );
  }
}
