import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:provider/provider.dart';

import 'core/constants/app_strings.dart';
import 'core/di/injector.dart';
import 'core/theme/app_theme.dart';
import 'domain/entities/category.dart';
import 'domain/repositories/backup_repository.dart';
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

class FootballTriviaApp extends StatelessWidget {
  const FootballTriviaApp({super.key, required this.injector});

  final Injector injector;

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        // مستودع بلا حالة — يُقدَّم كقيمة لا كمزوّد تغيير.
        Provider<BackupRepository>.value(value: injector.backupRepository),
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
          create: (_) => AdsProvider(service: injector.adService)..init(),
        ),
        ChangeNotifierProvider(
          create: (_) => SettingsProvider(
            repository: injector.settingsRepository,
            scheduler: injector.reminderScheduler,
          )..init(),
        ),
      ],
      child: MaterialApp(
        title: AppStrings.appName,
        debugShowCheckedModeBanner: false,
        theme: AppTheme.dark,
        themeMode: ThemeMode.dark,

        // دعم العربية واتجاه RTL على مستوى التطبيق كاملاً.
        locale: const Locale('ar'),
        supportedLocales: const [Locale('ar'), Locale('en')],
        localizationsDelegates: const [
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
        builder: (context, child) => Directionality(
          textDirection: TextDirection.rtl,
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
  }
}
