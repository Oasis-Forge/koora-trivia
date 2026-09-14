import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/constants/app_strings.dart';
import '../../core/theme/app_colors.dart';
import '../../domain/repositories/ad_service.dart';
import '../providers/ads_provider.dart';
import 'koora_buttons.dart';

/// زر إعلان مكافأ بحالاته الثلاث.
///
/// **يُعرض دائماً ولا يُخفى.** الزر المعطّل مع سبب واضح يُعلّم اللاعب أن
/// الخيار موجود؛ الزر المختفي يبدو كعطل في التطبيق.
class RewardedButton extends StatelessWidget {
  const RewardedButton({
    super.key,
    required this.label,
    required this.onEarned,
    this.dailyLimitReached = false,
    this.icon = Icons.play_circle_fill_rounded,
  });

  final String label;

  /// تُستدعى فقط عند إكمال الإعلان — لا عند إغلاقه مبكراً.
  final Future<void> Function() onEarned;

  final bool dailyLimitReached;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    final ads = context.watch<AdsProvider>();

    final String? disabledReason;
    if (dailyLimitReached) {
      disabledReason = AppStrings.adDailyLimitReached;
    } else if (!ads.isReady) {
      // غياب الإعلان يعني غالباً انقطاع الاتصال.
      disabledReason = AppStrings.adUnavailable;
    } else {
      disabledReason = null;
    }

    final enabled = disabledReason == null && !ads.isShowing;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        GoldButton(
          label: ads.isShowing ? AppStrings.adLoading : label,
          icon: ads.isShowing ? null : icon,
          onPressed: enabled ? () => _watch(context) : null,
        ),
        if (disabledReason != null)
          Padding(
            padding: const EdgeInsets.only(top: 6),
            child: Text(
              disabledReason,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: AppColors.chalkMuted,
              ),
            ),
          ),
      ],
    );
  }

  Future<void> _watch(BuildContext context) async {
    final messenger = ScaffoldMessenger.of(context);
    final result = await context.read<AdsProvider>().showRewarded();

    switch (result) {
      case RewardResult.earned:
        await onEarned();
        messenger
          ..hideCurrentSnackBar()
          ..showSnackBar(
            const SnackBar(content: Text(AppStrings.rewardGranted)),
          );
      case RewardResult.dismissed:
        messenger
          ..hideCurrentSnackBar()
          ..showSnackBar(
            const SnackBar(content: Text(AppStrings.adDismissed)),
          );
      case RewardResult.unavailable:
        messenger
          ..hideCurrentSnackBar()
          ..showSnackBar(
            const SnackBar(content: Text(AppStrings.adUnavailable)),
          );
    }
  }
}
