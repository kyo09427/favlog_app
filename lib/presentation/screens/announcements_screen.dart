import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:timeago/timeago.dart' as timeago;
import '../providers/announcement_providers.dart';
import '../../core/providers/profile_providers.dart';
import '../../data/repositories/supabase_auth_repository.dart';

/// お知らせ一覧画面
class AnnouncementsScreen extends ConsumerWidget {
  const AnnouncementsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final announcementsAsync = ref.watch(announcementsProvider);
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('お知らせ'),
        backgroundColor: theme.brightness == Brightness.dark
            ? const Color(0xFF1B5E20)
            : const Color(0xFF4CAF50),
        foregroundColor: Colors.white,
      ),
      body: announcementsAsync.when(
        data: (announcements) {
          if (announcements.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.campaign_outlined, size: 80, color: Colors.grey[400]),
                  const SizedBox(height: 16),
                  Text(
                    'お知らせはありません',
                    style: theme.textTheme.titleMedium?.copyWith(
                      color: Colors.grey[600],
                    ),
                  ),
                ],
              ),
            );
          }

          return RefreshIndicator(
            onRefresh: () async {
              ref.invalidate(announcementsProvider);
              ref.invalidate(unreadAnnouncementCountProvider);
            },
            child: ListView.builder(
              itemCount: announcements.length,
              itemBuilder: (context, index) {
                final announcement = announcements[index];
                return Card(
                  margin: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 8,
                  ),
                  elevation: announcement.isRead ? 0 : 2,
                  child: ListTile(
                    leading: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: _getCategoryColor(announcement.category)
                            .withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Icon(
                        _getCategoryIcon(announcement.category),
                        color: _getCategoryColor(announcement.category),
                        size: 28,
                      ),
                    ),
                    title: Text(
                      announcement.title,
                      style: TextStyle(
                        fontWeight: announcement.isRead
                            ? FontWeight.normal
                            : FontWeight.bold,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    subtitle: Padding(
                      padding: const EdgeInsets.only(top: 4),
                      child: Text(
                        timeago.format(announcement.publishedAt, locale: 'ja'),
                        style: theme.textTheme.bodySmall,
                      ),
                    ),
                    trailing: announcement.isRead
                        ? null
                        : Container(
                            width: 10,
                            height: 10,
                            decoration: const BoxDecoration(
                              color: Colors.red,
                              shape: BoxShape.circle,
                            ),
                          ),
                    onTap: () async {
                      await context.push('/announcements/${announcement.id}');
                      // 詳細画面から戻ってきたらプロバイダーを更新
                      ref.invalidate(announcementsProvider);
                      ref.invalidate(unreadAnnouncementCountProvider);
                    },
                  ),
                );
              },
            ),
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, stack) => Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.error_outline, size: 80, color: Colors.red[300]),
              const SizedBox(height: 16),
              Text(
                'エラーが発生しました',
                style: theme.textTheme.titleMedium?.copyWith(
                  color: Colors.red[600],
                ),
              ),
              const SizedBox(height: 8),
              Text(
                '$error',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: Colors.grey[600],
                ),
              ),
            ],
          ),
        ),
      ),
      floatingActionButton: _buildAdminFAB(context, ref),
    );
  }

  /// 管理者用のFloatingActionButtonを構築
  Widget? _buildAdminFAB(BuildContext context, WidgetRef ref) {
    final currentUser = ref.watch(authRepositoryProvider).getCurrentUser();
    if (currentUser == null) return null;

    final profileAsync = ref.watch(userProfileProvider(currentUser.id));

    return profileAsync.when(
      data: (profile) {
        if (profile == null || !profile.isAdmin) return null;

        return FloatingActionButton(
          onPressed: () {
            context.push('/announcements/create');
          },
          backgroundColor: const Color(0xFF4CAF50),
          foregroundColor: Colors.white,
          child: const Icon(Icons.add),
        );
      },
      loading: () => null,
      error: (_, __) => null,
    );
  }

  /// カテゴリに応じたアイコンを返す
  IconData _getCategoryIcon(String category) {
    switch (category) {
      case 'update':
        return Icons.system_update;
      case 'maintenance':
        return Icons.build;
      case 'news':
        return Icons.newspaper;
      default:
        return Icons.info;
    }
  }

  /// カテゴリに応じた色を返す
  Color _getCategoryColor(String category) {
    switch (category) {
      case 'update':
        return Colors.blue;
      case 'maintenance':
        return Colors.orange;
      case 'news':
        return Colors.green;
      default:
        return Colors.grey;
    }
  }
}
