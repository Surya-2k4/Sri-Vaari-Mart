class AdminProductModel {
  final String? id;
  final String name;
  final double price;
  final String type;
  final List<String> imageUrls; // Supports up to 3 images
  final String description;
  final String highlights;

  AdminProductModel({
    this.id,
    required this.name,
    required this.price,
    required this.type,
    required this.imageUrls,
    required this.description,
    required this.highlights,
  });

  Map<String, dynamic> toMap() {
    return {
      if (id != null) 'id': id,
      'name': name,
      'price': price,
      'type': type,
      'image_url': imageUrls.isNotEmpty ? imageUrls.first : '', // For backward compatibility if needed by some views
      'image_urls': imageUrls,
      'description': description,
      'highlights': highlights,
    };
  }

  factory AdminProductModel.fromMap(Map<String, dynamic> data) {
    // Handle both single image_url and list of image_urls for robust loading
    List<String> urls = [];
    if (data['image_urls'] != null) {
      urls = List<String>.from(data['image_urls']);
    } else if (data['image_url'] != null && data['image_url'].toString().isNotEmpty) {
      urls = [data['image_url']];
    }

    return AdminProductModel(
      id: data['id'],
      name: data['name'],
      price: (data['price'] as num).toDouble(),
      type: data['type'],
      imageUrls: urls,
      description: data['description'] ?? '',
      highlights: data['highlights'] ?? '',
    );
  }
}
