import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../model/admin_order_model.dart';

final adminOrderViewModelProvider =
    StateNotifierProvider.autoDispose<
      AdminOrderViewModel,
      AsyncValue<List<AdminOrderModel>>
    >((ref) {
      return AdminOrderViewModel();
    });

class AdminOrderViewModel
    extends StateNotifier<AsyncValue<List<AdminOrderModel>>> {
  AdminOrderViewModel() : super(const AsyncValue.loading()) {
    loadOrders();
  }

  final SupabaseClient _client = Supabase.instance.client;

  Future<void> loadOrders() async {
    try {
      final response = await _client
          .from('orders')
          .select('*, order_items(*)')
          .order('created_at', ascending: false);

      final orders = (response as List)
          .map((e) => AdminOrderModel.fromMap(e))
          .toList();

      state = AsyncValue.data(orders);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  Future<void> updateOrderStatus(String orderId, String newStatus) async {
    try {
      // 1. Fetch the order to get user_id
      final orderData = await _client
          .from('orders')
          .select('user_id')
          .eq('id', orderId)
          .single();
      
      final String userId = orderData['user_id'];

      // 2. Update status
      await _client
          .from('orders')
          .update({'status': newStatus})
          .eq('id', orderId);

      // 3. Send notification to the user
      await _sendOrderStatusNotification(userId, orderId, newStatus);

      await loadOrders();
    } catch (e) {
      print('❌ Error updating order status: $e');
      rethrow;
    }
  }

  Future<void> _sendOrderStatusNotification(
    String userId,
    String orderId,
    String status,
  ) async {
    try {
      final shortId = orderId.length > 8 ? orderId.substring(0, 8) : orderId;
      final title = 'Order Update: #$shortId';
      final body = 'Your order status has been updated to "$status".';

      await _client.from('notifications').insert({
        'user_id': userId,
        'title': title,
        'body': body,
        'created_at': DateTime.now().toIso8601String(),
        'is_read': false,
      });
      print('📢 Order status notification sent to user: $userId');
    } catch (e) {
      print('⚠️ Error sending order notification: $e');
    }
  }

  Future<void> deleteOrder(String orderId) async {
    try {
      // Delete order items first
      await _client.from('order_items').delete().eq('order_id', orderId);
      // Then delete order
      await _client.from('orders').delete().eq('id', orderId);
      await loadOrders();
    } catch (e) {
      print('❌ Error deleting order: $e');
      rethrow;
    }
  }
}
