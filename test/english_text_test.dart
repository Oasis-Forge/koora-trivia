import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:football_trivia/core/constants/app_strings.dart';
import 'package:football_trivia/core/utils/arabic_count.dart';

void main() {
  tearDown(() => AppText.use('ar'));

  test('العربية افتراضياً، والإنجليزية حين تُختار، وأي رمز آخر عربي', () {
    expect(AppStrings.languageCode, 'ar');
    expect(AppStrings.quickPlay, 'لعب سريع');

    AppText.use('en');
    expect(AppStrings.languageCode, 'en');
    expect(AppStrings.appName, 'Koora Trivia');
    expect(AppStrings.optionLetters, ['A', 'B', 'C', 'D']);

    AppText.use('fr');
    expect(AppStrings.languageCode, 'ar');
  });

  test('الأعداد بالإنجليزية: المفرد مع 1 وحده، والعربية كما هي', () {
    AppText.use('en');
    expect(ArabicCount.format(1, ArabicNoun.day), '1 day');
    expect(ArabicCount.format(2, ArabicNoun.star, object: true), '2 stars');
    expect(ArabicCount.format(0, ArabicNoun.point), '0 points');
    expect(ArabicCount.nounFor(11, ArabicNoun.question), 'questions');

    AppText.use('ar');
    expect(ArabicCount.format(2, ArabicNoun.day), 'يومان');
    expect(ArabicCount.format(11, ArabicNoun.day), '11 يوماً');
  });

  test('لا حرف عربياً في النصوص الإنجليزية إلا اسم العربية في قائمة اللغات', () {
    final arabic = RegExp('[؀-ۿ]');
    final lines =
        File('lib/core/constants/app_strings_en.dart').readAsLinesSync();
    final offending = [
      for (var i = 0; i < lines.length; i++)
        // تعليقات الكود عربية في المشروع؛ الفحص للنصوص وحدها.
        if (arabic.hasMatch(lines[i]) &&
            !lines[i].trimLeft().startsWith('//') &&
            !lines[i].contains("'ar':"))
          '${i + 1}: ${lines[i].trim()}',
    ];
    expect(offending, isEmpty, reason: offending.join('\n'));
  });
}
