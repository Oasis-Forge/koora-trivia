import 'dart:async';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/constants/app_strings.dart';
import '../../core/theme/app_colors.dart';
import '../../core/utils/arabic_count.dart';
import '../providers/quiz_provider.dart';
import '../providers/stats_provider.dart';
import '../widgets/category_chips.dart';
import '../widgets/daily_challenge_card.dart';
import '../widgets/pitch_background.dart';
import '../providers/economy_provider.dart';
import '../widgets/coin_badge.dart';
import '../widgets/hearts_bar.dart';
import '../widgets/stat_tile.dart';
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
      body: PitchBackground(
        child: SafeArea(
          child: ListView(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 32),
            children: [
              const _Header(),
              const SizedBox(height: 22),
              DailyChallengeCard(
                isDone: stats.isDailyDone,
                streak: stats.streak,
                untilNext: stats.untilNextDaily,
                onPlay: () => _play(daily: true),
              ),
              const SizedBox(height: 22),
              Row(
                children: [
                  Expanded(
                    child: StatTile(
                      icon: Icons.whatshot_rounded,
                      value: ArabicCount.format(stats.streak, ArabicNoun.day),
                      label: AppStrings.streak,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: StatTile(
                      icon: Icons.emoji_events_rounded,
                      value: '${stats.bestStreak}',
                      label: AppStrings.bestStreak,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: StatTile(
                      icon: Icons.star_rounded,
                      value: '${stats.stats.bestScore}',
                      label: AppStrings.bestScore,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 26),
              const Text(
                AppStrings.chooseCategory,
                style: TextStyle(fontSize: 17, fontWeight: FontWeight.w800),
              ),
              const SizedBox(height: 12),
              CategoryChips(
                categories: quiz.categories,
                selectedSlug: _categorySlug,
                onSelected: (v) => setState(() => _categorySlug = v),
              ),
              const SizedBox(height: 22),
              FilledButton.icon(
                onPressed: () => _play(daily: false),
                icon: const Icon(Icons.sports_soccer_rounded),
                label: const Text(AppStrings.quickPlay),
              ),
              const SizedBox(height: 12),
              OutlinedButton.icon(
                onPressed: () => Navigator.of(context)
                    .pushNamed(CategoriesScreen.routeName),
                icon: const Icon(Icons.grid_view_rounded),
                label: const Text(AppStrings.levels),
              ),
              const SizedBox(height: 14),
              Center(
                child: Text(
                  '${AppStrings.gamesPlayed}: ${stats.stats.gamesPlayed}',
                  style: TextStyle(
                    color: AppColors.chalkMuted,
                    fontSize: 13,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// زر المهام مع نقطة تنبيه حين توجد مكافأة جاهزة للاستلام.
class _TasksButton extends StatelessWidget {
  const _TasksButton();

  @override
  Widget build(BuildContext context) {
    final claimable = context.watch<EconomyProvider>().claimableCount;

    return Stack(
      clipBehavior: Clip.none,
      children: [
        OutlinedButton.icon(
          onPressed: () =>
              Navigator.of(context).pushNamed(TasksScreen.routeName),
          style: OutlinedButton.styleFrom(
            minimumSize: const Size(0, 40),
            padding: const EdgeInsets.symmetric(horizontal: 14),
          ),
          icon: const Icon(Icons.checklist_rounded, size: 18),
          label: const Text(
            AppStrings.tasks,
            style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700),
          ),
        ),
        if (claimable > 0)
          Positioned(
            top: -3,
            left: -3,
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
    );
  }
}

class _Header extends StatelessWidget {
  const _Header();

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
              width: 54,
              height: 54,
              decoration: BoxDecoration(
                gradient: AppColors.goldGradient,
                borderRadius: BorderRadius.circular(18),
              ),
              child: Icon(
                Icons.sports_soccer_rounded,
                color: AppColors.pitchDark,
                size: 32,
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    AppStrings.appName,
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.w900,
                      height: 1.2,
                    ),
                  ),
                  SizedBox(height: 4),
                  Text(
                    AppStrings.tagline,
                    style: TextStyle(
                      fontSize: 12.5,
                      color: AppColors.chalkMuted,
                      height: 1.4,
                    ),
                  ),
                ],
              ),
            ),
            IconButton(
              onPressed: () => Navigator.of(context)
                  .pushNamed(SettingsScreen.routeName),
              icon: const Icon(Icons.settings_rounded),
              color: AppColors.chalkMuted,
              tooltip: AppStrings.settings,
            ),
          ],
        ),
        const SizedBox(height: 14),
        Row(
          children: [
            const HeartsBar(),
            const SizedBox(width: 8),
            CoinBadge(
              onTap: () =>
                  Navigator.of(context).pushNamed(ShopScreen.routeName),
            ),
            const Spacer(),
            const _TasksButton(),
          ],
        ),
      ],
    );
  }
}
