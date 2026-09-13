import 'package:flutter/widgets.dart';
import 'package:provider/provider.dart';

import '../providers/ads_provider.dart';

/// يربط أحداث دورة حياة التطبيق بالمزوّدات في مكان واحد.
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

  @override
  void initState() {
    super.initState();
    _listener = AppLifecycleListener(onResume: _onResume);
  }

  // عودة الاتصال أثناء غياب اللاعب لا تُكتشف وحدها؛ العودة إلى التطبيق هي
  // اللحظة الطبيعية لإعادة محاولة إعلان فشل تحميله.
  void _onResume() => context.read<AdsProvider>().onAppResumed();

  @override
  void dispose() {
    _listener.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => widget.child;
}
