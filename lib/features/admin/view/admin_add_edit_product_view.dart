import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../home/model/category_model.dart';
import '../model/admin_product_model.dart';
import '../viewmodel/admin_product_viewmodel.dart';
import 'dart:io';
import 'package:image_picker/image_picker.dart';
import '../../../core/services/cloudinary_service.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/utils/toast_utils.dart';
import '../../../core/utils/category_icon_mapper.dart';

class AdminAddEditProductView extends ConsumerStatefulWidget {
  final AdminProductModel? product;
  final List<CategoryModel> categories;

  const AdminAddEditProductView({
    super.key,
    this.product,
    required this.categories,
  });

  @override
  ConsumerState<AdminAddEditProductView> createState() =>
      _AdminAddEditProductViewState();
}

class _AdminAddEditProductViewState
    extends ConsumerState<AdminAddEditProductView> {
  late TextEditingController _nameController;
  late TextEditingController _priceController;
  late TextEditingController _imageUrlController;
  late TextEditingController _descriptionController;
  late TextEditingController _highlightsController;
  String? _selectedType;
  final _formKey = GlobalKey<FormState>();

  // Multiple image support
  final List<File?> _imageFiles = [null, null, null]; // Max 3 slots
  final List<String> _remoteUrls = ['', '', '']; // URLs for each slot

  final ImagePicker _picker = ImagePicker();
  bool _isUploading = false;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.product?.name ?? '');
    _priceController = TextEditingController(
      text: widget.product?.price.toString() ?? '',
    );
    _imageUrlController =
        TextEditingController(); // No longer used for single URL

    // Initialize image lists from product
    if (widget.product != null) {
      for (int i = 0; i < widget.product!.imageUrls.length && i < 3; i++) {
        _remoteUrls[i] = widget.product!.imageUrls[i];
      }
    }

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
    // Get unique category types
    final uniqueCategories = <String, CategoryModel>{};
    for (var cat in widget.categories) {
      if (!uniqueCategories.containsKey(cat.type)) {
        uniqueCategories[cat.type] = cat;
      }
    }
    final categoryList = uniqueCategories.values.toList();

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: Text(
          widget.product == null ? 'Add New Product' : 'Edit Product',
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
        elevation: 0,
        backgroundColor: Colors.white,
        foregroundColor: AppColors.primaryBlack,
      ),
      body: SingleChildScrollView(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 600),
            child: Padding(
              padding: const EdgeInsets.all(24.0),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildSectionHeader('Basic Information'),
                    const SizedBox(height: 16),
                    _buildTextField(
                      controller: _nameController,
                      label: 'Product Name',
                      hint: 'Enter product name',
                      icon: Icons.shopping_bag_outlined,
                    ),
                    const SizedBox(height: 16),
                    _buildTextField(
                      controller: _priceController,
                      label: 'Price (₹)',
                      hint: '0.00',
                      icon: Icons.currency_rupee_rounded,
                      keyboardType: TextInputType.number,
                    ),
                    const SizedBox(height: 16),
                    _buildDropdown(categoryList),
                    const SizedBox(height: 32),
                    _buildSectionHeader('Visuals (Max 3)'),
                    const SizedBox(height: 16),
                    Row(
                      children: List.generate(
                        3,
                        (index) => Expanded(
                          child: Padding(
                            padding: EdgeInsets.only(right: index < 2 ? 12 : 0),
                            child: _buildImageUploadSlot(index),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 32),
                    const SizedBox(height: 32),
                    _buildSectionHeader('Product Details'),
                    const SizedBox(height: 16),
                    _buildTextField(
                      controller: _descriptionController,
                      label: 'Description',
                      hint: 'Keep it short and catchy',
                      icon: Icons.description_outlined,
                      maxLines: 4,
                    ),
                    const SizedBox(height: 16),
                    _buildTextField(
                      controller: _highlightsController,
                      label: 'Highlights',
                      hint: 'Feature 1, Feature 2, etc.',
                      icon: Icons.star_outline_rounded,
                      maxLines: 2,
                    ),
                    const SizedBox(height: 40),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: _isUploading ? null : _saveProduct,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primaryBlack,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 20),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                          elevation: 0,
                        ),
                        child: _isUploading
                            ? const SizedBox(
                                height: 20,
                                width: 20,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: Colors.white,
                                ),
                              )
                            : Text(
                                widget.product == null
                                    ? 'ADD PRODUCT'
                                    : 'UPDATE PRODUCT',
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  letterSpacing: 1.2,
                                ),
                              ),
                      ),
                    ),
                    const SizedBox(height: 50),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Text(
      title,
      style: TextStyle(
        fontSize: 14,
        fontWeight: FontWeight.bold,
        color: Colors.grey.shade400,
        letterSpacing: 1.1,
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required String hint,
    required IconData icon,
    int maxLines = 1,
    TextInputType? keyboardType,
    String? Function(String?)? validator,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade100),
      ),
      child: TextFormField(
        controller: controller,
        maxLines: maxLines,
        keyboardType: keyboardType,
        onChanged: (v) {
          if (label == 'Image URL') setState(() {});
        },
        decoration: InputDecoration(
          labelText: label,
          hintText: hint,
          prefixIcon: Icon(icon, color: AppColors.primaryBlack, size: 20),
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 20,
            vertical: 16,
          ),
        ),
        validator:
            validator ?? (v) => v?.trim().isEmpty ?? true ? 'Required' : null,
      ),
    );
  }

  Widget _buildDropdown(List<CategoryModel> categoryList) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade100),
      ),
      child: DropdownButtonFormField<String>(
        value: _selectedType,
        decoration: const InputDecoration(
          labelText: 'Category',
          prefixIcon: Icon(
            Icons.category_outlined,
            color: AppColors.primaryBlack,
            size: 20,
          ),
          border: InputBorder.none,
          contentPadding: EdgeInsets.symmetric(horizontal: 20, vertical: 12),
        ),
        items: categoryList
            .map<DropdownMenuItem<String>>(
              (cat) => DropdownMenuItem<String>(
                value: cat.type,
                child: Row(
                  children: [
                    Icon(
                      getCategoryIcon(cat.icon),
                      color: AppColors.primaryBlack,
                      size: 20,
                    ),
                    const SizedBox(width: 12),
                    Text(
                      cat.name,
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
            )
            .toList(),
        selectedItemBuilder: (context) {
          return categoryList.map((cat) {
            return Row(
              children: [
                Icon(
                  getCategoryIcon(cat.icon),
                  color: AppColors.primaryBlack,
                  size: 20,
                ),
                const SizedBox(width: 12),
                Text(cat.name),
              ],
            );
          }).toList();
        },
        onChanged: (value) => setState(() => _selectedType = value),
        validator: (v) => v == null ? 'Required' : null,
      ),
    );
  }

  Widget _buildImageUploadSlot(int index) {
    final bool hasImage =
        _imageFiles[index] != null || _remoteUrls[index].isNotEmpty;

    return Column(
      children: [
        GestureDetector(
          onTap: () => _showImageSourcePicker(index),
          child: Container(
            height: 120,
            decoration: BoxDecoration(
              color: Colors.grey.shade50,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: Colors.grey.shade100, width: 2),
              boxShadow: [
                if (hasImage)
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
              ],
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(18),
              child: hasImage
                  ? Stack(
                      fit: StackFit.expand,
                      children: [
                        _imageFiles[index] != null
                            ? Image.file(_imageFiles[index]!, fit: BoxFit.cover)
                            : Image.network(
                                _remoteUrls[index],
                                fit: BoxFit.cover,
                              ),
                        Positioned(
                          top: 4,
                          right: 4,
                          child: GestureDetector(
                            onTap: () => setState(() {
                              _imageFiles[index] = null;
                              _remoteUrls[index] = '';
                            }),
                            child: Container(
                              padding: const EdgeInsets.all(4),
                              decoration: const BoxDecoration(
                                color: Colors.white,
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(
                                Icons.close_rounded,
                                size: 14,
                                color: Colors.red,
                              ),
                            ),
                          ),
                        ),
                      ],
                    )
                  : Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.add_photo_alternate_outlined,
                          color: Colors.grey.shade400,
                          size: 32,
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Slot ${index + 1}',
                          style: TextStyle(
                            color: Colors.grey.shade400,
                            fontSize: 10,
                          ),
                        ),
                      ],
                    ),
            ),
          ),
        ),
      ],
    );
  }

  void _showImageSourcePicker(int index) {
    showModalBottomSheet(
      context: context,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      builder: (context) => Container(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              'Select Image Source',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
            ),
            const SizedBox(height: 24),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _buildPickerOption(
                  icon: Icons.photo_library_outlined,
                  label: 'Gallery',
                  onTap: () {
                    Navigator.pop(context);
                    _pickImage(ImageSource.gallery, index);
                  },
                ),
                _buildPickerOption(
                  icon: Icons.camera_alt_outlined,
                  label: 'Camera',
                  onTap: () {
                    Navigator.pop(context);
                    _pickImage(ImageSource.camera, index);
                  },
                ),
                _buildPickerOption(
                  icon: Icons.link_rounded,
                  label: 'URL',
                  onTap: () {
                    Navigator.pop(context);
                    _showUrlInputDialog(index);
                  },
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPickerOption({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.grey.shade50,
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: AppColors.primaryBlack),
          ),
          const SizedBox(height: 8),
          Text(label, style: const TextStyle(fontWeight: FontWeight.w500)),
        ],
      ),
    );
  }

  Future<void> _pickImage(ImageSource source, int index) async {
    final XFile? pickedFile = await _picker.pickImage(source: source);
    if (pickedFile != null) {
      setState(() {
        _imageFiles[index] = File(pickedFile.path);
        _remoteUrls[index] = '';
      });
    }
  }

  void _showUrlInputDialog(int index) {
    final controller = TextEditingController(text: _remoteUrls[index]);
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Paste Image URL'),
        content: TextField(
          controller: controller,
          decoration: const InputDecoration(
            hintText: 'https://example.com/image.jpg',
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              if (controller.text.trim().isNotEmpty) {
                setState(() {
                  _remoteUrls[index] = controller.text.trim();
                  _imageFiles[index] = null;
                });
                Navigator.pop(context);
              }
            },
            child: const Text('Add'),
          ),
        ],
      ),
    );
  }

  void _saveProduct() async {
    if (!_formKey.currentState!.validate()) return;

    // Check if at least one image is provided
    bool hasAnyImage =
        _imageFiles.any((f) => f != null) ||
        _remoteUrls.any((url) => url.isNotEmpty);
    if (!hasAnyImage) {
      ToastUtils.showError(context, 'Please provide at least one image');
      return;
    }

    setState(() => _isUploading = true);

    final List<String> finalUrls = [];

    try {
      for (int i = 0; i < 3; i++) {
        if (_imageFiles[i] != null) {
          // Upload local file to Cloudinary
          final uploadedUrl = await CloudinaryService.uploadImage(
            _imageFiles[i]!,
          );
          if (uploadedUrl == null) {
            throw Exception('Upload failed for image ${i + 1}');
          }
          finalUrls.add(uploadedUrl);
        } else if (_remoteUrls[i].isNotEmpty) {
          // Use existing remote URL
          finalUrls.add(_remoteUrls[i]);
        }
      }

      final product = AdminProductModel(
        id: widget.product?.id,
        name: _nameController.text.trim(),
        price: double.parse(_priceController.text.trim()),
        type: _selectedType!,
        imageUrls: finalUrls,
        description: _descriptionController.text.trim(),
        highlights: _highlightsController.text.trim(),
      );

      if (widget.product == null) {
        await ref
            .read(adminProductViewModelProvider.notifier)
            .addProduct(product);
        if (mounted) {
          ToastUtils.showSuccess(context, 'New product added successfully!');
          Navigator.pop(context);
        }
      } else {
        await ref
            .read(adminProductViewModelProvider.notifier)
            .updateProduct(product);
        if (mounted) {
          ToastUtils.showSuccess(context, 'Product details updated!');
          Navigator.pop(context);
        }
      }
    } catch (e) {
      if (mounted) {
        ToastUtils.showError(context, 'Saving failed: $e');
      }
    } finally {
      if (mounted) setState(() => _isUploading = false);
    }
  }
}
