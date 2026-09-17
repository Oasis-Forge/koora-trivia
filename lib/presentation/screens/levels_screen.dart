import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/constants/app_config.dart';
import '../../core/constants/app_strings.dart';
import '../../core/theme/app_colors.dart';
import '../../core/utils/arabic_count.dart';
import '../../domain/entities/category.dart';
import '../../domain/entities/question.dart';
import '../../domain/usecases/evaluate_level.dart';
import '../providers/progress_provider.dart';
import '../providers/quiz_provider.dart';
import '../widgets/banner_slot.dart';
import '../widgets/hearts_bar.dart';
import '../widgets/koora_app_bar.dart';
import '../widgets/koora_buttons.dart';
import '../widgets/level_tile.dart';
import '../widgets/pitch_background.dart';
import '../widgets/star_row.dart';
import '../widgets/surface.dart';
import 'quiz_screen.dart';

class LevelsScreen extends StatefulWidget {
  const LevelsScreen({super.key, required this.category});

  static const String routeName = '/levels';

  final Category category;

  @override
  State<LevelsScreen> createState() => _LevelsScreenState();
}

class _LevelsScreenState extends State<LevelsScreen> {
  static const int _columns = 3;
  static const double _spacing = 12;
  static const EdgeInsets _gridPadding = EdgeInsets.fromLTRB(20, 8, 20, 8);
  static const double _preferredAspectRatio = 1;

  /// أقصر مربّع يبقى مقروءاً (الرقم والنجوم). دونه تُمرَّر الشبكة بدل تقصيره.
  static const double _minTileHeight = 56;

  int? _selected;
  bool _starting = false;

  /// نسبة عرض المربّع إلى طوله بحيث تتسع الشبكة كلها للمساحة المتاحة.
  ///
  /// النسبة الثابتة جعلت الشبكة أطول من المساحة على شاشات 360×640 و411×731،
  /// والشبكة لم تكن قابلة للتمرير، فاختفى المستوى العاشر تحت الشريط السفلي. الآن
  /// يقصر المربّع حتى تتسع الصفوف، ولا يقصر عن حد أدنى.
  static double _tileAspectRatio(BoxConstraints constraints, int levelCount) {
    final rows = (levelCount / _columns).ceil();
    if (rows == 0) return _preferredAspectRatio;

    final tileWidth = (constraints.maxWidth -
            _gridPadding.horizontal -
            _spacing * (_columns - 1)) /
        _columns;
    final fitHeight = (constraints.maxHeight -
            _gridPadding.vertical -
            _spacing * (rows - 1)) /
        rows;

    final height = math.max(
      _minTileHeight,
      math.min(tileWidth / _preferredAspectRatio, fitHeight),
    );
    return tileWidth / height;
  }

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
    setState(() => _starting = true);

    // يفحص القلوب ويخصم قلب المحاولة — لا يمس تحدي اليوم ولا اللعب السريع.
    final quiz = context.read<QuizProvider>();
    final started = await NoHeartsDialog.startLevel(
      context,
      categorySlug: widget.category.slug,
      level: level,
    );

    if (!mounted) return;
    setState(() => _starting = false);
    if (!started) return;

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
      // الشريط الإعلاني أسفل المحتوى دائماً، لا داخل التمرير.
      bottomNavigationBar: const BannerSlot(),
      body: PitchBackground(
        child: SafeArea(
          bottom: false,
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 18, 20, 0),
                child: Column(
                  children: [
                    KooraAppBar(
                      title: widget.category.name,
                      subtitle: AppStrings.levelsProgress(
                        categoryProgress.completedLevels,
                        levelCount,
                      ),
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        const HeartsBar(compact: true),
                        const SizedBox(width: 8),
                        StatusPill(
                          icon: Icons.star_rounded,
                          label:
                              '${categoryProgress.totalStars} / ${categoryProgress.maxStars}',
                          labelColor: AppColors.gold,
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              // شبكة المستويات موسّطة عمودياً، ويقصر المربّع حتى تتسع الصفوف كلها.
              Expanded(
                child: LayoutBuilder(
                  builder: (context, constraints) => Center(
                    child: GridView.builder(
                      shrinkWrap: true,
                      padding: _gridPadding,
                      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: _columns,
                        crossAxisSpacing: _spacing,
                        mainAxisSpacing: _spacing,
                        childAspectRatio:
                            _tileAspectRatio(constraints, levelCount),
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
              ),
              _Footer(
                level: selected,
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
        SnackBar(
          content: Text(AppStrings.lockedLevel),
          duration: Duration(seconds: 2),
        ),
      );
  }
}

/// الشريط السفلي: المستوى المختار، عتبات الاجتياز والنجوم، كلفة المحاولة، وزر البدء.
class _Footer extends StatelessWidget {
  const _Footer({
    required this.level,
    required this.starting,
    required this.allDone,
    required this.onStart,
  });

  final int? level;
  final bool starting;
  final bool allDone;
  final VoidCallback? onStart;

  @override
  Widget build(BuildContext context) {
    final difficulty =
        level == null ? null : Question.difficultyForLevel(level!);
    // العتبات من التقييم نفسه لا أرقاماً مكتوبة، فتتبع أي تعديل في AppConfig.
    const evaluate = EvaluateLevel();
    const total = AppConfig.questionsPerLevel;
    final infoStyle = TextStyle(
      color: AppColors.chalkMuted,
      fontSize: 12,
      fontWeight: FontWeight.w700,
    );

    return Container(
      width: double.infinity,
      padding: EdgeInsets.fromLTRB(
        20,
        12,
        20,
        16 + MediaQuery.paddingOf(context).bottom,
      ),
      decoration: BoxDecoration(
        color: AppColors.pitchDark.withValues(alpha: 0.72),
        border: Border(
          top: BorderSide(color: Colors.white.withValues(alpha: 0.12)),
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (allDone) ...[
            Text(
              AppStrings.allLevelsDone,
              style: TextStyle(
                color: AppColors.gold,
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 8),
          ],
          if (level != null && difficulty != null) ...[
            Text(
              '${AppStrings.level} $level  ·  ${difficulty.arabicLabel}',
              style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w800),
            ),
            const SizedBox(height: 8),
            Text(
              AppStrings.levelGoal(
                pass: evaluate.minCorrectFor(1, total: total),
                twoStars: evaluate.minCorrectFor(2, total: total),
                threeStars: evaluate.minCorrectFor(3, total: total),
                total: total,
              ),
              textAlign: TextAlign.center,
              style: infoStyle,
            ),
            const SizedBox(height: 6),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.favorite_rounded, size: 14, color: AppColors.wrong),
                const SizedBox(width: 6),
                Flexible(
                  child: Text(
                    AppStrings.levelHeartCost,
                    textAlign: TextAlign.center,
                    style: infoStyle.copyWith(fontWeight: FontWeight.w600),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
          ],
          GoldButton(
            label: AppStrings.startLevel,
            icon: Icons.play_arrow_rounded,
            onPressed: starting ? null : onStart,
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

    return Surface(
      padding: const EdgeInsets.all(16),
      border: Border.all(color: color.withValues(alpha: 0.55)),
      color: Color.alphaBlend(color.withValues(alpha: 0.12), AppColors.cardSurface),
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
            Text(
              // من التقييم نفسه بدل الرقم 7 المكتوب في النص.
              AppStrings.levelFailedHint(
                ArabicCount.format(
                  const EvaluateLevel()
                      .minCorrectFor(1, total: AppConfig.questionsPerLevel),
                  ArabicNoun.correctAnswer,
                ),
              ),
              style: TextStyle(color: AppColors.chalkMuted, fontSize: 13),
            ),
          ],
          if (unlockedNext) ...[
            const SizedBox(height: 6),
            Text(
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
