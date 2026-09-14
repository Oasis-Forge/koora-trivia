import 'package:flutter/foundation.dart';

import '../../domain/repositories/error_log.dart';

/// يحفظ كل خطأ لا يلتقطه أحد في سجل محلي.
///
/// قبله كانت أخطاء ردود النداء غير المتزامنة تختفي بصمت — هكذا مرّ خطأ حفظ
/// النجوم في شاشة النتيجة دون أن يراه أحد. المعالجات السابقة تبقى تعمل بعده.
void installErrorHandlers(ErrorLog log) {
  final previousFlutter = FlutterError.onError;
  FlutterError.onError = (details) {
    log.record(details.exception, details.stack);
    previousFlutter?.call(details);
  };

  final previousPlatform = PlatformDispatcher.instance.onError;
  PlatformDispatcher.instance.onError = (error, stack) {
    log.record(error, stack);
    // `false` حين لا معالج قبله: يبقى المحرك يطبع الخطأ في سجل النظام كما كان
    // (`true` كان يخفيه)، ولا يُسقط ذلك التطبيق على Android.
    return previousPlatform?.call(error, stack) ?? false;
  };
}
