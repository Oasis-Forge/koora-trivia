import 'dart:async';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/constants/app_strings.dart';
import '../../core/theme/app_colors.dart';
import '../providers/economy_provider.dart';
import '../providers/quiz_provider.dart';
import '../providers/stats_provider.dart';
import '../widgets/banner_slot.dart';
import '../widgets/category_chips.dart';
import '../widgets/coin_badge.dart';
import '../widgets/daily_challenge_card.dart';
import '../widgets/hearts_bar.dart';
import '../widgets/koora_buttons.dart';
import '../widgets/pitch_background.dart';
import '../widgets/surface.dart';
import 'categories_screen.dart';
import 'quiz_screen.dart';
import 'settings_screen.dart';
import 'shop_screen.dart';
import 'tasks_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  static const String routeName = '/';

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  String? _categorySlug;
  Timer? _countdownTicker;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<QuizProvider>().loadCategories();
    });
    // تحديث العدّاد التنازلي لتحدي الغد كل دقيقة.
    _countdownTicker = Timer.periodic(const Duration(minutes: 1), (_) {
      if (mounted) setState(() {});
    });
  }

  @override
  void dispose() {
    _countdownTicker?.cancel();
    super.dispose();
  }

  Future<void> _play({required bool daily}) async {
    final quiz = context.read<QuizProvider>();
    if (daily) {
      await quiz.startDaily();
    } else {
      await quiz.startQuickPlay(categorySlug: _categorySlug);
    }
    if (!mounted) return;

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
    final stats = context.watch<StatsProvider>();
    final quiz = context.watch<QuizProvider>();

    return Scaffold(
      // الشريط الإعلاني أسفل المحتوى دائماً، لا داخل التمرير.
      bottomNavigationBar: const BannerSlot(),
      body: PitchBackground(
        child: SafeArea(
          child: ListView(
            padding: const EdgeInsets.fromLTRB(20, 18, 20, 24),
            children: [
              const _TopBar(),
              const SizedBox(height: 16),
              const _StatusRow(),
              const SizedBox(height: 16),
              DailyChallengeCard(
                isDone: stats.isDailyDone,
                streak: stats.streak,
                untilNext: stats.untilNextDaily,
                onPlay: () => _play(daily: true),
              ),
              const SizedBox(height: 16),
              _StatsCard(
                bestScore: stats.stats.bestScore,
                bestStreak: stats.bestStreak,
                streak: stats.streak,
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: Text(
                      AppStrings.chooseCategory,
                      style: TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                  _MoreButton(
                    onTap: () => Navigator.of(context)
                        .pushNamed(CategoriesScreen.routeName),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              CategoryChips(
                categories: quiz.categories,
                selectedSlug: _categorySlug,
                onSelected: (v) => setState(() => _categorySlug = v),
              ),
              const SizedBox(height: 16),
              SolidButton(
                label: AppStrings.quickPlay,
                icon: Icons.sports_soccer_rounded,
                onPressed: () => _play(daily: false),
              ),
              const SizedBox(height: 10),
              OutlineButton(
                label: AppStrings.levels,
                icon: Icons.grid_view_rounded,
                onPressed: () =>
                    Navigator.of(context).pushNamed(CategoriesScreen.routeName),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// اسم التطبيق وزر الإعدادات.
class _TopBar extends StatelessWidget {
  const _TopBar();

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Text(
            AppStrings.appName,
            style: TextStyle(
              fontSize: 22,
              height: 1.15,
              fontWeight: FontWeight.w900,
            ),
          ),
        ),
        const SizedBox(width: 12),
        Tooltip(
          message: AppStrings.settings,
          child: Surface(
            radius: 999,
            padding: EdgeInsets.zero,
            onTap: () =>
                Navigator.of(context).pushNamed(SettingsScreen.routeName),
            child: SizedBox(
              width: 48,
              height: 48,
              child: Icon(
                Icons.settings_rounded,
                size: 20,
                color: AppColors.chalk,
              ),
            ),
          ),
        ),
      ],
    );
  }
}

/// القلوب والعملات وزر المهام اليومية.
class _StatusRow extends StatelessWidget {
  const _StatusRow();

  @override
  Widget build(BuildContext context) {
    final claimable = context.watch<EconomyProvider>().claimableCount;

    return Row(
      children: [
        const HeartsBar(),
        const SizedBox(width: 8),
        CoinBadge(
          onTap: () => Navigator.of(context).pushNamed(ShopScreen.routeName),
        ),
        const SizedBox(width: 8),
        // مرن لا `Spacer`: على الهاتف الضيق يتقلّص نص الحبّة بدل أن يفيض الصف.
        Flexible(
          child: Align(
            alignment: AlignmentDirectional.centerEnd,
            child: Stack(
              clipBehavior: Clip.none,
              children: [
                StatusPill(
                  icon: Icons.checklist_rounded,
                  iconColor: AppColors.chalk,
                  label: AppStrings.tasks,
                  iconAtEnd: true,
                  onTap: () =>
                      Navigator.of(context).pushNamed(TasksScreen.routeName),
                ),
                if (claimable > 0)
                  PositionedDirectional(
                    top: -2,
                    end: -2,
                    child: Container(
                      width: 20,
                      height: 20,
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        color: AppColors.wrong,
                        shape: BoxShape.circle,
                      ),
                      child: Text(
                        '$claimable',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w900,
                          color: AppColors.chalk,
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

/// إحصائيات اللاعب الثلاث في بطاقة واحدة تفصلها خطوط رفيعة.
class _StatsCard extends StatelessWidget {
  const _StatsCard({
    required this.bestScore,
    required this.bestStreak,
    required this.streak,
  });

  final int bestScore;
  final int bestStreak;
  final int streak;

  @override
  Widget build(BuildContext context) {
    return Surface(
      padding: EdgeInsets.zero,
      child: Stack(
        alignment: Alignment.center,
        children: [
          // الكرة خلفية فقط: كانت تحدد ارتفاع البطاقة (170) فتبدو فارغة، والآن
          // تُقص عند حدود البطاقة ويحدد الصفُّ الارتفاع.
          Positioned.fill(
            // الحد الأدنى صفر: بدونه يرث عرض البطاقة (أكبر من 170) فتصير القيود
            // متناقضة، وهو خطأ لا يظهر إلا في نسخة التطوير.
            child: OverflowBox(
              minWidth: 0,
              minHeight: 0,
              maxWidth: 170,
              maxHeight: 170,
              child: Icon(
                Icons.sports_soccer,
                size: 170,
                color: Colors.white.withValues(alpha: 0.035),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 16),
            child: Row(
              children: [
                _Stat(
                  icon: Icons.star_rounded,
                  value: '$bestScore',
                  label: AppStrings.bestScore,
                ),
                _divider(),
                _Stat(
                  icon: Icons.emoji_events_rounded,
                  value: '$bestStreak',
                  label: AppStrings.bestStreak,
                ),
                _divider(),
                _Stat(
                  icon: Icons.event_available_rounded,
                  value: '$streak',
                  label: AppStrings.streak,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _divider() => Container(
        width: 1,
        height: 44,
        color: Colors.white.withValues(alpha: 0.11),
      );
}

class _Stat extends StatelessWidget {
  const _Stat({required this.icon, required this.value, required this.label});

  final IconData icon;
  final String value;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 19, color: AppColors.gold),
          const SizedBox(height: 4),
          Text(
            value,
            style: const TextStyle(
              fontSize: 20,
              height: 1.1,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 3),
          Text(
            label,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: AppColors.chalkMuted,
            ),
          ),
        ],
      ),
    );
  }
}

/// «المزيد» بجانب عنوان الفئات — يفتح شاشة التصنيفات.
class _MoreButton extends StatelessWidget {
  const _MoreButton({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final shape = BorderRadius.circular(999);

    return Material(
      color: Colors.white.withValues(alpha: 0.04),
      clipBehavior: Clip.antiAlias,
      shape: RoundedRectangleBorder(
        borderRadius: shape,
        side: BorderSide(color: AppColors.cardBorder),
      ),
      child: InkWell(
        onTap: onTap,
        child: SizedBox(
          height: 48,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 18),
            child: Center(
              child: Text(
                AppStrings.more,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: AppColors.gold,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
