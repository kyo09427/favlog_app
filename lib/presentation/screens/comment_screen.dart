import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../domain/models/comment.dart';
import '../../data/repositories/supabase_comment_repository.dart';
import '../../data/repositories/supabase_auth_repository.dart';
import '../../core/providers/profile_providers.dart';

final commentListProvider = FutureProvider.family<List<Comment>, String>((ref, reviewId) async {
  final commentRepository = ref.watch(commentRepositoryProvider);
  return commentRepository.getCommentsByReviewId(reviewId);
});

class CommentScreen extends ConsumerStatefulWidget {
  final String reviewId;
  final String productName;

  const CommentScreen({
    super.key,
    required this.reviewId,
    required this.productName,
  });

  @override
  ConsumerState<CommentScreen> createState() => _CommentScreenState();
}

class _CommentScreenState extends ConsumerState<CommentScreen> {
  final _commentController = TextEditingController();
  final _scrollController = ScrollController();
  bool _isSubmitting = false;

  @override
  void dispose() {
    _commentController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _submitComment() async {
    final text = _commentController.text.trim();
    if (text.isEmpty) return;

    setState(() => _isSubmitting = true);

    try {
      final commentRepository = ref.read(commentRepositoryProvider);
      final authRepository = ref.read(authRepositoryProvider);
      final currentUser = authRepository.getCurrentUser();

      if (currentUser == null) {
        throw Exception('ログインが必要です');
      }

      final newComment = Comment(
        userId: currentUser.id,
        reviewId: widget.reviewId,
        commentText: text,
      );

      await commentRepository.addComment(newComment);
      
      _commentController.clear();
      
      // リストを更新
      ref.invalidate(commentListProvider(widget.reviewId));
      
      // 最下部にスクロール
      Future.delayed(const Duration(milliseconds: 300), () {
        if (_scrollController.hasClients) {
          _scrollController.animateTo(
            _scrollController.position.maxScrollExtent,
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeOut,
          );
        }
      });
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('コメントの投稿に失敗しました: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isSubmitting = false);
      }
    }
  }

  Future<void> _deleteComment(String commentId) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('コメントを削除'),
        content: const Text('このコメントを削除してもよろしいですか?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('キャンセル'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('削除'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    try {
      final commentRepository = ref.read(commentRepositoryProvider);
      await commentRepository.deleteComment(commentId);
      ref.invalidate(commentListProvider(widget.reviewId));
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('コメントを削除しました')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('削除に失敗しました: $e')),
        );
      }
    }
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final difference = now.difference(date);

    if (difference.inDays == 0) {
      if (difference.inHours == 0) {
        if (difference.inMinutes == 0) return 'たった今';
        return '${difference.inMinutes}分前';
      }
      return '${difference.inHours}時間前';
    } else if (difference.inDays == 1) {
      return '昨日';
    } else if (difference.inDays < 7) {
      return '${difference.inDays}日前';
    }
    return '${date.year}/${date.month}/${date.day}';
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final currentUserId = ref.read(authRepositoryProvider).getCurrentUser()?.id;
    final commentsAsync = ref.watch(commentListProvider(widget.reviewId));

    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF102216) : const Color(0xFFF6F8F6),
      appBar: AppBar(
        backgroundColor: isDark ? const Color(0xFF1B5E20) : const Color(0xFF4CAF50),
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('コメント', style: TextStyle(color: Colors.white, fontSize: 16)),
            Text(
              widget.productName,
              style: const TextStyle(color: Colors.white70, fontSize: 12),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
      body: Column(
        children: [
          Expanded(
            child: commentsAsync.when(
              data: (comments) {
                if (comments.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.chat_bubble_outline, size: 64, color: Colors.grey[400]),
                        const SizedBox(height: 16),
                        Text(
                          'まだコメントがありません',
                          style: theme.textTheme.titleMedium?.copyWith(color: Colors.grey[600]),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          '最初のコメントを投稿してみましょう',
                          style: theme.textTheme.bodySmall?.copyWith(color: Colors.grey[500]),
                        ),
                      ],
                    ),
                  );
                }

                return ListView.separated(
                  controller: _scrollController,
                  padding: const EdgeInsets.all(16),
                  itemCount: comments.length,
                  separatorBuilder: (context, index) => const SizedBox(height: 16),
                  itemBuilder: (context, index) {
                    final comment = comments[index];
                    final isOwner = currentUserId == comment.userId;
                    final profileAsync = ref.watch(userProfileProvider(comment.userId));

                    return Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: isDark ? Colors.white.withOpacity(0.05) : Colors.white,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: isDark ? Colors.white24 : Colors.grey.shade300,
                        ),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              profileAsync.when(
                                data: (profile) {
                                  final avatarUrl = profile?.avatarUrl;
                                  if (avatarUrl != null && avatarUrl.isNotEmpty) {
                                    return CircleAvatar(
                                      radius: 16,
                                      backgroundImage: CachedNetworkImageProvider(avatarUrl),
                                    );
                                  }
                                  return CircleAvatar(
                                    radius: 16,
                                    backgroundColor: Colors.grey[300],
                                    child: const Icon(Icons.person, size: 16),
                                  );
                                },
                                loading: () => CircleAvatar(
                                  radius: 16,
                                  backgroundColor: Colors.grey[300],
                                ),
                                error: (_, __) => CircleAvatar(
                                  radius: 16,
                                  backgroundColor: Colors.grey[300],
                                  child: const Icon(Icons.error, size: 16),
                                ),
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      isOwner
                                          ? 'あなた'
                                          : profileAsync.when(
                                              data: (p) => p?.username ?? 'ユーザー',
                                              loading: () => '読み込み中...',
                                              error: (_, __) => 'ユーザー',
                                            ),
                                      style: theme.textTheme.bodyMedium?.copyWith(
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                    Text(
                                      _formatDate(comment.createdAt),
                                      style: theme.textTheme.bodySmall?.copyWith(
                                        color: Colors.grey,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              if (isOwner)
                                IconButton(
                                  icon: const Icon(Icons.delete_outline, size: 18),
                                  color: Colors.red,
                                  onPressed: () => _deleteComment(comment.id),
                                ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Text(
                            comment.commentText,
                            style: theme.textTheme.bodyMedium,
                          ),
                        ],
                      ),
                    );
                  },
                );
              },
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (error, stack) => Center(
                child: Text('エラー: $error'),
              ),
            ),
          ),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF050B07) : Colors.white,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.1),
                  blurRadius: 10,
                  offset: const Offset(0, -2),
                ),
              ],
            ),
            child: SafeArea(
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _commentController,
                      maxLines: null,
                      textInputAction: TextInputAction.send,
                      decoration: InputDecoration(
                        hintText: 'コメントを入力...',
                        filled: true,
                        fillColor: isDark
                            ? Colors.white.withOpacity(0.05)
                            : Colors.grey[100],
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(24),
                          borderSide: BorderSide.none,
                        ),
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 12,
                        ),
                      ),
                      onSubmitted: (_) => _submitComment(),
                    ),
                  ),
                  const SizedBox(width: 8),
                  IconButton(
                    onPressed: _isSubmitting ? null : _submitComment,
                    icon: _isSubmitting
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Icon(Icons.send),
                    color: const Color(0xFF22A06B),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}