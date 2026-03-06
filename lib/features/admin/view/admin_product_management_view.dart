import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../home/viewmodel/category_viewmodel.dart';
import '../../home/model/category_model.dart';
import '../model/admin_product_model.dart';
import '../viewmodel/admin_product_viewmodel.dart';

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

    return Column(
      children: [
        // Category Filter
        Padding(
          padding: const EdgeInsets.all(16),
          child: categoriesState.when(
            loading: () => const CircularProgressIndicator(),
            error: (e, _) => Text('Error: $e'),
            data: (categories) {
              // Get unique category types to avoid duplicates
              final uniqueCategories = <String, CategoryModel>{};
              for (var cat in categories) {
                if (!uniqueCategories.containsKey(cat.type)) {
                  uniqueCategories[cat.type] = cat;
                }
              }
              final categoryList = uniqueCategories.values.toList();

              // Validate selected category still exists
              if (_selectedCategory != null &&
                  !uniqueCategories.containsKey(_selectedCategory)) {
                WidgetsBinding.instance.addPostFrameCallback((_) {
                  if (mounted) {
                    setState(() => _selectedCategory = null);
                  }
                });
              }

              return DropdownButtonFormField<String>(
                value: _selectedCategory,
                decoration: const InputDecoration(
                  labelText: 'Filter by Category',
                  border: OutlineInputBorder(),
                ),
                items: [
                  const DropdownMenuItem(
                    value: null,
                    child: Text('All Categories'),
                  ),
                  ...categoryList.map(
                    (cat) => DropdownMenuItem(
                      value: cat.type,
                      child: Text(cat.name),
                    ),
                  ),
                ],
                onChanged: (value) {
                  setState(() {
                    _selectedCategory = value;
                  });
                },
              );
            },
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
                padding: const EdgeInsets.all(16),
                itemCount: filteredProducts.length,
                itemBuilder: (context, index) {
                  final product = filteredProducts[index];
                  return Card(
                    margin: const EdgeInsets.only(bottom: 12),
                    child: ListTile(
                      leading: product.imageUrl.isNotEmpty
                          ? Image.network(
                              product.imageUrl,
                              width: 50,
                              height: 50,
                              fit: BoxFit.cover,
                              errorBuilder: (_, __, ___) =>
                                  const Icon(Icons.image_not_supported),
                            )
                          : const Icon(Icons.shopping_bag),
                      title: Text(product.name),
                      subtitle: Text(
                        '₹${product.price.toStringAsFixed(0)} • ${product.type}',
                      ),
                      trailing: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          IconButton(
                            icon: const Icon(Icons.edit, color: Colors.blue),
                            onPressed: () => _showEditDialog(product),
                          ),
                          IconButton(
                            icon: const Icon(Icons.delete, color: Colors.red),
                            onPressed: () => _confirmDelete(product),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              );
            },
          ),
        ),
      ],
    );
  }

  void _showEditDialog(AdminProductModel product) {
    showDialog(
      context: context,
      builder: (context) => ProductFormDialog(
        product: product,
        categories: ref.read(categoryViewModelProvider).value ?? [],
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
              final navigator = Navigator.of(context);
              final scaffoldMessenger = ScaffoldMessenger.of(context);

              navigator.pop();

              try {
                await ref
                    .read(adminProductViewModelProvider.notifier)
                    .deleteProduct(product.id!);

                if (mounted) {
                  scaffoldMessenger.showSnackBar(
                    const SnackBar(
                      content: Text('Product deleted successfully'),
                      backgroundColor: Colors.green,
                    ),
                  );
                }
              } catch (e) {
                if (mounted) {
                  String errorMessage = 'Error deleting product';

                  if (e.toString().contains('foreign key constraint')) {
                    errorMessage =
                        'Product removed from all carts and deleted successfully';
                  } else if (e.toString().contains('row-level security')) {
                    errorMessage =
                        'Permission denied. Check database RLS policies.';
                  } else {
                    errorMessage = 'Error: ${e.toString().split('\n').first}';
                  }

                  scaffoldMessenger.showSnackBar(
                    SnackBar(
                      content: Text(errorMessage),
                      backgroundColor: e.toString().contains('foreign key')
                          ? Colors.green
                          : Colors.red,
                      duration: const Duration(seconds: 4),
                    ),
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

class ProductFormDialog extends ConsumerStatefulWidget {
  final AdminProductModel? product;
  final List<CategoryModel> categories;

  const ProductFormDialog({super.key, this.product, required this.categories});

  @override
  ConsumerState<ProductFormDialog> createState() => _ProductFormDialogState();
}

class _ProductFormDialogState extends ConsumerState<ProductFormDialog> {
  late TextEditingController _nameController;
  late TextEditingController _priceController;
  late TextEditingController _imageUrlController;
  late TextEditingController _descriptionController;
  late TextEditingController _highlightsController;
  String? _selectedType;
  final _formKey = GlobalKey<FormState>();

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.product?.name ?? '');
    _priceController = TextEditingController(
      text: widget.product?.price.toString() ?? '',
    );
    _imageUrlController = TextEditingController(
      text: widget.product?.imageUrl ?? '',
    );
    _descriptionController = TextEditingController(
      text: widget.product?.description ?? '',
    );
    _highlightsController = TextEditingController(
      text: widget.product?.highlights ?? '',
    );
    _selectedType = widget.product?.type;
  }

  @override
  void dispose() {
    _nameController.dispose();
    _priceController.dispose();
    _imageUrlController.dispose();
    _descriptionController.dispose();
    _highlightsController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Get unique category types to avoid duplicates
    final uniqueCategories = <String, CategoryModel>{};
    for (var cat in widget.categories) {
      if (!uniqueCategories.containsKey(cat.type)) {
        uniqueCategories[cat.type] = cat;
      }
    }
    final categoryList = uniqueCategories.values.toList();

    // Validate that _selectedType exists in the category list
    if (_selectedType != null && !uniqueCategories.containsKey(_selectedType)) {
      _selectedType = null;
    }

    return AlertDialog(
      title: Text(widget.product == null ? 'Add Product' : 'Edit Product'),
      content: SingleChildScrollView(
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextFormField(
                controller: _nameController,
                decoration: const InputDecoration(labelText: 'Product Name'),
                validator: (v) => v?.isEmpty ?? true ? 'Required' : null,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _priceController,
                decoration: const InputDecoration(labelText: 'Price'),
                keyboardType: TextInputType.number,
                validator: (v) => v?.isEmpty ?? true ? 'Required' : null,
              ),
              const SizedBox(height: 12),
              DropdownButtonFormField<String>(
                value: _selectedType,
                decoration: const InputDecoration(labelText: 'Category'),
                items: categoryList
                    .map<DropdownMenuItem<String>>(
                      (cat) => DropdownMenuItem<String>(
                        value: cat.type,
                        child: Text(cat.name),
                      ),
                    )
                    .toList(),
                onChanged: (value) => setState(() => _selectedType = value),
                validator: (v) => v == null ? 'Required' : null,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _imageUrlController,
                decoration: const InputDecoration(labelText: 'Image URL'),
                validator: (v) => v?.isEmpty ?? true ? 'Required' : null,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _descriptionController,
                decoration: const InputDecoration(labelText: 'Description'),
                maxLines: 3,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _highlightsController,
                decoration: const InputDecoration(labelText: 'Highlights'),
                maxLines: 2,
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        TextButton(onPressed: _saveProduct, child: const Text('Save')),
      ],
    );
  }

  void _saveProduct() async {
    if (!_formKey.currentState!.validate()) return;

    final product = AdminProductModel(
      id: widget.product?.id,
      name: _nameController.text.trim(),
      price: double.parse(_priceController.text.trim()),
      type: _selectedType!,
      imageUrl: _imageUrlController.text.trim(),
      description: _descriptionController.text.trim(),
      highlights: _highlightsController.text.trim(),
    );

    try {
      if (widget.product == null) {
        await ref
            .read(adminProductViewModelProvider.notifier)
            .addProduct(product);
      } else {
        await ref
            .read(adminProductViewModelProvider.notifier)
            .updateProduct(product);
      }

      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              widget.product == null
                  ? 'Product added successfully'
                  : 'Product updated successfully',
            ),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        String errorMessage = 'Error: $e';

        if (e.toString().contains('row-level security')) {
          errorMessage =
              'Database Permission Error!\n\n'
              'The database needs RLS policies configured.\n'
              'Please check DATABASE_SETUP_GUIDE.md for instructions.';
        }

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(errorMessage),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 6),
          ),
        );
      }
    }
  }
}
