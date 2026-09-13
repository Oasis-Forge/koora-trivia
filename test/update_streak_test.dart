import 'package:flutter_test/flutter_test.dart';
import 'package:football_trivia/domain/entities/user_stats.dart';
import 'package:football_trivia/domain/usecases/update_streak.dart';

void main() {
  const useCase = UpdateStreak();

  test('أول تحدٍ على الإطلاق يبدأ السلسلة من 1', () {
    final result = useCase(const UserStats(), todayKey: '2026-08-03');
    expect(result.currentStreak, 1);
    expect(result.bestStreak, 1);
    expect(result.lastDailyDayKey, '2026-08-03');
  });

  test('إنجاز في يوم متتالٍ يزيد السلسلة', () {
    const stats = UserStats(
      currentStreak: 4,
      bestStreak: 4,
      lastDailyDayKey: '2026-08-02',
    );
    final result = useCase(stats, todayKey: '2026-08-03');
    expect(result.currentStreak, 5);
    expect(result.bestStreak, 5);
  });

  test('انقطاع يومين يعيد السلسلة إلى 1 مع الحفاظ على الأفضل', () {
    const stats = UserStats(
      currentStreak: 9,
      bestStreak: 9,
      lastDailyDayKey: '2026-07-28',
    );
    final result = useCase(stats, todayKey: '2026-08-03');
    expect(result.currentStreak, 1);
    expect(result.bestStreak, 9);
  });

  test('السلسلة لا تتضاعف عند تكرار نفس اليوم', () {
    const stats = UserStats(
      currentStreak: 3,
      bestStreak: 3,
      lastDailyDayKey: '2026-08-03',
    );
    final result = useCase(stats, todayKey: '2026-08-03');
    expect(result.currentStreak, 3);
  });

  test('السلسلة المعروضة تصبح صفراً بعد الانقطاع', () {
    const stats = UserStats(currentStreak: 7, lastDailyDayKey: '2026-07-30');
    expect(UpdateStreak.visibleStreak(stats, '2026-08-03'), 0);
    expect(UpdateStreak.visibleStreak(stats, '2026-07-31'), 7);
  });
}
