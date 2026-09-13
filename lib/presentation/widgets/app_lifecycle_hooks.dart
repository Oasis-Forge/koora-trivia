import 'package:flutter/widgets.dart';
import 'package:provider/provider.dart';

import '../providers/ads_provider.dart';
import '../providers/economy_provider.dart';
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

  @override
  void initState() {
    super.initState();
    _listener = AppLifecycleListener(onResume: _onResume);

    // إنجاز تحدي اليوم أو تغيّر السلسلة يغيّر أيام التنبيه ونصّه.
    _stats = context.read<StatsProvider>()..addListener(_syncReminder);
    WidgetsBinding.instance.addPostFrameCallback((_) => _syncReminder());
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
  }

  void _syncReminder() {
    if (!mounted || _stats.isLoading) return;
    context.read<SettingsProvider>().syncReminder(_stats.stats);
  }

  @override
  void dispose() {
    _stats.removeListener(_syncReminder);
    _listener.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => widget.child;
}
