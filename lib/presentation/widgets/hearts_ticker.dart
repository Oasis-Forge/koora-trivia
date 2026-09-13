import 'dart:async';

import 'package:flutter/widgets.dart';
import 'package:provider/provider.dart';

import '../../core/constants/app_config.dart';
import '../providers/economy_provider.dart';

/// يعيد احتساب القلوب دورياً ما دامت ناقصة.
///
/// الرصيد يُحسب عند القراءة لا بمؤقّت، فكان عدّاد القلب التالي والقلب المتجدّد
/// يبقيان مجمّدين على الشاشة حتى يُعاد بناؤها لسبب آخر.
class HeartsTicker extends StatefulWidget {
  const HeartsTicker({super.key, required this.child});

  final Widget child;

  @override
  State<HeartsTicker> createState() => _HeartsTickerState();
}

class _HeartsTickerState extends State<HeartsTicker> {
  late final Timer _timer;

  @override
  void initState() {
    super.initState();
    _timer = Timer.periodic(
      const Duration(seconds: AppConfig.heartsRefreshSeconds),
      (_) => _tick(),
    );
  }

  void _tick() {
    final economy = context.read<EconomyProvider>();
    // الرصيد الممتلئ لا عدّاد له — لا داعي لإعادة الحساب والحفظ كل نصف دقيقة.
    if (!economy.isFull) economy.refresh();
  }

  @override
  void dispose() {
    _timer.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => widget.child;
}
