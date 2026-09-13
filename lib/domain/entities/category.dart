/// تصنيف واحد من تصنيفات الأسئلة.
class Category {
  const Category({
    required this.slug,
    required this.name,
    required this.idBlock,
    required this.order,
  });

  /// المعرّف البرمجي الثابت (لا يتغيّر أبداً — تُبنى عليه بيانات التقدّم).
  final String slug;

  /// الاسم المعروض بالعربية.
  final String name;

  /// بداية نطاق المعرّفات المخصص لهذا التصنيف (مثل 1000).
  final int idBlock;

  final int order;
}
