class CategoryModel {
  final String id;
  final String name;
  final String type;
  final String icon;

  CategoryModel({
    required this.id,
    required this.name,
    required this.type,
    required this.icon,
  });

  factory CategoryModel.fromMap(Map<String, dynamic> data) {
    return CategoryModel(
      id: data['id'],
      name: data['name'],
      type: data['type'],
      icon: data['icon'] ?? 'default', // 🔑 SAFE FALLBACK
    );
  }
}
