/// المهام اليومية المتاحة. المعرّف يُحفظ نصياً فلا يتأثر بترتيب العناصر.
enum TaskKind {
  correctAnswers('answers'),
  completeDaily('daily'),
  completeLevel('level');

  const TaskKind(this.id);
  final String id;
}

/// مهمة يومية واحدة بحالتها الحالية.
class DailyTask {
  const DailyTask({
    required this.kind,
    required this.progress,
    required this.target,
    required this.reward,
    required this.claimed,
  });

  final TaskKind kind;
  final int progress;
  final int target;
  final int reward;
  final bool claimed;

  bool get isComplete => progress >= target;

  /// جاهزة للمطالبة: مكتملة ولم تُستلم بعد.
  bool get isClaimable => isComplete && !claimed;

  double get ratio => target == 0 ? 0 : (progress / target).clamp(0.0, 1.0);

  /// العدد المعروض للاعب: التقدّم يستمر بعد الهدف (21 إجابة)، لكن «21 / 10» يبدو خطأً.
  int get shownProgress => progress > target ? target : progress;
}
