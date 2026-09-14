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
      'lib/core/constants/app_strings_en.dart',
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

  test('ملفات الترجمة بالعربية والإنجليزية، واسم التطبيق يطابق AppStrings في كل لغة',
      () {
    expect(AppLocalizations.supportedLocales,
        [const Locale('ar'), const Locale('en')]);

    final manifest =
        File('android/app/src/main/AndroidManifest.xml').readAsStringSync();
    expect(manifest, contains('android:label="@string/app_name"'));
    // لغات إعدادات أندرويد 13 تطابق ملفات الترجمة.
    expect(manifest, contains('android:localeConfig="@xml/locales_config"'));
    final localeConfig =
        File('android/app/src/main/res/xml/locales_config.xml').readAsStringSync();

    for (final (language, resFolder) in const [('ar', 'values'), ('en', 'values-en')]) {
      AppText.use(language);
      addTearDown(() => AppText.use('ar'));
      expect(lookupAppLocalizations(Locale(language)).appTitle, AppStrings.appName);
      final strings = File('android/app/src/main/res/$resFolder/strings.xml')
          .readAsStringSync();
      expect(strings,
          contains('<string name="app_name">${AppStrings.appName}</string>'));
      expect(localeConfig, contains('android:name="$language"'));
    }
  });

  // هاتف بالفرنسية (غير مدعومة) يحصل على العربية، وهاتف بالإنجليزية على الإنجليزية.
  for (final (phone, language, direction, title) in const [
    (Locale('fr', 'FR'), 'ar', TextDirection.rtl, 'تحدي كرة القدم'),
    (Locale('en', 'US'), 'en', TextDirection.ltr, 'Koora Trivia'),
  ]) {
    testWidgets('هاتف بلغة ${phone.languageCode} يحصل على $language واتجاهها',
        (tester) async {
      tester.platformDispatcher.localesTestValue = [phone];
      addTearDown(tester.platformDispatcher.clearLocalesTestValue);

      late Locale locale;
      late TextDirection textDirection;
      await tester.pumpWidget(
        MaterialApp(
          supportedLocales: AppLocalizations.supportedLocales,
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          home: Builder(
            builder: (context) {
              locale = Localizations.localeOf(context);
              textDirection = Directionality.of(context);
              return Text(AppLocalizations.of(context).appTitle);
            },
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(locale.languageCode, language);
      expect(textDirection, direction);
      expect(find.text(title), findsOneWidget);
    });
  }

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
