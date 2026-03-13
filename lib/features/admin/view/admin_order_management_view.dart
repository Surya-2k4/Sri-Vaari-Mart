import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../model/admin_order_model.dart';
import '../viewmodel/admin_order_viewmodel.dart';
import '../../../core/services/receipt_generator_service.dart';
import '../../../core/constants/app_colors.dart';

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

    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 900),
        child: Column(
          children: [
            // Status Filter with Refresh Button
            Padding(
              padding: const EdgeInsets.all(24),
              child: Row(
                children: [
                  Expanded(
                    child: Container(
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
                        value: _statusFilter,
                        borderRadius: BorderRadius.circular(24),
                        icon: const Icon(Icons.keyboard_arrow_down_rounded, color: AppColors.primaryBlack),
                        decoration: InputDecoration(
                          labelText: 'Filter by Status',
                          hintText: 'Select order status',
                          labelStyle: TextStyle(color: Colors.grey.shade700, fontWeight: FontWeight.w500),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(16),
                            borderSide: BorderSide.none,
                          ),
                          filled: true,
                          fillColor: Colors.white,
                          prefixIcon: const Icon(Icons.filter_list_rounded, color: AppColors.primaryBlack),
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 20,
                            vertical: 16,
                          ),
                        ),
                        items: [
                          const DropdownMenuItem(
                            value: null,
                            child: Row(
                              children: [
                                Icon(Icons.all_inbox, size: 20, color: Colors.grey),
                                SizedBox(width: 12),
                                Text('All Orders'),
                              ],
                            ),
                          ),
                          _buildDropdownItem('pending', 'Pending', Icons.pending, Colors.orange),
                          _buildDropdownItem('paid', 'Paid', Icons.payments, Colors.blue),
                          _buildDropdownItem('processing', 'Processing', Icons.autorenew, Colors.purple),
                          _buildDropdownItem('shipped', 'Shipped', Icons.local_shipping, Colors.teal),
                          _buildDropdownItem('delivered', 'Delivered', Icons.check_circle, Colors.green),
                          _buildDropdownItem('cancelled', 'Cancelled', Icons.cancel, Colors.red),
                        ],
                        onChanged: (value) {
                          setState(() {
                            _statusFilter = value;
                          });
                        },
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Container(
                    decoration: BoxDecoration(
                      color: Colors.orange.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: IconButton(
                      icon: const Icon(Icons.refresh, color: Colors.orange),
                      onPressed: () {
                        ref.invalidate(adminOrderViewModelProvider);
                      },
                      tooltip: 'Refresh Orders',
                      padding: const EdgeInsets.all(16),
                    ),
                  ),
                ],
              ),
            ),
            // Orders List
            Expanded(
              child: ordersState.when(
                loading: () => const Center(child: CircularProgressIndicator()),
                error: (e, _) => Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.error_outline, size: 48, color: Colors.red),
                      const SizedBox(height: 16),
                      Text('Error: $e'),
                      TextButton(
                        onPressed: () => ref.invalidate(adminOrderViewModelProvider),
                        child: const Text('Try Again'),
                      ),
                    ],
                  ),
                ),
                data: (orders) {
                  final filteredOrders = _statusFilter == null
                      ? orders
                      : orders.where((o) => o.status == _statusFilter).toList();

                  if (filteredOrders.isEmpty) {
                    return Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.assignment_late_outlined, size: 64, color: Colors.grey.shade300),
                          const SizedBox(height: 16),
                          Text(
                            'No orders found',
                            style: TextStyle(color: Colors.grey.shade600, fontSize: 16),
                          ),
                        ],
                      ),
                    );
                  }

                  return ListView.builder(
                    padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
                    itemCount: filteredOrders.length,
                    itemBuilder: (context, index) {
                      final order = filteredOrders[index];
                      final statusColor = _getStatusColor(order.status);
                      
                      return Container(
                        margin: const EdgeInsets.only(bottom: 20),
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
                          data: Theme.of(context).copyWith(
                            dividerColor: Colors.transparent,
                          ),
                          child: ExpansionTile(
                            tilePadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
                            expandedAlignment: Alignment.topLeft,
                            backgroundColor: Colors.grey.shade50.withOpacity(0.5),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(24),
                            ),
                            leading: Container(
                              padding: const EdgeInsets.all(10),
                              decoration: BoxDecoration(
                                color: statusColor.withOpacity(0.1),
                                shape: BoxShape.circle,
                              ),
                              child: Text(
                                order.items.length.toString(),
                                style: TextStyle(
                                  color: statusColor,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 16,
                                ),
                              ),
                            ),
                            title: Text(
                              'Order #${order.id.substring(0, 8)}',
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                              ),
                            ),
                            subtitle: Padding(
                              padding: const EdgeInsets.only(top: 4),
                              child: Text(
                                '₹${order.totalAmount.toStringAsFixed(0)} • ${_formatDate(order.createdAt)}',
                                style: TextStyle(color: Colors.grey.shade600, fontSize: 13),
                              ),
                            ),
                            trailing: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                              decoration: BoxDecoration(
                                color: statusColor,
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Text(
                                order.status.toUpperCase(),
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 10,
                                  fontWeight: FontWeight.bold,
                                  letterSpacing: 0.5,
                                ),
                              ),
                            ),
                            children: [
                              Padding(
                                padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const Divider(height: 1),
                                    const SizedBox(height: 20),
                                    Row(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Expanded(
                                          child: _buildInfoSection(
                                            context,
                                            'Customer Details',
                                            Icons.person_outline_rounded,
                                            [
                                              'ID: ${order.userId.substring(0, 12)}...',
                                              'Phone: ${order.phoneNumber}',
                                              'Payment: ${order.paymentMethod}',
                                            ],
                                          ),
                                        ),
                                        const SizedBox(width: 16),
                                        Expanded(
                                          child: _buildInfoSection(
                                            context,
                                            'Shipping Address',
                                            Icons.location_on_outlined,
                                            [order.shippingAddress],
                                          ),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 24),
                                    Text(
                                      'Order Items',
                                      style: Theme.of(context).textTheme.titleSmall?.copyWith(
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                    const SizedBox(height: 12),
                                    Container(
                                      padding: const EdgeInsets.all(20),
                                      decoration: BoxDecoration(
                                        color: Colors.white,
                                        borderRadius: BorderRadius.circular(20),
                                        border: Border.all(color: Colors.grey.shade100),
                                      ),
                                      child: Column(
                                        children: order.items.map((item) => Container(
                                          margin: const EdgeInsets.only(bottom: 12),
                                          padding: const EdgeInsets.all(12),
                                          decoration: BoxDecoration(
                                            color: Colors.grey.shade50,
                                            borderRadius: BorderRadius.circular(12),
                                          ),
                                          child: Row(
                                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                            children: [
                                              Expanded(
                                                child: Text(
                                                  '${item.quantity}x ${item.productName}',
                                                  style: const TextStyle(
                                                    fontSize: 13,
                                                    fontWeight: FontWeight.w500,
                                                  ),
                                                ),
                                              ),
                                              Container(
                                                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                                decoration: BoxDecoration(
                                                  color: Colors.white,
                                                  borderRadius: BorderRadius.circular(8),
                                                  border: Border.all(color: Colors.grey.shade200),
                                                ),
                                                child: Text(
                                                  '₹${(item.price * item.quantity).toStringAsFixed(0)}',
                                                  style: const TextStyle(
                                                    fontWeight: FontWeight.bold,
                                                    color: AppColors.primaryBlack,
                                                    fontSize: 13,
                                                  ),
                                                ),
                                              ),
                                            ],
                                          ),
                                        )).toList(),
                                      ),
                                    ),
                                    const SizedBox(height: 24),
                                    Row(
                                      children: [
                                        Expanded(
                                          child: ElevatedButton.icon(
                                            onPressed: () => _showStatusDialog(order),
                                            icon: const Icon(Icons.edit_road_rounded, size: 18),
                                            label: const Text('UPDATE STATUS'),
                                            style: ElevatedButton.styleFrom(
                                              padding: const EdgeInsets.symmetric(vertical: 16),
                                              shape: RoundedRectangleBorder(
                                                borderRadius: BorderRadius.circular(16),
                                              ),
                                            ),
                                          ),
                                        ),
                                        const SizedBox(width: 12),
                                        if (order.status.toLowerCase() == 'delivered')
                                          _buildActionIconButton(
                                            Icons.download_rounded,
                                            Colors.blue,
                                            () => _downloadReceipt(order),
                                            'Receipt',
                                          ),
                                        const SizedBox(width: 12),
                                        _buildActionIconButton(
                                          Icons.delete_outline_rounded,
                                          Colors.red,
                                          () => _confirmDelete(order),
                                          'Delete',
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
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoSection(
    BuildContext context,
    String title,
    IconData icon,
    List<String> details,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(icon, size: 16, color: Colors.grey.shade600),
            const SizedBox(width: 8),
            Text(
              title,
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 13,
                color: Colors.black87,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        ...details.map((detail) => Padding(
          padding: const EdgeInsets.only(bottom: 2),
          child: Text(
            detail,
            style: TextStyle(color: Colors.grey.shade700, fontSize: 12),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
        )),
      ],
    );
  }

  Widget _buildActionIconButton(
    IconData icon,
    Color color,
    VoidCallback onTap,
    String tooltip,
  ) {
    return Container(
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(16),
      ),
      child: IconButton(
        icon: Icon(icon, color: color),
        onPressed: onTap,
        tooltip: tooltip,
        padding: const EdgeInsets.all(12),
      ),
    );
  }

  DropdownMenuItem<String> _buildDropdownItem(
    String value,
    String label,
    IconData icon,
    Color color,
  ) {
    return DropdownMenuItem(
      value: value,
      child: Row(
        children: [
          Icon(icon, size: 20, color: color),
          const SizedBox(width: 12),
          Text(label),
        ],
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
