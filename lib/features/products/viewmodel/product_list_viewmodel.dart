import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../model/product_model.dart';

final productListViewModelProvider =
    StateNotifierProvider<ProductListViewModel, AsyncValue<List<ProductModel>>>(
      (ref) => ProductListViewModel(),
    );

class ProductListViewModel
    extends StateNotifier<AsyncValue<List<ProductModel>>> {
  ProductListViewModel() : super(const AsyncValue.loading()) {
    loadProducts();
  }

  final SupabaseClient _client = Supabase.instance.client;
  static const int _pageSize = 10;
  int _page = 0;
  bool _hasMore = true;

  // Filters
  String? _searchQuery;
  String? _categoryId;
  double? _minPrice;
  double? _maxPrice;
  String _sortBy = 'created_at';
  bool _ascending = false;

  Future<void> loadProducts({
    String? categoryId,
    String? searchQuery,
    double? minPrice,
    double? maxPrice,
    String? sortBy,
    bool? ascending,
  }) async {
    if (!_hasMore && _page != 0) return;

    // Update internal filters if provided
    if (categoryId != null) _categoryId = categoryId;
    if (searchQuery != null) _searchQuery = searchQuery;
    if (minPrice != null) _minPrice = minPrice;
    if (maxPrice != null) _maxPrice = maxPrice;
    if (sortBy != null) _sortBy = sortBy;
    if (ascending != null) _ascending = ascending;

    try {
      var query = _client.from('products').select();

      // Apply Filters
      if (_categoryId != null && _categoryId != 'all') {
        query = query.eq('type', _categoryId!);
      }

      if (_searchQuery != null && _searchQuery!.isNotEmpty) {
        query = query.ilike('name', '%$_searchQuery%');
      }

      if (_minPrice != null) {
        query = query.gte('price', _minPrice!);
      }

      if (_maxPrice != null) {
        query = query.lte('price', _maxPrice!);
      }

      // Pagination & Sorting
      final response = await query
          .range(_page * _pageSize, (_page + 1) * _pageSize - 1)
          .order(_sortBy, ascending: _ascending);

      final fetched = (response as List)
          .map((e) => ProductModel.fromMap(e))
          .toList();

      if (fetched.length < _pageSize) _hasMore = false;

      final current = _page == 0 ? <ProductModel>[] : (state.value ?? []);
      state = AsyncValue.data([...current, ...fetched]);

      _page++;
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  void reset() {
    _page = 0;
    _hasMore = true;
    _searchQuery = null;
    _categoryId = null;
    _minPrice = null;
    _maxPrice = null;
    state = const AsyncValue.loading();
  }

  void applyFilters({
    String? searchQuery,
    double? minPrice,
    double? maxPrice,
    String? categoryId,
  }) {
    _searchQuery = searchQuery;
    _minPrice = minPrice;
    _maxPrice = maxPrice;
    _categoryId = categoryId;
    _page = 0;
    _hasMore = true;
    state = const AsyncValue.loading();
    loadProducts();
  }
}
