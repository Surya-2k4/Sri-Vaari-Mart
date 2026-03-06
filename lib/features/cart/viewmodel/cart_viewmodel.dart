import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../model/cart_item_model.dart';

final cartViewModelProvider =
    StateNotifierProvider<CartViewModel, AsyncValue<List<CartItemModel>>>(
      (ref) => CartViewModel(),
    );

class CartViewModel extends StateNotifier<AsyncValue<List<CartItemModel>>> {
  CartViewModel() : super(const AsyncValue.loading()) {
    loadCart();
  }

  final SupabaseClient _client = Supabase.instance.client;

  Future<void> loadCart() async {
    try {
      final user = _client.auth.currentUser;
      if (user == null) {
        state = const AsyncValue.data([]);
        return;
      }

      final response = await _client
          .from('cart_items')
          .select(
            'id, product_id, quantity, products!inner(name, price, image_url)',
          )
          .eq('user_id', user.id);
      final items = (response as List)
          .map((e) => CartItemModel.fromMap(e))
          .toList();

      state = AsyncValue.data(items);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  Future<void> updateQuantity(String cartItemId, int quantity) async {
    await _client
        .from('cart_items')
        .update({'quantity': quantity})
        .eq('id', cartItemId);

    loadCart();
  }

  Future<void> removeItem(String cartItemId) async {
    await _client.from('cart_items').delete().eq('id', cartItemId);
    loadCart();
  }

  double totalAmount(List<CartItemModel> items) {
    return items.fold(0, (sum, item) => sum + (item.price * item.quantity));
  }
}
