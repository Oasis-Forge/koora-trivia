import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/constants/app_strings.dart';
import '../../core/theme/app_colors.dart';
import '../../domain/entities/category.dart';
import '../providers/progress_provider.dart';
import '../providers/quiz_provider.dart';
import '../widgets/banner_slot.dart';
import '../widgets/category_card.dart';
import '../widgets/koora_app_bar.dart';
import '../widgets/koora_buttons.dart';
import '../widgets/pitch_background.dart';
import '../widgets/surface.dart';
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
    final quiz = context.watch<QuizProvider>();
    final categories = quiz.categories;
    final progress = context.watch<ProgressProvider>();

    return Scaffold(
      // الشريط الإعلاني أسفل المحتوى دائماً، لا داخل التمرير.
      bottomNavigationBar: const BannerSlot(),
      body: PitchBackground(
        child: SafeArea(
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 18, 20, 16),
                child: KooraAppBar(
                  title: AppStrings.chooseCategoryTitle,
                  trailing: [
                    StatusPill(
                      icon: Icons.star_rounded,
                      label: '${progress.totalStars}',
                      labelColor: AppColors.gold,
                    ),
                  ],
                ),
              ),
              Expanded(
                child: categories.isEmpty
                    ? quiz.categoriesFailed
                        // كان الفشل يُبقي مؤشر التحميل يدور إلى الأبد.
                        ? Center(
                            child: Padding(
                              padding: const EdgeInsets.all(24),
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Text(
                                    AppStrings.loadCategoriesFailed,
                                    textAlign: TextAlign.center,
                                    style: TextStyle(
                                      color: AppColors.chalkMuted,
                                    ),
                                  ),
                                  const SizedBox(height: 14),
                                  GoldButton(
                                    label: AppStrings.retry,
                                    icon: Icons.refresh_rounded,
                                    onPressed: quiz.loadCategories,
                                  ),
                                ],
                              ),
                            ),
                          )
                        : const Center(child: CircularProgressIndicator())
                    : GridView.builder(
                        padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
                        gridDelegate:
                            const SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 2,
                          crossAxisSpacing: 12,
                          mainAxisSpacing: 12,
                          childAspectRatio: 1,
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
