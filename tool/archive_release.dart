// أداة أرشفة: تنسخ حزمة الإصدار المبنيّة إلى مجلد باسم الإصدار والتاريخ
// داخل releases/ لتتبّع ما رُفع إلى Play عبر الزمن.
//
// التشغيل بعد `flutter build appbundle --release`:
//   dart run tool/archive_release.dart
//   dart run tool/archive_release.dart "ملاحظة قصيرة عن هذا الإصدار"

import 'dart:io';

void main(List<String> args) {
  final root = Directory.current;

  // اقرأ الإصدار من pubspec.yaml (مثال: 1.0.1+2)
  final pubspec = File('${root.path}/pubspec.yaml');
  if (!pubspec.existsSync()) {
    stderr.writeln('لم يُعثر على pubspec.yaml — شغّل الأمر من جذر المشروع.');
    exit(1);
  }
  final versionLine = pubspec
      .readAsLinesSync()
      .firstWhere((l) => l.trimLeft().startsWith('version:'),
          orElse: () => '');
  final version = versionLine.split(':').last.trim(); // 1.0.1+2
  if (version.isEmpty) {
    stderr.writeln('تعذّرت قراءة الإصدار من pubspec.yaml.');
    exit(1);
  }

  final now = DateTime.now();
  final date =
      '${now.year}-${_two(now.month)}-${_two(now.day)}'; // 2026-09-06
  // اسم آمن للمجلد: نستبدل + بـ _plus_ لتفادي مشاكل بعض أنظمة الملفات.
  final safeVersion = version.replaceAll('+', '_build');
  final destDir = Directory('${root.path}/releases/v${safeVersion}_$date');
  destDir.createSync(recursive: true);

  // انسخ الحزمة والـ APK إن وُجدا.
  final artifacts = <String>[
    'build/app/outputs/bundle/release/app-release.aab',
    'build/app/outputs/flutter-apk/app-release.apk',
  ];
  var copied = 0;
  for (final rel in artifacts) {
    final src = File('${root.path}/$rel');
    if (src.existsSync()) {
      final name = rel.split('/').last;
      src.copySync('${destDir.path}/$name');
      final mb = (src.lengthSync() / (1024 * 1024)).toStringAsFixed(1);
      stdout.writeln('نُسخ $name ($mb م.ب) → ${destDir.path}');
      copied++;
    }
  }
  if (copied == 0) {
    stderr.writeln('لا توجد حِزم مبنيّة — شغّل flutter build أولاً.');
    exit(1);
  }

  // ملاحظات الإصدار.
  final note = args.isNotEmpty ? args.join(' ') : '';
  File('${destDir.path}/NOTES.md').writeAsStringSync(
    '# الإصدار v$version\n\n'
    '- التاريخ: $date\n'
    '- versionCode/Name: $version\n'
    '${note.isNotEmpty ? '- ملاحظات: $note\n' : ''}',
  );
  stdout.writeln('تمّت الأرشفة في ${destDir.path}');
}

String _two(int n) => n.toString().padLeft(2, '0');
