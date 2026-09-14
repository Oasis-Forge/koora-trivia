import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/constants/app_config.dart';
import '../../core/constants/app_strings.dart';
import '../../core/theme/app_colors.dart';
import '../providers/economy_provider.dart';
import '../providers/quiz_provider.dart';
import '../providers/stats_provider.dart';
import '../screens/quiz_screen.dart';
import 'hearts_ticker.dart';
import 'rewarded_button.dart';

/// شارة القلوب مع الوقت المتبقي للقلب التالي.
class HeartsBar extends StatelessWidget {
  const HeartsBar({super.key, this.compact = false});

  final bool compact;

  @override
  Widget build(BuildContext context) {
    final economy = context.watch<EconomyProvider>();
    final empty = !economy.hasHearts;

    return HeartsTicker(
      child: Container(
        padding: EdgeInsets.symmetric(
          horizontal: compact ? 10 : 12,
          vertical: compact ? 6 : 8,
        ),
        decoration: BoxDecoration(
          color: (empty ? AppColors.wrong : AppColors.cardSurface)
              .withValues(alpha: empty ? 0.18 : 1),
          borderRadius: BorderRadius.circular(999),
          border: Border.all(
            color: empty ? AppColors.wrong : AppColors.cardBorder,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              empty ? Icons.heart_broken_rounded : Icons.favorite_rounded,
              size: compact ? 15 : 17,
              color: AppColors.wrong,
            ),
            const SizedBox(width: 5),
            Text(
              '${economy.hearts}/${economy.maxHearts}',
              style: TextStyle(
                fontSize: compact ? 13 : 14,
                fontWeight: FontWeight.w800,
                color: AppColors.chalk,
              ),
            ),
            if (!compact && economy.untilNextHeart != null) ...[
              const SizedBox(width: 8),
              Text(
                _format(economy.untilNextHeart!),
                style: TextStyle(
                  fontSize: 11.5,
                  color: AppColors.chalkMuted,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  static String _format(Duration d) {
    final minutes = d.inMinutes;
    if (minutes >= 60) return AppStrings.hoursShort(d.inHours);
    return AppStrings.minutesShort(minutes < 1 ? 1 : minutes);
  }
}

/// حوار يظهر عند محاولة بدء مستوى بلا قلوب.
///
/// يعرض كل طرق الحصول على قلب الآن: تحدي اليوم إن لم يُنجز، والإعلان، والشراء
/// بالعملات.
class NoHeartsDialog extends StatelessWidget {
  const NoHeartsDialog({super.key});

  static Future<void> show(BuildContext context) {
    return showDialog<void>(
      context: context,
      builder: (_) => const NoHeartsDialog(),
    );
  }

  /// بوابة كل زر يبدأ مستوى: يعيد `true` إن وُجد قلب، وإلا يعرض الحوار ويعيد `false`.
  ///
  /// كان الفحص في شاشة المستويات وحدها، فبدأ زرّا "إعادة المستوى" و"المستوى
  /// التالي" في شاشة النتيجة مستوى بلا قلوب، فيصبح اللعب مجانياً بلا حد.
  static Future<bool> ensureHearts(BuildContext context) async {
    final economy = context.read<EconomyProvider>()..refresh();
    if (economy.hasHearts) return true;
    await show(context);
    return false;
  }

  /// الطريق الوحيد لبدء مستوى: يفحص القلوب ثم يخصم قلب المحاولة، وتعيده شاشة
  /// النتيجة عند الاجتياز. فالإخفاق والخروج وإغلاق التطبيق وسط المستوى تكلّف قلباً
  /// واحداً للمحاولة كلها — كان كل خطأ يكلّف قلباً فتنفد الخمسة في محاولة واحدة.
  /// يعيد `false` إن لم يبدأ لنفاد القلوب.
  static Future<bool> startLevel(
    BuildContext context, {
    required String categorySlug,
    required int level,
  }) async {
    if (!await ensureHearts(context)) return false;
    if (!context.mounted) return false;
    final quiz = context.read<QuizProvider>();
    final economy = context.read<EconomyProvider>();

    await quiz.startLevel(categorySlug: categorySlug, level: level);
    // تعذّر تحميل الأسئلة: لم تبدأ محاولة فلا يُخصم قلب.
    if (quiz.status == QuizStatus.playing) await economy.consumeHeart();
    return true;
  }

  @override
  Widget build(BuildContext context) {
    final economy = context.watch<EconomyProvider>();
    // بعد إنجاز تحدي اليوم لا معنى لاقتراحه: قلبه مُنح بالفعل.
    final dailyDone = context.watch<StatsProvider>().isDailyDone;
    final untilNext = economy.untilNextHeart;

    // قلب تجدّد والحوار مفتوح، أو مُنح بإعلان أو شراء: لم يعد للحوار سبب، وبقاؤه
    // يقول «نفدت قلوبك» ويعدّ إلى القلب الثاني.
    if (economy.hasHearts) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (context.mounted) _close(context);
      });
    }

    return HeartsTicker(
      child: AlertDialog(
        backgroundColor: AppColors.cardSurface,
        // أربعة خيارات قد لا تتسع لها الشاشات الصغيرة.
        scrollable: true,
        title: Row(
          children: [
            Icon(Icons.heart_broken_rounded, color: AppColors.wrong),
            SizedBox(width: 8),
            Text(AppStrings.noHeartsTitle),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              dailyDone
                  ? AppStrings.noHeartsBodyDailyDone
                  : AppStrings.noHeartsBody,
              style: const TextStyle(height: 1.6),
            ),
            if (untilNext != null) ...[
              const SizedBox(height: 12),
              Text(
                '${AppStrings.nextHeartIn} ${HeartsBar._format(untilNext)}',
                style: TextStyle(
                  color: AppColors.gold,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
            const SizedBox(height: 18),
            if (!dailyDone) ...[
              FilledButton.icon(
                onPressed: () => _playDaily(context),
                icon: const Icon(Icons.local_fire_department_rounded),
                label: const Text(AppStrings.playDailyForHeart),
              ),
              const SizedBox(height: 10),
            ],
            RewardedButton(
              label: AppStrings.watchAdForHeart,
              icon: Icons.favorite_rounded,
              dailyLimitReached: economy.rewardedRefillsLeft <= 0,
              onEarned: () async {
                await context.read<EconomyProvider>().grantRewardedHearts();
                if (context.mounted) _close(context);
              },
            ),
            const SizedBox(height: 10),
            OutlinedButton.icon(
              onPressed:
                  economy.canBuyHeartsRefill ? () => _buyRefill(context) : null,
              icon: const Icon(Icons.monetization_on_rounded),
              label: Text(
                '${AppStrings.refillHearts} · ${AppConfig.priceHeartsRefill}',
              ),
            ),
            if (!economy.canBuyHeartsRefill)
              Padding(
                padding: EdgeInsets.only(top: 6),
                child: Text(
                  AppStrings.notEnoughCoins,
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 12, color: AppColors.chalkMuted),
                ),
              ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => _close(context),
            child: const Text(AppStrings.ok),
          ),
        ],
      ),
    );
  }

  /// يغلق الحوار إن كان ما زال في الأعلى.
  ///
  /// الإغلاق يُطلب من أكثر من مكان (قلب تجدّد، شراء اكتمل حفظه، زر «حسناً»)،
  /// و`pop` غير مشروط بعد انتظار يغلق الشاشة التي تحت الحوار إن كان قد أُغلق.
  static void _close(BuildContext context) {
    final route = ModalRoute.of(context);
    if (route != null && route.isCurrent) Navigator.of(context).pop();
  }

  /// يغلق الحوار ويبدأ تحدي اليوم — مجاني دائماً ويمنح قلباً عند إكماله.
  Future<void> _playDaily(BuildContext context) async {
    final navigator = Navigator.of(context);
    final messenger = ScaffoldMessenger.of(context);
    final quiz = context.read<QuizProvider>();

    _close(context);
    await quiz.startDaily();

    if (quiz.status == QuizStatus.error) {
      messenger.showSnackBar(
        SnackBar(content: Text(quiz.errorMessage ?? AppStrings.errorTitle)),
      );
      return;
    }
    navigator.pushNamed(QuizScreen.routeName);
  }

  Future<void> _buyRefill(BuildContext context) async {
    final messenger = ScaffoldMessenger.of(context);
    if (!await context.read<EconomyProvider>().buyHeartsRefill()) return;

    // الحوار يُغلق وحده حين تمتلئ القلوب، غالباً قبل اكتمال الحفظ.
    if (context.mounted) _close(context);
    messenger
      ..hideCurrentSnackBar()
      ..showSnackBar(const SnackBar(content: Text(AppStrings.purchased)));
  }
}
