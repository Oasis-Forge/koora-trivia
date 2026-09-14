import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:football_trivia/core/constants/app_config.dart';
import 'package:football_trivia/core/constants/app_strings.dart';
import 'package:football_trivia/domain/entities/question.dart';
import 'package:football_trivia/domain/repositories/app_info.dart';
import 'package:football_trivia/domain/repositories/link_opener.dart';
import 'package:football_trivia/domain/usecases/build_question_report.dart';
import 'package:football_trivia/presentation/widgets/report_question_button.dart';
import 'package:provider/provider.dart';

import 'fakes/fake_repositories.dart';

const _question = Question(
  id: 3072,
  category: 'champions_league',
  categoryName: 'دوري أبطال أوروبا',
  level: 8,
  text: 'سؤال للاختبار',
  options: ['أ', 'ب', 'ج', 'د'],
  answerIndex: 2,
);

Future<FakeLinkOpener> _pump(
  WidgetTester tester, {
  bool emailAppExists = true,
  bool compact = false,
  Completer<bool>? gate,
}) async {
  final opener = FakeLinkOpener(result: emailAppExists, gate: gate);
  await tester.pumpWidget(
    MultiProvider(
      providers: [
        Provider<LinkOpener>.value(value: opener),
        Provider<AppInfo>.value(value: FakeAppInfo('1.0.4 (5)')),
      ],
      child: MaterialApp(
        home: Directionality(
          textDirection: TextDirection.rtl,
          child: Scaffold(
            body: Center(
              child: ReportQuestionButton(question: _question, compact: compact),
            ),
          ),
        ),
      ),
    ),
  );
  return opener;
}

void main() {
  testWidgets('اللمس يعرض الأسباب، والاختيار يفتح رسالة بريد بالبلاغ',
      (tester) async {
    final opener = await _pump(tester);

    await tester.tap(find.text(AppStrings.reportQuestion));
    await tester.pumpAndSettle();

    expect(find.text(AppStrings.reportQuestionTitle), findsOneWidget);
    for (final reason in ReportReason.values) {
      expect(find.text(BuildQuestionReport.label(reason)), findsOneWidget);
    }

    await tester.tap(find.text(AppStrings.reportTwoCorrect));
    await tester.pumpAndSettle();

    final uri = opener.opened.single;
    expect(uri.scheme, 'mailto');
    expect(uri.path, AppConfig.contactEmail);
    expect(uri.queryParameters['subject'], AppStrings.reportSubject(3072));
    expect(uri.queryParameters['body'], contains(AppStrings.reportTwoCorrect));
    expect(uri.queryParameters['body'], contains('1.0.4 (5)'));
    expect(find.text(AppStrings.reportQuestionTitle), findsNothing);
  });

  testWidgets('إغلاق القائمة دون اختيار لا يفتح شيئاً', (tester) async {
    final opener = await _pump(tester);

    await tester.tap(find.text(AppStrings.reportQuestion));
    await tester.pumpAndSettle();
    await tester.tapAt(const Offset(10, 10));
    await tester.pumpAndSettle();

    expect(find.text(AppStrings.reportQuestionTitle), findsNothing);
    expect(opener.opened, isEmpty);
  });

  testWidgets('بلا تطبيق بريد تظهر رسالة فيها عنوان البريد', (tester) async {
    await _pump(tester, emailAppExists: false);

    await tester.tap(find.text(AppStrings.reportQuestion));
    await tester.pumpAndSettle();
    await tester.tap(find.text(AppStrings.reportTypo));
    await tester.pumpAndSettle();

    expect(
      find.text(AppStrings.noEmailApp(AppConfig.contactEmail)),
      findsOneWidget,
    );
  });

  testWidgets('الصيغة المضغوطة أيقونة بتلميح مقروء، وتعمل مثل الزر',
      (tester) async {
    final opener = await _pump(tester, compact: true);

    expect(find.text(AppStrings.reportQuestion), findsNothing);
    await tester.tap(find.byTooltip(AppStrings.reportQuestion));
    await tester.pumpAndSettle();
    await tester.tap(find.text(AppStrings.reportOther));
    await tester.pumpAndSettle();

    expect(opener.opened, hasLength(1));
  });

  testWidgets('القائمة تبقى حتى يُطلب فتح البريد، ولمسة ثانية لا تفتحه مرتين',
      (tester) async {
    final gate = Completer<bool>();
    final opener = await _pump(tester, gate: gate);

    await tester.tap(find.text(AppStrings.reportQuestion));
    await tester.pumpAndSettle();
    await tester.tap(find.text(AppStrings.reportTypo));
    await tester.pumpAndSettle();

    // حاجز القائمة ما زال يمنع لمس ما خلفها.
    expect(find.text(AppStrings.reportQuestionTitle), findsOneWidget);
    await tester.tap(find.text(AppStrings.reportOther));
    await tester.pumpAndSettle();
    expect(opener.opened, hasLength(1));

    gate.complete(true);
    await tester.pumpAndSettle();
    expect(find.text(AppStrings.reportQuestionTitle), findsNothing);
    expect(
      find.text(AppStrings.noEmailApp(AppConfig.contactEmail)),
      findsNothing,
    );
  });

  testWidgets('إغلاق القائمة أثناء فتح البريد لا يغلق الشاشة التي تحتها',
      (tester) async {
    const page = 'صفحة السؤال';
    final gate = Completer<bool>();
    await _pump(tester, gate: gate);
    tester.state<NavigatorState>(find.byType(Navigator)).push(
          MaterialPageRoute<void>(
            builder: (_) => const Scaffold(
              body: Column(
                children: [
                  Text(page),
                  ReportQuestionButton(question: _question),
                ],
              ),
            ),
          ),
        );
    await tester.pumpAndSettle();

    await tester.tap(find.text(AppStrings.reportQuestion));
    await tester.pumpAndSettle();
    await tester.tap(find.text(AppStrings.reportWrongAnswer));
    await tester.pumpAndSettle();
    await tester.tapAt(const Offset(10, 10));
    await tester.pump();
    // القائمة ما زالت تخرج حين يعود طلب الفتح.
    gate.complete(true);
    await tester.pumpAndSettle();

    expect(find.text(page), findsOneWidget);
  });
}
