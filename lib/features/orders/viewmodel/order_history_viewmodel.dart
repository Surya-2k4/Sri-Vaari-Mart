import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../model/order_model.dart';
import '../model/order_item_model.dart';

final orderHistoryViewModelProvider =
    StateNotifierProvider.autoDispose<
      OrderHistoryViewModel,
      AsyncValue<List<OrderModel>>
    >((ref) => OrderHistoryViewModel());

class OrderHistoryViewModel
    extends StateNotifier<AsyncValue<List<OrderModel>>> {
  OrderHistoryViewModel() : super(const AsyncValue.loading()) {
    loadOrders();
  }

  final SupabaseClient _client = Supabase.instance.client;

  Future<void> loadOrders() async {
    try {
      final user = _client.auth.currentUser;
      if (user == null) {
        print('⚠️ No user logged in for orders');
        state = const AsyncValue.data([]);
        return;
      }

      print('📦 Fetching orders for user: ${user.id}');

      final response = await _client
          .from('orders')
          .select('*, order_items(*)')
          .eq('user_id', user.id)
          .order('created_at', ascending: false);

      print('📦 Response received: ${response.length} orders');

      final orders = (response as List).map((e) {
        print('   Order: ${e['id']} - ₹${e['total_amount']}');
        return OrderModel(
          id: e['id'],
          totalAmount: (e['total_amount'] as num).toDouble(),
          status: e['status'],
          paymentMethod: e['payment_method'] ?? 'Unknown',
          shippingAddress: e['shipping_address'] ?? '',
          phoneNumber: e['phone_number'] ?? 0,
          createdAt: DateTime.parse(e['created_at']),
          items: (e['order_items'] as List? ?? [])
              .map(
                (item) => OrderItemModel(
                  productName: item['product_name'],
                  price: (item['price'] as num).toDouble(),
                  quantity: item['quantity'],
                ),
              )
              .toList(),
        );
      }).toList();

      print('✅ Orders loaded: ${orders.length}');
      state = AsyncValue.data(orders);
    } catch (e, st) {
      print('❌ Error loading orders: $e');
      print('Stack trace: $st');
      state = AsyncValue.error(e, st);
    }
  }
}
