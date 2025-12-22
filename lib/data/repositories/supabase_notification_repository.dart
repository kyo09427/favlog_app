import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../domain/models/app_notification.dart';
import '../../domain/repositories/notification_repository.dart';
import '../../main.dart';

final notificationRepositoryProvider = Provider<NotificationRepository>((ref) {
  return SupabaseNotificationRepository(ref.watch(supabaseProvider));
});

class SupabaseNotificationRepository implements NotificationRepository {
  final SupabaseClient _supabaseClient;

  SupabaseNotificationRepository(this._supabaseClient);

  @override
  Future<List<AppNotification>> getNotifications(String userId) async {
    try {
      final response = await _supabaseClient
          .from('notifications')
          .select()
          .eq('user_id', userId)
          .order('created_at', ascending: false);

      return (response as List)
          .map((json) => AppNotification.fromJson(json))
          .toList();
    } catch (e) {
      throw Exception('Failed to get notifications: $e');
    }
  }

  @override
  Future<int> getUnreadCount(String userId) async {
    try {
      final response = await _supabaseClient
          .from('notifications')
          .select('id')
          .eq('user_id', userId)
          .eq('is_read', false)
          .count(CountOption.exact);

      return response.count ?? 0;
    } catch (e) {
      throw Exception('Failed to get unread count: $e');
    }
  }

  @override
  Future<void> markAsRead(String notificationId) async {
    try {
      await _supabaseClient.from('notifications').update({
        'is_read': true,
        'read_at': DateTime.now().toUtc().toIso8601String(),
      }).eq('id', notificationId);
    } catch (e) {
      throw Exception('Failed to mark notification as read: $e');
    }
  }

  @override
  Future<void> markAllAsRead(String userId) async {
    try {
      await _supabaseClient.from('notifications').update({
        'is_read': true,
        'read_at': DateTime.now().toUtc().toIso8601String(),
      }).eq('user_id', userId).eq('is_read', false);
    } catch (e) {
      throw Exception('Failed to mark all notifications as read: $e');
    }
  }

  @override
  Future<void> createNotification(AppNotification notification) async {
    try {
      await _supabaseClient
          .from('notifications')
          .insert(notification.toJson());
    } catch (e) {
      throw Exception('Failed to create notification: $e');
    }
  }

  @override
  Future<void> deleteNotification(String notificationId) async {
    try {
      await _supabaseClient
          .from('notifications')
          .delete()
          .eq('id', notificationId);
    } catch (e) {
      throw Exception('Failed to delete notification: $e');
    }
  }

  @override
  Future<void> deleteAllNotifications(String userId) async {
    try {
      await _supabaseClient
          .from('notifications')
          .delete()
          .eq('user_id', userId);
    } catch (e) {
      throw Exception('Failed to delete all notifications: $e');
    }
  }
}
