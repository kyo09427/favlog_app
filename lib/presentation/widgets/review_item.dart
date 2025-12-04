import 'package:go_router/go_router.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../domain/models/product.dart';
import '../../domain/models/review.dart';
import '../../domain/models/review_stats.dart';
import '../screens/edit_review_screen.dart';
import '../../data/repositories/supabase_auth_repository.dart';
import '../../core/providers/profile_providers.dart';

class ReviewItem extends ConsumerWidget {
  final Product product;
  final Review review;
  final ReviewStats? stats;
  final bool? isLiked;
  final VoidCallback? onLikeToggle;
  final VoidCallback? onCommentTap;
  final VoidCallback? onReviewUpdated;

  const ReviewItem({
    super.key,
    required this.product,
    required this.review,
    this.stats,
    this.isLiked,
    this.onLikeToggle,
    this.onCommentTap,
    this.onReviewUpdated,
  });

  Widget _buildRatingStars(BuildContext context) {
    final theme = Theme.of(context);
    const calmGreen = Color(0xFF22A06B);

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: List.generate(5, (starIndex) {
        final starPosition = starIndex + 1;

        IconData icon;
        Color color;

        if (review.rating >= starPosition) {
          icon = Icons.star;
          color = calmGreen;
        } else if (review.rating >= starPosition - 0.5) {
          icon = Icons.star_half;
          color = calmGreen;
        } else {
          icon = Icons.star_border;
          color = theme.brightness == Brightness.dark
              ? Colors.grey[600]!
              : Colors.grey[400]!;
        }

        return Icon(icon, color: color, size: 18);
      }),
    );
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
    } else if (difference.inDays < 30) {
      final weeks = (difference.inDays / 7).floor();
      return '$weeks週間前';
    } else if (difference.inDays < 365) {
      final months = (difference.inDays / 30).floor();
      return '$monthsヶ月前';
    } else {
      return '${date.year}/${date.month}/${date.day}';
    }
  }

  String _truncateText(String text, int maxLength) {
    if (text.length <= maxLength) return text;
    return '${text.substring(0, maxLength)}...';
  }

  Future<void> _handleEdit(BuildContext context) async {
    final result = await context.push<bool>(
      '/edit-review', // 新しいパスを定義する必要がある
      extra: {
        'review': review,
        'product': product,
      },
    );

    if (result == true && onReviewUpdated != null) {
      onReviewUpdated!();
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final reviewText = review.reviewText.trim();
    final currentUserId = ref.read(authRepositoryProvider).getCurrentUser()?.id;
    final isOwner = currentUserId != null && currentUserId == review.userId;

    final userProfileAsync = ref.watch(userProfileProvider(review.userId));

    final likeCount = stats?.likeCount ?? 0;
    final commentCount = stats?.commentCount ?? 0;
    final liked = isLiked ?? false;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // 上部: アバター + ユーザー名 + 相対時間
        Row(
          children: [
            userProfileAsync.when(
              data: (profile) {
                final avatarUrl = profile?.avatarUrl;
                if (avatarUrl != null && avatarUrl.isNotEmpty) {
                  return CircleAvatar(
                    radius: 20,
                    backgroundColor: isDark ? Colors.grey[700] : Colors.grey[300],
                    backgroundImage: CachedNetworkImageProvider(avatarUrl),
                  );
                }
                return CircleAvatar(
                  radius: 20,
                  backgroundColor: isDark ? Colors.grey[700] : Colors.grey[300],
                  child: Icon(
                    Icons.person,
                    size: 20,
                    color: isDark ? Colors.white : Colors.grey[800],
                  ),
                );
              },
              loading: () => CircleAvatar(
                radius: 20,
                backgroundColor: isDark ? Colors.grey[700] : Colors.grey[300],
                child: const SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
              ),
              error: (err, stack) => CircleAvatar(
                radius: 20,
                backgroundColor: isDark ? Colors.grey[700] : Colors.grey[300],
                child: const Icon(Icons.error_outline, size: 20),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    isOwner
                        ? 'あなた'
                        : userProfileAsync.when(
                            data: (profile) => profile?.username ?? 'レビュアー',
                            loading: () => '読み込み中...',
                            error: (e, st) => '取得失敗',
                          ),
                    style: theme.textTheme.bodyMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: isDark ? Colors.white : Colors.black,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    _formatDate(review.createdAt.toLocal()),
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: isDark ? Colors.grey[400] : Colors.grey[600],
                    ),
                  ),
                ],
              ),
            ),
            if (isOwner)
              IconButton(
                icon: Icon(
                  Icons.edit_outlined,
                  size: 20,
                  color: isDark ? Colors.grey[400] : Colors.grey[600],
                ),
                onPressed: () => _handleEdit(context),
                tooltip: '編集',
              ),
          ],
        ),
        const SizedBox(height: 8),
        // 星評価 + 数値
        Row(
          children: [
            _buildRatingStars(context),
            const SizedBox(width: 6),
            Text(
              review.rating.toStringAsFixed(1),
              style: theme.textTheme.bodyMedium?.copyWith(
                fontWeight: FontWeight.bold,
                color: isDark ? Colors.white : Colors.black,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        // 本文
        Text(
          _truncateText(reviewText, 400),
          style: theme.textTheme.bodyMedium?.copyWith(
            height: 1.5,
            color: isDark ? Colors.grey[200] : Colors.grey[800],
          ),
          maxLines: 4,
          overflow: TextOverflow.ellipsis,
        ),
        const SizedBox(height: 8),
        // アクション (いいね / コメント)
        Row(
          children: [
            InkWell(
              borderRadius: BorderRadius.circular(999),
              onTap: onLikeToggle,
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
                child: Row(
                  children: [
                    Icon(
                      liked ? Icons.favorite : Icons.favorite_border,
                      size: 18,
                      color: liked
                          ? Colors.red
                          : (isDark ? Colors.white : Colors.black),
                    ),
                    const SizedBox(width: 4),
                    Text(
                      '$likeCount',
                      style: theme.textTheme.bodySmall?.copyWith(
                        fontWeight: FontWeight.w500,
                        color: isDark ? Colors.white : Colors.black,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(width: 24),
            InkWell(
              borderRadius: BorderRadius.circular(999),
              onTap: onCommentTap,
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
                child: Row(
                  children: [
                    Icon(
                      Icons.chat_bubble_outline,
                      size: 18,
                      color: isDark ? Colors.white : Colors.black,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      '$commentCount',
                      style: theme.textTheme.bodySmall?.copyWith(
                        fontWeight: FontWeight.w500,
                        color: isDark ? Colors.white : Colors.black,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }
}