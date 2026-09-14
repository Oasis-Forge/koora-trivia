import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/constants/app_strings.dart';
import '../../domain/repositories/app_updater.dart';
import '../providers/ads_provider.dart';
import '../providers/check_for_update.dart';
import '../providers/economy_provider.dart';
import '../providers/quiz_provider.dart';
import '../providers/settings_provider.dart';
import '../providers/stats_provider.dart';

/// يربط أحداث دورة حياة التطبيق وتغيّر الإحصائيات بالمزوّدات في مكان واحد.
///
/// يُلفّ حول كل الشاشات في `MaterialApp.builder`، فيبقى حيّاً مهما تغيّرت
/// الشاشة المعروضة.
class AppLifecycleHooks extends StatefulWidget {
  const AppLifecycleHooks({super.key, required this.child});

  final Widget child;

  @override
  State<AppLifecycleHooks> createState() => _AppLifecycleHooksState();
}

class _AppLifecycleHooksState extends State<AppLifecycleHooks> {
  late final AppLifecycleListener _listener;
  late final StatsProvider _stats;
  late final SettingsProvider _settings;

  /// لغة النصوص عند آخر تحميل للتصنيفات وجدولة للتنبيه.
  late String _language;

  /// سؤال Play واحد في كل مرة: تنزيل التحديث المرن قد يستمر دقائق، والعودة إلى
  /// التطبيق أثناءه لا تبدأ سؤالاً ثانياً.
  bool _checkingUpdate = false;

  @override
  void initState() {
    super.initState();
    _listener = AppLifecycleListener(onResume: _onResume);

    // إنجاز تحدي اليوم أو تغيّر السلسلة يغيّر أيام التنبيه ونصّه.
    _stats = context.read<StatsProvider>()..addListener(_syncReminder);
    _language = AppStrings.languageCode;
    _settings = context.read<SettingsProvider>()
      ..addListener(_onSettingsChanged);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _syncReminder();
      _checkForUpdate();
    });
  }

  void _onResume() {
    // عودة الاتصال أثناء غياب اللاعب لا تُكتشف وحدها؛ العودة إلى التطبيق هي
    // اللحظة الطبيعية لإعادة محاولة إعلان فشل تحميله.
    context.read<AdsProvider>().onAppResumed();

    // القلوب والعدّاد والمهام اليومية تُحسب عند القراءة، فتبقى مجمّدة على
    // الشاشة بعد الغياب ما لم نُعد الحساب.
    context.read<EconomyProvider>().refresh();

    // قد يكون اليوم تغيّر أثناء الغياب: تحدي الأمس لم يعد «تحدي اليوم».
    _syncReminder();

    // تحديث إلزامي أُغلقت شاشته يُستأنف، وتحديث نُزّل في الغياب يُعرض تثبيته.
    _checkForUpdate();
  }

  /// تبديل اللغة يُطبَّق في بناء التطبيق التالي، فتُقارَن اللغة بعد الإطار. التصنيفات
  /// المحمّلة تحمل أسماءها باللغة السابقة، والتنبيه المجدول نصّه بها.
  void _onSettingsChanged() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted || AppStrings.languageCode == _language) return;
      _language = AppStrings.languageCode;
      context.read<QuizProvider>().loadCategories();
      _syncReminder();
    });
  }

  void _syncReminder() {
    if (!mounted || _stats.isLoading) return;
    context.read<SettingsProvider>().syncReminder(_stats.stats);
  }

  Future<void> _checkForUpdate() async {
    if (_checkingUpdate || !mounted) return;
    _checkingUpdate = true;
    final updater = context.read<AppUpdater>();
    try {
      final downloaded = await CheckForUpdate(updater: updater)();
      if (downloaded && mounted) _offerRestart(updater);
    } finally {
      _checkingUpdate = false;
    }
  }

  /// التحديث المنزَّل لا يُثبَّت دون إذن اللاعب: قد يكون وسط جولة.
  void _offerRestart(AppUpdater updater) {
    ScaffoldMessenger.maybeOf(context)
      ?..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text(AppStrings.updateDownloaded),
          duration: const Duration(seconds: 10),
          action: SnackBarAction(
            label: AppStrings.updateRestart,
            onPressed: updater.completeFlexibleUpdate,
          ),
        ),
      );
  }

  @override
  void dispose() {
    _stats.removeListener(_syncReminder);
    _settings.removeListener(_onSettingsChanged);
    _listener.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => widget.child;
}
