import 'package:flutter_test/flutter_test.dart';
import 'package:football_trivia/core/utils/arabic_count.dart';

void main() {
  group('ArabicCount.format — يوم', () {
    const cases = <(int, String)>[
      (0, '0 يوم'),
      (1, 'يوم واحد'),
      (2, 'يومان'),
      (3, '3 أيام'),
      (10, '10 أيام'),
      (11, '11 يوماً'),
      (99, '99 يوماً'),
      (100, '100 يوم'),
      (102, '102 يوم'),
      (103, '103 أيام'),
      (111, '111 يوماً'),
    ];

    for (final (count, expected) in cases) {
      test('$count → $expected', () {
        expect(ArabicCount.format(count, ArabicNoun.day), expected);
      });
    }
  });

  test('المؤنث: نجمة واحدة · نجمتان · 3 نجوم · 11 نجمة', () {
    expect(ArabicCount.format(1, ArabicNoun.star), 'نجمة واحدة');
    expect(ArabicCount.format(2, ArabicNoun.star), 'نجمتان');
    expect(ArabicCount.format(3, ArabicNoun.star), '3 نجوم');
    expect(ArabicCount.format(11, ArabicNoun.star), '11 نجمة');
  });

  test('المثنى بعد فعل أو مضاف منصوب، وبقية الأعداد لا تتأثر', () {
    expect(ArabicCount.format(2, ArabicNoun.star, object: true), 'نجمتين');
    expect(ArabicCount.format(2, ArabicNoun.level, object: true), 'مستويين');
    expect(ArabicCount.format(5, ArabicNoun.level, object: true), '5 مستويات');
    expect(
      ArabicCount.format(10, ArabicNoun.correctAnswer, object: true),
      '10 إجابات صحيحة',
    );
  });

  test('نقاط النتيجة الكبيرة تتبع آخر رقمين', () {
    expect(ArabicCount.format(0, ArabicNoun.point), '0 نقطة');
    expect(ArabicCount.format(1250, ArabicNoun.point), '1250 نقطة');
    expect(ArabicCount.format(1205, ArabicNoun.point), '1205 نقاط');
    expect(ArabicCount.format(1300, ArabicNoun.point), '1300 نقطة');
  });

  test('الأسئلة: عدد تحدي اليوم وعدد المستوى', () {
    expect(ArabicCount.format(7, ArabicNoun.question), '7 أسئلة');
    expect(ArabicCount.format(15, ArabicNoun.question), '15 سؤالاً');
  });

  group('ArabicCount.nounFor — الاسم وحده تحت رقم منفصل', () {
    test('يتبع آخر رقمين', () {
      expect(ArabicCount.nounFor(0, ArabicNoun.point), 'نقطة');
      expect(ArabicCount.nounFor(2, ArabicNoun.point), 'نقطة');
      expect(ArabicCount.nounFor(5, ArabicNoun.point), 'نقاط');
      expect(ArabicCount.nounFor(150, ArabicNoun.point), 'نقطة');
      expect(ArabicCount.nounFor(1207, ArabicNoun.point), 'نقاط');
    });
  });

  test('لكل اسم صيغ مختلفة للواحد والمثنى والجمع', () {
    for (final noun in const [
      ArabicNoun.day,
      ArabicNoun.star,
      ArabicNoun.point,
      ArabicNoun.level,
      ArabicNoun.question,
      ArabicNoun.correctAnswer,
    ]) {
      final forms = {noun.one, noun.dual, noun.dualObject, noun.plural};
      expect(forms, hasLength(4), reason: noun.singular);
    }
  });
}
