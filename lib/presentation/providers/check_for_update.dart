import '../../domain/repositories/app_updater.dart';
import '../../domain/usecases/choose_update_mode.dart';

/// يسأل Play عن تحديث (عند الإقلاع والعودة إلى التطبيق) ويبدأ المرن أو الإلزامي.
class CheckForUpdate {
  const CheckForUpdate({
    required AppUpdater updater,
    ChooseUpdateMode choose = const ChooseUpdateMode(),
    DateTime Function()? clock,
  })  : _updater = updater,
        _choose = choose,
        _clock = clock;

  final AppUpdater _updater;
  final ChooseUpdateMode _choose;
  final DateTime Function()? _clock;

  /// يعيد `true` إن كان تحديث مرن منزَّلاً ينتظر إعادة التشغيل.
  Future<bool> call() async {
    final status = await _updater.check();
    if (status.downloaded) return true;

    final mode = _choose(
      status: status,
      lastAskedAt: await _updater.lastFlexibleAskAt(),
      now: (_clock ?? DateTime.now)(),
    );
    switch (mode) {
      case UpdateMode.none:
        return false;
      case UpdateMode.immediate:
        await _updater.updateImmediately();
        return false;
      case UpdateMode.flexible:
        // يُسجَّل قبل النافذة: من رفض لا يُسأل ثانية قبل انقضاء المهلة.
        await _updater.recordFlexibleAsk();
        return _updater.startFlexibleUpdate();
    }
  }
}
