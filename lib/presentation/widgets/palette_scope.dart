import 'package:flutter/widgets.dart';

/// يعيد بناء الشجرة كلها عند تبديل مظهر الألوان.
///
/// الألوان تُقرأ من `AppColors` وقت البناء، والودجات الثابتة لا تُبنى من جديد
/// من تلقاء نفسها — فيُعلَّم كل عنصر للبناء بعد التبديل، دون إغلاق الشاشات
/// المفتوحة (إعادة إنشاء `MaterialApp` بمفتاح جديد كانت ستعيد اللاعب للرئيسية).
class PaletteScope extends StatefulWidget {
  const PaletteScope({super.key, required this.themeId, required this.child});

  final String themeId;
  final Widget child;

  @override
  State<PaletteScope> createState() => _PaletteScopeState();
}

class _PaletteScopeState extends State<PaletteScope> {
  @override
  void didUpdateWidget(PaletteScope oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.themeId == widget.themeId) return;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      void rebuild(Element element) {
        element.markNeedsBuild();
        element.visitChildren(rebuild);
      }

      (context as Element).visitChildren(rebuild);
    });
  }

  @override
  Widget build(BuildContext context) => widget.child;
}
