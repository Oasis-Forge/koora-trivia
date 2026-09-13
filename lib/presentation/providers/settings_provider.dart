import 'package:flutter/foundation.dart';

import '../../core/services/feedback_service.dart';
import '../../domain/entities/app_settings.dart';
import '../../domain/repositories/reminder_scheduler.dart';
import '../../domain/repositories/settings_repository.dart';

class SettingsProvider extends ChangeNotifier {
  SettingsProvider({
    required SettingsRepository repository,
    required ReminderScheduler scheduler,
  })  : _repository = repository,
        _scheduler = scheduler;

  final SettingsRepository _repository;
  final ReminderScheduler _scheduler;

  AppSettings _settings = const AppSettings();
  bool _loading = true;

  /// يصبح `true` إذا رفض المستخدم إذن الإشعارات.
  bool _permissionDenied = false;

  AppSettings get settings => _settings;
  bool get isLoading => _loading;
  bool get reminderEnabled => _settings.reminderEnabled;
  bool get permissionDenied => _permissionDenied;
  String get reminderLabel => _settings.reminderLabel;

  Future<void> init() async {
    _settings = await _repository.load();
    _loading = false;
    notifyListeners();

    await _scheduler.init();

    // قد يُلغي المستخدم الإذن من إعدادات النظام والتطبيق مغلق، فنتحقق دائماً.
    if (_settings.reminderEnabled) {
      if (await _scheduler.hasPermission()) {
        await _reschedule();
      } else {
        await _persist(_settings.copyWith(reminderEnabled: false));
      }
    }
  }

  /// تشغيل التنبيه أو إيقافه. يعيد `false` إذا رُفض الإذن.
  Future<bool> setReminderEnabled(bool enabled) async {
    if (!enabled) {
      await _scheduler.cancelDaily();
      await _persist(_settings.copyWith(reminderEnabled: false));
      _permissionDenied = false;
      notifyListeners();
      return true;
    }

    final granted = await _scheduler.hasPermission()
        ? true
        : await _scheduler.requestPermission();

    if (!granted) {
      _permissionDenied = true;
      notifyListeners();
      return false;
    }

    _permissionDenied = false;
    await _persist(_settings.copyWith(reminderEnabled: true));
    await _reschedule();
    return true;
  }

  bool get soundEnabled => _settings.soundEnabled;
  bool get hapticsEnabled => _settings.hapticsEnabled;
  bool get onboardingSeen => _settings.onboardingSeen;

  /// خدمة المؤثرات مضبوطة على تفضيلات المستخدم الحالية.
  FeedbackService get feedback => FeedbackService(
        sound: _settings.soundEnabled,
        haptics: _settings.hapticsEnabled,
      );

  Future<void> setSoundEnabled(bool value) =>
      _persist(_settings.copyWith(soundEnabled: value));

  Future<void> setHapticsEnabled(bool value) =>
      _persist(_settings.copyWith(hapticsEnabled: value));

  Future<void> markOnboardingSeen() =>
      _persist(_settings.copyWith(onboardingSeen: true));

  Future<void> setReminderTime({required int hour, required int minute}) async {
    await _persist(
      _settings.copyWith(reminderHour: hour, reminderMinute: minute),
    );
    if (_settings.reminderEnabled) await _reschedule();
  }

  Future<void> _reschedule() => _scheduler.scheduleDaily(
        hour: _settings.reminderHour,
        minute: _settings.reminderMinute,
      );

  Future<void> _persist(AppSettings next) async {
    _settings = next;
    notifyListeners();
    await _repository.save(next);
  }
}
