import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:football_trivia/core/theme/app_colors.dart';
import 'package:football_trivia/presentation/widgets/koora_buttons.dart';
import 'package:football_trivia/presentation/widgets/pitch_background.dart';
import 'package:football_trivia/presentation/widgets/rows_card.dart';
import 'package:football_trivia/presentation/widgets/surface.dart';

Future<void> _pump(WidgetTester tester, Widget child) => tester.pumpWidget(
      MaterialApp(
        locale: const Locale('ar'),
        home: Directionality(
          textDirection: TextDirection.rtl,
          child: Scaffold(body: Center(child: child)),
        ),
      ),
    );

/// عناصر التصميم المشتركة (Claude Design): المقاسات والألوان واتجاه الأيقونة.
void main() {
  testWidgets('الأزرار بارتفاعاتها، وأيقونتها على يسار النص', (tester) async {
    await _pump(
      tester,
      const Column(
        children: [
          GoldButton(label: 'ابدأ', onPressed: null, icon: Icons.play_arrow),
          SolidButton(label: 'لعب', onPressed: null),
          OutlineButton(label: 'المستويات', onPressed: null),
        ],
      ),
    );

    expect(tester.getSize(find.byType(GoldButton)).height, 56);
    expect(tester.getSize(find.byType(SolidButton)).height, 56);
    expect(tester.getSize(find.byType(OutlineButton)).height, 52);

    // في العربية يقع النص يميناً والأيقونة يساره.
    expect(
      tester.getCenter(find.byIcon(Icons.play_arrow)).dx,
      lessThan(tester.getCenter(find.text('ابدأ')).dx),
    );
  });

  testWidgets('الزر الذهبي يعمل عند التفعيل ويخفت عند التعطيل', (tester) async {
    var taps = 0;
    await _pump(tester, GoldButton(label: 'ابدأ', onPressed: () => taps++));
    await tester.tap(find.byType(GoldButton));
    expect(taps, 1);

    await _pump(tester, const GoldButton(label: 'ابدأ', onPressed: null));
    await tester.tap(find.byType(GoldButton));
    expect(taps, 1);
    expect(
      tester.widget<Text>(find.text('ابدأ')).style!.color,
      AppColors.chalkMuted,
    );
  });

  testWidgets('حبّة الحالة بارتفاع 48 وتعرض الرقم والوقت التالي', (tester) async {
    await _pump(
      tester,
      const StatusPill(icon: Icons.favorite_rounded, label: '3/5', trailing: '9 د'),
    );

    expect(tester.getSize(find.byType(StatusPill)).height, 48);
    expect(find.text('3/5'), findsOneWidget);
    expect(find.text('9 د'), findsOneWidget);
  });

  testWidgets('بطاقة السطح تُظهر محتواها وتستجيب للمس', (tester) async {
    var taps = 0;
    await _pump(
      tester,
      Surface(onTap: () => taps++, child: const Text('محتوى')),
    );

    expect(find.text('محتوى'), findsOneWidget);
    await tester.tap(find.byType(Surface));
    expect(taps, 1);
  });

  testWidgets('بطاقة الصفوف تفصل صفوفها بخطوط، والعنوان ذهبي', (tester) async {
    await _pump(
      tester,
      const Column(
        children: [
          SectionHeading('إحصائياتك'),
          RowsCard(
            children: [
              KooraRow(label: 'سلسلة الأيام', value: 'يوم واحد'),
              KooraRow(label: 'أفضل نتيجة', value: '898'),
              KooraRow(label: 'عدد الجولات', value: '5'),
            ],
          ),
        ],
      ),
    );

    expect(find.byType(Divider), findsNWidgets(2));
    expect(find.text('898'), findsOneWidget);
    expect(
      tester.widget<Text>(find.text('إحصائياتك')).style!.color,
      AppColors.gold,
    );
  });

  testWidgets('شريط التقدّم يملأ بنسبة القيمة', (tester) async {
    await _pump(
      tester,
      const SizedBox(width: 200, child: KooraProgress(value: 0.5)),
    );

    expect(
      tester.widget<FractionallySizedBox>(find.byType(FractionallySizedBox))
          .widthFactor,
      0.5,
    );
    expect(tester.getSize(find.byType(KooraProgress)).height, 6);
  });

  testWidgets('خلفية الملعب ترسم المحتوى فوقها دون قصّه', (tester) async {
    await _pump(
      tester,
      const SizedBox(
        width: 390,
        height: 844,
        child: PitchBackground(child: Center(child: Text('فوق الملعب'))),
      ),
    );

    expect(find.text('فوق الملعب'), findsOneWidget);
    expect(find.byIcon(Icons.sports_soccer), findsOneWidget);
  });
}
