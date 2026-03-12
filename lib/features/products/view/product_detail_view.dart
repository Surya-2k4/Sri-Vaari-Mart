import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../auth/view/login_view.dart';
import '../../cart/view/cart_view.dart';
import '../../cart/viewmodel/cart_viewmodel.dart';
import '../viewmodel/product_detail_viewmodel.dart';
import '../../profile/viewmodel/wishlist_viewmodel.dart';
import '../../../core/utils/responsive.dart';


class ProductDetailView extends ConsumerStatefulWidget {
  final String productId;

  const ProductDetailView({super.key, required this.productId});

  @override
  ConsumerState<ProductDetailView> createState() => _ProductDetailViewState();
}

class _ProductDetailViewState extends ConsumerState<ProductDetailView> {
  int _currentPage = 0;
  late final PageController _pageController;
  Timer? _timer; // Corrected from java.util.Timer to dart:async.Timer

  @override
  void initState() {
    super.initState();
    _pageController = PageController(initialPage: 0);

    Future.microtask(() {
      ref
          .read(productDetailViewModelProvider.notifier)
          .loadProduct(widget.productId);
    });
  }

  void _startAutoScroll(int count) {
    if (count <= 1) return;
    _timer = Timer.periodic(const Duration(seconds: 3), (timer) {
      if (_currentPage < count - 1) {
        _currentPage++;
      } else {
        _currentPage = 0;
      }
      if (_pageController.hasClients) {
        _pageController.animateToPage(
          _currentPage,
          duration: const Duration(milliseconds: 800),
          curve: Curves.easeInOutQuart,
        );
      }
    });
  }

  @override
  void dispose() {
    _pageController.dispose();
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(productDetailViewModelProvider);

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text('Product Details'),
        backgroundColor: Colors.white,
        elevation: 0,
        foregroundColor: Colors.black,
        leading: IconButton(
          onPressed: () => Navigator.pop(context),
          icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 20),
        ),
        actions: [
          Consumer(
            builder: (context, ref, _) {
              final isWishlisted =
                  ref.watch(wishlistProvider).contains(widget.productId);
              return IconButton(
                icon: Icon(
                  isWishlisted ? Icons.favorite : Icons.favorite_border,
                  color: isWishlisted ? Colors.red : Colors.black,
                ),
                onPressed: () {
                  ref
                      .read(wishlistProvider.notifier)
                      .toggleWishlist(widget.productId);
                },
              );
            },
          ),
          const SizedBox(width: 8),
        ],
      ),

      body: state.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text(e.toString())),
        data: (product) {
          final theme = Theme.of(context);

          // Start timer only once when data is loaded
          if (_timer == null && product.images.length > 1) {
            // Changed condition to check _timer == null
            // We use a small delay to avoid starting during build
            Future.delayed(Duration.zero, () {
              if (mounted && _timer == null) {
                _startAutoScroll(product.images.length);
              }
            });
          }

          return Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 1200),
              child: SingleChildScrollView(
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Responsive(
                    mobile: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildImageGallery(product),
                        const SizedBox(height: 24),
                        _buildProductDetails(context, product, theme),
                        const SizedBox(height: 48),
                        _buildAddToCartButton(
                          context,
                          product,
                          theme,
                          ref,
                          mounted,
                        ),
                        const SizedBox(height: 24),
                      ],
                    ),
                    desktop: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(flex: 3, child: _buildImageGallery(product)),
                        const SizedBox(width: 48),
                        Expanded(
                          flex: 2,
                          child: SingleChildScrollView(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                _buildProductDetails(context, product, theme),
                                const SizedBox(height: 48),
                                _buildAddToCartButton(
                                  context,
                                  product,
                                  theme,
                                  ref,
                                  mounted,
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildImageGallery(dynamic product) {
    return Stack(
      children: [
        Container(
          height: 500,
          width: double.infinity,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(32),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.12),
                blurRadius: 40,
                offset: const Offset(0, 20),
              ),
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(32),
            child: PageView.builder(
              controller: _pageController,
              itemCount: product.images.length,
              onPageChanged: (index) {
                setState(() => _currentPage = index);
              },
              itemBuilder: (context, index) {
                return Image.network(
                  product.images[index],
                  fit: BoxFit.cover,
                  loadingBuilder: (context, child, loadingProgress) {
                    if (loadingProgress == null) return child;
                    return Container(
                      color: Colors.grey.shade50,
                      child: const Center(
                        child: CircularProgressIndicator(strokeWidth: 2),
                      ),
                    );
                  },
                  errorBuilder: (_, __, ___) => Container(
                    color: Colors.grey.shade100,
                    child: const Icon(
                      Icons.image_not_supported_outlined,
                      size: 50,
                      color: Colors.grey,
                    ),
                  ),
                );
              },
            ),
          ),
        ),
        Positioned(
          bottom: 30,
          left: 0,
          right: 0,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: List.generate(
              product.images.length,
              (index) => AnimatedContainer(
                duration: const Duration(milliseconds: 400),
                margin: const EdgeInsets.symmetric(horizontal: 5),
                width: index == _currentPage ? 28 : 10,
                height: 10,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(6),
                  color: index == _currentPage
                      ? Colors.white
                      : Colors.white.withValues(alpha: 0.4),
                  boxShadow: [
                    if (index == _currentPage)
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.2),
                        blurRadius: 10,
                      ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildProductDetails(
    BuildContext context,
    dynamic product,
    ThemeData theme,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Expanded(
              child: Text(
                product.name,
                style: theme.textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            Text(
              '₹${product.price.toStringAsFixed(0)}',
              style: theme.textTheme.headlineSmall?.copyWith(
                color: theme.colorScheme.secondary,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
        const SizedBox(height: 24),
        Text(
          'About this item',
          style: theme.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.bold,
            color: theme.colorScheme.primary,
          ),
        ),
        const SizedBox(height: 12),
        Text(
          product.description,
          style: theme.textTheme.bodyLarge?.copyWith(
            height: 1.5,
            color: theme.colorScheme.onSurface.withValues(alpha: 0.8),
          ),
        ),
        const SizedBox(height: 24),
        if (product.highlights.isNotEmpty) ...[
          Text(
            'Key Features',
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.bold,
              color: theme.colorScheme.primary,
            ),
          ),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: theme.colorScheme.primary.withValues(alpha: 0.05),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: theme.colorScheme.primary.withValues(alpha: 0.1),
              ),
            ),
            child: Text(
              product.highlights,
              style: theme.textTheme.bodyMedium?.copyWith(height: 1.4),
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildAddToCartButton(
    BuildContext context,
    dynamic product,
    ThemeData theme,
    WidgetRef ref,
    bool mounted,
  ) {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        style: ElevatedButton.styleFrom(
          padding: const EdgeInsets.symmetric(vertical: 20),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
        ),
        onPressed: () async {
          final added = await ref
              .read(productDetailViewModelProvider.notifier)
              .addToCart(product.id);

          if (!mounted) return;

          if (!added) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Please sign in to add items to your cart.'),
                behavior: SnackBarBehavior.floating,
              ),
            );
            Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const LoginView()),
            );
            return;
          }

          await ref.read(cartViewModelProvider.notifier).loadCart();
          if (!mounted) return;

          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: const Text('Added to cart!'),
              backgroundColor: theme.colorScheme.secondary,
              behavior: SnackBarBehavior.floating,
              action: SnackBarAction(
                label: 'VIEW CART',
                textColor: Colors.white,
                onPressed: () => Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const CartView()),
                ),
              ),
            ),
          );
        },
        child: const Text('ADD TO CART'),
      ),
    );
  }
}
