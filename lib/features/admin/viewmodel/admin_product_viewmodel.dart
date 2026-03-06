import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../model/admin_product_model.dart';

final adminProductViewModelProvider =
    StateNotifierProvider.autoDispose<
      AdminProductViewModel,
      AsyncValue<List<AdminProductModel>>
    >((ref) {
      return AdminProductViewModel();
    });

class AdminProductViewModel
    extends StateNotifier<AsyncValue<List<AdminProductModel>>> {
  AdminProductViewModel() : super(const AsyncValue.loading()) {
    loadProducts();
  }

  final SupabaseClient _client = Supabase.instance.client;

  Future<void> loadProducts() async {
    try {
      final response = await _client.from('products').select().order('name');

      final products = (response as List)
          .map((e) => AdminProductModel.fromMap(e))
          .toList();

      state = AsyncValue.data(products);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  Future<void> addProduct(AdminProductModel product) async {
    try {
      print('📦 Adding product: ${product.name}');
      print('   Data: ${product.toMap()}');

      await _client.from('products').insert(product.toMap());

      print('✅ Product added successfully');
      await loadProducts();
    } catch (e) {
      print('❌ Error adding product: $e');
      if (e.toString().contains('row-level security')) {
        print(
          '⚠️  RLS Policy Error: The database needs RLS policies configured.',
        );
        print('⚠️  See DATABASE_SETUP_GUIDE.md for instructions.');
      }
      rethrow;
    }
  }

  Future<void> updateProduct(AdminProductModel product) async {
    try {
      await _client
          .from('products')
          .update(product.toMap())
          .eq('id', product.id!);
      await loadProducts();
    } catch (e) {
      print('❌ Error updating product: $e');
      rethrow;
    }
  }

  Future<void> deleteProduct(String productId) async {
    try {
      print('🗑️ Deleting product: $productId');

      // First, delete all cart items referencing this product
      print('   Removing from carts...');
      await _client.from('cart_items').delete().eq('product_id', productId);

      // Then delete the product
      print('   Deleting product...');
      await _client.from('products').delete().eq('id', productId);

      print('✅ Product deleted successfully');
      await loadProducts();
    } catch (e) {
      print('❌ Error deleting product: $e');
      if (e.toString().contains('foreign key constraint')) {
        print('⚠️  Foreign Key Error: Product is still referenced elsewhere.');
      }
      rethrow;
    }
  }

  Future<void> updatePrice(String productId, double newPrice) async {
    try {
      await _client
          .from('products')
          .update({'price': newPrice})
          .eq('id', productId);
      await loadProducts();
    } catch (e) {
      print('❌ Error updating price: $e');
      rethrow;
    }
  }
}
