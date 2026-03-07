class ProductModel {
  final String id;
  final String name;
  final double price;
  final String type;
  final String imageUrl;
  final List<String> images;
  final String description;
  final String highlights;

  ProductModel({
    required this.id,
    required this.name,
    required this.price,
    required this.type,
    required this.imageUrl,
    required this.images,
    required this.description,
    required this.highlights,
  });

  factory ProductModel.fromMap(Map<String, dynamic> data) {
    final mainImage =
        data['image_url'] ??
        'https://images.unsplash.com/photo-1542838132-92c53300491e?q=80&w=1000&auto=format&fit=crop';

    // Generating 3 images for the slideshow as requested
    // In a real app, these would come from a database field like 'images_list'
    final List<String> imagesList = [
      mainImage,
      // Adding relevant variations or high-quality product placeholders
      'https://images.unsplash.com/photo-1543168252-418658e7d361?q=80&w=1000&auto=format&fit=crop',
      'https://images.unsplash.com/photo-1583258292688-d0213dc5a3a8?q=80&w=1000&auto=format&fit=crop',
    ];

    return ProductModel(
      id: data['id'],
      name: data['name'],
      price: (data['price'] as num).toDouble(),
      type: data['type'],
      imageUrl: mainImage,
      images: imagesList,
      description: data['description'] ?? '',
      highlights: data['highlights'] ?? '',
    );
  }
}
