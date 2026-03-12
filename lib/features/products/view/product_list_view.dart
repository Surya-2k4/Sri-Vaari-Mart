import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../home/viewmodel/category_viewmodel.dart';
import '../viewmodel/product_list_viewmodel.dart';
import '../../profile/viewmodel/wishlist_viewmodel.dart';
import 'product_detail_view.dart';


class ProductListView extends ConsumerStatefulWidget {
  final String? categoryId;
  final String? searchQuery;

  const ProductListView({super.key, this.categoryId, this.searchQuery});

  @override
  ConsumerState<ProductListView> createState() => _ProductListViewState();
}

class _ProductListViewState extends ConsumerState<ProductListView> {
  final _scrollController = ScrollController();
  double _minPrice = 0;
  double _maxPrice = 10000;
  String? _selectedCategoryId;

  @override
  void initState() {
    super.initState();
    _selectedCategoryId = widget.categoryId;

    Future.microtask(() {
      final viewModel = ref.read(productListViewModelProvider.notifier);
      viewModel.reset();
      viewModel.loadProducts(
        categoryId: widget.categoryId,
        searchQuery: widget.searchQuery,
      );
    });

    _scrollController.addListener(() {
      if (_scrollController.position.pixels >=
          _scrollController.position.maxScrollExtent - 200) {
        ref.read(productListViewModelProvider.notifier).loadProducts();
      }
    });
  }

  void _showFilterSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) {
        return Consumer(
          builder: (context, ref, _) {
            final categoryState = ref.watch(categoryViewModelProvider);

            return StatefulBuilder(
              builder: (context, setSheetState) {
                return DraggableScrollableSheet(
                  initialChildSize: 0.6,
                  maxChildSize: 0.9,
                  minChildSize: 0.4,
                  expand: false,
                  builder: (context, scrollController) {
                    return SingleChildScrollView(
                      controller: scrollController,
                      padding: const EdgeInsets.all(24),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Filters',
                            style: Theme.of(context).textTheme.headlineSmall,
                          ),
                          const SizedBox(height: 24),
                          Text(
                            'Categories',
                            style: Theme.of(context).textTheme.titleMedium,
                          ),
                          const SizedBox(height: 12),
                          categoryState.when(
                            loading: () => const CircularProgressIndicator(),
                            error: (e, _) => Text('Error: $e'),
                            data: (categories) {
                              return Wrap(
                                spacing: 8,
                                children: [
                                  ChoiceChip(
                                    label: const Text('All'),
                                    selected: _selectedCategoryId == null,
                                    onSelected: (selected) {
                                      setSheetState(() {
                                        _selectedCategoryId = null;
                                      });
                                    },
                                  ),
                                  ...categories.map((cat) {
                                    return ChoiceChip(
                                      label: Text(cat.name),
                                      selected: _selectedCategoryId == cat.id,
                                      onSelected: (selected) {
                                        setSheetState(() {
                                          _selectedCategoryId = selected
                                              ? cat.id
                                              : null;
                                        });
                                      },
                                    );
                                  }),
                                ],
                              );
                            },
                          ),
                          const SizedBox(height: 24),
                          Text(
                            'Price Range (₹${_minPrice.toInt()} - ₹${_maxPrice.toInt()})',
                            style: Theme.of(context).textTheme.titleMedium,
                          ),
                          RangeSlider(
                            values: RangeValues(_minPrice, _maxPrice),
                            min: 0,
                            max: 10000,
                            divisions: 20,
                            labels: RangeLabels(
                              '₹${_minPrice.toInt()}',
                              '₹${_maxPrice.toInt()}',
                            ),
                            onChanged: (values) {
                              setSheetState(() {
                                _minPrice = values.start;
                                _maxPrice = values.end;
                              });
                            },
                          ),
                          const SizedBox(height: 32),
                          SizedBox(
                            width: double.infinity,
                            child: ElevatedButton(
                              onPressed: () {
                                ref
                                    .read(productListViewModelProvider.notifier)
                                    .applyFilters(
                                      searchQuery: widget.searchQuery,
                                      categoryId: _selectedCategoryId,
                                      minPrice: _minPrice,
                                      maxPrice: _maxPrice,
                                    );
                                Navigator.pop(context);
                              },
                              child: const Text('Apply Filters'),
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                );
              },
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final productState = ref.watch(productListViewModelProvider);

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.searchQuery != null ? 'Search Results' : 'Products'),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.filter_list),
            onPressed: _showFilterSheet,
          ),
        ],
      ),
      body: productState.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text(e.toString())),
        data: (products) {
          if (products.isEmpty) {
            return const Center(child: Text('No products found'));
          }

          return ListView.separated(
            controller: _scrollController,
            padding: const EdgeInsets.all(16),
            itemCount: products.length,
            separatorBuilder: (_, __) => const SizedBox(height: 12),
            itemBuilder: (context, index) {
              final product = products[index];

              return InkWell(
                borderRadius: BorderRadius.circular(12),
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => ProductDetailView(productId: product.id),
                    ),
                  );
                },
                child: Card(
                  elevation: 1,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    children: [
                      ClipRRect(
                        borderRadius: const BorderRadius.only(
                          topLeft: Radius.circular(12),
                          bottomLeft: Radius.circular(12),
                        ),
                        child: Image.network(
                          product.imageUrl,
                          width: 110,
                          height: 110,
                          fit: BoxFit.cover,
                          errorBuilder: (_, __, ___) => Container(
                            width: 110,
                            height: 110,
                            color: Colors.grey.shade200,
                            child: const Icon(Icons.image_not_supported),
                          ),
                        ),
                      ),
                      Expanded(
                        child: Padding(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 8,
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                product.name,
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                                style: Theme.of(context).textTheme.titleMedium,
                              ),
                              const SizedBox(height: 6),
                              Text(
                                '₹${product.price.toStringAsFixed(0)}',
                                style: Theme.of(context).textTheme.bodyLarge,
                              ),
                            ],
                          ),
                        ),
                      ),
                      Consumer(
                        builder: (context, ref, _) {
                          final isWishlisted =
                              ref.watch(wishlistProvider).contains(product.id);
                          return IconButton(
                            icon: Icon(
                              isWishlisted ? Icons.favorite : Icons.favorite_border,
                              color: isWishlisted ? Colors.red : Colors.grey,
                            ),
                            onPressed: () {
                              ref
                                  .read(wishlistProvider.notifier)
                                  .toggleWishlist(product.id);
                            },
                          );
                        },
                      ),
                    ],
                  ),
                ),

              );
            },
          );
        },
      ),
    );
  }
}
