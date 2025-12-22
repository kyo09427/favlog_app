import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../domain/models/app_notification.dart';
import '../../domain/models/user_settings.dart';
import '../../data/repositories/supabase_notification_repository.dart';
import '../../data/repositories/supabase_settings_repository.dart';
import '../../data/repositories/supabase_auth_repository.dart';

// 通知リストのプロバイダー
final notificationsProvider = FutureProvider<List<AppNotification>>((ref) async {
  final authRepository = ref.watch(authRepositoryProvider);
  final currentUser = authRepository.getCurrentUser();
  
  if (currentUser == null) {
    return [];
  }

  final notificationRepository = ref.watch(notificationRepositoryProvider);
  return await notificationRepository.getNotifications(currentUser.id);
});

// 未読通知数のプロバイダー
final unreadNotificationCountProvider = FutureProvider<int>((ref) async {
  final authRepository = ref.watch(authRepositoryProvider);
  final currentUser = authRepository.getCurrentUser();
  
  if (currentUser == null) {
    return 0;
  }

  final notificationRepository = ref.watch(notificationRepositoryProvider);
  return await notificationRepository.getUnreadCount(currentUser.id);
});

// ユーザー設定のプロバイダー
final userSettingsProvider = FutureProvider<UserSettings>((ref) async {
  final authRepository = ref.watch(authRepositoryProvider);
  final currentUser = authRepository.getCurrentUser();
  
  if (currentUser == null) {
    throw Exception('User not logged in');
  }

  final settingsRepository = ref.watch(settingsRepositoryProvider);
  return await settingsRepository.getUserSettings(currentUser.id);
});

// 通知を既読にするアクション
final markNotificationAsReadProvider = Provider((ref) {
  return (String notificationId) async {
    final notificationRepository = ref.read(notificationRepositoryProvider);
    await notificationRepository.markAsRead(notificationId);
    // プロバイダーを更新
    ref.invalidate(notificationsProvider);
    ref.invalidate(unreadNotificationCountProvider);
  };
});

// すべての通知を既読にするアクション
final markAllNotificationsAsReadProvider = Provider((ref) {
  return () async {
    final authRepository = ref.read(authRepositoryProvider);
    final currentUser = authRepository.getCurrentUser();
    
    if (currentUser == null) return;

    final notificationRepository = ref.read(notificationRepositoryProvider);
    await notificationRepository.markAllAsRead(currentUser.id);
    // プロバイダーを更新
    ref.invalidate(notificationsProvider);
    ref.invalidate(unreadNotificationCountProvider);
  };
});

// 通知を削除するアクション
final deleteNotificationProvider = Provider((ref) {
  return (String notificationId) async {
    final notificationRepository = ref.read(notificationRepositoryProvider);
    await notificationRepository.deleteNotification(notificationId);
    // プロバイダーを更新
    ref.invalidate(notificationsProvider);
    ref.invalidate(unreadNotificationCountProvider);
  };
});

// ユーザー設定を更新するアクション
final updateUserSettingsProvider = Provider((ref) {
  return (UserSettings settings) async {
    final settingsRepository = ref.read(settingsRepositoryProvider);
    await settingsRepository.updateUserSettings(settings);
    // プロバイダーを更新
    ref.invalidate(userSettingsProvider);
  };
});
