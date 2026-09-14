import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:football_trivia/data/datasources/settings_local_datasource.dart';
import 'package:football_trivia/data/repositories/backup_repository_impl.dart';
import 'package:football_trivia/domain/entities/app_settings.dart';
import 'package:football_trivia/l10n/app_localizations.dart';
import 'package:football_trivia/presentation/providers/settings_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'fakes/fake_repositories.dart';

/// خيار اللغة: لغة الهاتف أو لغة بعينها، ولا تنقلب لغة من بدأ بالعربية.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUp(() => SharedPreferences.setMockInitialValues({}));

  test('اللاعب الجديد على العربية ما دامت اللغة الوحيدة، وعلى لغة الهاتف مع لغة ثانية',
      () {
    // عند إضافة لغة ثانية يفشل هذا الاختبار حتى تصبح القيمة الافتراضية `null`.
    final languages = AppLocalizations.supportedLocales;
    expect(
      AppSettings.defaultLanguageCode,
      languages.length == 1 ? languages.single.languageCode : isNull,
    );
    expect(const AppSettings().languageCode, AppSettings.defaultLanguageCode);
  });

  test('تُحفظ لغة الهاتف واللغة المختارة، والإعدادات الأقدم من الخيار تبقى على العربية',
      () async {
    final source = PrefsSettingsDataSource();
    await source.write(const AppSettings(languageCode: null));
    expect((await source.read()).languageCode, isNull);

    await source.write(const AppSettings(languageCode: 'en'));
    expect((await source.read()).languageCode, 'en');

    final old = json.encode({'soundEnabled': false, 'onboardingSeen': true});
    expect(PrefsSettingsDataSource.decode(old).languageCode, 'ar');
  });

  test('copyWith ينتقل إلى لغة الهاتف، ويُبقي اللغة حين لا تُذكر', () {
    const settings = AppSettings(languageCode: 'ar');
    expect(settings.copyWith(soundEnabled: false).languageCode, 'ar');
    expect(settings.copyWith(languageCode: null).languageCode, isNull);
    expect(
      settings.copyWith(languageCode: null).copyWith(themeId: 'red').languageCode,
      isNull,
    );
  });

  test('اختيار اللغة من المزوّد يُحفظ في المستودع', () async {
    final repository = FakeSettingsRepository();
    final settings =
        SettingsProvider(repository: repository, scheduler: FakeScheduler());
    await settings.init();

    await settings.setLanguageCode(null);
    expect(settings.languageCode, isNull);
    expect(repository.settings.languageCode, isNull);

    await settings.setLanguageCode('ar');
    expect(repository.settings.languageCode, 'ar');
  });

  test('النسخة الاحتياطية تنقل اختيار لغة الهاتف', () async {
    await PrefsSettingsDataSource().write(const AppSettings(languageCode: null));
    final code = await BackupRepositoryImpl().export();

    SharedPreferences.setMockInitialValues({});
    expect(await BackupRepositoryImpl().import(code), isTrue);

    expect((await PrefsSettingsDataSource().read()).languageCode, isNull);
  });
}
