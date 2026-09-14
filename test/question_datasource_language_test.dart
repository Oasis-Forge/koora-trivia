import 'package:flutter_test/flutter_test.dart';
import 'package:football_trivia/core/constants/app_strings.dart';
import 'package:football_trivia/data/datasources/question_local_datasource.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  tearDown(() => AppText.use('ar'));

  // يقرأ الملفات الحقيقية عبر rootBundle: مجلد لغة غير مُعلن في pubspec يُفشل الاختبار،
  // لا التطبيق وحده بعد النشر.
  test('يقرأ بنك لغة التطبيق بالمعرّفات نفسها، ولكل لغة نسختها المحفوظة', () async {
    var language = 'ar';
    final source = AssetQuestionDataSource(language: () => language);

    final ar = await source.load();
    language = 'en';
    final en = await source.load();

    expect(ar.categories.first.name, 'كأس العالم');
    expect(en.categories.first.name, 'World Cup');
    expect(en.questions.map((q) => q.id), ar.questions.map((q) => q.id));
    expect(en.questions.first.categoryName, 'World Cup');
    expect(en.questions.first.text, isNot(ar.questions.first.text));

    // لا قراءة ثانية: كل لغة تعود بنسختها.
    expect(identical(await source.load(), en), isTrue);
    language = 'ar';
    expect(identical(await source.load(), ar), isTrue);
  });

  test('بلا لغة محددة يتبع لغة AppStrings الحالية', () async {
    AppText.use('en');
    final bank = await AssetQuestionDataSource().load();
    expect(bank.categories.first.name, 'World Cup');
  });
}
