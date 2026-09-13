import 'package:flutter_test/flutter_test.dart';
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
}
