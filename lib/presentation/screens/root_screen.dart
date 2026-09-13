import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../providers/settings_provider.dart';
import 'home_screen.dart';
import 'onboarding_screen.dart';

/// يقرر أول شاشة: الترحيب لأول مرة، ثم الرئيسية دائماً بعدها.
class RootScreen extends StatefulWidget {
  const RootScreen({super.key});

  static const String routeName = '/';

  @override
  State<RootScreen> createState() => _RootScreenState();
}

class _RootScreenState extends State<RootScreen> {
  /// يُستخدم لإخفاء الترحيب فوراً دون انتظار إعادة القراءة من التخزين.
  bool _dismissed = false;

  @override
  Widget build(BuildContext context) {
    final settings = context.watch<SettingsProvider>();

    // ننتظر تحميل الإعدادات حتى لا تومض شاشة الترحيب لمن رآها سابقاً.
    if (settings.isLoading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    if (settings.onboardingSeen || _dismissed) return const HomeScreen();

    return OnboardingScreen(
      onDone: () => setState(() => _dismissed = true),
    );
  }
}
