import '../../domain/entities/category.dart';

class CategoryModel extends Category {
  const CategoryModel({
    required super.slug,
    required super.name,
    required super.idBlock,
    required super.order,
  });

  factory CategoryModel.fromJson(Map<String, dynamic> json) {
    return CategoryModel(
      slug: json['slug'] as String,
      name: json['name'] as String,
      idBlock: json['idBlock'] as int,
      order: json['order'] as int,
    );
  }
}
