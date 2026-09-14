import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/constants/app_config.dart';
import '../../core/constants/app_strings.dart';
import '../../core/theme/app_colors.dart';
import '../../domain/entities/question.dart';
import '../../domain/repositories/app_info.dart';
import '../../domain/repositories/link_opener.dart';
import '../../domain/usecases/build_question_report.dart';

/// زر «أبلغ عن خطأ» في سؤال: يسأل عن السبب ثم يفتح رسالة بريد جاهزة.
///
/// لا يُرسل شيء تلقائياً — اللاعب يرى الرسالة في تطبيق البريد ويقرر إرسالها.
class ReportQuestionButton extends StatelessWidget {
  const ReportQuestionButton({
    super.key,
    required this.question,
    this.compact = false,
  });

  final Question question;

  /// أيقونة وحدها حيث المساحة ضيقة (صف المراجعة)، وإلا زر بنص.
  final bool compact;

  @override
  Widget build(BuildContext context) {
    if (compact) {
      return IconButton(
        onPressed: () => _report(context),
        tooltip: AppStrings.reportQuestion,
        icon: const Icon(Icons.flag_outlined, size: 18),
        color: AppColors.chalkMuted,
      );
    }

    return TextButton.icon(
      onPressed: () => _report(context),
      style: TextButton.styleFrom(foregroundColor: AppColors.chalkMuted),
      icon: const Icon(Icons.flag_outlined, size: 18),
      label: const Text(AppStrings.reportQuestion),
    );
  }

  Future<void> _report(BuildContext context) async {
    final linkOpener = context.read<LinkOpener>();
    final appInfo = context.read<AppInfo>();
    final messenger = ScaffoldMessenger.of(context);

    // القائمة لا تُغلق قبل طلب فتح البريد: حاجزها يمنع لمس «التالي» خلفها، فلا
    // يبدأ عدّاد السؤال التالي واللاعب في تطبيق البريد.
    final opened = await showModalBottomSheet<bool>(
      context: context,
      backgroundColor: AppColors.cardSurface,
      builder: (_) => _ReasonSheet(
        onPick: (reason) async => linkOpener.open(
          const BuildQuestionReport()(
            question: question,
            reason: reason,
            version: await appInfo.version(),
          ).toMailtoUri(),
        ),
      ),
    );
    // `null`: أُغلقت القائمة دون فتح البريد.
    if (opened != false) return;

    messenger
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(content: Text(AppStrings.noEmailApp(AppConfig.contactEmail))),
      );
  }
}

class _ReasonSheet extends StatefulWidget {
  const _ReasonSheet({required this.onPick});

  /// يفتح البريد بالسبب المختار ويعيد هل فُتح.
  final Future<bool> Function(ReportReason reason) onPick;

  @override
  State<_ReasonSheet> createState() => _ReasonSheetState();
}

class _ReasonSheetState extends State<_ReasonSheet> {
  /// لمسة ثانية أثناء فتح البريد لا تفتح رسالة أخرى.
  bool _busy = false;

  Future<void> _pick(ReportReason reason) async {
    if (_busy) return;
    _busy = true;
    final opened = await widget.onPick(reason);
    // أُغلقت القائمة أثناء الانتظار: `pop` هنا كان سيغلق الشاشة التي تحتها.
    if (!mounted || !(ModalRoute.of(context)?.isCurrent ?? false)) return;
    Navigator.of(context).pop(opened);
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 12),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Padding(
              padding: EdgeInsets.fromLTRB(20, 8, 20, 8),
              child: Text(
                AppStrings.reportQuestionTitle,
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800),
              ),
            ),
            for (final reason in ReportReason.values)
              ListTile(
                onTap: () => _pick(reason),
                leading: Icon(
                  Icons.flag_outlined,
                  size: 20,
                  color: AppColors.gold,
                ),
                title: Text(BuildQuestionReport.label(reason)),
              ),
          ],
        ),
      ),
    );
  }
}
