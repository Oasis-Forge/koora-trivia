/// خطأ واحد محفوظ في سجل الأخطاء المحلي.
class ErrorEntry {
  const ErrorEntry({required this.at, required this.message, this.stack});

  final DateTime at;

  /// نص الخطأ مع نوعه، مقصوصاً إلى طول معقول.
  final String message;

  /// أول أسطر مسار الاستدعاء — تكفي لمعرفة مكان الخطأ.
  final String? stack;
}
