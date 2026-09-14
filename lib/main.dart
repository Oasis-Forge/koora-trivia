import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'app.dart';
import 'core/di/injector.dart';
import 'core/services/error_handlers.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();

  final injector = Injector();
  // قبل أي شيء آخر، حتى تُسجَّل أخطاء الإقلاع نفسها.
  installErrorHandlers(injector.errorLog);

  SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.light,
    ),
  );

  runApp(FootballTriviaApp(injector: injector));
}
