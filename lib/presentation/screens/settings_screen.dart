import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../../domain/repositories/app_info.dart';
import '../../domain/repositories/backup_repository.dart';
import '../../domain/repositories/error_log.dart';
import '../../domain/repositories/link_opener.dart';
import '../../domain/usecases/build_feedback_email.dart';

import '../../core/constants/app_config.dart';
import '../../core/constants/app_strings.dart';
import '../../core/theme/app_colors.dart';
import '../../core/utils/arabic_count.dart';
import '../providers/ads_provider.dart';
import '../providers/economy_provider.dart';
import '../providers/progress_provider.dart';
import '../providers/quiz_provider.dart';
import '../providers/restore_backup.dart';
import '../providers/settings_provider.dart';
import '../providers/stats_provider.dart';
import '../widgets/pitch_background.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  static const String routeName = '/settings';

  @override
  Widget build(BuildContext context) {
    final stats = context.watch<StatsProvider>();
    final progress = context.watch<ProgressProvider>();
    final categoryCount = context.watch<QuizProvider>().categories.length;

    final maxLevels = categoryCount * AppConfig.levelsPerCategory;
    final maxStars = maxLevels * 3;

    return Scaffold(
      body: PitchBackground(
        child: SafeArea(
          child: Column(
            children: [
              _Header(),
              Expanded(
                child: ListView(
                  padding: const EdgeInsets.fromLTRB(20, 4, 20, 28),
                  children: [
                    const _SectionTitle(AppStrings.yourStats),
                    _StatsPanel(
                      rows: [
                        (
                          Icons.whatshot_rounded,
                          AppStrings.streak,
                          ArabicCount.format(stats.streak, ArabicNoun.day),
                        ),
                        (
                          Icons.emoji_events_rounded,
                          AppStrings.bestStreak,
                          '${stats.bestStreak}',
                        ),
                        (
                          Icons.star_rounded,
                          AppStrings.bestScore,
                          '${stats.stats.bestScore}',
                        ),
                        (
                          Icons.functions_rounded,
                          AppStrings.totalScore,
                          '${stats.stats.totalScore}',
                        ),
                        (
                          Icons.sports_esports_rounded,
                          AppStrings.gamesPlayed,
                          '${stats.stats.gamesPlayed}',
                        ),
                        (
                          Icons.grid_view_rounded,
                          AppStrings.completedLevels,
                          maxLevels == 0
                              ? '${progress.totalCompletedLevels}'
                              : '${progress.totalCompletedLevels} / $maxLevels',
                        ),
                        (
                          Icons.auto_awesome_rounded,
                          AppStrings.totalStars,
                          maxStars == 0
                              ? '${progress.totalStars}'
                              : '${progress.totalStars} / $maxStars',
                        ),
                      ],
                    ),

                    const SizedBox(height: 26),
                    const _SectionTitle(AppStrings.reminderSection),
                    const _ReminderPanel(),

                    const SizedBox(height: 26),
                    const _SectionTitle(AppStrings.effectsSection),
                    const _EffectsPanel(),

                    const SizedBox(height: 26),
                    const _SectionTitle(AppStrings.themeSection),
                    const _ThemePanel(),

                    const SizedBox(height: 26),
                    const _SectionTitle(AppStrings.backupSection),
                    const _BackupPanel(),

                    const SizedBox(height: 26),
                    const _SectionTitle(AppStrings.dataSection),
                    _DangerButton(
                      icon: Icons.restart_alt_rounded,
                      label: AppStrings.resetStats,
                      enabled: stats.stats.gamesPlayed > 0,
                      onConfirmed: () => context.read<StatsProvider>().resetAll(),
                      body: AppStrings.resetStatsBody,
                    ),
                    const SizedBox(height: 10),
                    _DangerButton(
                      icon: Icons.lock_reset_rounded,
                      label: AppStrings.resetProgress,
                      enabled: progress.hasProgress,
                      // نذكر الخسارة بالأرقام لأن هذا الإجراء يمحو كل النجوم.
                      body: '${AppStrings.resetProgressBody}\n\n'
                          '${AppStrings.resetProgressLoss(
                        ArabicCount.format(
                          progress.totalStars,
                          ArabicNoun.star,
                          object: true,
                        ),
                        ArabicCount.format(
                          progress.totalCompletedLevels,
                          ArabicNoun.level,
                          object: true,
                        ),
                      )}',
                      onConfirmed: () =>
                          context.read<ProgressProvider>().resetAll(),
                    ),

                    const SizedBox(height: 26),
                    const _SectionTitle(AppStrings.privacySection),
                    const _PrivacyPanel(),

                    const SizedBox(height: 26),
                    const _SectionTitle(AppStrings.aboutSection),
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: AppColors.cardSurface,
                        borderRadius: BorderRadius.circular(18),
                        border: Border.all(color: AppColors.cardBorder),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            AppStrings.appName,
                            style: TextStyle(
                              fontWeight: FontWeight.w800,
                              fontSize: 16,
                            ),
                          ),
                          SizedBox(height: 6),
                          _VersionText(),
                          SizedBox(height: 10),
                          Text(
                            AppStrings.bankSummary,
                            style: TextStyle(
                              color: AppColors.chalkMuted,
                              fontSize: 13,
                              height: 1.6,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 12),
                    const _FeedbackButton(),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// رقم الإصدار كما بُني فعلاً — كان نصاً ثابتاً «1.0.0» لم يُحدَّث قط.
class _VersionText extends StatefulWidget {
  const _VersionText();

  @override
  State<_VersionText> createState() => _VersionTextState();
}

class _VersionTextState extends State<_VersionText> {
  late final Future<String> _version = context.read<AppInfo>().version();

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<String>(
      future: _version,
      builder: (context, snapshot) => Text(
        snapshot.hasData ? AppStrings.appVersion(snapshot.data!) : '',
        style: TextStyle(color: AppColors.chalkMuted, fontSize: 13),
      ),
    );
  }
}

/// رسالة ملاحظات إلى المطوّر، مع رقم الإصدار وآخر الأخطاء المسجّلة على الجهاز.
class _FeedbackButton extends StatelessWidget {
  const _FeedbackButton();

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        OutlinedButton.icon(
          onPressed: () => _send(context),
          icon: const Icon(Icons.mail_outline_rounded),
          label: const Text(AppStrings.sendFeedback),
        ),
        Padding(
          padding: EdgeInsets.only(top: 6),
          child: Text(
            AppStrings.sendFeedbackHint,
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 12, color: AppColors.chalkMuted),
          ),
        ),
      ],
    );
  }

  Future<void> _send(BuildContext context) async {
    final linkOpener = context.read<LinkOpener>();
    final appInfo = context.read<AppInfo>();
    final errorLog = context.read<ErrorLog>();
    final messenger = ScaffoldMessenger.of(context);

    final draft = const BuildFeedbackEmail()(
      version: await appInfo.version(),
      errors: await errorLog.recent(),
    );
    if (await linkOpener.open(draft.toMailtoUri())) return;

    messenger
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(content: Text(AppStrings.noEmailApp(AppConfig.contactEmail))),
      );
  }
}

class _Header extends StatelessWidget {
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
          const Text(
            AppStrings.settings,
            style: TextStyle(fontSize: 22, fontWeight: FontWeight.w900),
          ),
        ],
      ),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  const _SectionTitle(this.text);

  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10, right: 4),
      child: Text(
        text,
        style: TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.w800,
          color: AppColors.gold,
        ),
      ),
    );
  }
}

class _StatsPanel extends StatelessWidget {
  const _StatsPanel({required this.rows});

  final List<(IconData, String, String)> rows;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.cardSurface,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColors.cardBorder),
      ),
      child: Column(
        children: [
          for (var i = 0; i < rows.length; i++) ...[
            if (i > 0) const Divider(height: 1, thickness: 1),
            Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 13,
              ),
              child: Row(
                children: [
                  Icon(rows[i].$1, size: 19, color: AppColors.gold),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      rows[i].$2,
                      style: const TextStyle(fontSize: 14.5),
                    ),
                  ),
                  Text(
                    rows[i].$3,
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w800,
                      color: AppColors.chalk,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _ReminderPanel extends StatelessWidget {
  const _ReminderPanel();

  @override
  Widget build(BuildContext context) {
    final settings = context.watch<SettingsProvider>();

    // اللون على `Material` لا على `Container`، وإلا اختفى أثر اللمس في
    // عناصر ListTile لأنها ترسمه على أقرب Material أعلاها.
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColors.cardBorder),
      ),
      child: Material(
        color: AppColors.cardSurface,
        borderRadius: BorderRadius.circular(18),
        clipBehavior: Clip.antiAlias,
        child: Column(
          children: [
            SwitchListTile(
              value: settings.reminderEnabled,
              onChanged: (value) => _toggle(context, value),
              activeThumbColor: AppColors.gold,
              title: const Text(
                AppStrings.reminderToggle,
                style: TextStyle(fontSize: 14.5, fontWeight: FontWeight.w700),
              ),
              subtitle: Text(
                AppStrings.reminderToggleHint,
                style: TextStyle(
                  fontSize: 12.5,
                  color: AppColors.chalkMuted,
                  height: 1.5,
                ),
              ),
            ),
            if (settings.reminderEnabled) ...[
              const Divider(height: 1, thickness: 1),
              ListTile(
                onTap: () => _pickTime(context, settings),
                leading: Icon(
                  Icons.schedule_rounded,
                  size: 20,
                  color: AppColors.gold,
                ),
                title: const Text(
                  AppStrings.reminderTime,
                  style: TextStyle(fontSize: 14.5),
                ),
                trailing: Text(
                  settings.reminderLabel,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                    color: AppColors.gold,
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Future<void> _toggle(BuildContext context, bool value) async {
    final messenger = ScaffoldMessenger.of(context);
    final granted =
        await context.read<SettingsProvider>().setReminderEnabled(value);

    if (!granted) {
      messenger
        ..hideCurrentSnackBar()
        ..showSnackBar(
          const SnackBar(content: Text(AppStrings.reminderDenied)),
        );
    }
  }

  Future<void> _pickTime(
    BuildContext context,
    SettingsProvider settings,
  ) async {
    final picked = await showTimePicker(
      context: context,
      initialTime: TimeOfDay(
        hour: settings.settings.reminderHour,
        minute: settings.settings.reminderMinute,
      ),
    );
    if (picked == null || !context.mounted) return;

    await context
        .read<SettingsProvider>()
        .setReminderTime(hour: picked.hour, minute: picked.minute);
  }
}

class _EffectsPanel extends StatelessWidget {
  const _EffectsPanel();

  @override
  Widget build(BuildContext context) {
    final settings = context.watch<SettingsProvider>();

    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColors.cardBorder),
      ),
      child: Material(
        color: AppColors.cardSurface,
        borderRadius: BorderRadius.circular(18),
        clipBehavior: Clip.antiAlias,
        child: Column(
          children: [
            SwitchListTile(
              value: settings.soundEnabled,
              activeThumbColor: AppColors.gold,
              onChanged: (v) =>
                  context.read<SettingsProvider>().setSoundEnabled(v),
              secondary: Icon(
                Icons.volume_up_rounded,
                color: AppColors.gold,
                size: 20,
              ),
              title: const Text(
                AppStrings.soundToggle,
                style: TextStyle(fontSize: 14.5),
              ),
            ),
            const Divider(height: 1, thickness: 1),
            SwitchListTile(
              value: settings.hapticsEnabled,
              activeThumbColor: AppColors.gold,
              onChanged: (v) =>
                  context.read<SettingsProvider>().setHapticsEnabled(v),
              secondary: Icon(
                Icons.vibration_rounded,
                color: AppColors.gold,
                size: 20,
              ),
              title: const Text(
                AppStrings.hapticsToggle,
                style: TextStyle(fontSize: 14.5),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// اختيار مظهر الألوان: عيّنة لكل مظهر، والمختار محاط بالذهبي.
class _ThemePanel extends StatelessWidget {
  const _ThemePanel();

  static const Map<String, String> _names = {
    'green': AppStrings.themeGreen,
    'blue': AppStrings.themeBlue,
    'purple': AppStrings.themePurple,
    'red': AppStrings.themeRed,
  };

  @override
  Widget build(BuildContext context) {
    final selected =
        context.select<SettingsProvider, String>((s) => s.themeId);

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        for (final palette in AppPalette.all)
          Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 4),
              child: _ThemeSwatch(
                palette: palette,
                label: _names[palette.id]!,
                selected: palette.id == selected,
                onTap: () =>
                    context.read<SettingsProvider>().setThemeId(palette.id),
              ),
            ),
          ),
      ],
    );
  }
}

class _ThemeSwatch extends StatelessWidget {
  const _ThemeSwatch({
    required this.palette,
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final AppPalette palette;
  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      selected: selected,
      label: label,
      excludeSemantics: true,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Column(
          children: [
            AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              height: 56,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(16),
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [palette.pitchLight, palette.pitchDark],
                ),
                border: Border.all(
                  color: selected ? palette.gold : AppColors.cardBorder,
                  width: selected ? 2.5 : 1,
                ),
              ),
              child: selected
                  ? Icon(Icons.check_rounded, color: palette.gold)
                  : null,
            ),
            const SizedBox(height: 6),
            Text(
              label,
              textAlign: TextAlign.center,
              maxLines: 2,
              style: TextStyle(
                fontSize: 12,
                color: selected ? AppColors.chalk : AppColors.chalkMuted,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// خيارات خصوصية الإعلانات وسياسة الخصوصية.
class _PrivacyPanel extends StatelessWidget {
  const _PrivacyPanel();

  @override
  Widget build(BuildContext context) {
    final ads = context.watch<AdsProvider>();

    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColors.cardBorder),
      ),
      child: Material(
        color: AppColors.cardSurface,
        borderRadius: BorderRadius.circular(18),
        clipBehavior: Clip.antiAlias,
        child: Column(
          children: [
            // غوغل تشترط مدخلاً دائماً لتعديل الموافقة حيث تكون مطلوبة (أوروبا
            // مثلاً)، ويختفي حيث لا يلزم حتى لا يحيّر بقية اللاعبين.
            if (ads.isPrivacyOptionsRequired) ...[
              ListTile(
                onTap: () => _openPrivacyOptions(context),
                leading: Icon(
                  Icons.privacy_tip_rounded,
                  size: 20,
                  color: AppColors.gold,
                ),
                title: const Text(
                  AppStrings.adPrivacyOptions,
                  style: TextStyle(fontSize: 14.5),
                ),
              ),
              const Divider(height: 1, thickness: 1),
            ],
            ListTile(
              onTap: () => _openPolicy(context),
              leading: Icon(
                Icons.policy_rounded,
                size: 20,
                color: AppColors.gold,
              ),
              title: const Text(
                AppStrings.privacyPolicy,
                style: TextStyle(fontSize: 14.5),
              ),
              trailing: Icon(
                Icons.open_in_new_rounded,
                size: 18,
                color: AppColors.chalkMuted,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _openPrivacyOptions(BuildContext context) async {
    final messenger = ScaffoldMessenger.of(context);
    final shown = await context.read<AdsProvider>().showPrivacyOptions();
    if (shown) return;

    messenger
      ..hideCurrentSnackBar()
      ..showSnackBar(
        const SnackBar(content: Text(AppStrings.privacyOptionsFailed)),
      );
  }

  Future<void> _openPolicy(BuildContext context) async {
    final messenger = ScaffoldMessenger.of(context);
    final opened = await context
        .read<LinkOpener>()
        .open(Uri.parse(AppConfig.privacyPolicyUrl));
    if (opened) return;

    messenger
      ..hideCurrentSnackBar()
      ..showSnackBar(const SnackBar(content: Text(AppStrings.linkOpenFailed)));
  }
}

/// تصدير واستيراد التقدّم — البديل المحلي عن الحفظ السحابي.
class _BackupPanel extends StatelessWidget {
  const _BackupPanel();

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Padding(
          padding: EdgeInsets.only(bottom: 12, right: 4, left: 4),
          child: Text(
            AppStrings.backupHint,
            style: TextStyle(
              fontSize: 12.5,
              color: AppColors.chalkMuted,
              height: 1.6,
            ),
          ),
        ),
        OutlinedButton.icon(
          onPressed: () => _export(context),
          icon: const Icon(Icons.copy_rounded),
          label: const Text(AppStrings.exportBackup),
        ),
        const SizedBox(height: 10),
        OutlinedButton.icon(
          onPressed: () => _import(context),
          icon: const Icon(Icons.download_rounded),
          label: const Text(AppStrings.importBackup),
        ),
      ],
    );
  }

  Future<void> _export(BuildContext context) async {
    final messenger = ScaffoldMessenger.of(context);
    final code = await context.read<BackupRepository>().export();

    await Clipboard.setData(ClipboardData(text: code));
    messenger
      ..hideCurrentSnackBar()
      ..showSnackBar(const SnackBar(content: Text(AppStrings.backupCopied)));
  }

  Future<void> _import(BuildContext context) async {
    final controller = TextEditingController();
    final messenger = ScaffoldMessenger.of(context);
    final restore = RestoreBackup(
      repository: context.read<BackupRepository>(),
      stats: context.read<StatsProvider>(),
      progress: context.read<ProgressProvider>(),
      economy: context.read<EconomyProvider>(),
      settings: context.read<SettingsProvider>(),
    );

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        backgroundColor: AppColors.cardSurface,
        title: const Text(AppStrings.importTitle),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(AppStrings.importBody, style: TextStyle(height: 1.6)),
            const SizedBox(height: 14),
            TextField(
              controller: controller,
              maxLines: 3,
              minLines: 2,
              style: const TextStyle(fontSize: 12),
              decoration: const InputDecoration(
                border: OutlineInputBorder(),
                isDense: true,
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: const Text(AppStrings.cancel),
          ),
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: Text(
              AppStrings.importConfirm,
              style: TextStyle(
                color: AppColors.wrong,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    final ok = await restore(controller.text);
    messenger
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text(
            ok ? AppStrings.importSuccess : AppStrings.importFailed,
          ),
        ),
      );
  }
}

/// زر إجراء مدمّر — لا ينفّذ شيئاً قبل تأكيد صريح في حوار منفصل.
class _DangerButton extends StatelessWidget {
  const _DangerButton({
    required this.icon,
    required this.label,
    required this.body,
    required this.enabled,
    required this.onConfirmed,
  });

  final IconData icon;
  final String label;
  final String body;
  final bool enabled;
  final Future<void> Function() onConfirmed;

  @override
  Widget build(BuildContext context) {
    return OutlinedButton.icon(
      onPressed: enabled ? () => _confirm(context) : null,
      style: OutlinedButton.styleFrom(
        foregroundColor: AppColors.wrong,
        side: BorderSide(
          color: enabled
              ? AppColors.wrong.withValues(alpha: 0.55)
              : AppColors.cardBorder,
        ),
        disabledForegroundColor: AppColors.chalkMuted,
      ),
      icon: Icon(icon),
      label: Text(label),
    );
  }

  Future<void> _confirm(BuildContext context) async {
    final messenger = ScaffoldMessenger.of(context);

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        backgroundColor: AppColors.cardSurface,
        title: Text(label),
        content: Text(body, style: const TextStyle(height: 1.6)),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: const Text(AppStrings.cancel),
          ),
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: Text(
              AppStrings.confirmReset,
              style: TextStyle(
                color: AppColors.wrong,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    await onConfirmed();
    messenger
      ..hideCurrentSnackBar()
      ..showSnackBar(const SnackBar(content: Text(AppStrings.resetDone)));
  }
}
