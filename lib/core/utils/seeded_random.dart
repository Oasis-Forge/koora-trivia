/// مولّد أرقام شبه عشوائي حتمي (LCG) — نفس البذرة تعطي نفس الترتيب دائماً.
///
/// يُستخدم لاختيار أسئلة تحدي اليوم بحيث يحصل كل المستخدمين على نفس المجموعة.
class SeededRandom {
  SeededRandom(int seed) : _state = (seed & 0x7FFFFFFF) | 1;

  int _state;

  int nextInt(int max) {
    assert(max > 0);
    // معاملات Numerical Recipes للـ LCG.
    _state = (_state * 1664525 + 1013904223) & 0x7FFFFFFF;
    return _state % max;
  }

  /// خلط Fisher-Yates حتمي، يعيد قائمة جديدة دون تعديل الأصل.
  List<T> shuffled<T>(List<T> source) {
    final list = List<T>.of(source);
    for (var i = list.length - 1; i > 0; i--) {
      final j = nextInt(i + 1);
      final tmp = list[i];
      list[i] = list[j];
      list[j] = tmp;
    }
    return list;
  }
}
