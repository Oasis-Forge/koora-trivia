/// الأسئلة التي عرضتها الجولة السريعة مؤخراً، الأقدم أولاً.
///
/// تتجنّبها الجولة التالية ما دام في المجموعة غيرها — كانت تكرر سؤالاً رآه
/// اللاعب قبل دقائق.
abstract class RecentQuestionsRepository {
  Future<List<int>> load();
  Future<void> save(List<int> ids);
}
