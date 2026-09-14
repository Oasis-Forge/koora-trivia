import 'dart:convert';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:football_trivia/core/theme/app_colors.dart';
import 'package:football_trivia/data/datasources/settings_local_datasource.dart';
import 'package:football_trivia/data/repositories/backup_repository_impl.dart';
import 'package:football_trivia/domain/entities/app_settings.dart';
import 'package:football_trivia/presentation/providers/settings_provider.dart';
import 'package:football_trivia/presentation/widgets/palette_scope.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'fakes/fake_repositories.dart';
import 'fakes/score_screen_harness.dart';

/// نسبة التباين حسب WCAG بين لونين معتمين.
double _contrast(Color a, Color b) {
  double channel(double v) =>
      v <= 0.03928 ? v / 12.92 : pow((v + 0.055) / 1.055, 2.4).toDouble();
  double luminance(Color c) =>
      0.2126 * channel(c.r) + 0.7152 * channel(c.g) + 0.0722 * channel(c.b);
  final la = luminance(a);
  final lb = luminance(b);
  return (max(la, lb) + 0.05) / (min(la, lb) + 0.05);
}

/// لون شبه شفاف كما يظهر فوق خلفيته.
Color _over(Color fg, Color bg) => Color.alphaBlend(fg, bg);

class _Probe extends StatelessWidget {
  const _Probe();

  @override
  Widget build(BuildContext context) => ColoredBox(color: AppColors.pitchDark);
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  tearDown(() => AppColors.use(AppPalette.green));

  group('المظاهر', () {
    test('أربعة مظاهر بمفاتيح مختلفة، والمفتاح المجهول يعود إلى الأخضر', () {
      expect(AppPalette.all.map((p) => p.id).toSet(),
          {'green', 'blue', 'purple', 'red'});
      expect(AppPalette.byId('unknown'), AppPalette.green);
      expect(AppPalette.byId(null), AppPalette.green);
      expect(AppSettings.defaultThemeId, AppPalette.green.id);
    });

    test('النص مقروء في كل مظهر، ولا مظهر أقل وضوحاً من الأخضر الأصلي', () {
      const original = AppPalette.green;
      double pair(AppPalette p, Color Function(AppPalette) fg,
              Color Function(AppPalette) bg) =>
          _contrast(_over(fg(p), bg(p)), bg(p));

      final checks = <String, (Color Function(AppPalette), Color Function(AppPalette))>{
        'الطباشير على الأرضية': ((p) => p.chalk, (p) => p.pitchDark),
        'الطباشير على البطاقة': ((p) => p.chalk, (p) => p.cardSurface),
        'الطباشير الباهت على البطاقة': ((p) => p.chalkMuted, (p) => p.cardSurface),
        'الذهبي على الأرضية': ((p) => p.gold, (p) => p.pitchDark),
        'الصحيح على البطاقة': ((p) => p.correct, (p) => p.cardSurface),
        'الخطأ على البطاقة': ((p) => p.wrong, (p) => p.cardSurface),
      };

      for (final palette in AppPalette.all) {
        expect(pair(palette, (p) => p.chalk, (p) => p.pitchDark),
            greaterThanOrEqualTo(7), reason: '${palette.id}: نص أساسي');
        expect(pair(palette, (p) => p.chalk, (p) => p.cardSurface),
            greaterThanOrEqualTo(4.5), reason: '${palette.id}: نص على بطاقة');
        for (final MapEntry(key: name, value: (fg, bg)) in checks.entries) {
          expect(
            pair(palette, fg, bg),
            greaterThanOrEqualTo(pair(original, fg, bg) * 0.95),
            reason: '${palette.id}: $name',
          );
        }
      }
    });
  });

  group('حفظ المظهر', () {
    setUp(() => SharedPreferences.setMockInitialValues({}));

    test('يُحفظ ويُقرأ، والإعدادات القديمة بلا مظهر تبقى على الأخضر', () async {
      final source = PrefsSettingsDataSource();
      await source.write(const AppSettings(themeId: 'purple'));
      expect((await source.read()).themeId, 'purple');

      final old = json.encode({'soundEnabled': false, 'onboardingSeen': true});
      expect(PrefsSettingsDataSource.decode(old).themeId, 'green');
    });

    test('اختيار المظهر من المزوّد يُحفظ في المستودع', () async {
      final repository = FakeSettingsRepository();
      final settings =
          SettingsProvider(repository: repository, scheduler: FakeScheduler());
      await settings.init();

      await settings.setThemeId('red');

      expect(settings.themeId, 'red');
      expect(repository.settings.themeId, 'red');
    });

    test('النسخة الاحتياطية تنقل المظهر', () async {
      await PrefsSettingsDataSource().write(const AppSettings(themeId: 'blue'));
      final code = await BackupRepositoryImpl().export();

      SharedPreferences.setMockInitialValues({});
      expect(await BackupRepositoryImpl().import(code), isTrue);

      expect((await PrefsSettingsDataSource().read()).themeId, 'blue');
    });
  });

  testWidgets('تبديل المظهر يعيد بناء الودجات الثابتة بالألوان الجديدة',
      (tester) async {
    var themeId = 'green';
    late StateSetter setOuter;
    await tester.pumpWidget(
      StatefulBuilder(
        builder: (context, setState) {
          setOuter = setState;
          AppColors.use(AppPalette.byId(themeId));
          return PaletteScope(themeId: themeId, child: const _Probe());
        },
      ),
    );
    expect(tester.widget<ColoredBox>(find.byType(ColoredBox)).color,
        AppPalette.green.pitchDark);

    setOuter(() => themeId = 'blue');
    await tester.pump();
    await tester.pump();

    expect(tester.widget<ColoredBox>(find.byType(ColoredBox)).color,
        AppPalette.blue.pitchDark);
  });

  testWidgets('شاشة النتيجة تُبنى بكل مظهر دون أخطاء', (tester) async {
    tester.view.physicalSize = const Size(800, 4000);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);

    for (final palette in AppPalette.all) {
      AppColors.use(palette);
      final quiz = await pumpScoreScreen(tester, correct: 8);
      expect(tester.takeException(), isNull, reason: palette.id);
      quiz.abandon();
    }
  });
}
