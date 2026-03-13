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

    // Build slideshow images from the 'image_urls' column (jsonb array in DB).
    // Falls back to main image if the column is missing or empty.
    List<String> imagesList = [];

    if (data['image_urls'] != null &&
        data['image_urls'] is List &&
        (data['image_urls'] as List).isNotEmpty) {
      imagesList =
          (data['image_urls'] as List).map((e) => e.toString()).toList();
    }

    // If no images array from DB, use the main image for the slideshow
    if (imagesList.isEmpty) {
      imagesList = [mainImage];
    }

    // Ensure the main image is always the first in the list
    if (imagesList.isNotEmpty && imagesList[0] != mainImage) {
      imagesList.insert(0, mainImage);
    }

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
