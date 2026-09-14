import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/constants/app_strings.dart';
import '../../core/theme/app_colors.dart';
import '../../domain/entities/category.dart';
import '../providers/progress_provider.dart';
import '../providers/quiz_provider.dart';
import '../widgets/category_card.dart';
import '../widgets/pitch_background.dart';
import 'levels_screen.dart';

class CategoriesScreen extends StatefulWidget {
  const CategoriesScreen({super.key});

  static const String routeName = '/categories';

  @override
  State<CategoriesScreen> createState() => _CategoriesScreenState();
}

class _CategoriesScreenState extends State<CategoriesScreen> {
  /// أيقونة لكل تصنيف حسب الـ slug، مع بديل عام لأي تصنيف جديد.
  static const Map<String, IconData> _icons = {
    'world_cup': Icons.public_rounded,
    'continental_cups': Icons.emoji_events_rounded,
    'champions_league': Icons.workspace_premium_rounded,
    'top_leagues': Icons.leaderboard_rounded,
    'arab_football': Icons.mosque_rounded,
    'players': Icons.person_rounded,
    'clubs': Icons.shield_rounded,
    'coaches': Icons.psychology_rounded,
    'laws': Icons.gavel_rounded,
    'moments_records': Icons.auto_awesome_rounded,
  };

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<QuizProvider>().loadCategories();
    });
  }

  @override
  Widget build(BuildContext context) {
    final categories = context.watch<QuizProvider>().categories;
    final progress = context.watch<ProgressProvider>();

    return Scaffold(
      body: PitchBackground(
        child: SafeArea(
          child: Column(
            children: [
              _Header(totalStars: progress.totalStars),
              Expanded(
                child: categories.isEmpty
                    ? const Center(child: CircularProgressIndicator())
                    : GridView.builder(
                        padding: const EdgeInsets.fromLTRB(20, 4, 20, 28),
                        gridDelegate:
                            const SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 2,
                          crossAxisSpacing: 12,
                          mainAxisSpacing: 12,
                          childAspectRatio: 0.95,
                        ),
                        itemCount: categories.length,
                        itemBuilder: (context, i) {
                          final category = categories[i];
                          return CategoryCard(
                            name: category.name,
                            icon: _icons[category.slug] ??
                                Icons.sports_soccer_rounded,
                            progress: progress.forCategory(category.slug),
                            onTap: () => _openLevels(category),
                          );
                        },
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _openLevels(Category category) {
    Navigator.of(context).pushNamed(
      LevelsScreen.routeName,
      arguments: category,
    );
  }
}

class _Header extends StatelessWidget {
  const _Header({required this.totalStars});

  final int totalStars;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(8, 8, 20, 12),
      child: Row(
        children: [
          IconButton(
            onPressed: () => Navigator.of(context).pop(),
            icon: const Icon(Icons.arrow_forward_rounded),
            color: AppColors.chalk,
          ),
          const Expanded(
            child: Text(
              AppStrings.chooseCategoryTitle,
              style: TextStyle(fontSize: 22, fontWeight: FontWeight.w900),
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
            decoration: BoxDecoration(
              color: AppColors.gold.withValues(alpha: 0.16),
              borderRadius: BorderRadius.circular(999),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.star_rounded,
                    size: 16, color: AppColors.gold),
                const SizedBox(width: 4),
                Text(
                  '$totalStars',
                  style: TextStyle(
                    color: AppColors.gold,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
