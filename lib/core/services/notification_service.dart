import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'dart:async';
import '../../features/notifications/viewmodel/notification_viewmodel.dart';

final notificationServiceProvider = Provider((ref) => NotificationService(ref));

class NotificationService {
  final _client = Supabase.instance.client;
  StreamSubscription? _orderSubscription;
  final Map<String, String> _lastStatusMap = {};

  final Ref _ref;
  NotificationService(this._ref);

  void init(BuildContext context) {
    if (_orderSubscription != null) return;

    final userId = _client.auth.currentUser?.id;
    if (userId == null) return;

    _orderSubscription = _client
        .from('orders')
        .stream(primaryKey: ['id'])
        .eq('user_id', userId)
        .listen((List<Map<String, dynamic>> orders) {
          for (final order in orders) {
            final orderId = order['id'].toString();
            final status = order['status'].toString().toLowerCase();
            final shortOrderId = orderId.substring(0, 8);

            // Notify if it's a new status change
            if (_lastStatusMap.containsKey(orderId) &&
                _lastStatusMap[orderId] != status) {
              String title = 'Order Update';
              String body =
                  'Your order #$shortOrderId status has been updated to $status.';

              if (status == 'shipped') {
                title = 'Order Shipped! 🚚';
                body =
                    'Great news! Your order #$shortOrderId has been shipped.';
              } else if (status == 'delivered') {
                title = 'Order Delivered! 🎁';
                body =
                    'Your order #$shortOrderId has been successfully delivered.';
              } else if (status == 'cancelled') {
                title = 'Order Cancelled ❌';
                body = 'Your order #$shortOrderId has been cancelled.';
              } else if (status == 'processing') {
                title = 'Order Processing ⚙️';
                body = 'Manufacturer is preparing your order #$shortOrderId.';
              }

              _saveNotification(title, body);
              _showNotification(context, title, body);
            }

            // Update the last known status
            _lastStatusMap[orderId] = status;
          }
        });
  }

  Future<void> _saveNotification(String title, String body) async {
    try {
      final userId = _client.auth.currentUser?.id;
      if (userId == null) return;

      await _client.from('notifications').insert({
        'user_id': userId,
        'title': title,
        'body': body,
      });

      // Refresh the notification list viewmodel
      _ref.invalidate(notificationListProvider);
    } catch (e) {
      print('Error saving notification: $e');
    }
  }

  void _showNotification(BuildContext context, String title, String body) {
    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
            Text(body),
          ],
        ),
        behavior: SnackBarBehavior.floating,
        backgroundColor: Colors.black,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        margin: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
        duration: const Duration(seconds: 4),
      ),
    );
  }

  Future<void> notifyOrderPlaced(
    BuildContext context,
    Map<String, dynamic> order,
    List<dynamic> items,
  ) async {
    final orderId = order['id'].toString().substring(0, 8);
    final total = order['total_amount'];

    final title = 'Order Confirmed! 🎉';
    final body = 'Order #$orderId for ₹$total is successfully placed.';

    await _saveNotification(title, body);
    _showNotification(context, title, body);
  }

  void dispose() {
    _orderSubscription?.cancel();
    _orderSubscription = null;
  }
}
