import 'package:flutter/foundation.dart';

import '../../core/services/feedback_service.dart';
import '../../core/utils/day_key.dart';
import '../../core/constants/app_strings.dart';
import '../../domain/entities/app_settings.dart';
import '../../domain/entities/user_stats.dart';
import '../../domain/repositories/reminder_scheduler.dart';
import '../../domain/repositories/settings_repository.dart';
import '../../domain/usecases/plan_reminders.dart';
import '../../domain/usecases/update_streak.dart';

class SettingsProvider extends ChangeNotifier {
  SettingsProvider({
    required SettingsRepository repository,
    required ReminderScheduler scheduler,
    PlanReminders planReminders = const PlanReminders(),
    DateTime Function()? clock,
  })  : _repository = repository,
        _scheduler = scheduler,
        _planReminders = planReminders,
        _clock = clock ?? DateTime.now;

  final SettingsRepository _repository;
  final ReminderScheduler _scheduler;
  final PlanReminders _planReminders;
  final DateTime Function() _clock;

  AppSettings _settings = const AppSettings();
  bool _loading = true;

  /// يصبح `true` إذا رفض المستخدم إذن الإشعارات.
  bool _permissionDenied = false;

  /// الإحصائيات التي يُبنى عليها موعد التنبيه ونصّه. نحفظها كاملة لا كـ«أُنجز
  /// اليوم» جاهزة، لأن «اليوم» يُحسب لحظة الجدولة وقد يكون تغيّر منذ المزامنة.
  UserStats _stats = const UserStats();

  /// بصمة آخر خطة جُدولت، حتى لا تُعاد جدولة خطة مطابقة عند كل تغيّر في
  /// الإحصائيات.
  String? _scheduledKey;

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
        // دائماً عند الإقلاع: التنبيه الأول مبني على حالة آخر فتح للتطبيق.
        await _reschedule(force: true);
      } else {
        await _scheduler.cancelAll();
        _scheduledKey = null;
        await _persist(_settings.copyWith(reminderEnabled: false));
      }
    } else {
      // التنبيه مطفأ في الإعدادات المحمّلة — ومنها نسخة احتياطية مستوردة بعد أن
      // كان مفعّلاً: لا يبقى تنبيه قديم مجدولاً لا يطفئه شيء.
      await _scheduler.cancelAll();
      _scheduledKey = null;
    }
  }

  /// تشغيل التنبيه أو إيقافه. يعيد `false` إذا رُفض الإذن.
  Future<bool> setReminderEnabled(bool enabled) async {
    if (!enabled) {
      await _scheduler.cancelAll();
      _scheduledKey = null;
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
    await _reschedule(force: true);
    return true;
  }

  /// يُستدعى عند تغيّر الإحصائيات وعند العودة إلى التطبيق (قد يكون اليوم تغيّر).
  ///
  /// إنجاز تحدي اليوم ينقل أول تنبيه إلى الغد، والسلسلة تدخل نصّه.
  Future<void> syncReminder(UserStats stats) async {
    _stats = stats;
    if (_loading || !_settings.reminderEnabled) return;
    await _reschedule();
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

  String get themeId => _settings.themeId;

  Future<void> setThemeId(String id) =>
      _persist(_settings.copyWith(themeId: id));

  /// رمز اللغة المختارة، أو `null` لاتباع لغة الهاتف.
  String? get languageCode => _settings.languageCode;

  Future<void> setLanguageCode(String? code) =>
      _persist(_settings.copyWith(languageCode: code));

  Future<void> setReminderTime({required int hour, required int minute}) async {
    await _persist(
      _settings.copyWith(reminderHour: hour, reminderMinute: minute),
    );
    if (_settings.reminderEnabled) await _reschedule(force: true);
  }

  Future<void> _reschedule({bool force = false}) async {
    final now = _clock();
    // «اليوم» من ساعة الجدولة نفسها: التطبيق قد يبقى مفتوحاً بعد منتصف الليل
    // دون أي حدث يحدّث حالة التحدي، فيُعامَل اليوم الجديد كأنه أُنجز.
    final today = DayKey.from(now);
    final plans = _planReminders(
      now: now,
      hour: _settings.reminderHour,
      minute: _settings.reminderMinute,
      dailyDoneToday: _stats.isDailyDoneOn(today),
      streak: UpdateStreak.visibleStreak(_stats, today),
    );

    // أول تنبيه يحدد الخطة كلها: يومه وساعته والسلسلة في نصّه، ولغة النص.
    final key = '${plans.first.at.toIso8601String()}|${plans.first.streak}|'
        '${AppStrings.languageCode}';
    if (!force && key == _scheduledKey) return;

    _scheduledKey = key;
    await _scheduler.schedule(plans);
  }

  Future<void> _persist(AppSettings next) async {
    _settings = next;
    notifyListeners();
    await _repository.save(next);
  }
}
