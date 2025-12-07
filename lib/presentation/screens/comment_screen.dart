import 'package:go_router/go_router.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../domain/models/comment.dart';
import '../../data/repositories/supabase_comment_repository.dart';
import '../../data/repositories/supabase_auth_repository.dart';
import '../../data/repositories/supabase_like_repository.dart';
import '../../core/providers/profile_providers.dart';
import '../widgets/review_info_card.dart';
import '../providers/comment_screen_provider.dart';

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
  bool _isLiked = false;
  int _likeCount = 0;

  @override
  void initState() {
    super.initState();
    _loadLikeStatus();
  }

  Future<void> _loadLikeStatus() async {
    final currentUserId = ref.read(authRepositoryProvider).getCurrentUser()?.id;
    if (currentUserId == null) return;

    try {
      final likeRepository = ref.read(likeRepositoryProvider);
      final isLiked = await likeRepository.hasUserLiked(widget.reviewId, currentUserId);
      final likeCounts = await likeRepository.getLikeCounts([widget.reviewId]);
      
      if (mounted) {
        setState(() {
          _isLiked = isLiked;
          _likeCount = likeCounts[widget.reviewId] ?? 0;
        });
      }
    } catch (e) {
      debugPrint('Failed to load like status: $e');
    }
  }

  Future<void> _toggleLike() async {
    final currentUserId = ref.read(authRepositoryProvider).getCurrentUser()?.id;
    if (currentUserId == null) return;

    try {
      final likeRepository = ref.read(likeRepositoryProvider);
      
      if (_isLiked) {
        await likeRepository.removeLike(widget.reviewId);
        setState(() {
          _isLiked = false;
          _likeCount = (_likeCount - 1).clamp(0, 999999);
        });
      } else {
        await likeRepository.addLike(widget.reviewId);
        setState(() {
          _isLiked = true;
          _likeCount++;
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('いいねの操作に失敗しました: $e')),
        );
      }
    }
  }

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
      return '1日前';
    } else if (difference.inDays < 7) {
      return '${difference.inDays}日前';
    }
    return '${date.year}/${date.month}/${date.day}';
  }

  Future<void> _editComment(Comment comment) async {
    final controller = TextEditingController(text: comment.commentText);
    
    final result = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('コメントを編集'),
        content: TextField(
          controller: controller,
          maxLines: null,
          autofocus: true,
          decoration: const InputDecoration(
            hintText: 'コメントを入力...',
            border: OutlineInputBorder(),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => context.pop(),
            child: const Text('キャンセル'),
          ),
          TextButton(
            onPressed: () => context.pop(controller.text),
            child: const Text('保存'),
          ),
        ],
      ),
    );

    if (result == null || result.trim().isEmpty) return;

    try {
      final commentRepository = ref.read(commentRepositoryProvider);
      final updatedComment = Comment(
        id: comment.id,
        userId: comment.userId,
        reviewId: comment.reviewId,
        commentText: result.trim(),
        createdAt: comment.createdAt,
      );
      
      await commentRepository.updateComment(updatedComment);
      ref.invalidate(commentListProvider(widget.reviewId));
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('コメントを編集しました')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('編集に失敗しました: $e')),
        );
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

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final currentUserId = ref.read(authRepositoryProvider).getCurrentUser()?.id;
    final commentsAsync = ref.watch(commentListProvider(widget.reviewId));
    final reviewDetailsAsync = ref.watch(reviewDetailsProvider(widget.reviewId));

    const primaryColor = Color(0xFF13ec5b);
    final backgroundColor = isDark ? const Color(0xFF102216) : const Color(0xFFF6F8F6);
    final cardColor = isDark ? const Color(0xFF1C1C1E) : Colors.white;
    final textColor = isDark ? Colors.white : const Color(0xFF1F2937);
    final mutedTextColor = isDark ? const Color(0xFF9CA3AF) : const Color(0xFF6B7280);
    final borderColor = isDark ? const Color(0xFF374151) : const Color(0xFFE5E7EB);

    return Scaffold(
      backgroundColor: backgroundColor,
      appBar: AppBar(
        backgroundColor: backgroundColor,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios_new, color: textColor),
          onPressed: () => context.pop(),
        ),
        title: Text(
          'コメント',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: textColor,
          ),
        ),
        centerTitle: true,
        actions: [
          IconButton(
            icon: Icon(Icons.more_horiz, color: textColor),
            onPressed: () {
              // メニュー表示（将来的に実装）
            },
          ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: reviewDetailsAsync.when(
              data: (details) {
                final review = details.review;
                final product = details.product;
                
                return ListView(
                  controller: _scrollController,
                  children: [
                    // レビュー情報カード
                    ReviewInfoCard(
                      review: review,
                      product: product,
                      isLiked: _isLiked,
                      likeCount: _likeCount,
                      commentCount: commentsAsync.value?.length ?? 0,
                      onToggleLike: _toggleLike,
                      isDark: isDark,
                    ),

                    // コメントヘッダー
                    Padding(
                      padding: const EdgeInsets.all(16),
                      child: Text(
                        commentsAsync.when(
                          data: (comments) => 'コメント ${comments.length}件',
                          loading: () => 'コメント',
                          error: (_, __) => 'コメント 0件',
                        ),
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: textColor,
                        ),
                      ),
                    ),

                    // コメントリスト
                    commentsAsync.when(
                      data: (comments) {
                        if (comments.isEmpty) {
                          return Padding(
                            padding: const EdgeInsets.all(32),
                            child: Center(
                              child: Text(
                                'まだコメントがありません',
                                style: TextStyle(
                                  fontSize: 14,
                                  color: mutedTextColor,
                                ),
                              ),
                            ),
                          );
                        }

                        return Column(
                          children: comments.map((comment) {
                            final isOwner = currentUserId == comment.userId;
                            final commentAuthorProfile = ref.watch(userProfileProvider(comment.userId));

                            return Container(
                              padding: const EdgeInsets.all(16),
                              decoration: BoxDecoration(
                                border: Border(
                                  top: BorderSide(color: borderColor),
                                ),
                              ),
                              child: Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  // アバター
                                  commentAuthorProfile.when(
                                    data: (profile) {
                                      final avatarUrl = profile?.avatarUrl;
                                      return Container(
                                        width: 32,
                                        height: 32,
                                        decoration: BoxDecoration(
                                          shape: BoxShape.circle,
                                          image: avatarUrl != null && avatarUrl.isNotEmpty
                                              ? DecorationImage(
                                                  image: CachedNetworkImageProvider(avatarUrl),
                                                  fit: BoxFit.cover,
                                                )
                                              : null,
                                          color: Colors.grey[300],
                                        ),
                                        child: avatarUrl == null || avatarUrl.isEmpty
                                            ? const Icon(Icons.person, size: 16)
                                            : null,
                                      );
                                    },
                                    loading: () => Container(
                                      width: 32,
                                      height: 32,
                                      decoration: BoxDecoration(
                                        shape: BoxShape.circle,
                                        color: Colors.grey[300],
                                      ),
                                    ),
                                    error: (_, __) => Container(
                                      width: 32,
                                      height: 32,
                                      decoration: BoxDecoration(
                                        shape: BoxShape.circle,
                                        color: Colors.grey[300],
                                      ),
                                      child: const Icon(Icons.error, size: 16),
                                    ),
                                  ),

                                  const SizedBox(width: 12),

                                  // コメント内容
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Row(
                                          children: [
                                            Text(
                                              commentAuthorProfile.when(
                                                data: (p) => p?.username ?? 'ユーザー',
                                                loading: () => '読み込み中...',
                                                error: (_, __) => 'ユーザー',
                                              ),
                                              style: TextStyle(
                                                fontSize: 14,
                                                fontWeight: FontWeight.bold,
                                                color: textColor,
                                              ),
                                            ),
                                            const SizedBox(width: 8),
                                            Text(
                                              _formatDate(comment.createdAt),
                                              style: TextStyle(
                                                fontSize: 12,
                                                color: mutedTextColor,
                                              ),
                                            ),
                                          ],
                                        ),
                                        const SizedBox(height: 4),
                                        Text(
                                          comment.commentText,
                                          style: TextStyle(
                                            fontSize: 16,
                                            color: textColor,
                                            height: 1.4,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),

                                  // 自分のコメントの場合、メニューボタンを表示
                                  if (isOwner)
                                    PopupMenuButton<String>(
                                      icon: Icon(Icons.more_vert, size: 20, color: mutedTextColor),
                                      onSelected: (value) {
                                        if (value == 'edit') {
                                          _editComment(comment);
                                        } else if (value == 'delete') {
                                          _deleteComment(comment.id);
                                        }
                                      },
                                      itemBuilder: (context) => [
                                        const PopupMenuItem(
                                          value: 'edit',
                                          child: Row(
                                            children: [
                                              Icon(Icons.edit, size: 18),
                                              SizedBox(width: 8),
                                              Text('編集'),
                                            ],
                                          ),
                                        ),
                                        const PopupMenuItem(
                                          value: 'delete',
                                          child: Row(
                                            children: [
                                              Icon(Icons.delete, size: 18, color: Colors.red),
                                              SizedBox(width: 8),
                                              Text('削除', style: TextStyle(color: Colors.red)),
                                            ],
                                          ),
                                        ),
                                      ],
                                    ),
                                ],
                              ),
                            );
                          }).toList(),
                        );
                      },
                      loading: () => const Padding(
                        padding: EdgeInsets.all(32),
                        child: Center(child: CircularProgressIndicator(color: primaryColor)),
                      ),
                      error: (error, stack) => Padding(
                        padding: const EdgeInsets.all(32),
                        child: Center(
                          child: Text(
                            'エラー: $error',
                            style: const TextStyle(color: Colors.red),
                          ),
                        ),
                      ),
                    ),

                    const SizedBox(height: 80), // フッターの高さ分の余白
                  ],
                );
              },
              loading: () => const Center(child: CircularProgressIndicator(color: primaryColor)),
              error: (error, stack) => Center(child: Text('エラーが発生しました: $error')),
            ),
          ),
        ],
      ),
      bottomNavigationBar: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: cardColor,
          border: Border(
            top: BorderSide(color: borderColor),
          ),
        ),
        child: SafeArea(
          child: Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _commentController,
                  maxLines: null,
                  textInputAction: TextInputAction.send,
                  style: TextStyle(color: textColor),
                  decoration: InputDecoration(
                    hintText: 'コメントを追加...',
                    hintStyle: TextStyle(color: mutedTextColor),
                    filled: true,
                    fillColor: isDark ? const Color(0xFF374151) : const Color(0xFFF3F4F6),
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
              Container(
                width: 40,
                height: 40,
                decoration: const BoxDecoration(
                  color: primaryColor,
                  shape: BoxShape.circle,
                ),
                child: IconButton(
                  onPressed: _isSubmitting ? null : _submitComment,
                  icon: _isSubmitting
                      ? const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : const Icon(Icons.arrow_upward, color: Colors.white, size: 20),
                  padding: EdgeInsets.zero,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
