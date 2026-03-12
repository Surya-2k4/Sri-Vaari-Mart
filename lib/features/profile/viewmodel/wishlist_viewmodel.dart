import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../products/model/product_model.dart';

final wishlistProvider = StateNotifierProvider<WishlistViewModel, List<String>>((ref) {
  return WishlistViewModel();
});

class WishlistViewModel extends StateNotifier<List<String>> {
  WishlistViewModel() : super([]) {
    _loadWishlist();
  }

  static const _wishlistKey = 'user_wishlist';


  Future<void> _loadWishlist() async {
    final prefs = await SharedPreferences.getInstance();
    final wishlist = prefs.getStringList(_wishlistKey) ?? [];
    state = wishlist;
  }

  Future<void> toggleWishlist(String productId) async {
    final prefs = await SharedPreferences.getInstance();
    List<String> currentWishlist = [...state];

    if (currentWishlist.contains(productId)) {
      currentWishlist.remove(productId);
    } else {
      currentWishlist.add(productId);
    }

    state = currentWishlist;
    await prefs.setStringList(_wishlistKey, currentWishlist);
  }

  bool isWishlisted(String productId) {
    return state.contains(productId);
  }
}

final wishlistProductsProvider = FutureProvider<List<ProductModel>>((ref) async {
  final ids = ref.watch(wishlistProvider);
  if (ids.isEmpty) return [];

  final client = Supabase.instance.client;
  final response = await client
      .from('products')
      .select()
      .filter('id', 'in', '(${ids.join(',')})');

  return (response as List).map((e) => ProductModel.fromMap(e)).toList();
});

