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
      await _client
          .from('orders')
          .update({'status': newStatus})
          .eq('id', orderId);
      await loadOrders();
    } catch (e) {
      print('❌ Error updating order status: $e');
      rethrow;
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
