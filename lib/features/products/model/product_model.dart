class ProductModel {
  final String id;
  final String name;
  final double price;
  final String type;
  final String imageUrl;
  final String description;
  final String highlights;

  ProductModel({
    required this.id,
    required this.name,
    required this.price,
    required this.type,
    required this.imageUrl,
    required this.description,
    required this.highlights,
  });

  factory ProductModel.fromMap(Map<String, dynamic> data) {
    return ProductModel(
      id: data['id'],
      name: data['name'],
      price: (data['price'] as num).toDouble(),
      type: data['type'],
      imageUrl:
          data['image_url'] ??
          'https://images.unsplash.com/photo-1582582621959-48d27397dc69',
      description: data['description'] ?? '',
      highlights: data['highlights'] ?? '',
    );
  }
}
