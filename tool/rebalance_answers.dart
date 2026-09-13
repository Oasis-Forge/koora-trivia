import 'dart:convert';
import 'dart:io';

/// يعيد توزيع موضع الإجابة الصحيحة ليكون متوازناً تماماً (25% لكل موضع).
///
/// **شغّل هذه الأداة بعد أي إضافة أو تعديل لأسئلة بنك الأسئلة.**
///
/// ```bash
/// dart run tool/rebalance_answers.dart
/// ```
///
/// كاتب الأسئلة — بشراً كان أو نموذجاً — يميل لا شعورياً لوضع الإجابة الصحيحة
/// في موضع واحد. حدث ذلك فعلاً في هذا المشروع: 66% من أول 300 سؤال كانت
/// إجابتها في الموضع 1، والموضع 3 استُخدم مرتين فقط.
///
/// الأداة تحرّك نص الإجابة الصحيحة إلى الموضع المستهدف بالتبادل مع ما فيه،
/// فتبقى الخيارات الأربعة كما هي ويتغيّر ترتيبها فقط. آمنة للتشغيل المتكرر.
///
/// يحرسها اختبار في `test/question_bank_test.dart` يفشل عند اختلال التوازن.
void main() {
  final index = json.decode(
    File('assets/data/categories.json').readAsStringSync(),
  ) as Map<String, dynamic>;

  for (final c in (index['categories'] as List<dynamic>)) {
    final slug = (c as Map<String, dynamic>)['slug'] as String;
    final file = File('assets/data/questions/$slug.json');
    final decoded = json.decode(file.readAsStringSync()) as Map<String, dynamic>;
    final questions = (decoded['questions'] as List<dynamic>)
        .cast<Map<String, dynamic>>();

    // قائمة أهداف متوازنة تماماً، تُخلط ببذرة ثابتة مشتقة من اسم الملف
    // حتى تكون النتيجة حتمية ولا تتغيّر بين تشغيل وآخر.
    final targets = <int>[for (var i = 0; i < questions.length; i++) i % 4];
    var state = slug.codeUnits.fold<int>(7, (a, b) => a * 31 + b) & 0x7FFFFFFF;
    for (var i = targets.length - 1; i > 0; i--) {
      state = (state * 1664525 + 1013904223) & 0x7FFFFFFF;
      final j = state % (i + 1);
      final tmp = targets[i];
      targets[i] = targets[j];
      targets[j] = tmp;
    }

    for (var i = 0; i < questions.length; i++) {
      final q = questions[i];
      final options = (q['options'] as List<dynamic>).cast<String>();
      final current = q['answerIndex'] as int;
      final target = targets[i];

      if (current != target) {
        final tmp = options[target];
        options[target] = options[current];
        options[current] = tmp;
        q['options'] = options;
        q['answerIndex'] = target;
      }
    }

    file.writeAsStringSync(
      '${const JsonEncoder.withIndent('  ').convert(decoded)}\n',
    );

    final counts = <int, int>{0: 0, 1: 0, 2: 0, 3: 0};
    for (final q in questions) {
      final i = q['answerIndex'] as int;
      counts[i] = counts[i]! + 1;
    }
    stdout.writeln(
      '${slug.padRight(18)} 0=${counts[0]}  1=${counts[1]}  '
      '2=${counts[2]}  3=${counts[3]}',
    );
  }
}
