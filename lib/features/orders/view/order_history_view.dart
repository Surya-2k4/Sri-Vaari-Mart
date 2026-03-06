import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../viewmodel/order_history_viewmodel.dart';
import '../../../core/services/customer_receipt_service.dart';

class OrderHistoryView extends ConsumerWidget {
  const OrderHistoryView({super.key});

  String _formatDate(DateTime date) {
    final months = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec',
    ];
    return '${date.day} ${months[date.month - 1]} ${date.year}';
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final orderState = ref.watch(orderHistoryViewModelProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('My Orders'), centerTitle: true),
      body: orderState.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text(e.toString())),
        data: (orders) {
          if (orders.isEmpty) {
            return const Center(child: Text('No orders yet'));
          }

          return ListView.separated(
            padding: const EdgeInsets.all(16),
            itemCount: orders.length,
            separatorBuilder: (_, __) => const SizedBox(height: 12),
            itemBuilder: (context, index) {
              final order = orders[index];

              return Card(
                elevation: 1,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'Order #${order.id.substring(0, 8)}',
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 6,
                            ),
                            decoration: BoxDecoration(
                              color: _getStatusColor(
                                order.status,
                              ).withOpacity(0.1),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Text(
                              order.status.toUpperCase(),
                              style: TextStyle(
                                color: _getStatusColor(order.status),
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Text(
                        'Total: ₹${order.totalAmount.toStringAsFixed(0)}',
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Payment: ${order.paymentMethod}',
                        style: TextStyle(color: Colors.grey[600], fontSize: 14),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Phone: ${order.phoneNumber}',
                        style: TextStyle(color: Colors.grey[600], fontSize: 14),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Address: ${order.shippingAddress}',
                        style: TextStyle(color: Colors.grey[600], fontSize: 14),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Date: ${_formatDate(order.createdAt)}',
                        style: TextStyle(color: Colors.grey[600], fontSize: 14),
                      ),
                      if (order.items.isNotEmpty) ...[
                        const Divider(height: 24),
                        const Text(
                          'Items:',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 14,
                          ),
                        ),
                        const SizedBox(height: 8),
                        ...order.items.map(
                          (item) => Padding(
                            padding: const EdgeInsets.only(bottom: 4),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Expanded(
                                  child: Text(
                                    '${item.quantity}x ${item.productName}',
                                    style: const TextStyle(fontSize: 13),
                                  ),
                                ),
                                Text(
                                  '₹${(item.price * item.quantity).toStringAsFixed(0)}',
                                  style: const TextStyle(fontSize: 13),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                      if (order.status.toLowerCase() == 'delivered') ...[
                        const Divider(height: 24),
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton.icon(
                            onPressed: () async {
                              try {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content: Text('Generating receipt...'),
                                  ),
                                );
                                await CustomerReceiptService().generateReceipt(
                                  order,
                                );
                                if (context.mounted) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(
                                      content: Text(
                                        'Receipt generated successfully!',
                                      ),
                                      backgroundColor: Colors.green,
                                    ),
                                  );
                                }
                              } catch (e) {
                                if (context.mounted) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                      content: Text(
                                        'Error generating receipt: $e',
                                      ),
                                      backgroundColor: Colors.red,
                                    ),
                                  );
                                }
                              }
                            },
                            icon: const Icon(Icons.download),
                            label: const Text('Download Receipt'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.orange,
                              foregroundColor: Colors.white,
                            ),
                          ),
                        ),
                      ],
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

  Color _getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'pending':
        return Colors.orange;
      case 'paid':
        return Colors.blue;
      case 'processing':
        return Colors.purple;
      case 'shipped':
        return Colors.teal;
      case 'delivered':
        return Colors.green;
      case 'cancelled':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }
}
