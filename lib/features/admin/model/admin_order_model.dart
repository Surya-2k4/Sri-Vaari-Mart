import '../../orders/model/order_item_model.dart';

class AdminOrderModel {
  final String id;
  final String userId;
  final double totalAmount;
  final String status;
  final String paymentMethod;
  final String shippingAddress;
  final int phoneNumber;
  final DateTime createdAt;
  final List<OrderItemModel> items;

  AdminOrderModel({
    required this.id,
    required this.userId,
    required this.totalAmount,
    required this.status,
    required this.paymentMethod,
    required this.shippingAddress,
    required this.phoneNumber,
    required this.createdAt,
    required this.items,
  });

  factory AdminOrderModel.fromMap(Map<String, dynamic> data) {
    return AdminOrderModel(
      id: data['id'],
      userId: data['user_id'],
      totalAmount: (data['total_amount'] as num).toDouble(),
      status: data['status'],
      paymentMethod: data['payment_method'] ?? 'Unknown',
      shippingAddress: data['shipping_address'] ?? '',
      phoneNumber: data['phone_number'] ?? 0,
      createdAt: DateTime.parse(data['created_at']),
      items: (data['order_items'] as List? ?? [])
          .map(
            (item) => OrderItemModel(
              productName: item['product_name'],
              price: (item['price'] as num).toDouble(),
              quantity: item['quantity'],
            ),
          )
          .toList(),
    );
  }
}
