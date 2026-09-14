import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:football_trivia/core/constants/app_config.dart';

/// يتحقق من سلامة بنك الأسئلة كاملاً — يقرأ الملفات من القرص مباشرة.
///
/// هذا الاختبار هو خط الدفاع ضد تكرار الأسئلة بين التصنيفات: مع آلاف الأسئلة
/// لا يمكن الاعتماد على المراجعة البصرية.
void main() {
  final index = json.decode(
    File('assets/data/categories.json').readAsStringSync(),
  ) as Map<String, dynamic>;

  final categories = (index['categories'] as List<dynamic>)
      .cast<Map<String, dynamic>>();
  final levelsPerCategory = index['levelsPerCategory'] as int;
  final questionsPerLevel = index['questionsPerLevel'] as int;

  /// كل الأسئلة مع تصنيفها، محمّلة مرة واحدة.
  final all = <({String slug, int idBlock, Map<String, dynamic> q})>[];
  for (final c in categories) {
    final slug = c['slug'] as String;
    final file = File('assets/data/questions/$slug.json');
    final decoded =
        json.decode(file.readAsStringSync()) as Map<String, dynamic>;
    for (final q in decoded['questions'] as List<dynamic>) {
      all.add((
        slug: slug,
        idBlock: c['idBlock'] as int,
        q: q as Map<String, dynamic>,
      ));
    }
  }

  test('إعدادات التطبيق تطابق فهرس التصنيفات', () {
    // AppConfig.levelsPerCategory مستخدم في الواجهة والتخزين، فاختلافه عن
    // الملف يعني شبكة مستويات لا تطابق البيانات.
    expect(levelsPerCategory, AppConfig.levelsPerCategory);
    expect(questionsPerLevel, AppConfig.questionsPerLevel);
  });

  test('كل تصنيف يملك ملفاً وعدداً صحيحاً من الأسئلة', () {
    for (final c in categories) {
      final slug = c['slug'] as String;
      expect(
        File('assets/data/questions/$slug.json').existsSync(),
        isTrue,
        reason: 'ملف $slug.json مفقود',
      );

      final inCategory = all.where((e) => e.slug == slug);
      expect(
        inCategory.length,
        levelsPerCategory * questionsPerLevel,
        reason: 'التصنيف $slug لا يملك 100 سؤال',
      );

      for (var level = 1; level <= levelsPerCategory; level++) {
        expect(
          inCategory.where((e) => e.q['level'] == level).length,
          questionsPerLevel,
          reason: 'المستوى $level في $slug لا يملك $questionsPerLevel أسئلة',
        );
      }
    }
  });

  test('المعرّفات فريدة عالمياً وداخل نطاق التصنيف', () {
    final seen = <int, String>{};

    for (final e in all) {
      final id = e.q['id'] as int;

      expect(
        seen.containsKey(id),
        isFalse,
        reason: 'المعرّف $id مكرر بين ${seen[id]} و ${e.slug}',
      );
      seen[id] = e.slug;

      final offset = id - e.idBlock;
      expect(
        offset,
        inInclusiveRange(1, levelsPerCategory * questionsPerLevel),
        reason: 'المعرّف $id خارج نطاق التصنيف ${e.slug}',
      );

      // المستوى مشتق من موضع السؤال داخل النطاق.
      expect(
        e.q['level'],
        ((offset - 1) ~/ questionsPerLevel) + 1,
        reason: 'المعرّف $id لا يطابق مستواه',
      );
    }
  });

  test('بنية كل سؤال صحيحة', () {
    for (final e in all) {
      final q = e.q;
      final id = q['id'];

      final text = q['question'] as String;
      expect(text.trim(), isNotEmpty, reason: 'السؤال $id فارغ');

      final options = (q['options'] as List<dynamic>).cast<String>();
      expect(options.length, 4, reason: 'السؤال $id لا يملك 4 خيارات');
      expect(
        options.map(_normalize).toSet().length,
        4,
        reason: 'السؤال $id يحتوي خيارات مكررة',
      );
      for (final o in options) {
        expect(o.trim(), isNotEmpty, reason: 'خيار فارغ في السؤال $id');
      }

      expect(
        q['answerIndex'] as int,
        inInclusiveRange(0, 3),
        reason: 'answerIndex خارج النطاق في السؤال $id',
      );
    }
  });

  test('موضع الإجابة الصحيحة موزّع بالتساوي في كل تصنيف', () {
    // بدون هذا الفحص يميل كاتب الأسئلة لا شعورياً لوضع الإجابة في موضع واحد.
    // التطبيق يخلط الخيارات قبل العرض، لكن التوازن يبقي الملف قابلاً للمراجعة.
    for (final c in categories) {
      final slug = c['slug'] as String;
      final inCategory = all.where((e) => e.slug == slug).toList();
      final expected = inCategory.length / 4;

      for (var i = 0; i < 4; i++) {
        final count =
            inCategory.where((e) => e.q['answerIndex'] == i).length;
        expect(
          count,
          closeTo(expected, expected * 0.4),
          reason: 'التصنيف $slug: الموضع $i استُخدم $count مرة من '
              '${inCategory.length}',
        );
      }
    }
  });

  test('لا توجد خيارات من نوع "كل ما سبق" أو "لا يوجد"', () {
    // هذه الخيارات تفقد معناها لأن ترتيب الخيارات يُخلط قبل العرض.
    const banned = [
      'كل ما سبق',
      'جميع ما سبق',
      'كل ما ذكر',
      'لا شيء مما سبق',
      'لا يوجد',
      'لا أحد منهم',
      'كلاهما',
      'كلتاهما',
    ];

    final offenders = <String>[];
    for (final e in all) {
      for (final option in (e.q['options'] as List<dynamic>).cast<String>()) {
        for (final phrase in banned) {
          if (option.contains(phrase)) {
            offenders.add('${e.q['id']} (${e.slug}): "$option"');
          }
        }
      }
    }

    expect(offenders, isEmpty, reason: offenders.join('\n'));
  });

  test('لا توجد محارف اتجاه أو تنسيق مخفية', () {
    // لا تُرى بالعربية، لكنها تعيد ترتيب النص بصمت إن نُسخ إلى لغة تُكتب من
    // اليسار، وتُفشل مطابقة النصوص.
    final hidden = RegExp('[\u200B-\u200F\u061C\u202A-\u202E\u2066-\u2069\uFEFF]');

    final offenders = <String>[];
    for (final e in all) {
      final text = [
        e.q['question'],
        ...(e.q['options'] as List<dynamic>),
        e.q['explanation'] ?? '',
      ].join('\n');
      for (final m in hidden.allMatches(text)) {
        final code = m.group(0)!.codeUnitAt(0).toRadixString(16).toUpperCase();
        offenders.add('${e.q['id']} (${e.slug}): U+$code');
      }
    }

    expect(offenders, isEmpty, reason: offenders.join('\n'));
  });

  test('لا يوجد سؤال مكرر بين التصنيفات', () {
    final seen = <String, ({int id, String slug})>{};
    final duplicates = <String>[];

    for (final e in all) {
      final key = _normalize(e.q['question'] as String);
      final previous = seen[key];

      if (previous != null) {
        duplicates.add(
          'السؤال ${e.q['id']} (${e.slug}) يكرر '
          '${previous.id} (${previous.slug}): "${e.q['question']}"',
        );
      } else {
        seen[key] = (id: e.q['id'] as int, slug: e.slug);
      }
    }

    expect(duplicates, isEmpty, reason: duplicates.join('\n'));
  });

  test('لا يوجد سؤالان بنفس النص والإجابة الصحيحة بصياغة مختلفة قليلاً', () {
    // بصمة أضعف: نص السؤال بعد إزالة الكلمات الشائعة + نص الإجابة الصحيحة.
    final seen = <String, ({int id, String slug})>{};
    final collisions = <String>[];

    for (final e in all) {
      final options = (e.q['options'] as List<dynamic>).cast<String>();
      final answer = options[e.q['answerIndex'] as int];
      final key = '${_fingerprint(e.q['question'] as String)}|'
          '${_normalize(answer)}';

      final previous = seen[key];
      if (previous != null) {
        collisions.add(
          'السؤال ${e.q['id']} (${e.slug}) يشبه '
          '${previous.id} (${previous.slug}): "${e.q['question']}"',
        );
      } else {
        seen[key] = (id: e.q['id'] as int, slug: e.slug);
      }
    }

    expect(collisions, isEmpty, reason: collisions.join('\n'));
  });
}

/// توحيد النص العربي: إزالة التشكيل والتطويل وتوحيد الألف والهاء والياء.
String _normalize(String input) {
  final buffer = StringBuffer();

  for (final rune in input.runes) {
    final ch = String.fromCharCode(rune);

    // التشكيل (064B-0652) والتطويل (0640).
    if (rune >= 0x064B && rune <= 0x0652) continue;
    if (rune == 0x0640) continue;

    switch (ch) {
      case 'أ' || 'إ' || 'آ' || 'ٱ':
        buffer.write('ا');
      case 'ة':
        buffer.write('ه');
      case 'ى':
        buffer.write('ي');
      case 'ؤ':
        buffer.write('و');
      case 'ئ':
        buffer.write('ي');
      default:
        // نُبقي الحروف والأرقام فقط ونُسقط المسافات وعلامات الترقيم.
        if (RegExp(r'[\p{L}\p{N}]', unicode: true).hasMatch(ch)) {
          buffer.write(ch.toLowerCase());
        }
    }
  }

  return buffer.toString();
}

/// بصمة أخشن: تُسقط كلمات الاستفهام والربط الشائعة قبل التوحيد.
String _fingerprint(String input) {
  const noise = [
    'من', 'ما', 'هو', 'هي', 'أي', 'اي', 'في', 'على', 'عام', 'كم', 'هل',
    'التي', 'الذي', 'كان', 'هذه', 'هذا', 'مع', 'عن', 'إلى', 'الى',
  ];

  final words = input
      .split(RegExp(r'\s+'))
      .map(_normalize)
      .where((w) => w.isNotEmpty && !noise.contains(w))
      .toList()
    ..sort();

  return words.join();
}
