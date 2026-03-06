import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../model/category_model.dart';

final categoryViewModelProvider =
    StateNotifierProvider<CategoryViewModel, AsyncValue<List<CategoryModel>>>(
      (ref) => CategoryViewModel(),
    );

class CategoryViewModel extends StateNotifier<AsyncValue<List<CategoryModel>>> {
  CategoryViewModel() : super(const AsyncValue.loading()) {
    loadCategories();
  }

  final SupabaseClient _client = Supabase.instance.client;

  Future<void> loadCategories() async {
    try {
      final response = await _client.from('categories').select().order('name');

      print('📂 Categories loaded: ${(response as List).length} categories');

      final categories = (response as List)
          .map((e) => CategoryModel.fromMap(e))
          .toList();

      print('📂 Categories parsed: ${categories.length}');
      for (var cat in categories) {
        print('   - ${cat.name} (${cat.type})');
      }

      state = AsyncValue.data(categories);
    } catch (e, st) {
      print('❌ Error loading categories: $e');
      state = AsyncValue.error(e, st);
    }
  }
}
