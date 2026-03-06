import 'order_item_model.dart';

class OrderModel {
  final String id;
  final double totalAmount;
  final String status;
  final String paymentMethod;
  final String shippingAddress;
  final int phoneNumber;
  final DateTime createdAt;
  final List<OrderItemModel> items;

  OrderModel({
    required this.id,
    required this.totalAmount,
    required this.status,
    required this.paymentMethod,
    required this.shippingAddress,
    required this.phoneNumber,
    required this.createdAt,
    required this.items,
  });
}
