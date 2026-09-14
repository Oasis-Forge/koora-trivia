import '../../core/constants/app_config.dart';
import '../entities/app_update_status.dart';

enum UpdateMode { none, flexible, immediate }

/// متى يُفرض التحديث ومتى يُعرض بلطف.
///
/// الافتراضي تحديث مرن: يُنزَّل في الخلفية ويكمل اللاعب لعبه. الإلزامي (شاشة Play
/// تمنع اللعب حتى يكتمل) فقط لإصدار أولويته `AppConfig.forceUpdatePriority` فأعلى —
/// إصلاح انهيار أو فقدان بيانات — لأن فرض كل تحديث يُنفّر اللاعبين.
class ChooseUpdateMode {
  const ChooseUpdateMode();

  UpdateMode call({
    required AppUpdateStatus status,
    required DateTime now,
    DateTime? lastAskedAt,
  }) {
    // تحديث إلزامي بدأ ولم يكتمل يُستأنف: الخروج منه لا يتجاوزه.
    if (status.inProgress) return UpdateMode.immediate;
    if (!status.available) return UpdateMode.none;

    if (status.priority >= AppConfig.forceUpdatePriority &&
        status.immediateAllowed) {
      return UpdateMode.immediate;
    }
    if (!status.flexibleAllowed) return UpdateMode.none;

    // لا نعرض التحديث المرن مع كل فتح للتطبيق.
    if (lastAskedAt != null &&
        now.difference(lastAskedAt) <
            const Duration(days: AppConfig.flexibleUpdateAskEveryDays)) {
      return UpdateMode.none;
    }
    return UpdateMode.flexible;
  }
}
