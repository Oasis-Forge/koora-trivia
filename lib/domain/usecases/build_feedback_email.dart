import '../../core/constants/app_config.dart';
import '../../core/constants/app_strings.dart';
import '../../core/utils/day_key.dart';
import '../entities/email_draft.dart';
import '../entities/error_entry.dart';

/// يكتب رسالة الملاحظات: مساحة للاعب، ثم رقم الإصدار وآخر الأخطاء المسجّلة.
///
/// الأخطاء ظاهرة في المسودة قبل الإرسال — اللاعب يرى ما سيرسله ويحذف ما يشاء.
class BuildFeedbackEmail {
  const BuildFeedbackEmail();

  /// سطر الخطأ في الرسالة يُقصّ أكثر من المحفوظ: روابط البريد الطويلة ترفضها
  /// بعض تطبيقات البريد.
  static const int _maxErrorLength = 160;

  EmailDraft call({
    required String version,
    required List<ErrorEntry> errors,
  }) {
    final shown = errors.take(AppConfig.feedbackEmailErrors).map((e) {
      final message = e.message.length > _maxErrorLength
          ? '${e.message.substring(0, _maxErrorLength)}…'
          : e.message;
      final time = '${e.at.hour.toString().padLeft(2, '0')}:'
          '${e.at.minute.toString().padLeft(2, '0')}';
      return '• ${DayKey.from(e.at)} $time · $message';
    });

    final body = [
      AppStrings.feedbackBodyPrompt,
      '',
      '',
      '',
      AppStrings.feedbackDiagnostics,
      '${AppStrings.versionLabel}: $version',
      '${AppStrings.recentErrors}:',
      if (shown.isEmpty) AppStrings.noRecentErrors else ...shown,
    ].join('\n');

    return EmailDraft(
      to: AppConfig.contactEmail,
      subject: AppStrings.feedbackSubject,
      body: body,
    );
  }
}
