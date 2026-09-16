import 'dart:convert';
import 'dart:io';
import 'dart:math';

import 'package:flutter_test/flutter_test.dart';

/// قواعد محتوى البنك التي لا تراها فحوص البنية، باللغتين: كلمات زمنية بلا سنة، وشرح
/// يكشف إجابة سؤال لاحق في المستوى نفسه، وسؤالان يطرحان الحقيقة نفسها بصياغة أخرى.
typedef _Question = ({String slug, Map<String, dynamic> ar, Map<String, dynamic> en});

String _char(int code) => String.fromCharCode(code);

Map<String, dynamic> _load(String path) =>
    jsonDecode(File(path).readAsStringSync()) as Map<String, dynamic>;

String _answer(Map<String, dynamic> q) =>
    (q['options'] as List)[q['answerIndex'] as int] as String;

final _year = RegExp('(18|19|20)[0-9]{2}|[${_char(0x0661)}${_char(0x0662)}]'
    '[${_char(0x0660)}-${_char(0x0669)}]{3}');
final _enTime = RegExp(
  r'\b(currently|current|so far|to date|until now|at present|presently|nowadays|'
  r'these days|last decade|past decade|recent years|recent seasons)\b',
  caseSensitive: false,
);
final _arTime = RegExp('حالياً|حاليا|الحالي|الحالية|حتى الآن|حتى الان|حتى اليوم|'
    'الوقت الراهن|العقد الأخير|العقد الماضي|السنوات الأخيرة');

/// كلمات النص الإنجليزي بلا ترقيم ولا «'s».
String _wordsEn(String s) => s
    .toLowerCase()
    .replaceAll("'s", '')
    .replaceAll(RegExp('[^a-z0-9]+'), ' ')
    .trim();

/// كلمات النص العربي بعد إزالة التشكيل وتوحيد الألف والتاء المربوطة والياء.
String _wordsAr(String s) {
  var text = s.replaceAll(
    RegExp('[${_char(0x064B)}-${_char(0x0652)}${_char(0x0640)}]'),
    '',
  );
  for (final (from, to) in const [
    ('أ', 'ا'), ('إ', 'ا'), ('آ', 'ا'), ('ٱ', 'ا'),
    ('ة', 'ه'), ('ى', 'ي'), ('ؤ', 'و'), ('ئ', 'ي'),
  ]) {
    text = text.replaceAll(from, to);
  }
  return text
      .toLowerCase()
      .replaceAll(RegExp(r'[^\p{L}\p{N}_]+', unicode: true), ' ')
      .trim();
}

const _enStop = {
  'a', 'an', 'the', 'of', 'in', 'at', 'on', 'to', 'for', 'by', 'with', 'from',
  'and', 'or', 'is', 'was', 'were', 'are', 'be', 'been', 'being', 'has', 'have',
  'had', 'did', 'does', 'do', 'which', 'who', 'whom', 'whose', 'what', 'when',
  'where', 'why', 'how', 'many', 'much', 'that', 'this', 'these', 'those', 'it',
  'its', 'his', 'her', 'their', 'they', 'them', 'he', 'she', 'as', 'into',
  'than', 'then', 'also', 'after', 'before', 'during', 'between', 'against',
  'under', 'over', 'there', 'here', 'not', 'no', 'yes', 'one',
};

/// كلمات المعنى في الصياغة الإنجليزية، بلا كلمات الربط وبلا جمع بسيط.
Set<String> _tokens(String s) => {
      for (final w in _wordsEn(s).split(' '))
        if (w.isNotEmpty && !_enStop.contains(w))
          w.length > 4 && w.endsWith('s') ? w.substring(0, w.length - 1) : w,
    };

/// عبارتا التثبيت الزمني الموحّدتان (QUESTION_BANK.md) تتكرران في أسئلة كثيرة،
/// فلا تُحسبان تشابهاً بينها.
final _anchor = RegExp(
  r'by the end of the \d{4}-\d{2} season|after the \d{4} world cup',
  caseSensitive: false,
);

/// السنوات في النص؛ الموسم «2011-12» أو «2011-2012» يعطي سنتيه كلتيهما.
Set<String> _yearsIn(String s) => {
      for (final m in RegExp(r'\b((?:18|19|20)\d\d)(?:[-/](\d{4}|\d{2}))?\b')
          .allMatches(s)) ...[
        m.group(1)!,
        if (m.group(2) case final end?)
          end.length == 2 ? '${m.group(1)!.substring(0, 2)}$end' : end,
      ],
    };

/// أزواج متشابهة الصياغة تطرح حقيقتين مختلفتين فعلاً.
const _distinctFacts = <String>{
  '1019/1023', // ألقاب ألمانيا وألقاب إيطاليا في كأس العالم: 4 لكل منهما.
  '2028/3004', // هدّاف اليورو التاريخي وهدّاف دوري الأبطال: رونالدو في البطولتين.
  '3021/5054', // ألقاب برشلونة الأوروبية وألقاب الزمالك الأفريقية: 5 لكل منهما.
  '5007/5021', // أكثر العرب فوزاً بأمم أفريقيا، وثلاثة ألقاب متتالية: مصر في الحالتين.
  '5007/5088', // أكثر العرب فوزاً بأمم أفريقيا وأكثرهم استضافة لها: مصر في الحالتين.
  '3015/3018', // ألقاب ليفربول وألقاب بايرن: ناديان مختلفان بالعدد نفسه (6).
  '4005/4017', // أكثر الأندية فوزاً بالدوري الألماني، وأطول سلسلة ألقاب متتالية.
  '7032/7081', // سنة تأسيس برشلونة وسنة تأسيس ميلان: كلاهما 1899.
};

/// كلمات المعنى في نص إنجليزي لفحص تكرار كلمة السؤال في الإجابة.
const _echoStop = {
  'the', 'a', 'an', 'of', 'in', 'at', 'on', 'to', 'for', 'by', 'with', 'from',
  'and', 'or', 'is', 'was', 'were', 'are', 'be', 'has', 'have', 'had', 'did',
  'does', 'which', 'who', 'what', 'when', 'where', 'how', 'many', 'much', 'that',
  'this', 'his', 'her', 'their', 'its', 'as', 'after', 'before', 'end', 'season',
  'world', 'cup', 'first', 'last', 'one', 'two', 'three', 'club', 'team', 'player',
};

Set<String> _contentWords(String s) => {
      for (final m in RegExp('[a-z0-9]+').allMatches(s.toLowerCase()))
        if (m.group(0)!.length > 2 && !_echoStop.contains(m.group(0))) m.group(0)!,
    };

/// أسئلة تتكرر فيها كلمة من السؤال في الإجابة وحدها دون أن تدلّ عليها (راجعها قارئ).
const _harmlessEchoes = <int>{};

void main() {
  final slugs = [
    for (final c in _load('assets/data/categories.json')['categories'] as List)
      (c as Map)['slug'] as String,
  ];
  final bank = <_Question>[
    for (final slug in slugs)
      for (final (i, ar) in (_load('assets/data/questions/$slug.json')['questions']
              as List)
          .indexed)
        (
          slug: slug,
          ar: ar as Map<String, dynamic>,
          en: (_load('assets/data/en/questions/$slug.json')['questions']
              as List)[i] as Map<String, dynamic>,
        ),
  ];

  test('لا كلمات زمنية نسبية («حالياً»، «حتى الآن»، "currently") دون سنة', () {
    // «الملعب الحالي» و«حتى الآن» تصبح خاطئة بعد موسم أو بطولة؛ السنة تجعلها ثابتة.
    final problems = <String>[];
    for (final q in bank) {
      for (final (lang, data, words) in [('ar', q.ar, _arTime), ('en', q.en, _enTime)]) {
        final texts = [
          data['question'] as String,
          ...(data['options'] as List).cast<String>(),
          (data['explanation'] ?? '') as String,
        ];
        for (final text in texts) {
          final match = words.firstMatch(text);
          if (match != null && !_year.hasMatch(text)) {
            problems.add('${data['id']} $lang: «${match.group(0)}» في: $text');
          }
        }
      }
    }
    expect(problems, isEmpty, reason: problems.join('\n'));
  });

  test('شرح السؤال لا يذكر إجابة سؤال لاحق في المستوى نفسه', () {
    // المستوى يُلعب بترتيب المعرّف ويظهر الشرح بعد كل إجابة، فذكر إجابة سؤال قادم يكشفها.
    final levels = <String, List<_Question>>{};
    for (final q in bank) {
      levels.putIfAbsent('${q.slug}/${q.ar['level']}', () => []).add(q);
    }

    final problems = <String>[];
    for (final level in levels.values) {
      level.sort((a, b) => (a.ar['id'] as int).compareTo(b.ar['id'] as int));
      for (var i = 0; i < level.length; i++) {
        for (final later in level.skip(i + 1)) {
          for (final lang in const ['ar', 'en']) {
            final words = lang == 'ar' ? _wordsAr : _wordsEn;
            final earlier = lang == 'ar' ? level[i].ar : level[i].en;
            final next = lang == 'ar' ? later.ar : later.en;
            final answer = words(_answer(next));
            // الأعداد الصغيرة والإجابات القصيرة تتكرر في أي نص دون أن تكشف شيئاً.
            if (answer.replaceAll(' ', '').length < 3 ||
                RegExp(r'^\d{1,3}$').hasMatch(answer)) {
              continue;
            }
            bool names(String text) => ' ${words(text)} '.contains(' $answer ');
            // الإجابة مذكورة في نص السؤال اللاحق نفسه، أو هي إجابة السؤال السابق الظاهرة أصلاً.
            if (names(next['question'] as String)) continue;
            if (answer == words(_answer(earlier))) continue;
            if (names((earlier['explanation'] ?? '') as String)) {
              problems.add('$lang: شرح ${earlier['id']} يذكر «${_answer(next)}» '
                  'إجابة ${next['id']}');
            }
          }
        }
      }
    }
    expect(problems, isEmpty, reason: problems.join('\n'));
  });

  test('لا يوجد سؤالان يطرحان الحقيقة نفسها بصياغة مختلفة', () {
    // المقارنة بالصياغة الإنجليزية لأن كلماتها بلا سوابق. سلسلة مثل «من فاز بيورو
    // 2008؟» و«2012؟» تحمل سنتين مختلفتين فليست تكراراً.
    final questions = [
      for (final q in bank) (q.en['question'] as String).replaceAll(_anchor, ' '),
    ];
    final tokens = [
      for (var i = 0; i < bank.length; i++)
        _tokens('${questions[i]} ${_answer(bank[i].en)}'),
    ];
    final years = [for (final text in questions) _yearsIn(text)];

    final problems = <String>[];
    for (var i = 0; i < bank.length; i++) {
      for (var j = i + 1; j < bank.length; j++) {
        final a = tokens[i], b = tokens[j];
        if (a.isEmpty || b.isEmpty) continue;
        if (years[i].isNotEmpty &&
            years[j].isNotEmpty &&
            (years[i].length != years[j].length || !years[i].containsAll(years[j]))) {
          continue;
        }
        final idA = bank[i].en['id'], idB = bank[j].en['id'];
        if (_distinctFacts.contains('$idA/$idB')) continue;

        final similarity = a.intersection(b).length / a.union(b).length;
        final sameAnswer =
            _wordsEn(_answer(bank[i].en)) == _wordsEn(_answer(bank[j].en));
        // عتبتان اختيرتا على البنك: تلتقطان إعادة الصياغة بكلمة أو كلمتين دون إنذارات
        // كاذبة كثيرة. التكرار بصياغة بعيدة يحتاج قارئاً.
        if ((sameAnswer && similarity >= 0.6) || similarity >= 0.75) {
          problems.add('$idA / $idB (${similarity.toStringAsFixed(2)}): '
              '"${bank[i].en['question']}" / "${bank[j].en['question']}"');
        }
      }
    }
    expect(problems, isEmpty, reason: problems.join('\n'));
  });

  test('الإجابة الصحيحة لا تتميّز بطولها عن الخيارات الخاطئة', () {
    // خيار صحيح أطول بكثير من البقية يُخمَّن دون معرفة الحقيقة، فيُفحص في اللغتين.
    final problems = <String>[];
    for (final q in bank) {
      for (final (lang, data) in [('ar', q.ar), ('en', q.en)]) {
        final options = (data['options'] as List).cast<String>();
        final index = data['answerIndex'] as int;
        final longestWrong = [
          for (var k = 0; k < options.length; k++)
            if (k != index) options[k].length,
        ].reduce(max);
        final length = options[index].length;
        if (length >= 1.6 * longestWrong && length - longestWrong >= 8) {
          problems.add('${data['id']} $lang: $length حرفاً مقابل $longestWrong '
              'لأطول خيار خاطئ');
        }
      }
    }
    expect(problems, isEmpty, reason: problems.join('\n'));
  });

  test('الإجابة الصحيحة وحدها لا تكرر كلمة من نص السؤال', () {
    // «في أي مدينة يلعب بايرن ميونخ؟ ← ميونخ». الفحص بالإنجليزية لأن كلماتها بلا سوابق،
    // والعربية ترجمتها بالخيارات نفسها.
    final problems = <String>[];
    for (final q in bank) {
      final id = q.en['id'] as int;
      if (_harmlessEchoes.contains(id)) continue;
      final options = (q.en['options'] as List).cast<String>();
      final index = q.en['answerIndex'] as int;
      final words = _contentWords(q.en['question'] as String);
      final shared = words.intersection(_contentWords(options[index]));
      final wrongShares = [
        for (var k = 0; k < options.length; k++)
          if (k != index) words.intersection(_contentWords(options[k])).isNotEmpty,
      ].any((shares) => shares);
      if (shared.isNotEmpty && !wrongShares) {
        problems.add('$id: «${shared.join('، ')}» في "${q.en['question']}" ← ${options[index]}');
      }
    }
    expect(problems, isEmpty, reason: problems.join('\n'));
  });
}
