import 'package:flutter/widgets.dart';

import '../../core/constants/app_strings.dart';
import 'palette_scope.dart';

/// يطبّق على `AppStrings` اللغة التي حسمها `MaterialApp`: اختيار اللاعب، أو لغة
/// الهاتف إن كانت مدعومة، وإلا أول لغة مدعومة.
///
/// يُوضع في `MaterialApp.builder` تحت `Localizations`، فيُبنى من جديد مع كل تغيير
/// لغة — من الإعدادات أو من لغة الهاتف والتطبيق يعمل — ويعيد بناء الشاشات المفتوحة
/// بالنصوص الجديدة دون إغلاقها.
class AppLanguageScope extends StatelessWidget {
  const AppLanguageScope({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    final languageCode = Localizations.localeOf(context).languageCode;
    AppText.use(languageCode);
    return PaletteScope(languageCode: languageCode, child: child);
  }
}
