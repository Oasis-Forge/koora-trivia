import 'dart:async';
import 'dart:ui';

import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:football_trivia/core/constants/app_config.dart';
import 'package:football_trivia/core/services/error_handlers.dart';
import 'package:football_trivia/data/datasources/prefs_error_log.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'fakes/fake_repositories.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('PrefsErrorLog', () {
    setUp(() => SharedPreferences.setMockInitialValues({}));

    test('الأحدث أولاً، مع نوع الخطأ وأول أسطر مسار الاستدعاء', () async {
      var now = DateTime(2026, 9, 14, 10);
      final log = PrefsErrorLog(clock: () => now);

      await log.record(StateError('الأول'), StackTrace.current);
      now = now.add(const Duration(minutes: 1));
      await log.record(const FormatException('الثاني'), null);

      final entries = await log.recent();
      expect(entries, hasLength(2));
      expect(entries.first.message, contains('الثاني'));
      expect(entries.first.at, DateTime(2026, 9, 14, 10, 1));
      expect(entries.first.stack, isNull);
      expect(entries.last.message, contains('Bad state: الأول'));
      expect(entries.last.stack!.split('\n').length, lessThanOrEqualTo(4));
    });

    test('لا يحفظ أكثر من الحد، والأقدم يُحذف', () async {
      final log = PrefsErrorLog();

      for (var i = 0; i < AppConfig.errorLogMaxEntries + 5; i++) {
        await log.record('خطأ $i', null);
      }

      final entries = await log.recent();
      expect(entries, hasLength(AppConfig.errorLogMaxEntries));
      expect(entries.first.message, 'خطأ ${AppConfig.errorLogMaxEntries + 4}');
      expect(entries.last.message, 'خطأ 5');
    });

    test('الرسالة الطويلة تُقص', () async {
      final log = PrefsErrorLog();

      await log.record('x' * 1000, null);

      expect((await log.recent()).single.message.length, 300);
    });

    test('أخطاء متتالية دون انتظار لا يضيع منها شيء', () async {
      final log = PrefsErrorLog();

      unawaited(log.record('أ', null));
      unawaited(log.record('ب', null));
      unawaited(log.record('ج', null));

      final messages = (await log.recent()).map((e) => e.message);
      expect(messages, ['ج', 'ب', 'أ']);
    });

    test('سجل تالف لا يُسقط القراءة ولا الكتابة', () async {
      SharedPreferences.setMockInitialValues({
        PrefsErrorLog.key: '{"ليس":"قائمة"}',
      });
      final log = PrefsErrorLog();

      expect(await log.recent(), isEmpty);
      await log.record('بعد التلف', null);
      expect((await log.recent()).single.message, 'بعد التلف');
    });
  });

  group('installErrorHandlers', () {
    late FlutterExceptionHandler? originalFlutter;
    late ErrorCallback? originalPlatform;

    setUp(() {
      originalFlutter = FlutterError.onError;
      originalPlatform = PlatformDispatcher.instance.onError;
    });

    tearDown(() {
      FlutterError.onError = originalFlutter;
      PlatformDispatcher.instance.onError = originalPlatform;
    });

    test('خطأ في إطار Flutter يُسجَّل ويصل إلى المعالج السابق', () {
      final log = FakeErrorLog();
      var previousCalls = 0;
      FlutterError.onError = (_) => previousCalls++;

      installErrorHandlers(log);
      FlutterError.reportError(
        FlutterErrorDetails(exception: StateError('أثناء البناء')),
      );

      expect(log.entries.single.message, contains('أثناء البناء'));
      expect(previousCalls, 1);
    });

    test('خطأ غير متزامن غير ملتقط يُسجَّل ويبقى مطبوعاً في سجل النظام', () {
      final log = FakeErrorLog();
      PlatformDispatcher.instance.onError = null;

      installErrorHandlers(log);
      final handled = PlatformDispatcher.instance.onError!(
        StateError('في رد نداء'),
        StackTrace.current,
      );

      // `false`: المحرك يطبعه كما لو لم يكن هناك معالج.
      expect(handled, isFalse);
      expect(log.entries.single.message, contains('في رد نداء'));
    });
  });
}
