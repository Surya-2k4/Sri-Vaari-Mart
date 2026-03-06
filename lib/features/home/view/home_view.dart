import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/theme_provider.dart';
import '../../../core/utils/category_icon_mapper.dart';
import '../../products/view/product_list_view.dart';
import '../../products/viewmodel/product_list_viewmodel.dart';
import '../../products/view/product_detail_view.dart';
import '../viewmodel/category_viewmodel.dart';

class HomeView extends ConsumerStatefulWidget {
  const HomeView({super.key});

  @override
  ConsumerState<HomeView> createState() => _HomeViewState();
}

class _HomeViewState extends ConsumerState<HomeView> {
  final _searchController = TextEditingController();
  Timer? _debounce;
  bool _isSearching = false;

  @override
  void dispose() {
    _searchController.dispose();
    _debounce?.cancel();
    super.dispose();
  }

  void _onSearchChanged(String query) {
    // Immediate state update to show/hide clear icon and update visual state
    setState(() {
      if (query.isEmpty) {
        _isSearching = false;
      }
    });

    if (_debounce?.isActive ?? false) _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 500), () {
      if (query.trim().isNotEmpty) {
        setState(() => _isSearching = true);
        ref
            .read(productListViewModelProvider.notifier)
            .applyFilters(searchQuery: query.trim());
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final categoryState = ref.watch(categoryViewModelProvider);
    final themeMode = ref.watch(themeProvider);
    final productState = ref.watch(productListViewModelProvider);
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Vaari'),
        centerTitle: true,
        actions: [
          IconButton(
            onPressed: () => ref.read(themeProvider.notifier).toggleTheme(),
            icon: Icon(
              themeMode == ThemeMode.dark ? Icons.light_mode : Icons.dark_mode,
            ),
            tooltip: 'Toggle theme',
          ),
        ],
      ),
      body: CustomScrollView(
        slivers: [
          // Search Bar
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: TextField(
                controller: _searchController,
                onChanged: _onSearchChanged,
                style: TextStyle(color: colorScheme.onSurface),
                decoration: InputDecoration(
                  hintText: 'Search products...',
                  prefixIcon: const Icon(Icons.search),
                  suffixIcon: _searchController.text.isNotEmpty
                      ? IconButton(
                          icon: const Icon(Icons.clear),
                          onPressed: () {
                            _searchController.clear();
                            _onSearchChanged('');
                          },
                        )
                      : null,
                ),
                onSubmitted: (value) {
                  if (value.trim().isNotEmpty) {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) =>
                            ProductListView(searchQuery: value.trim()),
                      ),
                    );
                  }
                },
              ),
            ),
          ),

          if (!_isSearching) ...[
            // Categories Title
            const SliverToBoxAdapter(
              child: Padding(
                padding: EdgeInsets.symmetric(horizontal: 16),
                child: Text(
                  'Categories',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
              ),
            ),

            categoryState.when(
              loading: () => const SliverFillRemaining(
                child: Center(child: CircularProgressIndicator()),
              ),
              error: (e, _) =>
                  SliverFillRemaining(child: Center(child: Text(e.toString()))),
              data: (categories) {
                return SliverPadding(
                  padding: const EdgeInsets.all(16),
                  sliver: SliverGrid(
                    gridDelegate:
                        const SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 2,
                          mainAxisSpacing: 16,
                          crossAxisSpacing: 16,
                          childAspectRatio: 1.2,
                        ),
                    delegate: SliverChildBuilderDelegate((context, index) {
                      final category = categories[index];
                      return InkWell(
                        borderRadius: BorderRadius.circular(12),
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) =>
                                  ProductListView(categoryId: category.id),
                            ),
                          );
                        },
                        child: Card(
                          elevation: 1,
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(getCategoryIcon(category.icon), size: 42),
                              const SizedBox(height: 10),
                              Text(
                                category.name,
                                textAlign: TextAlign.center,
                                style: Theme.of(context).textTheme.titleMedium,
                              ),
                            ],
                          ),
                        ),
                      );
                    }, childCount: categories.length),
                  ),
                );
              },
            ),
          ] else ...[
            // Search Results Title
            const SliverToBoxAdapter(
              child: Padding(
                padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: Text(
                  'Search Results',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
              ),
            ),

            productState.when(
              loading: () => const SliverFillRemaining(
                child: Center(child: CircularProgressIndicator()),
              ),
              error: (e, _) =>
                  SliverFillRemaining(child: Center(child: Text(e.toString()))),
              data: (products) {
                if (products.isEmpty) {
                  return const SliverFillRemaining(
                    child: Center(child: Text('No products found')),
                  );
                }

                return SliverPadding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  sliver: SliverList(
                    delegate: SliverChildBuilderDelegate((context, index) {
                      final product = products[index];
                      return Card(
                        margin: const EdgeInsets.only(bottom: 12),
                        child: ListTile(
                          leading: ClipRRect(
                            borderRadius: BorderRadius.circular(8),
                            child: Image.network(
                              product.imageUrl,
                              width: 50,
                              height: 50,
                              fit: BoxFit.cover,
                              errorBuilder: (_, __, ___) => Container(
                                width: 50,
                                height: 50,
                                color: Colors.grey.shade200,
                                child: const Icon(Icons.image),
                              ),
                            ),
                          ),
                          title: Text(product.name),
                          subtitle: Text('₹${product.price}'),
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) =>
                                    ProductDetailView(productId: product.id),
                              ),
                            );
                          },
                        ),
                      );
                    }, childCount: products.length),
                  ),
                );
              },
            ),
          ],
        ],
      ),
    );
  }
}
