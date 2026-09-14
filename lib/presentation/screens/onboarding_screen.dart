import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/constants/app_strings.dart';
import '../../core/theme/app_colors.dart';
import '../providers/settings_provider.dart';
import '../widgets/pitch_background.dart';

/// ثلاث بطاقات تشرح الأنماط والقلوب والسلسلة. تُعرض مرة واحدة فقط.
class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key, required this.onDone});

  final VoidCallback onDone;

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final PageController _controller = PageController();
  int _page = 0;

  static const List<({IconData icon, String title, String body})> _pages = [
    (
      icon: Icons.sports_soccer_rounded,
      title: AppStrings.onboard1Title,
      body: AppStrings.onboard1Body,
    ),
    (
      icon: Icons.favorite_rounded,
      title: AppStrings.onboard2Title,
      body: AppStrings.onboard2Body,
    ),
    (
      icon: Icons.local_fire_department_rounded,
      title: AppStrings.onboard3Title,
      body: AppStrings.onboard3Body,
    ),
  ];

  bool get _isLast => _page == _pages.length - 1;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _finish() async {
    await context.read<SettingsProvider>().markOnboardingSeen();
    widget.onDone();
  }

  void _next() {
    if (_isLast) {
      _finish();
      return;
    }
    _controller.nextPage(
      duration: const Duration(milliseconds: 280),
      curve: Curves.easeOut,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: PitchBackground(
        child: SafeArea(
          child: Column(
            children: [
              Align(
                alignment: AlignmentDirectional.centerStart,
                child: TextButton(
                  onPressed: _finish,
                  child: Text(
                    AppStrings.onboardSkip,
                    style: TextStyle(color: AppColors.chalkMuted),
                  ),
                ),
              ),
              Expanded(
                child: PageView.builder(
                  controller: _controller,
                  itemCount: _pages.length,
                  onPageChanged: (i) => setState(() => _page = i),
                  itemBuilder: (context, i) {
                    final page = _pages[i];
                    return Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 32),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Container(
                            width: 116,
                            height: 116,
                            decoration: BoxDecoration(
                              gradient: AppColors.goldGradient,
                              shape: BoxShape.circle,
                              boxShadow: [
                                BoxShadow(
                                  color:
                                      AppColors.gold.withValues(alpha: 0.32),
                                  blurRadius: 30,
                                ),
                              ],
                            ),
                            child: Icon(
                              page.icon,
                              size: 58,
                              color: AppColors.pitchDark,
                            ),
                          ),
                          const SizedBox(height: 34),
                          Text(
                            page.title,
                            textAlign: TextAlign.center,
                            style: const TextStyle(
                              fontSize: 24,
                              fontWeight: FontWeight.w900,
                              height: 1.3,
                            ),
                          ),
                          const SizedBox(height: 14),
                          Text(
                            page.body,
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontSize: 15,
                              height: 1.8,
                              color: AppColors.chalkMuted,
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                ),
              ),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  for (var i = 0; i < _pages.length; i++)
                    AnimatedContainer(
                      duration: const Duration(milliseconds: 220),
                      margin: const EdgeInsets.symmetric(horizontal: 4),
                      width: i == _page ? 22 : 8,
                      height: 8,
                      decoration: BoxDecoration(
                        color: i == _page
                            ? AppColors.gold
                            : Colors.white.withValues(alpha: 0.24),
                        borderRadius: BorderRadius.circular(999),
                      ),
                    ),
                ],
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(28, 24, 28, 24),
                child: FilledButton(
                  onPressed: _next,
                  child: Text(
                    _isLast ? AppStrings.onboardStart : AppStrings.onboardNext,
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
