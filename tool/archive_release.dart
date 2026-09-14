// أداة أرشفة: تنسخ حزمتي الإصدار المبنيّتين إلى مجلد باسم الإصدار والتاريخ
// داخل releases/ لتتبّع ما رُفع إلى Play عبر الزمن.
//
// التشغيل بعد بناء الحزمتين (`flutter build appbundle --release` ثم
// `flutter build apk --release`):
//   dart run tool/archive_release.dart "ملاحظة قصيرة عن هذا الإصدار"
//
// ترفض الأرشفة إن نقصت إحدى الحزمتين، أو كانت أقدم من pubspec.yaml، أو اختلف
// رقم إصدار الـ APK عن pubspec، أو وُقّعت إحداهما بمفتاح التصحيح، أو اختلف مفتاحا
// توقيعهما. نُسخت مرة حزمة قديمة باسم إصدار جديد (v1.0.2).

import 'dart:io';

const _aab = 'build/app/outputs/bundle/release/app-release.aab';
const _apk = 'build/app/outputs/flutter-apk/app-release.apk';

void main(List<String> args) {
  final root = Directory.current;

  // اقرأ الإصدار من pubspec.yaml (مثال: 1.0.5+6)
  final pubspec = File('${root.path}/pubspec.yaml');
  if (!pubspec.existsSync()) {
    _fail('لم يُعثر على pubspec.yaml — شغّل الأمر من جذر المشروع.');
  }
  final versionLine = pubspec
      .readAsLinesSync()
      .firstWhere((l) => l.trimLeft().startsWith('version:'),
          orElse: () => '');
  final version = versionLine.split(':').last.trim();
  final parts = version.split('+');
  if (version.isEmpty || parts.length != 2) {
    _fail('تعذّرت قراءة الإصدار من pubspec.yaml.');
  }
  final versionName = parts[0];
  final versionCode = parts[1];

  // الحزمتان معاً، وكلتاهما مبنيّة بعد آخر تعديل لـ pubspec.yaml.
  final aab = File('${root.path}/$_aab');
  final apk = File('${root.path}/$_apk');
  final bumpedAt = pubspec.lastModifiedSync();
  for (final file in [aab, apk]) {
    if (!file.existsSync()) {
      _fail('لا توجد ${_name(file)} — ابنِ الحزمتين كلتيهما قبل الأرشفة.');
    }
    if (file.lastModifiedSync().isBefore(bumpedAt)) {
      _fail('${_name(file)} أقدم من pubspec.yaml — أعد بناءها للإصدار $version.');
    }
  }

  final tools = _Tools.find();
  _checkApkVersion(tools, apk, versionName, versionCode);
  _checkSigning(tools, aab, apk);

  final now = DateTime.now();
  final date = '${now.year}-${_two(now.month)}-${_two(now.day)}';
  final safeVersion = version.replaceAll('+', '_build');
  final destDir = Directory('${root.path}/releases/v${safeVersion}_$date');
  destDir.createSync(recursive: true);

  for (final file in [aab, apk]) {
    file.copySync('${destDir.path}/${_name(file)}');
    final mb = (file.lengthSync() / (1024 * 1024)).toStringAsFixed(1);
    stdout.writeln('نُسخ ${_name(file)} ($mb م.ب) → ${destDir.path}');
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

/// رقم الإصدار داخل الـ APK نفسه (aapt2)، لا اسم الملف.
void _checkApkVersion(_Tools tools, File apk, String name, String code) {
  final aapt2 = tools.aapt2;
  if (aapt2 == null) {
    stdout.writeln('تنبيه: aapt2 غير موجود، لم يُفحص رقم إصدار الـ APK.');
    return;
  }
  final result = Process.runSync(aapt2, ['dump', 'badging', apk.path]);
  final match = RegExp(r"versionCode='(\d+)' versionName='([^']*)'")
      .firstMatch('${result.stdout}');
  if (match == null) _fail('تعذّرت قراءة إصدار الـ APK: ${result.stderr}');
  if (match.group(1) != code || match.group(2) != name) {
    _fail('الـ APK للإصدار ${match.group(2)}+${match.group(1)} لا $name+$code.');
  }
  stdout.writeln('✓ الـ APK للإصدار $name+$code');
}

/// لا توقيع بمفتاح التصحيح، والحزمتان بمفتاح واحد.
void _checkSigning(_Tools tools, File aab, File apk) {
  final apkSha = tools.apksignerJar == null || tools.java == null
      ? null
      : _certSha(
          _run(tools.java!, [
            '-jar',
            tools.apksignerJar!,
            'verify',
            '--print-certs',
            apk.path,
          ]),
          RegExp(r'certificate SHA-256 digest: ([0-9a-fA-F]+)'),
          apk,
        );
  final aabSha = tools.keytool == null
      ? null
      : _certSha(
          _run(tools.keytool!, ['-printcert', '-jarfile', aab.path]),
          RegExp(r'SHA256: ([0-9A-Fa-f:]+)'),
          aab,
        );

  if (apkSha == null || aabSha == null) {
    stdout.writeln('تنبيه: apksigner أو keytool غير موجود، لم يُقارن مفتاحا التوقيع.');
    return;
  }
  if (apkSha != aabSha) _fail('الحزمتان موقّعتان بمفتاحين مختلفين.');
  stdout.writeln('✓ الحزمتان موقّعتان بمفتاح الإصدار نفسه');
}

String? _certSha(String output, RegExp digest, File file) {
  if (output.contains('CN=Android Debug')) {
    _fail('${_name(file)} موقّعة بمفتاح التصحيح — تحقّق من android/key.properties.');
  }
  final match = digest.firstMatch(output);
  if (match == null) _fail('تعذّرت قراءة توقيع ${_name(file)}:\n$output');
  return match.group(1)!.replaceAll(':', '').toLowerCase();
}

String _run(String executable, List<String> args) {
  final result = Process.runSync(executable, args);
  return '${result.stdout}\n${result.stderr}';
}

/// أدوات Android وJava المثبّتة، أو `null` لما لم يُعثر عليه.
///
/// `apksigner.bat` يحتاج `java` في PATH وليس فيه على هذا الجهاز، فيُشغَّل
/// `apksigner.jar` بـ Java مباشرة.
class _Tools {
  _Tools(this.aapt2, this.apksignerJar, this.java, this.keytool);

  final String? aapt2;
  final String? apksignerJar;
  final String? java;
  final String? keytool;

  static _Tools find() {
    final env = Platform.environment;
    final exe = Platform.isWindows ? '.exe' : '';

    final sdk = [
      env['ANDROID_HOME'],
      env['ANDROID_SDK_ROOT'],
      if (env['LOCALAPPDATA'] != null) '${env['LOCALAPPDATA']}/Android/Sdk',
    ].whereType<String>().firstWhere(
          (path) => Directory('$path/build-tools').existsSync(),
          orElse: () => '',
        );

    String? aapt2;
    String? apksignerJar;
    if (sdk.isNotEmpty) {
      final versions = Directory('$sdk/build-tools')
          .listSync()
          .whereType<Directory>()
          .map((d) => d.path)
          .toList()
        ..sort();
      if (versions.isNotEmpty) {
        aapt2 = _existing('${versions.last}/aapt2$exe');
        apksignerJar = _existing('${versions.last}/lib/apksigner.jar');
      }
    }

    // Java المشروع: JAVA_HOME إن ضُبط، وإلا المرفقة مع Android Studio.
    final javaHome = env['JAVA_HOME'];
    final javaBins = [
      if (javaHome != null) '$javaHome/bin',
      'C:/Program Files/Android/Android Studio/jbr/bin',
    ];
    String? tool(String name) => javaBins
        .map((bin) => _existing('$bin/$name$exe'))
        .whereType<String>()
        .firstOrNull;

    return _Tools(aapt2, apksignerJar, tool('java'), tool('keytool'));
  }

  static String? _existing(String path) => File(path).existsSync() ? path : null;
}

Never _fail(String message) {
  stderr.writeln('✗ $message');
  exit(1);
}

String _name(File file) => file.uri.pathSegments.last;

String _two(int n) => n.toString().padLeft(2, '0');
