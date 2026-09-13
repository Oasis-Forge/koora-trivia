import 'package:flutter_test/flutter_test.dart';
import 'package:football_trivia/core/constants/app_config.dart';

/// يحرس توازن الاقتصاد لا صحّة الكود.
///
/// القاعدة: الدخل اليومي الكامل يجب أن يبقى **أقل** من سعر شراء واحد، وإلا
/// صارت القلوب بلا ثمن فعلي وفقد الإعلان المكافأ جدواه.
void main() {
  const dailyIncome = AppConfig.coinsTaskAnswers +
      AppConfig.coinsTaskDaily +
      AppConfig.coinsTaskLevel +
      AppConfig.coinsChestBonus;

  test('الدخل اليومي أقل من سعر أرخص عملية شراء', () {
    final cheapest = AppConfig.priceHeartsRefill < AppConfig.priceHintsPack
        ? AppConfig.priceHeartsRefill
        : AppConfig.priceHintsPack;

    expect(
      dailyIncome,
      lessThan(cheapest),
      reason: 'الدخل اليومي $dailyIncome يساوي أو يتجاوز السعر $cheapest — '
          'هذا يجعل الشراء يومياً ويُفرغ الاقتصاد من معناه',
    );
  });

  test('الشراء لا يحتاج أكثر من يومين من المهام', () {
    final days = AppConfig.priceHeartsRefill / dailyIncome;

    expect(
      days,
      lessThanOrEqualTo(2.0),
      reason: 'الادخار ${days.toStringAsFixed(1)} يوم طويل بما يُحبط اللاعب',
    );
    expect(days, greaterThan(1.0), reason: 'الشراء اليومي سخيّ أكثر من اللازم');
  });

  test('الإعلانات البينية مطفأة عند الإطلاق', () {
    // قرار مقصود: تقييمات الأيام الأولى أهم من دخل الإعلان البيني.
    // إن فُعّلت لاحقاً في تحديث، احذف هذا الاختبار أو اعكسه.
    expect(AppConfig.interstitialsEnabled, isFalse);
  });

  test('الصندوق يستحق إتمام كل المهام', () {
    // مكافأة الصندوق يجب ألا تكون أقل من أصغر مهمة، وإلا فلا معنى لإتمامها كلها.
    expect(
      AppConfig.coinsChestBonus,
      greaterThanOrEqualTo(AppConfig.coinsTaskAnswers),
    );
  });
}
