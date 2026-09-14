import '../../core/constants/app_config.dart';
import '../../core/constants/app_strings.dart';
import '../entities/email_draft.dart';
import '../entities/question.dart';

/// أسباب البلاغ عن سؤال.
enum ReportReason { wrongAnswer, twoCorrect, typo, other }

/// يكتب رسالة البلاغ عن سؤال: كل ما يلزم لإيجاده وتصحيحه دون سؤال اللاعب مجدداً.
class BuildQuestionReport {
  const BuildQuestionReport();

  static const List<String> _letters = ['أ', 'ب', 'ج', 'د'];

  static String label(ReportReason reason) => switch (reason) {
        ReportReason.wrongAnswer => AppStrings.reportWrongAnswer,
        ReportReason.twoCorrect => AppStrings.reportTwoCorrect,
        ReportReason.typo => AppStrings.reportTypo,
        ReportReason.other => AppStrings.reportOther,
      };

  EmailDraft call({
    required Question question,
    required ReportReason reason,
    required String version,
  }) {
    final options = [
      for (var i = 0; i < question.options.length; i++)
        // الخيارات بترتيب ظهورها للاعب، والمعتمدة معلّمة.
        '${i < _letters.length ? _letters[i] : i + 1}) ${question.options[i]}'
            '${i == question.answerIndex ? ' ✓' : ''}',
    ];

    final body = [
      '${AppStrings.reportReasonLabel}: ${label(reason)}',
      '',
      '${AppStrings.reportQuestionLabel} ${question.id} · '
          '${question.categoryName} · ${AppStrings.level} ${question.level}',
      question.text,
      '',
      '${AppStrings.reportOptionsLabel}:',
      ...options,
      '',
      AppStrings.reportNotePrompt,
      '',
      '',
      '${AppStrings.versionLabel}: $version',
    ].join('\n');

    return EmailDraft(
      to: AppConfig.contactEmail,
      subject: AppStrings.reportSubject(question.id),
      body: body,
    );
  }
}
