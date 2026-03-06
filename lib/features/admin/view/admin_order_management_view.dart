import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../model/admin_order_model.dart';
import '../viewmodel/admin_order_viewmodel.dart';
import '../../../core/services/receipt_generator_service.dart';

class AdminOrderManagementView extends ConsumerStatefulWidget {
  const AdminOrderManagementView({super.key});

  @override
  ConsumerState<AdminOrderManagementView> createState() =>
      _AdminOrderManagementViewState();
}

class _AdminOrderManagementViewState
    extends ConsumerState<AdminOrderManagementView> {
  String? _statusFilter;

  @override
  Widget build(BuildContext context) {
    final ordersState = ref.watch(adminOrderViewModelProvider);

    return Column(
      children: [
        // Status Filter with Refresh Button
        Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Expanded(
                child: DropdownButtonFormField<String>(
                  value: _statusFilter,
                  decoration: const InputDecoration(
                    labelText: 'Filter by Status',
                    border: OutlineInputBorder(),
                  ),
                  items: const [
                    DropdownMenuItem(value: null, child: Text('All Orders')),
                    DropdownMenuItem(value: 'pending', child: Text('Pending')),
                    DropdownMenuItem(value: 'paid', child: Text('Paid')),
                    DropdownMenuItem(
                      value: 'processing',
                      child: Text('Processing'),
                    ),
                    DropdownMenuItem(value: 'shipped', child: Text('Shipped')),
                    DropdownMenuItem(
                      value: 'delivered',
                      child: Text('Delivered'),
                    ),
                    DropdownMenuItem(
                      value: 'cancelled',
                      child: Text('Cancelled'),
                    ),
                  ],
                  onChanged: (value) {
                    setState(() {
                      _statusFilter = value;
                    });
                  },
                ),
              ),
              const SizedBox(width: 8),
              IconButton(
                icon: const Icon(Icons.refresh),
                onPressed: () {
                  ref.invalidate(adminOrderViewModelProvider);
                },
                tooltip: 'Refresh Orders',
                style: IconButton.styleFrom(
                  backgroundColor: Colors.orange.withOpacity(0.1),
                ),
              ),
            ],
          ),
        ),
        // Orders List
        Expanded(
          child: ordersState.when(
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (e, _) => Center(child: Text('Error: $e')),
            data: (orders) {
              final filteredOrders = _statusFilter == null
                  ? orders
                  : orders.where((o) => o.status == _statusFilter).toList();

              if (filteredOrders.isEmpty) {
                return const Center(child: Text('No orders found'));
              }

              return ListView.builder(
                padding: const EdgeInsets.all(16),
                itemCount: filteredOrders.length,
                itemBuilder: (context, index) {
                  final order = filteredOrders[index];
                  return Card(
                    margin: const EdgeInsets.only(bottom: 16),
                    child: ExpansionTile(
                      leading: CircleAvatar(
                        backgroundColor: _getStatusColor(order.status),
                        child: Text(
                          order.items.length.toString(),
                          style: const TextStyle(color: Colors.white),
                        ),
                      ),
                      title: Text('Order #${order.id.substring(0, 8)}'),
                      subtitle: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const SizedBox(height: 4),
                          Text(
                            'Total: ₹${order.totalAmount.toStringAsFixed(0)}',
                          ),
                          Text('Payment: ${order.paymentMethod}'),
                          Text('Date: ${_formatDate(order.createdAt)}'),
                        ],
                      ),
                      trailing: Chip(
                        label: Text(
                          order.status.toUpperCase(),
                          style: const TextStyle(fontSize: 11),
                        ),
                        backgroundColor: _getStatusColor(order.status),
                      ),
                      children: [
                        Padding(
                          padding: const EdgeInsets.all(16),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Divider(),
                              const SizedBox(height: 8),
                              Text(
                                'Customer Details',
                                style: Theme.of(context).textTheme.titleSmall,
                              ),
                              const SizedBox(height: 8),
                              Text(
                                'User ID: ${order.userId.substring(0, 12)}...',
                              ),
                              Text('Phone: ${order.phoneNumber}'),
                              Text('Address: ${order.shippingAddress}'),
                              const SizedBox(height: 16),
                              Text(
                                'Order Items',
                                style: Theme.of(context).textTheme.titleSmall,
                              ),
                              const SizedBox(height: 8),
                              ...order.items.map(
                                (item) => Padding(
                                  padding: const EdgeInsets.only(bottom: 4),
                                  child: Row(
                                    mainAxisAlignment:
                                        MainAxisAlignment.spaceBetween,
                                    children: [
                                      Expanded(
                                        child: Text(
                                          '${item.quantity}x ${item.productName}',
                                        ),
                                      ),
                                      Text(
                                        '₹${(item.price * item.quantity).toStringAsFixed(0)}',
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                              const SizedBox(height: 16),
                              Row(
                                children: [
                                  Expanded(
                                    child: ElevatedButton(
                                      onPressed: () => _showStatusDialog(order),
                                      child: const Text('Update Status'),
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  if (order.status.toLowerCase() == 'delivered')
                                    IconButton(
                                      icon: const Icon(
                                        Icons.download,
                                        color: Colors.blue,
                                      ),
                                      onPressed: () => _downloadReceipt(order),
                                      tooltip: 'Download Receipt',
                                    ),
                                  IconButton(
                                    icon: const Icon(
                                      Icons.delete,
                                      color: Colors.red,
                                    ),
                                    onPressed: () => _confirmDelete(order),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ],
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

  void _showStatusDialog(AdminOrderModel order) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Update Order Status'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              title: const Text('Pending'),
              leading: const Icon(Icons.pending, color: Colors.orange),
              onTap: () => _updateStatus(order.id, 'pending'),
            ),
            ListTile(
              title: const Text('Processing'),
              leading: const Icon(Icons.autorenew, color: Colors.purple),
              onTap: () => _updateStatus(order.id, 'processing'),
            ),
            ListTile(
              title: const Text('Shipped'),
              leading: const Icon(Icons.local_shipping, color: Colors.teal),
              onTap: () => _updateStatus(order.id, 'shipped'),
            ),
            ListTile(
              title: const Text('Delivered'),
              leading: const Icon(Icons.check_circle, color: Colors.green),
              onTap: () => _updateStatus(order.id, 'delivered'),
            ),
            ListTile(
              title: const Text('Cancelled'),
              leading: const Icon(Icons.cancel, color: Colors.red),
              onTap: () => _updateStatus(order.id, 'cancelled'),
            ),
          ],
        ),
      ),
    );
  }

  void _updateStatus(String orderId, String newStatus) async {
    Navigator.pop(context);
    try {
      await ref
          .read(adminOrderViewModelProvider.notifier)
          .updateOrderStatus(orderId, newStatus);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Order status updated to $newStatus')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error: $e')));
      }
    }
  }

  void _confirmDelete(AdminOrderModel order) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Order'),
        content: Text(
          'Are you sure you want to delete order #${order.id.substring(0, 8)}?',
        ),
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
                    .read(adminOrderViewModelProvider.notifier)
                    .deleteOrder(order.id);
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Order deleted')),
                  );
                }
              } catch (e) {
                if (mounted) {
                  ScaffoldMessenger.of(
                    context,
                  ).showSnackBar(SnackBar(content: Text('Error: $e')));
                }
              }
            },
            child: const Text('Delete', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  Future<void> _downloadReceipt(AdminOrderModel order) async {
    try {
      // Show loading indicator
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Generating receipt...')));
      }

      // Generate and download receipt
      await ReceiptGeneratorService().generateReceipt(order);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Receipt generated successfully!'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error generating receipt: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }
}
