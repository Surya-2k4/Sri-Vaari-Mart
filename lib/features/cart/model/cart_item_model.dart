class CartItemModel {
  final String id;
  final String productId;
  final String name;
  final double price;
  final int quantity;
  final String imageUrl;

  CartItemModel({
    required this.id,
    required this.productId,
    required this.name,
    required this.price,
    required this.quantity,
    required this.imageUrl,
  });

  factory CartItemModel.fromMap(Map<String, dynamic> data) {
    return CartItemModel(
      id: data['id'],
      productId: data['product_id'],
      name: data['products']['name'],
      price: (data['products']['price'] as num).toDouble(),
      quantity: data['quantity'],
      imageUrl:
          data['products']['image_url'] ??
          'https://images.unsplash.com/photo-1582582621959-48d27397dc69',
    );
  }
}
