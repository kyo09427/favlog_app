import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:go_router/go_router.dart';
import '../providers/announcement_providers.dart';
import '../../core/providers/profile_providers.dart';
import '../../data/repositories/supabase_auth_repository.dart';

/// お知らせ詳細画面
class AnnouncementDetailScreen extends ConsumerStatefulWidget {
  final String announcementId;

  const AnnouncementDetailScreen({
    super.key,
    required this.announcementId,
  });

  @override
  ConsumerState<AnnouncementDetailScreen> createState() =>
      _AnnouncementDetailScreenState();
}

class _AnnouncementDetailScreenState
    extends ConsumerState<AnnouncementDetailScreen> {
  @override
  void initState() {
    super.initState();
    // 画面を開いたら既読にする
    Future.microtask(() async {
      final repository = ref.read(announcementRepositoryProvider);
      try {
        await repository.markAsRead(widget.announcementId);
        // プロバイダーを更新
        ref.invalidate(announcementsProvider);
        ref.invalidate(unreadAnnouncementCountProvider);
      } catch (e) {
        // 既読マークのエラーは無視
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final repository = ref.watch(announcementRepositoryProvider);
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('お知らせ詳細'),
        backgroundColor: theme.brightness == Brightness.dark
            ? const Color(0xFF1B5E20)
            : const Color(0xFF4CAF50),
        foregroundColor: Colors.white,
        actions: _buildAdminActions(repository),
      ),
      body: FutureBuilder(
        future: repository.getAnnouncementById(widget.announcementId),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return Center(
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
                    '${snapshot.error}',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: Colors.grey[600],
                    ),
                  ),
                ],
              ),
            );
          }

          final announcement = snapshot.data;
          if (announcement == null) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.campaign_outlined, size: 80, color: Colors.grey[400]),
                  const SizedBox(height: 16),
                  Text(
                    'お知らせが見つかりません',
                    style: theme.textTheme.titleMedium?.copyWith(
                      color: Colors.grey[600],
                    ),
                  ),
                ],
              ),
            );
          }

          return SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // カテゴリバッジ
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: _getCategoryColor(announcement.category)
                        .withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: _getCategoryColor(announcement.category),
                      width: 1,
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        _getCategoryIcon(announcement.category),
                        size: 16,
                        color: _getCategoryColor(announcement.category),
                      ),
                      const SizedBox(width: 4),
                      Text(
                        _getCategoryLabel(announcement.category),
                        style: TextStyle(
                          color: _getCategoryColor(announcement.category),
                          fontWeight: FontWeight.bold,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                // タイトル
                Text(
                  announcement.title,
                  style: theme.textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                // 公開日時
                Text(
                  DateFormat('yyyy年MM月dd日 HH:mm')
                      .format(announcement.publishedAt),
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: Colors.grey,
                  ),
                ),
                const Divider(height: 32),
                // 本文
                Text(
                  announcement.content,
                  style: theme.textTheme.bodyLarge?.copyWith(
                    height: 1.6,
                  ),
                ),
              ],
            ),
          );
        },
      ),
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

  /// カテゴリに応じたラベルを返す
  String _getCategoryLabel(String category) {
    switch (category) {
      case 'update':
        return 'アップデート';
      case 'maintenance':
        return 'メンテナンス';
      case 'news':
        return 'お知らせ';
      default:
        return 'その他';
    }
  }

  /// 管理者用のアクションボタンを構築
  List<Widget> _buildAdminActions(dynamic repository) {
    final currentUser = ref.watch(authRepositoryProvider).getCurrentUser();
    if (currentUser == null) return [];

    final profileAsync = ref.watch(userProfileProvider(currentUser.id));

    return profileAsync.when(
      data: (profile) {
        if (profile == null || !profile.isAdmin) return [];

        return [
          // 編集ボタン
          IconButton(
            icon: const Icon(Icons.edit),
            onPressed: () async {
              final announcement = await repository.getAnnouncementById(widget.announcementId);
              if (announcement != null && mounted) {
                final result = await context.push<bool>(
                  '/announcements/${widget.announcementId}/edit',
                  extra: announcement,
                );
                if (result == true && mounted) {
                  ref.invalidate(announcementsProvider);
                  context.pop();
                }
              }
            },
          ),
          // 削除ボタン
          IconButton(
            icon: const Icon(Icons.delete),
            onPressed: () => _showDeleteConfirmDialog(repository),
          ),
        ];
      },
      loading: () => [],
      error: (_, __) => [],
    );
  }

  /// 削除確認ダイアログを表示
  Future<void> _showDeleteConfirmDialog(dynamic repository) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('削除確認'),
        content: const Text('このお知らせを削除しますか？\nこの操作は取り消せません。'),
        actions: [
          TextButton(
            onPressed: () => context.pop(false),
            child: const Text('キャンセル'),
          ),
          TextButton(
            onPressed: () => context.pop(true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('削除'),
          ),
        ],
      ),
    );

    if (confirmed == true && mounted) {
      try {
        await repository.deleteAnnouncement(widget.announcementId);
        ref.invalidate(announcementsProvider);
        ref.invalidate(unreadAnnouncementCountProvider);
        
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('お知らせを削除しました')),
          );
          context.pop();
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('削除に失敗しました: $e'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    }
  }
}
