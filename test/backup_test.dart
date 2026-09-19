import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:football_trivia/core/constants/app_config.dart';
import 'package:football_trivia/data/datasources/economy_local_datasource.dart';
import 'package:football_trivia/data/datasources/progress_local_datasource.dart';
import 'package:football_trivia/data/datasources/settings_local_datasource.dart';
import 'package:football_trivia/data/datasources/stats_local_datasource.dart';
import 'package:football_trivia/data/repositories/backup_repository_impl.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  const stats = '{"currentStreak":7,"bestScore":1450,"gamesPlayed":31}';
  const progress = '{"version":1,"categories":{"world_cup":[3,3,2]}}';

  setUp(() {
    SharedPreferences.setMockInitialValues({
      'user_stats_v1': stats,
      'level_progress_v1': progress,
      'economy_v1': '{"hearts":3,"coins":420}',
      'app_settings_v1': '{"reminderEnabled":true}',
      'recent_questions_v1': '[1001,1002]',
    });
  });

  test('التصدير ثم الاستيراد يعيد نفس البيانات', () async {
    final repo = BackupRepositoryImpl();
    final code = await repo.export();

    expect(code, isNotEmpty);
    // الرمز مشفّر لا نص صريح.
    expect(code, isNot(contains('currentStreak')));

    // نمسح كل شيء ثم نستورد.
    SharedPreferences.setMockInitialValues({});
    expect(await repo.import(code), isTrue);

    final prefs = await SharedPreferences.getInstance();
    expect(prefs.getString('user_stats_v1'), stats);
    expect(prefs.getString('level_progress_v1'), progress);
    expect(prefs.getString('economy_v1'), '{"hearts":3,"coins":420}');
    // ذاكرة الجولة السريعة تنتقل مع التقدّم فلا تتكرر أسئلتها على الجهاز الجديد.
    expect(prefs.getString('recent_questions_v1'), '[1001,1002]');
  });

  test('الرمز التالف يُرفض دون إسقاط التطبيق', () async {
    final repo = BackupRepositoryImpl();

    expect(await repo.import('ليس رمزاً'), isFalse);
    expect(await repo.import(''), isFalse);
    expect(await repo.import('!!!!'), isFalse);
  });

  test('المسافات والأسطر الزائدة لا تُفسد الاستيراد', () async {
    final repo = BackupRepositoryImpl();
    final code = await repo.export();

    SharedPreferences.setMockInitialValues({});
    expect(await repo.import('  $code \n '), isTrue);
  });

  test('إصدار أحدث من المدعوم يُرفض', () async {
    final repo = BackupRepositoryImpl();
    // v:99 أعلى من الإصدار المدعوم.
    const future = 'eyJ2Ijo5OSwiZGF0YSI6eyJ1c2VyX3N0YXRzX3YxIjoie30ifX0=';

    expect(await repo.import(future), isFalse);
  });

  test('التصدير يتجاهل المفاتيح غير الموجودة', () async {
    SharedPreferences.setMockInitialValues({'user_stats_v1': stats});
    final repo = BackupRepositoryImpl();

    final code = await repo.export();
    SharedPreferences.setMockInitialValues({});
    expect(await repo.import(code), isTrue);

    final prefs = await SharedPreferences.getInstance();
    expect(prefs.getString('user_stats_v1'), stats);
    expect(prefs.getString('economy_v1'), isNull);
  });

  group('فحص القيم قبل الكتابة', () {
    String encode(Map<String, Object?> data) =>
        base64Url.encode(utf8.encode(json.encode({'v': 1, 'data': data})));

    test('قيمة واحدة بنوع خاطئ ترفض النسخة كلها ولا يُكتب منها شيء', () async {
      final code = encode({
        'user_stats_v1': '{"gamesPlayed":99}',
        'economy_v1': '{"hearts":"three"}',
      });

      expect(await BackupRepositoryImpl().import(code), isFalse);

      final prefs = await SharedPreferences.getInstance();
      expect(prefs.getString('user_stats_v1'), stats);
      expect(prefs.getString('economy_v1'), '{"hearts":3,"coins":420}');
    });

    test('قيمة ليست نصاً تُرفض', () async {
      final code = encode({
        'user_stats_v1': {'gamesPlayed': 3},
      });

      expect(await BackupRepositoryImpl().import(code), isFalse);
    });

    test('مفتاح يوم لا يُقرأ كتاريخ يُرفض', () async {
      final code = encode({'user_stats_v1': '{"lastDailyDayKey":"أمس"}'});

      expect(await BackupRepositoryImpl().import(code), isFalse);
    });

    test('نسخة بلا أي مفتاح معروف تُرفض', () async {
      final code = encode({'something_else_v1': '{}'});

      expect(await BackupRepositoryImpl().import(code), isFalse);
    });
  });

  group('قيمة محفوظة بنوع غير متوقع لا تُسقط القراءة', () {
    Future<String?> stored(String key) async =>
        (await SharedPreferences.getInstance()).getString(key);

    test('الاقتصاد يعود للافتراضي ويُحذف التالف', () async {
      SharedPreferences.setMockInitialValues({
        'economy_v1': '{"hearts":"three","coins":5}',
      });

      final economy = await PrefsEconomyDataSource().read();

      expect(economy.hearts, AppConfig.maxHearts);
      expect(economy.coins, 0);
      expect(await stored('economy_v1'), isNull);
    });

    test('الإحصائيات', () async {
      SharedPreferences.setMockInitialValues({
        'user_stats_v1': '{"gamesPlayed":"x"}',
      });

      expect((await PrefsStatsDataSource().read()).gamesPlayed, 0);
      expect(await stored('user_stats_v1'), isNull);
    });

    test('التقدّم', () async {
      SharedPreferences.setMockInitialValues({
        'level_progress_v1': '{"categories":{"world_cup":"x"}}',
      });

      expect(await PrefsProgressDataSource().read(), isEmpty);
      expect(await stored('level_progress_v1'), isNull);
    });

    test('الإعدادات', () async {
      SharedPreferences.setMockInitialValues({
        'app_settings_v1': '{"soundEnabled":"yes"}',
      });

      expect((await PrefsSettingsDataSource().read()).soundEnabled, isTrue);
      expect(await stored('app_settings_v1'), isNull);
    });
  });
}
