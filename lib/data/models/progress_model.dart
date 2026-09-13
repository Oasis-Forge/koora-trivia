import '../../domain/entities/category_progress.dart';

class CategoryProgressModel extends CategoryProgress {
  const CategoryProgressModel({required super.slug, required super.stars});

  factory CategoryProgressModel.fromEntity(CategoryProgress progress) {
    return CategoryProgressModel(
      slug: progress.slug,
      stars: progress.stars,
    );
  }

  /// [levelCount] يضبط الطول عند تغيّر عدد المستويات بين إصدارات التطبيق.
  factory CategoryProgressModel.fromJson(
    String slug,
    List<dynamic> raw,
    int levelCount,
  ) {
    final stars = List<int>.filled(levelCount, 0);
    for (var i = 0; i < raw.length && i < levelCount; i++) {
      final value = raw[i];
      if (value is int) stars[i] = value.clamp(0, 3);
    }
    return CategoryProgressModel(slug: slug, stars: stars);
  }

  List<int> toJson() => stars;
}
