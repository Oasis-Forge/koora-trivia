import 'package:flutter_test/flutter_test.dart';
import 'package:football_trivia/core/constants/app_config.dart';
import 'package:football_trivia/core/constants/app_strings.dart';
import 'package:football_trivia/domain/entities/email_draft.dart';
import 'package:football_trivia/domain/entities/error_entry.dart';
import 'package:football_trivia/domain/entities/question.dart';
import 'package:football_trivia/domain/usecases/build_feedback_email.dart';
import 'package:football_trivia/domain/usecases/build_question_report.dart';

const _question = Question(
  id: 1021,
  category: 'world_cup',
  categoryName: 'كأس العالم',
  level: 3,
  text: 'من فاز بكأس العالم 2022؟',
  options: ['فرنسا', 'الأرجنتين', 'كرواتيا', 'البرازيل'],
  answerIndex: 1,
);

void main() {
  group('EmailDraft', () {
    test('رابط mailto يحمل المستلم والموضوع والنص بترميز صحيح', () {
      const draft = EmailDraft(
        to: 'a@b.com',
        subject: 'بلاغ عن السؤال 5',
        body: 'سطر أول\nسطر & ثانٍ',
      );

      final uri = draft.toMailtoUri();

      expect(uri.scheme, 'mailto');
      expect(uri.path, 'a@b.com');
      expect(uri.queryParameters['subject'], 'بلاغ عن السؤال 5');
      expect(uri.queryParameters['body'], 'سطر أول\nسطر & ثانٍ');
      // المسافة %20 لا «+» — بعض تطبيقات البريد تعرض «+» حرفياً.
      expect(uri.toString(), isNot(contains('+')));
    });
  });

  group('BuildQuestionReport', () {
    final draft = const BuildQuestionReport()(
      question: _question,
      reason: ReportReason.wrongAnswer,
      version: '1.0.4 (5)',
    );

    test('يُرسل إلى البريد العام وموضوعه رقم السؤال', () {
      expect(draft.to, AppConfig.contactEmail);
      expect(draft.subject, AppStrings.reportSubject(1021));
    });

    test('النص فيه كل ما يلزم لإيجاد السؤال وتصحيحه', () {
      final body = draft.body;

      expect(body, contains(AppStrings.reportWrongAnswer));
      expect(body, contains('1021'));
      expect(body, contains('كأس العالم'));
      expect(body, contains('${AppStrings.level} 3'));
      expect(body, contains(_question.text));
      expect(body, contains('1.0.4 (5)'));
    });

    test('الخيارات بترتيبها والمعتمدة وحدها معلّمة', () {
      final lines = draft.body.split('\n');

      expect(lines, contains('أ) فرنسا'));
      expect(lines, contains('ب) الأرجنتين ✓'));
      expect(lines, contains('ج) كرواتيا'));
      expect(lines, contains('د) البرازيل'));
      expect('✓'.allMatches(draft.body), hasLength(1));
    });

    test('لكل سبب نص مختلف غير فارغ', () {
      final labels = ReportReason.values.map(BuildQuestionReport.label).toSet();

      expect(labels, hasLength(ReportReason.values.length));
      expect(labels.every((l) => l.isNotEmpty), isTrue);
    });
  });

  group('BuildFeedbackEmail', () {
    test('بلا أخطاء: رقم الإصدار ونص «لا أخطاء»', () {
      final draft = const BuildFeedbackEmail()(version: '1.0.4 (5)', errors: []);

      expect(draft.to, AppConfig.contactEmail);
      expect(draft.subject, AppStrings.feedbackSubject);
      expect(draft.body, startsWith(AppStrings.feedbackBodyPrompt));
      expect(draft.body, contains('1.0.4 (5)'));
      expect(draft.body, contains(AppStrings.noRecentErrors));
    });

    test('أحدث الأخطاء فقط، بتاريخها ووقتها، والطويل مقصوص', () {
      final errors = [
        for (var i = 0; i < AppConfig.feedbackEmailErrors + 3; i++)
          ErrorEntry(
            at: DateTime(2026, 9, 14, 9, 5 + i),
            message: i == 0 ? 'X' * 500 : 'خطأ رقم $i',
          ),
      ];

      final body =
          const BuildFeedbackEmail()(version: 'v', errors: errors).body;
      final errorLines = body.split('\n').where((l) => l.startsWith('• '));

      expect(errorLines, hasLength(AppConfig.feedbackEmailErrors));
      expect(errorLines.first, startsWith('• 2026-09-14 09:05 · '));
      expect(errorLines.first, endsWith('…'));
      expect(errorLines.first.length, lessThan(200));
      expect(body, isNot(contains('خطأ رقم ${AppConfig.feedbackEmailErrors}')));
      expect(body, isNot(contains(AppStrings.noRecentErrors)));
    });
  });
}
