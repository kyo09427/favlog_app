import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:timeago/timeago.dart' as timeago;
import '../../core/providers/notification_providers.dart';
import '../../domain/models/app_notification.dart';

class NotificationsScreen extends ConsumerStatefulWidget {
  const NotificationsScreen({super.key});

  @override
  ConsumerState<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends ConsumerState<NotificationsScreen> {
  @override
  void initState() {
    super.initState();
    // 日本語のローカライゼーション設定
    timeago.setLocaleMessages('ja', timeago.JaMessages());
  }

  @override
  Widget build(BuildContext context) {
    final notificationsAsync = ref.watch(notificationsProvider);
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final backgroundColor = isDark ? const Color(0xFF102216) : const Color(0xFFF6F8F6);
    final textColor = isDark ? Colors.white : const Color(0xFF1F2937);
    final mutedTextColor = isDark ? const Color(0xFF9CA3AF) : const Color(0xFF6B7280);
    const primaryColor = Color(0xFF13ec5b);

    return Scaffold(
      backgroundColor: backgroundColor,
      appBar: AppBar(
        backgroundColor: backgroundColor,
        elevation: 0,
        title: Text(
          '通知',
          style: TextStyle(
            color: textColor,
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        centerTitle: true,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios_new, color: textColor),
          onPressed: () => context.pop(),
        ),
        actions: [
          TextButton(
            onPressed: () async {
              final markAllAsRead = ref.read(markAllNotificationsAsReadProvider);
              await markAllAsRead();
            },
            child: const Text(
              'すべて既読',
              style: TextStyle(
                color: primaryColor,
                fontSize: 14,
              ),
            ),
          ),
        ],
      ),
      body: notificationsAsync.when(
        data: (notifications) {
          if (notifications.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.notifications_none,
                    size: 80,
                    color: mutedTextColor,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    '通知はありません',
                    style: TextStyle(
                      fontSize: 16,
                      color: mutedTextColor,
                    ),
                  ),
                ],
              ),
            );
          }

          return ListView.separated(
            padding: const EdgeInsets.all(16),
            itemCount: notifications.length,
            separatorBuilder: (context, index) => const Divider(height: 1),
            itemBuilder: (context, index) {
              final notification = notifications[index];
              return _buildNotificationItem(
                notification,
                textColor,
                mutedTextColor,
                isDark,
              );
            },
          );
        },
        loading: () => const Center(
          child: CircularProgressIndicator(color: primaryColor),
        ),
        error: (error, stack) => Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error_outline, color: Colors.red, size: 60),
              const SizedBox(height: 16),
              Text(
                '通知の読み込みに失敗しました',
                style: TextStyle(color: textColor),
              ),
              const SizedBox(height: 8),
              TextButton(
                onPressed: () => ref.invalidate(notificationsProvider),
                child: const Text('再読み込み', style: TextStyle(color: primaryColor)),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildNotificationItem(
    AppNotification notification,
    Color textColor,
    Color mutedTextColor,
    bool isDark,
  ) {
    final markAsRead = ref.read(markNotificationAsReadProvider);
    final deleteNotification = ref.read(deleteNotificationProvider);
    
    IconData icon;
    Color iconColor;

    switch (notification.type) {
      case 'new_review':
        icon = Icons.rate_review;
        iconColor = const Color(0xFF13ec5b);
        break;
      case 'like':
        icon = Icons.favorite;
        iconColor = Colors.red;
        break;
      case 'comment':
        icon = Icons.comment;
        iconColor = Colors.blue;
        break;
      default:
        icon = Icons.notifications;
        iconColor = const Color(0xFF13ec5b);
    }

    return Dismissible(
      key: Key(notification.id),
      direction: DismissDirection.endToStart,
      background: Container(
        color: Colors.red,
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 20),
        child: const Icon(Icons.delete, color: Colors.white),
      ),
      onDismissed: (direction) async {
        await deleteNotification(notification.id);
      },
      child: InkWell(
        onTap: () async {
          if (!notification.isRead) {
            await markAsRead(notification.id);
          }
          if (!mounted) return;
          if (notification.relatedReviewId != null) {
            context.push('/review/${notification.relatedReviewId}');
          }
        },
        child: Container(
          color: notification.isRead
              ? Colors.transparent
              : (isDark
                  ? const Color(0xFF1C1C1E).withValues(alpha: 0.5)
                  : const Color(0xFF13ec5b).withValues(alpha: 0.05)),
          padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 4),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // アイコン
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: iconColor.withValues(alpha: 0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(icon, color: iconColor, size: 20),
              ),
              const SizedBox(width: 12),
              // コンテンツ
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      notification.title,
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: notification.isRead
                            ? FontWeight.normal
                            : FontWeight.bold,
                        color: textColor,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      notification.body,
                      style: TextStyle(
                        fontSize: 13,
                        color: mutedTextColor,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      timeago.format(notification.createdAt, locale: 'ja'),
                      style: TextStyle(
                        fontSize: 12,
                        color: mutedTextColor,
                      ),
                    ),
                  ],
                ),
              ),
              // 未読インジケーター
              if (!notification.isRead)
                Container(
                  width: 8,
                  height: 8,
                  decoration: const BoxDecoration(
                    color: Color(0xFF13ec5b),
                    shape: BoxShape.circle,
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
