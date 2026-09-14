import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:football_trivia/core/theme/app_theme.dart';

void main() {
  testWidgets('أيقونة كل زر بنص تقع على يسار النص في العربية', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.dark,
        home: Directionality(
          textDirection: TextDirection.rtl,
          child: Scaffold(
            body: Column(
              children: [
                FilledButton.icon(
                  onPressed: () {},
                  icon: const Icon(Icons.share_rounded),
                  label: const Text('ممتلئ'),
                ),
                OutlinedButton.icon(
                  onPressed: () {},
                  icon: const Icon(Icons.replay_rounded),
                  label: const Text('محدد'),
                ),
                TextButton.icon(
                  onPressed: () {},
                  icon: const Icon(Icons.flag_outlined),
                  label: const Text('نصي'),
                ),
              ],
            ),
          ),
        ),
      ),
    );

    for (final (icon, label) in [
      (Icons.share_rounded, 'ممتلئ'),
      (Icons.replay_rounded, 'محدد'),
      (Icons.flag_outlined, 'نصي'),
    ]) {
      expect(
        tester.getCenter(find.byIcon(icon)).dx,
        lessThan(tester.getCenter(find.text(label)).dx),
        reason: 'أيقونة زر «$label» ليست على يسار النص',
      );
    }
  });
}
