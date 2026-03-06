import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../auth/view/login_view.dart';
import '../../cart/view/cart_view.dart';
import '../../cart/viewmodel/cart_viewmodel.dart';
import '../viewmodel/product_detail_viewmodel.dart';

class ProductDetailView extends ConsumerStatefulWidget {
  final String productId;

  const ProductDetailView({super.key, required this.productId});

  @override
  ConsumerState<ProductDetailView> createState() => _ProductDetailViewState();
}

class _ProductDetailViewState extends ConsumerState<ProductDetailView> {
  @override
  void initState() {
    super.initState();
    Future.microtask(() {
      ref
          .read(productDetailViewModelProvider.notifier)
          .loadProduct(widget.productId);
    });
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(productDetailViewModelProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Product')),
      body: state.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text(e.toString())),
        data: (product) {
          return Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(16),
                  child: Image.network(
                    product.imageUrl,
                    height: 240,
                    width: double.infinity,
                    fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) => Container(
                      height: 240,
                      color: Colors.grey.shade200,
                      child: const Icon(Icons.image_not_supported, size: 48),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        product.name,
                        style: Theme.of(context).textTheme.headlineSmall,
                      ),
                      const SizedBox(height: 12),
                      Text(
                        '₹${product.price.toStringAsFixed(0)}',
                        style: Theme.of(context).textTheme.titleLarge,
                      ),
                      const Spacer(),
                      const SizedBox(height: 16),
                      Text(
                        'Description',
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                      const SizedBox(height: 6),
                      Text(
                        product.description,
                        style: Theme.of(context).textTheme.bodyMedium,
                      ),

                      const SizedBox(height: 16),
                      Text(
                        'Highlights',
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                      const SizedBox(height: 6),
                      Text(
                        product.highlights,
                        style: Theme.of(context).textTheme.bodyMedium,
                      ),
                      Text(
                        product.highlights,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                      const Spacer(),
                      const Spacer(),
                      const Spacer(),
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          onPressed: () async {
                            final added = await ref
                                .read(productDetailViewModelProvider.notifier)
                                .addToCart(product.id);

                            if (!mounted) {
                              return;
                            }

                            if (!added) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text(
                                    'Please sign in to add items to your cart.',
                                  ),
                                ),
                              );

                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => const LoginView(),
                                ),
                              );
                              return;
                            }

                            await ref
                                .read(cartViewModelProvider.notifier)
                                .loadCart();

                            if (!mounted) {
                              return;
                            }

                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text('Added to cart')),
                            );

                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => const CartView(),
                              ),
                            );
                          },
                          child: const Text('Add to Cart'),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
