import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:vaari/features/orders/view/checkout_view.dart';

import '../viewmodel/cart_viewmodel.dart';
import '../../../core/utils/responsive.dart';
import 'package:vaari/features/navigation/navigation_provider.dart';

class CartView extends ConsumerWidget {
  const CartView({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final cartState = ref.watch(cartViewModelProvider);
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Scaffold(
      appBar: AppBar(title: const Text('Shopping Cart'), centerTitle: true),
      body: cartState.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.error_outline, size: 64, color: colorScheme.error),
              const SizedBox(height: 16),
              Text('Something went wrong', style: theme.textTheme.titleMedium),
              TextButton(
                onPressed: () =>
                    ref.read(cartViewModelProvider.notifier).loadCart(),
                child: const Text('Try Again'),
              ),
            ],
          ),
        ),
        data: (items) {
          if (items.isEmpty) {
            return _buildEmptyCart(context, ref, theme, colorScheme);
          }

          final total = ref
              .read(cartViewModelProvider.notifier)
              .totalAmount(items);

          return Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 1200),
              child: Responsive(
                mobile: Column(
                  children: [
                    Expanded(
                      child: _buildCartList(ref, items, colorScheme, theme),
                    ),
                    _buildCheckoutSummary(
                      context,
                      total,
                      theme,
                      colorScheme,
                      true,
                    ),
                  ],
                ),
                desktop: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      flex: 3,
                      child: _buildCartList(ref, items, colorScheme, theme),
                    ),
                    const SizedBox(width: 32),
                    Expanded(
                      flex: 2,
                      child: Padding(
                        padding: const EdgeInsets.only(top: 16),
                        child: _buildCheckoutSummary(
                          context,
                          total,
                          theme,
                          colorScheme,
                          false,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildEmptyCart(
    BuildContext context,
    WidgetRef ref,
    ThemeData theme,
    ColorScheme colorScheme,
  ) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.shopping_cart_outlined,
            size: 80,
            color: colorScheme.primary.withValues(alpha: 0.2),
          ),
          const SizedBox(height: 24),
          Text(
            'Your cart is empty',
            style: theme.textTheme.headlineSmall?.copyWith(
              color: colorScheme.onSurface.withValues(alpha: 0.5),
            ),
          ),
          const SizedBox(height: 32),
          SizedBox(
            width: 200, // Restricted button size
            child: ElevatedButton(
              onPressed: () {
                // Navigate to Home tab
                ref.read(navigationIndexProvider.notifier).state = 0;
              },
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: const Text('Start Shopping'),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCartList(
    WidgetRef ref,
    List<dynamic> items,
    ColorScheme colorScheme,
    ThemeData theme,
  ) {
    return RefreshIndicator(
      onRefresh: () => ref.read(cartViewModelProvider.notifier).loadCart(),
      color: colorScheme.primary,
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: items.length,
        itemBuilder: (context, index) {
          final item = items[index];
          return Card(
            margin: const EdgeInsets.only(bottom: 16),
            child: Padding(
              padding: const EdgeInsets.all(12.0),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Product Image
                  ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: Image.network(
                      item.imageUrl,
                      width: 90,
                      height: 90,
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => Container(
                        width: 90,
                        height: 90,
                        color: colorScheme.surfaceContainerHighest,
                        child: const Icon(Icons.shopping_bag_outlined),
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  // Info
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          item.name,
                          style: theme.textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '₹${item.price.toStringAsFixed(0)}',
                          style: theme.textTheme.titleMedium?.copyWith(
                            color: colorScheme.secondary,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 12),
                        // Quantity Controls
                        Row(
                          children: [
                            _QuantityButton(
                              icon: Icons.remove,
                              onPressed: item.quantity > 1
                                  ? () => ref
                                        .read(cartViewModelProvider.notifier)
                                        .updateQuantity(
                                          item.id,
                                          item.quantity - 1,
                                        )
                                  : null,
                            ),
                            Padding(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 16.0,
                              ),
                              child: Text(
                                item.quantity.toString(),
                                style: theme.textTheme.titleMedium?.copyWith(
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                            _QuantityButton(
                              icon: Icons.add,
                              onPressed: () => ref
                                  .read(cartViewModelProvider.notifier)
                                  .updateQuantity(item.id, item.quantity + 1),
                            ),
                            const Spacer(),
                            IconButton(
                              onPressed: () => ref
                                  .read(cartViewModelProvider.notifier)
                                  .removeItem(item.id),
                              icon: const Icon(Icons.delete_outline_rounded),
                              color: colorScheme.error,
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildCheckoutSummary(
    BuildContext context,
    double total,
    ThemeData theme,
    ColorScheme colorScheme,
    bool isBottom,
  ) {
    return Container(
      padding: EdgeInsets.fromLTRB(24, 24, 24, isBottom ? 40 : 24),
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: isBottom
            ? const BorderRadius.vertical(top: Radius.circular(30))
            : BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: Offset(0, isBottom ? -5 : 5),
          ),
        ],
        border: !isBottom
            ? Border.all(color: colorScheme.outlineVariant)
            : null,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Total Amount',
                style: theme.textTheme.bodyLarge?.copyWith(
                  color: colorScheme.onSurface.withValues(alpha: 0.6),
                ),
              ),
              Text(
                '₹${total.toStringAsFixed(0)}',
                style: theme.textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: colorScheme.primary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          ElevatedButton(
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const CheckoutView()),
              );
            },
            child: const Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.check_circle_outline),
                SizedBox(width: 8),
                Text('CHECKOUT'),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _QuantityButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback? onPressed;

  const _QuantityButton({required this.icon, this.onPressed});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey.withValues(alpha: 0.3)),
        borderRadius: BorderRadius.circular(8),
      ),
      child: IconButton(
        icon: Icon(icon, size: 18),
        onPressed: onPressed,
        constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
        padding: EdgeInsets.zero,
      ),
    );
  }
}
