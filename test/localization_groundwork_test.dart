import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:football_trivia/core/constants/app_strings.dart';
import 'package:football_trivia/l10n/app_localizations.dart';

/// أساس تعدد اللغات: لا نص للاعب خارج AppStrings، ولا لغة أو اتجاه مفروضان.
void main() {
  test('لا نص عربي للاعب مكتوب خارج AppStrings', () {
    final arabic = RegExp('[\u0600-\u06FF]');
    final literal = RegExp("'[^'\\n]*'|\"[^\"\\n]*\"");
    // رسائل للمطوّر لا يراها اللاعب.
    const developerOnly = [
      'debugPrint',
      'FormatException',
      'ErrorDescription',
      'StateError',
      'ArgumentError',
    ];
    // جدول صيغ العدد العربية نفسها (انظر ArabicCount) ومصدر النصوص.
    const allowed = {
      'lib/core/constants/app_strings.dart',
      'lib/core/utils/arabic_count.dart',
    };

    final offenders = <String>[];
    for (final dir in ['lib/presentation', 'lib/domain', 'lib/core']) {
      final files = Directory(dir)
          .listSync(recursive: true)
          .whereType<File>()
          .where((f) => f.path.endsWith('.dart'));
      for (final file in files) {
        final path = file.path.replaceAll('\\', '/');
        if (allowed.contains(path)) continue;
        final lines = file.readAsLinesSync();
        for (var i = 0; i < lines.length; i++) {
          final code = lines[i].split('//').first;
          if (developerOnly.any(code.contains)) continue;
          for (final m in literal.allMatches(code)) {
            if (arabic.hasMatch(m.group(0)!)) {
              offenders.add('$path:${i + 1}: ${lines[i].trim()}');
            }
          }
        }
      }
    }

    expect(offenders, isEmpty, reason: offenders.join('\n'));
  });

  test('ملفات الترجمة فيها العربية وحدها، واسم التطبيق يطابق AppStrings', () {
    expect(AppLocalizations.supportedLocales, [const Locale('ar')]);
    expect(lookupAppLocalizations(const Locale('ar')).appTitle,
        AppStrings.appName);

    final strings =
        File('android/app/src/main/res/values/strings.xml').readAsStringSync();
    expect(strings, contains('<string name="app_name">${AppStrings.appName}</string>'));
    final manifest =
        File('android/app/src/main/AndroidManifest.xml').readAsStringSync();
    expect(manifest, contains('android:label="@string/app_name"'));
  });

  testWidgets('جهاز بلغة غير مدعومة يحصل على العربية ومن اليمين إلى اليسار',
      (tester) async {
    tester.platformDispatcher.localesTestValue = const [Locale('en', 'US')];
    addTearDown(tester.platformDispatcher.clearLocalesTestValue);

    late Locale locale;
    late TextDirection direction;
    await tester.pumpWidget(
      MaterialApp(
        supportedLocales: AppLocalizations.supportedLocales,
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        home: Builder(
          builder: (context) {
            locale = Localizations.localeOf(context);
            direction = Directionality.of(context);
            return Text(AppLocalizations.of(context).appTitle);
          },
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(locale.languageCode, 'ar');
    expect(direction, TextDirection.rtl);
    expect(find.text(AppStrings.appName), findsOneWidget);
  });

  test('الصيغ المنقولة إلى AppStrings تكتب النص نفسه', () {
    expect(AppStrings.hoursMinutes(2, 5), '2 س و 5 د');
    expect(AppStrings.minutesShort(29), '29 د');
    expect(AppStrings.hoursShort(3), '3 س');
    expect(AppStrings.levelLabel(4), 'المستوى 4');
    expect(AppStrings.levelsProgress(3, 10), '3 من 10 ${AppStrings.levelsDone}');
    expect(AppStrings.optionLetters, ['أ', 'ب', 'ج', 'د']);
    expect(AppStrings.monthNames, hasLength(12));
  });
}
