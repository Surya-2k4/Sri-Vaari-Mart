import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../model/notification_model.dart';

final notificationListProvider =
    StateNotifierProvider<
      NotificationListNotifier,
      AsyncValue<List<NotificationModel>>
    >((ref) {
      return NotificationListNotifier();
    });

final unreadNotificationCountProvider = Provider<int>((ref) {
  final notificationState = ref.watch(notificationListProvider);
  return notificationState.maybeWhen(
    data: (notifications) => notifications.where((n) => !n.isRead).length,
    orElse: () => 0,
  );
});

class NotificationListNotifier
    extends StateNotifier<AsyncValue<List<NotificationModel>>> {
  NotificationListNotifier() : super(const AsyncValue.loading()) {
    fetchNotifications();
  }

  final _client = Supabase.instance.client;

  Future<void> fetchNotifications() async {
    try {
      final userId = _client.auth.currentUser?.id;
      if (userId == null) {
        state = const AsyncValue.data([]);
        return;
      }

      final data = await _client
          .from('notifications')
          .select()
          .eq('user_id', userId)
          .order('created_at', ascending: false);

      final notifications = (data as List)
          .map((e) => NotificationModel.fromMap(e))
          .toList();
      state = AsyncValue.data(notifications);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  Future<void> deleteNotification(String id) async {
    try {
      final currentList = state.value ?? [];
      state = AsyncValue.data(currentList.where((n) => n.id != id).toList());

      await _client.from('notifications').delete().eq('id', id);
    } catch (e) {
      // Revert if failed
      fetchNotifications();
    }
  }

  Future<void> markAsRead(String id) async {
    try {
      await _client
          .from('notifications')
          .update({'is_read': true})
          .eq('id', id);
      fetchNotifications();
    } catch (e) {}
  }
}
