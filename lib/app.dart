import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'core/constants/app_strings.dart';
import 'core/di/injector.dart';
import 'core/theme/app_colors.dart';
import 'core/theme/app_theme.dart';
import 'domain/entities/category.dart';
import 'domain/repositories/app_info.dart';
import 'domain/repositories/app_updater.dart';
import 'domain/repositories/backup_repository.dart';
import 'domain/repositories/error_log.dart';
import 'domain/repositories/link_opener.dart';
import 'domain/repositories/review_prompter.dart';
import 'presentation/providers/ads_provider.dart';
import 'presentation/providers/economy_provider.dart';
import 'presentation/providers/progress_provider.dart';
import 'presentation/providers/quiz_provider.dart';
import 'presentation/providers/settings_provider.dart';
import 'presentation/providers/stats_provider.dart';
import 'presentation/screens/categories_screen.dart';
import 'presentation/screens/root_screen.dart';
import 'presentation/screens/levels_screen.dart';
import 'presentation/screens/quiz_screen.dart';
import 'presentation/screens/score_screen.dart';
import 'presentation/screens/settings_screen.dart';
import 'presentation/screens/shop_screen.dart';
import 'presentation/screens/tasks_screen.dart';
import 'presentation/widgets/app_lifecycle_hooks.dart';
import 'presentation/widgets/palette_scope.dart';
import 'l10n/app_localizations.dart';

/// لغة نصوص التطبيق بقاعدة `MaterialApp` نفسها: اللغة المختارة إن كانت مدعومة،
/// وإلا أول لغة مدعومة في قائمة لغات الهاتف، وإلا أول لغة مدعومة (العربية).
String resolveLanguage(String? chosen, List<Locale> phoneLocales) {
  final supported =
      AppLocalizations.supportedLocales.map((l) => l.languageCode).toList();
  if (chosen != null && supported.contains(chosen)) return chosen;
  for (final locale in phoneLocales) {
    if (supported.contains(locale.languageCode)) return locale.languageCode;
  }
  return supported.first;
}

class FootballTriviaApp extends StatelessWidget {
  const FootballTriviaApp({super.key, required this.injector});

  final Injector injector;

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        // مستودع بلا حالة — يُقدَّم كقيمة لا كمزوّد تغيير.
        Provider<BackupRepository>.value(value: injector.backupRepository),
        Provider<LinkOpener>.value(value: injector.linkOpener),
        Provider<ErrorLog>.value(value: injector.errorLog),
        Provider<AppInfo>.value(value: injector.appInfo),
        Provider<ReviewPrompter>.value(value: injector.reviewPrompter),
        Provider<AppUpdater>.value(value: injector.appUpdater),
        ChangeNotifierProvider(
          create: (_) => QuizProvider(repository: injector.quizRepository),
        ),
        ChangeNotifierProvider(
          create: (_) =>
              StatsProvider(repository: injector.statsRepository)..init(),
        ),
        ChangeNotifierProvider(
          create: (_) =>
              ProgressProvider(repository: injector.progressRepository)
                ..init(),
        ),
        ChangeNotifierProvider(
          create: (_) =>
              EconomyProvider(repository: injector.economyRepository)..init(),
        ),
        ChangeNotifierProvider(
          // غير كسول عمداً: الموافقة والإعلانات تبدأ عند الإقلاع. المزوّد الكسول
          // لا يُنشأ إلا عند أول قراءة (الإعدادات أو شاشة النتيجة أو المتجر)،
          // فيظهر نموذج الموافقة وسط اللعب ولا يكون الإعلان جاهزاً عند أول زر.
          lazy: false,
          create: (_) => AdsProvider(service: injector.adService)..init(),
        ),
        ChangeNotifierProvider(
          create: (_) => SettingsProvider(
            repository: injector.settingsRepository,
            scheduler: injector.reminderScheduler,
          )..init(),
        ),
      ],
      // الثيم والشاشات تقرأ الألوان الحالية، فيُضبط المظهر قبل بناء `MaterialApp`.
      // واللغة من اختيار اللاعب؛ سجلّ لا `Consumer` حتى لا يعيد الصوت بناء التطبيق.
      child: Selector<SettingsProvider, (String, String?)>(
        selector: (_, settings) => (settings.themeId, settings.languageCode),
        builder: (context, choice, _) {
          final (themeId, languageCode) = choice;
          AppColors.use(AppPalette.byId(themeId));
          AppText.use(resolveLanguage(
            languageCode,
            WidgetsBinding.instance.platformDispatcher.locales,
          ));
          return PaletteScope(
            themeId: themeId,
            child: MaterialApp(
        onGenerateTitle: (context) => AppLocalizations.of(context).appTitle,
        debugShowCheckedModeBanner: false,
        theme: AppTheme.dark,
        themeMode: ThemeMode.dark,

        // اللغات من ملفات الترجمة في lib/l10n (العربية وحدها حالياً)، واتجاه
        // الكتابة يتبع اللغة. اللغة المختارة في الإعدادات تتقدّم، و`null` تعني لغة
        // الهاتف: جهاز بلغة غير مدعومة يحصل على أول لغة مدعومة (العربية).
        locale: languageCode == null ? null : Locale(languageCode),
        supportedLocales: AppLocalizations.supportedLocales,
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        builder: (context, child) => AppLifecycleHooks(
          child: child ?? const SizedBox.shrink(),
        ),

        initialRoute: RootScreen.routeName,
        routes: {
          RootScreen.routeName: (_) => const RootScreen(),
          QuizScreen.routeName: (_) => const QuizScreen(),
          ScoreScreen.routeName: (_) => const ScoreScreen(),
          CategoriesScreen.routeName: (_) => const CategoriesScreen(),
          SettingsScreen.routeName: (_) => const SettingsScreen(),
          TasksScreen.routeName: (_) => const TasksScreen(),
          ShopScreen.routeName: (_) => const ShopScreen(),
        },

        // شاشة المستويات تحتاج التصنيف كوسيط، فتُبنى هنا لا في جدول المسارات.
        onGenerateRoute: (settings) {
          if (settings.name != LevelsScreen.routeName) return null;

          final category = settings.arguments;
          if (category is! Category) return null;

          return MaterialPageRoute<void>(
            builder: (_) => LevelsScreen(category: category),
            settings: settings,
          );
        },
      ),
          );
        },
      ),
    );
  }
}
