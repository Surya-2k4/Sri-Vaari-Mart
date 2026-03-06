import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../model/product_model.dart';

final productDetailViewModelProvider =
    StateNotifierProvider<ProductDetailViewModel, AsyncValue<ProductModel>>(
      (ref) => ProductDetailViewModel(),
    );

class ProductDetailViewModel extends StateNotifier<AsyncValue<ProductModel>> {
  ProductDetailViewModel() : super(const AsyncValue.loading());

  final _client = Supabase.instance.client;

  Future<void> loadProduct(String productId) async {
    try {
      final data = await _client
          .from('products')
          .select()
          .eq('id', productId)
          .single();

      state = AsyncValue.data(ProductModel.fromMap(data));
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  Future<bool> addToCart(String productId) async {
    final user = _client.auth.currentUser;
    if (user == null) {
      return false;
    }

    await _client.from('cart_items').insert({
      'user_id': user.id,
      'product_id': productId,
      'quantity': 1,
    });

    return true;
  }
}
