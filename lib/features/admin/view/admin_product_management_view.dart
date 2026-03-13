import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:vaari/core/constants/app_colors.dart';
import '../../home/viewmodel/category_viewmodel.dart';
import '../../home/model/category_model.dart';
import '../model/admin_product_model.dart';
import '../viewmodel/admin_product_viewmodel.dart';
import 'admin_add_edit_product_view.dart';

class AdminProductManagementView extends ConsumerStatefulWidget {
  const AdminProductManagementView({super.key});

  @override
  ConsumerState<AdminProductManagementView> createState() =>
      _AdminProductManagementViewState();
}

class _AdminProductManagementViewState
    extends ConsumerState<AdminProductManagementView> {
  String? _selectedCategory;

  @override
  Widget build(BuildContext context) {
    final productsState = ref.watch(adminProductViewModelProvider);
    final categoriesState = ref.watch(categoryViewModelProvider);

    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 900),
        child: Column(
          children: [
            // Header with Add Button and Filter
            Padding(
              padding: const EdgeInsets.all(24),
              child: Row(
                children: [
                  Expanded(
                    child: _buildCategoryFilter(categoriesState),
                  ),
                  const SizedBox(width: 16),
                  _buildAddButton(categoriesState),
                ],
              ),
            ),
            // Products List
            Expanded(
              child: productsState.when(
                loading: () => const Center(child: CircularProgressIndicator()),
                error: (e, _) => Center(child: Text('Error: $e')),
                data: (products) {
                  final filteredProducts = _selectedCategory == null
                      ? products
                      : products.where((p) => p.type == _selectedCategory).toList();

                  if (filteredProducts.isEmpty) {
                    return const Center(child: Text('No products found'));
                  }

                  return ListView.builder(
                    padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
                    itemCount: filteredProducts.length,
                    itemBuilder: (context, index) {
                      final product = filteredProducts[index];
                      return _buildProductCard(product);
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCategoryFilter(AsyncValue<List<CategoryModel>> categoriesState) {
    return categoriesState.when(
      loading: () => const LinearProgressIndicator(),
      error: (e, _) => const Text('Error loading categories'),
      data: (categories) {
        final uniqueCategories = <String, CategoryModel>{};
        for (var cat in categories) {
          if (!uniqueCategories.containsKey(cat.type)) {
            uniqueCategories[cat.type] = cat;
          }
        }
        final categoryList = uniqueCategories.values.toList();

        return Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.05),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: DropdownButtonFormField<String>(
            value: _selectedCategory,
            borderRadius: BorderRadius.circular(24),
            decoration: InputDecoration(
              labelText: 'Filter by Category',
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
                borderSide: BorderSide.none,
              ),
              filled: true,
              fillColor: Colors.white,
              prefixIcon: const Icon(Icons.category_outlined, color: AppColors.primaryBlack),
              contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
            ),
            items: [
              const DropdownMenuItem(value: null, child: Text('All Categories')),
              ...categoryList.map(
                (cat) => DropdownMenuItem(value: cat.type, child: Text(cat.name)),
              ),
            ],
            onChanged: (value) => setState(() => _selectedCategory = value),
          ),
        );
      },
    );
  }

  Widget _buildAddButton(AsyncValue<List<CategoryModel>> categoriesState) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.primaryBlack,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: AppColors.primaryBlack.withOpacity(0.2),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: IconButton(
        icon: const Icon(Icons.add_rounded, color: Colors.white, size: 28),
        onPressed: () {
          final categories = categoriesState.value ?? [];
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => AdminAddEditProductView(categories: categories),
            ),
          );
        },
        tooltip: 'Add Product',
        padding: const EdgeInsets.all(16),
      ),
    );
  }

  Widget _buildProductCard(AdminProductModel product) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 15,
            offset: const Offset(0, 8),
          ),
        ],
        border: Border.all(color: Colors.grey.shade100),
      ),
      child: Theme(
        data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
        child: ExpansionTile(
          tilePadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
          backgroundColor: Colors.grey.shade50.withOpacity(0.5),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
          leading: Container(
            width: 60,
            height: 60,
            decoration: BoxDecoration(
              color: Colors.grey.shade100,
              borderRadius: BorderRadius.circular(12),
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: product.imageUrls.isNotEmpty
                  ? Image.network(
                      product.imageUrls.first,
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => const Icon(Icons.broken_image, size: 30, color: Colors.grey),
                    )
                  : const Icon(Icons.image_not_supported, size: 30, color: Colors.grey),
            ),
          ),
          title: Text(
            product.name,
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
          ),
          subtitle: Text(
            '₹${product.price.toStringAsFixed(0)} • ${product.type}',
            style: TextStyle(color: Colors.grey.shade600, fontSize: 13),
          ),
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Divider(),
                  const SizedBox(height: 12),
                  _buildProductDetailRow('Description', product.description),
                  const SizedBox(height: 12),
                  _buildProductDetailRow('Highlights', product.highlights),
                  const SizedBox(height: 20),
                  Row(
                    children: [
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => AdminAddEditProductView(
                                  product: product,
                                  categories: ref.read(categoryViewModelProvider).value ?? [],
                                ),
                              ),
                            );
                          },
                          icon: const Icon(Icons.edit_rounded, size: 18),
                          label: const Text('EDIT PRODUCT'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.primaryBlack,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      _buildDeleteButton(product),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildProductDetailRow(String label, String value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.bold,
            color: Colors.grey.shade500,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          value.isEmpty ? 'N/A' : value,
          style: const TextStyle(fontSize: 14, color: Colors.black87),
        ),
      ],
    );
  }

  Widget _buildDeleteButton(AdminProductModel product) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.red.withOpacity(0.1),
        borderRadius: BorderRadius.circular(16),
      ),
      child: IconButton(
        icon: const Icon(Icons.delete_outline_rounded, color: Colors.red),
        onPressed: () => _confirmDelete(product),
        tooltip: 'Delete Product',
        padding: const EdgeInsets.all(16),
      ),
    );
  }

  void _confirmDelete(AdminProductModel product) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Product'),
        content: Text('Are you sure you want to delete "${product.name}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(context);
              try {
                await ref
                    .read(adminProductViewModelProvider.notifier)
                    .deleteProduct(product.id!);
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Product deleted successfully')),
                  );
                }
              } catch (e) {
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
                  );
                }
              }
            },
            child: const Text('Delete', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }
}
