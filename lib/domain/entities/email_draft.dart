/// رسالة بريد جاهزة يفتحها تطبيق البريد لدى اللاعب — لا يُرسل شيء تلقائياً.
class EmailDraft {
  const EmailDraft({
    required this.to,
    required this.subject,
    required this.body,
  });

  final String to;
  final String subject;
  final String body;

  /// رابط `mailto:` بترميز `%20` للمسافات.
  ///
  /// `Uri(queryParameters: …)` يرمّز المسافة «+»، وكثير من تطبيقات البريد يعرضها
  /// «+» حرفياً في الموضوع والنص.
  Uri toMailtoUri() => Uri.parse(
        'mailto:$to'
        '?subject=${Uri.encodeComponent(subject)}'
        '&body=${Uri.encodeComponent(body)}',
      );
}
