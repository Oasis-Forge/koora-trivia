import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:football_trivia/core/constants/app_strings.dart';
import 'package:football_trivia/domain/entities/app_settings.dart';
import 'package:football_trivia/domain/entities/category.dart';
import 'package:football_trivia/domain/entities/economy.dart';
import 'package:football_trivia/domain/entities/question.dart';
import 'package:football_trivia/domain/repositories/quiz_repository.dart';
import 'package:football_trivia/presentation/providers/ads_provider.dart';
import 'package:football_trivia/presentation/providers/economy_provider.dart';
import 'package:football_trivia/presentation/providers/quiz_provider.dart';
import 'package:football_trivia/presentation/providers/settings_provider.dart';
import 'package:football_trivia/presentation/screens/quiz_screen.dart';
import 'package:football_trivia/presentation/widgets/answer_option.dart';
import 'package:football_trivia/presentation/widgets/banner_slot.dart';
import 'package:football_trivia/presentation/widgets/hint_bar.dart';
import 'package:football_trivia/presentation/widgets/surface.dart';
import 'package:provider/provider.dart';

import 'fakes/fake_ad_service.dart';
import 'fakes/fake_repositories.dart';

/// بطول سؤال حقيقي متوسط.
const _questionText = 'من سجّل أكثر الأهداف في تاريخ كأس العالم؟';

/// شرح طويل بما يكفي ليقع خارج الشاشة القصيرة تحت الخيارات.
const _explanation =
    'سجّل ميروسلاف كلوزه ستة عشر هدفاً في أربع نسخ متتالية من البطولة.';

class _QuizRepository implements QuizRepository {
  _QuizRepository({this.text = _questionText});

  final String text;

  @override
  Future<List<Category>> getCategories() async => const [];

  @override
  Future<List<Question>> getLevelQuestions({
    required String categorySlug,
    required int level,
  }) async =>
      [
        for (var i = 1; i <= 10; i++)
          Question(
            id: 1000 + i,
            category: categorySlug,
            categoryName: 'ألفا',
            level: level,
            text: text,
            options: const ['أ', 'ب', 'ج', 'د'],
            answerIndex: 0,
            explanation: _explanation,
          ),
      ];

  @override
  Future<int> getLevelCount(String categorySlug) async => 10;

  @override
  Future<List<Question>> getRandomQuestions({
    required int count,
    String? categorySlug,
  }) async =>
      const [];

  @override
  Future<List<Question>> getDailyQuestions({
    required String dayKey,
    required int count,
  }) async =>
      const [];
}

/// شاشة سؤال في نمط المستويات (أضيق حالة: فيها شريط المساعدات) بمقاس [size].
Future<QuizProvider> _pumpQuiz(
  WidgetTester tester,
  Size size, {
  String text = _questionText,
  bool banners = false,
}) async {
  tester.view.physicalSize = size;
  tester.view.devicePixelRatio = 1;
  tester.view.padding = const FakeViewPadding(top: 24);
  addTearDown(tester.view.reset);

  final quiz = QuizProvider(repository: _QuizRepository(text: text));
  final economy = EconomyProvider(
    repository: FakeEconomyRepository(
      Economy(lastRegenAtIso: DateTime.now().toIso8601String()),
    ),
  );
  final settings = SettingsProvider(
    repository: FakeSettingsRepository(
      const AppSettings(soundEnabled: false, hapticsEnabled: false),
    ),
    scheduler: FakeScheduler(),
  );
  await economy.init();
  await settings.init();
  await quiz.startLevel(categorySlug: 'alpha', level: 1);

  await tester.pumpWidget(
    MultiProvider(
      providers: [
        ChangeNotifierProvider.value(value: quiz),
        ChangeNotifierProvider.value(value: economy),
        ChangeNotifierProvider.value(value: settings),
        ChangeNotifierProvider(
          create: (_) =>
              AdsProvider(service: FakeAdService(bannersAllowed: banners)),
        ),
      ],
      child: const MaterialApp(
        home: Directionality(
          textDirection: TextDirection.rtl,
          child: QuizScreen(),
        ),
      ),
    ),
  );
  await tester.pump();
  return quiz;
}

/// مؤقّت السؤال يعيش في المزوّد لا في الشجرة، فيُتلف صراحةً.
Future<void> _finish(WidgetTester tester, QuizProvider quiz) async {
  await tester.pumpWidget(const SizedBox());
  quiz.dispose();
}

double _scrollPixels(WidgetTester tester) =>
    tester.state<ScrollableState>(find.byType(Scrollable)).position.pixels;

double _questionFontSize(WidgetTester tester) =>
    tester.widget<Text>(find.text(_questionText)).style!.fontSize!;

Future<void> _settle(WidgetTester tester) async {
  // اللوحة تنتظر انتهاء حركة الخيارات ثم تمرّر نفسها إلى المنطقة المرئية.
  await tester.pump(const Duration(milliseconds: 300));
  await tester.pumpAndSettle();
}

void main() {
  const short = Size(360, 640);
  const tall = Size(412, 915);

  testWidgets('على 360×640 يظهر الخيار الرابع فوق شريط المساعدات دون تمرير',
      (tester) async {
    final quiz = await _pumpQuiz(tester, short);

    final lastOption = tester.getRect(find.byType(AnswerOption).last);
    final hintBar = tester.getRect(find.byType(HintBar));
    expect(lastOption.bottom, lessThanOrEqualTo(hintBar.top));
    expect(_questionFontSize(tester), 18);

    await _finish(tester, quiz);
  });

  testWidgets('الشريط الإعلاني يبقى تحت الخيارات ولا يلامسها', (tester) async {
    // شريط إعلاني ملاصق لزر إجابة = نقرات خاطئة، وهي عند AdMob «حركة غير
    // صالحة» تُعرّض الحساب للإيقاف. أضيق شاشة هي أخطر حالة، وأطول شريط
    // متكيّف تسمح به غوغل هو 15% من ارتفاع الشاشة.
    const size = Size(320, 640);
    const tallest = 0.15 * 640;
    BannerSlot.testAdBuilder = (_) => const SizedBox.expand();
    BannerSlot.testAdHeight = tallest;
    addTearDown(() {
      BannerSlot.testAdBuilder = null;
      BannerSlot.testAdHeight = null;
    });
    final quiz = await _pumpQuiz(tester, size, banners: true);

    final lastOption = tester.getRect(find.byType(AnswerOption).last);
    final banner = tester.getRect(find.byType(BannerSlot));

    // أطول من الحدّ في شاشة السؤال، فيعود إلى المقاس الثابت.
    expect(banner.height, BannerSlot.adHeight + BannerSlot.gap);
    expect(banner.top, greaterThanOrEqualTo(lastOption.bottom));
    // الخيار الرابع ظاهر دون تمرير والوقت يجري.
    expect(lastOption.bottom, lessThanOrEqualTo(size.height));
    await _finish(tester, quiz);
  });

  testWidgets('على الشاشة الطويلة: المقاس العادي، والخيارات ملاصقة للمساعدات',
      (tester) async {
    final quiz = await _pumpQuiz(tester, tall);

    expect(_questionFontSize(tester), 21);
    final lastOption = tester.getRect(find.byType(AnswerOption).last);
    final hintBar = tester.getRect(find.byType(HintBar));
    // الفاصل هو هامش المحتوى السفلي وحده، لا فراغ موزّع فوقه.
    expect(hintBar.top - lastOption.bottom, lessThanOrEqualTo(20));

    await _finish(tester, quiz);
  });

  testWidgets('بعد الإجابة تُمرَّر لوحة الشرح حتى تظهر كاملة فوق زر التالي',
      (tester) async {
    final quiz = await _pumpQuiz(tester, short);

    await tester.tap(find.byType(AnswerOption).first);
    await tester.pump();
    await _settle(tester);

    final explanation = tester.getRect(find.text(_explanation));
    final next = tester.getRect(find.text(AppStrings.next));
    expect(explanation.bottom, lessThanOrEqualTo(next.top));

    await _finish(tester, quiz);
  });

  testWidgets('مساعدة التخطّي تُعرض كتخطٍّ لا كانتهاء وقت', (tester) async {
    final quiz = await _pumpQuiz(tester, short);

    quiz.skipQuestion();
    await tester.pump();

    expect(find.text(AppStrings.skippedAnswer), findsOneWidget);
    expect(find.text(AppStrings.timeUp), findsNothing);
    await _settle(tester);

    await _finish(tester, quiz);
  });

  testWidgets('السؤال التالي يبدأ من أعلى الشاشة بعد تمرير لوحة الشرح',
      (tester) async {
    // خط نظام كبير يجعل السؤال نفسه أطول من الشاشة، فيبقى أي إزاح قديم ظاهراً.
    tester.platformDispatcher.textScaleFactorTestValue = 2;
    addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
    final quiz = await _pumpQuiz(tester, short);

    quiz.selectAnswer(1);
    await tester.pump();
    await _settle(tester);
    expect(_scrollPixels(tester), greaterThan(0), reason: 'اللوحة مُرِّرت');

    await tester.tap(find.text(AppStrings.next));
    await tester.pump();

    expect(_scrollPixels(tester), 0);
    await _finish(tester, quiz);
  });

  testWidgets('لوحة أطول من الشاشة تُظهر أعلاها: الحكم والإجابة الصحيحة',
      (tester) async {
    tester.platformDispatcher.textScaleFactorTestValue = 2;
    addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
    final quiz = await _pumpQuiz(tester, const Size(320, 480));

    quiz.selectAnswer(1);
    await tester.pump();
    await _settle(tester);

    final viewport = tester.getRect(find.byType(CustomScrollView));
    final panel = find.byWidgetPredicate(
      (w) => w.runtimeType.toString() == '_FeedbackPanel',
    );
    expect(
      tester.getSize(panel).height,
      greaterThan(viewport.height),
      reason: 'اللوحة أطول من المنطقة المرئية',
    );
    expect(
      tester.getRect(find.text(AppStrings.wrong)).top,
      greaterThanOrEqualTo(viewport.top),
    );
    await _finish(tester, quiz);
  });

  testWidgets('بطاقة سؤال قصير تملأ العرض كالخيارات تحتها', (tester) async {
    const text = 'من فاز؟';
    final quiz = await _pumpQuiz(tester, short, text: text);

    final card = find
        .ancestor(of: find.text(text), matching: find.byType(Surface))
        .first;
    expect(
      tester.getSize(card).width,
      tester.getSize(find.byType(AnswerOption).first).width,
    );

    // الوسمان (التصنيف والصعوبة) بعرض نصّهما لا بعرض البطاقة.
    final tags = find.descendant(
      of: card,
      matching: find.byWidgetPredicate(
        (w) => w is Container && w.constraints?.minHeight == 32,
      ),
    );
    expect(tags, findsNWidgets(2));
    for (final tag in tags.evaluate()) {
      expect(
        tag.size!.width,
        lessThan(tester.getSize(card).width * 0.6),
      );
    }

    await _finish(tester, quiz);
  });

  testWidgets('زر «أبلغ عن خطأ» يظهر في لوحة الشرح بعد كشف الإجابة فقط',
      (tester) async {
    final quiz = await _pumpQuiz(tester, tall);
    expect(find.text(AppStrings.reportQuestion), findsNothing);

    quiz.selectAnswer(0);
    await tester.pump();
    await _settle(tester);

    expect(find.text(AppStrings.reportQuestion), findsOneWidget);
    await _finish(tester, quiz);
  });

  testWidgets('انتهاء الوقت ما زال يُعرض كانتهاء وقت', (tester) async {
    final quiz = await _pumpQuiz(tester, short);

    await tester.pump(const Duration(seconds: 21));

    expect(find.text(AppStrings.timeUp), findsOneWidget);
    expect(find.text(AppStrings.skippedAnswer), findsNothing);
    await _settle(tester);

    await _finish(tester, quiz);
  });


  // القلب يُخصم عند بدء المحاولة لا عند الخطأ، واللمسة الثانية لا تُسجَّل.
  testWidgets('لمستان سريعتان على خيار خاطئ تسجّلان إجابة واحدة ولا تخصمان قلباً',
      (tester) async {
    final quiz = await _pumpQuiz(tester, tall);
    final economy = Provider.of<EconomyProvider>(
      tester.element(find.byType(QuizScreen)),
      listen: false,
    );
    final before = economy.hearts;

    // الخيار الأول صحيح في هذا البنك، والثاني خاطئ. اللمسة الثانية قبل إعادة البناء.
    await tester.tap(find.byType(AnswerOption).at(1));
    await tester.tap(find.byType(AnswerOption).at(1), warnIfMissed: false);
    await _settle(tester);

    expect(economy.hearts, before);
    expect(quiz.answers, hasLength(1));
    await _finish(tester, quiz);
  });

  testWidgets('مغادرة التطبيق توقف العدّاد وتخفي السؤال حتى العودة',
      (tester) async {
    final quiz = await _pumpQuiz(tester, tall);

    // `inactive` أول حالة تصل عند مغادرة التطبيق، وما زالت الإطارات تُرسم فيها
    // (بعد `paused` يتوقف الرسم، فلا تظهر شاشة الإيقاف في الاختبار).
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.inactive);
    await tester.pump();
    expect(quiz.isPaused, isTrue);
    expect(find.text(AppStrings.quizPaused), findsOneWidget);
    expect(find.text(_questionText), findsNothing);

    final left = quiz.secondsLeft;
    await tester.pump(const Duration(seconds: 5));
    expect(quiz.secondsLeft, left);

    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
    await tester.pump();
    expect(quiz.isPaused, isFalse);
    expect(find.text(_questionText), findsOneWidget);
    await _finish(tester, quiz);
  });
}
