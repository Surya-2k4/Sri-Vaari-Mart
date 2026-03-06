class AdminProductModel {
  final String? id;
  final String name;
  final double price;
  final String type;
  final String imageUrl;
  final String description;
  final String highlights;

  AdminProductModel({
    this.id,
    required this.name,
    required this.price,
    required this.type,
    required this.imageUrl,
    required this.description,
    required this.highlights,
  });

  Map<String, dynamic> toMap() {
    return {
      if (id != null) 'id': id,
      'name': name,
      'price': price,
      'type': type,
      'image_url': imageUrl,
      'description': description,
      'highlights': highlights,
    };
  }

  factory AdminProductModel.fromMap(Map<String, dynamic> data) {
    return AdminProductModel(
      id: data['id'],
      name: data['name'],
      price: (data['price'] as num).toDouble(),
      type: data['type'],
      imageUrl: data['image_url'] ?? '',
      description: data['description'] ?? '',
      highlights: data['highlights'] ?? '',
    );
  }
}
