import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

/// البنك الإنجليزي ترجمة للعربي بالمعرّفات نفسها: تحدي يوم واحد للجميع، والتقدّم
/// لا يتغيّر بتغيير اللغة. أي تعديل على سؤال عربي يحتاج التعديل نفسه هنا.
/// نطاق أحرف من رموزه، لا بأحرف اتجاه مخفية داخل الكود (يحذّر منها المحلّل).
String _range(int from, int to) =>
    '${String.fromCharCode(from)}-${String.fromCharCode(to)}';

final _arabic = RegExp('[${_range(0x0600, 0x06FF)}${_range(0x0750, 0x077F)}'
    '${_range(0xFB50, 0xFDFF)}${_range(0xFE70, 0xFEFF)}]');
final _invisible = RegExp('[${_range(0x200B, 0x200F)}${_range(0x202A, 0x202E)}'
    '${_range(0x2066, 0x2069)}${String.fromCharCode(0xFEFF)}]');
const _bannedOptions = {
  'all of the above',
  'none of the above',
  'none',
  'both',
  'neither',
  'nobody',
  'no one',
  'it never happened',
  'never happened',
};

Map<String, dynamic> _load(String path) =>
    jsonDecode(File(path).readAsStringSync()) as Map<String, dynamic>;

List<String> _textProblems(String where, String text) => [
      if (text.trim().isEmpty) '$where: empty',
      if (_arabic.hasMatch(text)) '$where: Arabic script',
      if (_invisible.hasMatch(text)) '$where: invisible character',
    ];

void main() {
  final arCategories = _load('assets/data/categories.json');
  final slugs = [
    for (final c in arCategories['categories'] as List) (c as Map)['slug'] as String,
  ];

  test('التصنيفات الإنجليزية نفسها بترتيبها ونطاق معرّفاتها، بأسماء إنجليزية', () {
    final en = _load('assets/data/en/categories.json');
    final problems = <String>[];
    for (final key in const ['version', 'levelsPerCategory', 'questionsPerLevel']) {
      if (en[key] != arCategories[key]) problems.add('$key differs');
    }
    final ar = arCategories['categories'] as List;
    final list = en['categories'] as List;
    expect(list.length, ar.length);
    for (var i = 0; i < ar.length; i++) {
      final a = ar[i] as Map;
      final e = list[i] as Map;
      for (final key in const ['slug', 'idBlock', 'order']) {
        if (e[key] != a[key]) problems.add('${a['slug']}: $key differs');
      }
      problems.addAll(_textProblems('${a['slug']} name', '${e['name'] ?? ''}'));
    }
    expect(problems, isEmpty, reason: problems.join('\n'));
  });

  for (final slug in slugs) {
    test('$slug: الإنجليزية تطابق العربية في المعرّفات والإجابات والأرقام', () {
      final ar = _load('assets/data/questions/$slug.json');
      final en = _load('assets/data/en/questions/$slug.json');
      final problems = <String>[
        if (en['version'] != ar['version']) 'version differs',
        if (en['category'] != ar['category']) 'category differs',
      ];
      final aq = ar['questions'] as List;
      final eq = en['questions'] as List;
      expect(eq.length, aq.length);

      for (var i = 0; i < aq.length; i++) {
        final a = aq[i] as Map;
        final e = eq[i] as Map;
        final id = a['id'];
        for (final key in const ['id', 'level', 'answerIndex']) {
          if (e[key] != a[key]) problems.add('$id: $key differs');
        }
        if (!e.keys.toSet().containsAll(a.keys) ||
            !a.keys.toSet().containsAll(e.keys)) {
          problems.add('$id: fields differ');
        }

        final aOptions = [for (final o in a['options'] as List) '$o'];
        final eOptions = [for (final o in e['options'] as List) '$o'];
        if (eOptions.length != aOptions.length) {
          problems.add('$id: option count differs');
          continue;
        }
        if (eOptions.map((o) => o.trim().toLowerCase()).toSet().length !=
            eOptions.length) {
          problems.add('$id: options not distinct');
        }
        for (var j = 0; j < aOptions.length; j++) {
          // خيار بلا حروف عربية (سنة، نتيجة، عدد) يبقى كما هو حرفياً.
          if (!_arabic.hasMatch(aOptions[j]) &&
              eOptions[j].trim() != aOptions[j].trim()) {
            problems.add('$id: option $j must stay "${aOptions[j]}"');
          }
          final bare = eOptions[j].trim().toLowerCase().replaceAll(RegExp(r'[.!]$'), '');
          if (_bannedOptions.contains(bare)) {
            problems.add('$id: banned option "${eOptions[j]}"');
          }
          problems.addAll(_textProblems('$id option $j', eOptions[j]));
        }
        problems.addAll(_textProblems('$id question', '${e['question'] ?? ''}'));
        if (a.containsKey('explanation')) {
          problems.addAll(
              _textProblems('$id explanation', '${e['explanation'] ?? ''}'));
        }
      }
      expect(problems, isEmpty, reason: problems.take(30).join('\n'));
    });
  }
}
