import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:vaari/features/orders/view/checkout_view.dart';
import '../viewmodel/cart_viewmodel.dart';

class CartView extends ConsumerWidget {
  const CartView({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final cartState = ref.watch(cartViewModelProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('My Cart'), centerTitle: true),
      body: cartState.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text(e.toString())),
        data: (items) {
          if (items.isEmpty) {
            return const Center(child: Text('Your cart is empty'));
          }

          final total = ref
              .read(cartViewModelProvider.notifier)
              .totalAmount(items);

          return Column(
            children: [
              Expanded(
                child: ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: items.length,
                  itemBuilder: (context, index) {
                    final item = items[index];

                    return Card(
                      margin: const EdgeInsets.only(bottom: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: ListTile(
                        contentPadding: const EdgeInsets.all(12),
                        leading: ClipRRect(
                          borderRadius: BorderRadius.circular(8),
                          child: Image.network(
                            item.imageUrl,
                            width: 64,
                            height: 64,
                            fit: BoxFit.cover,
                            errorBuilder: (_, __, ___) => Container(
                              width: 64,
                              height: 64,
                              color: Colors.grey.shade200,
                              alignment: Alignment.center,
                              child: const Icon(Icons.image_not_supported),
                            ),
                          ),
                        ),
                        title: Text(item.name),
                        subtitle: Text(
                          '₹${item.price.toStringAsFixed(0)} x ${item.quantity}',
                        ),
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            IconButton(
                              icon: const Icon(Icons.remove),
                              onPressed: item.quantity > 1
                                  ? () {
                                      ref
                                          .read(cartViewModelProvider.notifier)
                                          .updateQuantity(
                                            item.id,
                                            item.quantity - 1,
                                          );
                                    }
                                  : null,
                            ),
                            IconButton(
                              icon: const Icon(Icons.add),
                              onPressed: () {
                                ref
                                    .read(cartViewModelProvider.notifier)
                                    .updateQuantity(item.id, item.quantity + 1);
                              },
                            ),
                            IconButton(
                              icon: const Icon(Icons.delete),
                              onPressed: () {
                                ref
                                    .read(cartViewModelProvider.notifier)
                                    .removeItem(item.id);
                              },
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.surface,
                  boxShadow: const [
                    BoxShadow(
                      blurRadius: 4,
                      offset: Offset(0, -2),
                      color: Colors.black12,
                    ),
                  ],
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Total: ₹${total.toStringAsFixed(0)}',
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    ElevatedButton(
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => const CheckoutView(),
                          ),
                        );
                      },
                      child: const Text('Checkout'),
                    ),
                  ],
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}
