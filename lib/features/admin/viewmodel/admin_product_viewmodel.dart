import 'dart:io';
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

  Future<String?> uploadProductImage(File imageFile) async {
    try {
      final fileName = '${DateTime.now().millisecondsSinceEpoch}.jpg';
      final storageResponse = await _client.storage
          .from('products')
          .upload(fileName, imageFile);

      if (storageResponse.isEmpty) return null;

      final imageUrl = _client.storage.from('products').getPublicUrl(fileName);
      return imageUrl;
    } catch (e) {
      print('❌ Error uploading image: $e');
      return null;
    }
  }

  Future<void> addProduct(AdminProductModel product) async {
    try {
      print('📦 Adding product: ${product.name}');
      print('   Data: ${product.toMap()}');

      await _client.from('products').insert(product.toMap());
      await _broadcastProductNotification(product, isNew: true);

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
      await _broadcastProductNotification(product, isNew: false);
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

  Future<void> _broadcastProductNotification(
    AdminProductModel product, {
    required bool isNew,
  }) async {
    try {
      final title = isNew ? 'New Product Added!' : 'Product Updated';
      final body =
          isNew
              ? '${product.name} is now available in ${product.type} category. Check it out!'
              : 'Details for ${product.name} have been updated. Take a look!';

      // Fetch all user IDs from profiles table
      final profilesResponse = await _client.from('profiles').select('id');
      final List<dynamic> profiles = profilesResponse as List;

      if (profiles.isEmpty) return;

      final notifications =
          profiles.map((p) {
            return {
              'user_id': p['id'],
              'title': title,
              'body': body,
              'created_at': DateTime.now().toIso8601String(),
              'is_read': false,
            };
          }).toList();

      // Batch insert notifications
      await _client.from('notifications').insert(notifications);
      print('📢 Broadcast notifications sent to ${profiles.length} users');
    } catch (e) {
      print('⚠️ Error broadcasting notifications: $e');
      // Don't rethrow as this is secondary to the product update itself
    }
  }
}
