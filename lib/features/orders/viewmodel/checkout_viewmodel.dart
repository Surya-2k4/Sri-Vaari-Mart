import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../cart/model/cart_item_model.dart';
import '../../../core/services/notification_service.dart';

final checkoutViewModelProvider =
    StateNotifierProvider<CheckoutViewModel, AsyncValue<void>>(
      (ref) => CheckoutViewModel(ref),
    );

class CheckoutViewModel extends StateNotifier<AsyncValue<void>> {
  final Ref _ref;
  CheckoutViewModel(this._ref) : super(const AsyncValue.data(null));

  final SupabaseClient _client = Supabase.instance.client;

  /// Creates order + order_items and clears cart
  Future<void> placeOrder({
    required BuildContext context,
    required List<CartItemModel> items,
    required String paymentMethod,
    required String address,
    required String phone,
  }) async {
    try {
      state = const AsyncValue.loading();

      final user = _client.auth.currentUser;
      if (user == null) {
        print('❌ Order failed: User not logged in');
        throw Exception('User not logged in');
      }

      if (items.isEmpty) {
        print('❌ Order failed: Cart is empty');
        throw Exception('Cart is empty');
      }

      final totalAmount = items.fold(
        0.0,
        (sum, item) => sum + (item.price * item.quantity),
      );

      // Convert phone string to int for database
      final phoneInt = int.tryParse(phone);
      if (phoneInt == null) {
        print('❌ Order failed: Invalid phone number format');
        throw Exception('Invalid phone number. Please enter only digits.');
      }

      print('📦 Creating order...');
      print('   User: ${user.id}');
      print('   Total: ₹$totalAmount');
      print('   Items: ${items.length}');
      print('   Payment: $paymentMethod');

      // 1️⃣ Create order
      final order = await _client
          .from('orders')
          .insert({
            'user_id': user.id,
            'total_amount': totalAmount,
            'status': paymentMethod == 'COD' ? 'pending' : 'paid',
            'payment_method': paymentMethod,
            'shipping_address': address,
            'phone_number': phoneInt,
          })
          .select()
          .single();

      print('✅ Order created: ${order['id']}');

      // 2️⃣ Create order items
      final List<Map<String, dynamic>> orderItems = items
          .map(
            (item) => {
              'order_id': order['id'],
              'product_name': item.name,
              'price': item.price,
              'quantity': item.quantity,
            },
          )
          .toList();

      await _client.from('order_items').insert(orderItems);
      print('✅ Order items created: ${orderItems.length} items');

      // 3️⃣ Clear cart
      await _client.from('cart_items').delete().eq('user_id', user.id);
      print('✅ Cart cleared');

      // 4️⃣ Notify user
      _ref
          .read(notificationServiceProvider)
          .notifyOrderPlaced(context, order, orderItems);

      state = const AsyncValue.data(null);
    } catch (e, st) {
      print('❌ Order placement error: $e');
      print('Stack trace: $st');
      state = AsyncValue.error(e, st);
      rethrow;
    }
  }

  Future<void> placeOrderAfterPayment({
    required BuildContext context,
    required List<CartItemModel> items,
    required String address,
    required String phone,
  }) async {
    return placeOrder(
      context: context,
      items: items,
      paymentMethod: 'Razorpay',
      address: address,
      phone: phone,
    );
  }
}
