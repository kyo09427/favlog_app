import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../domain/models/product.dart';
import '../../domain/models/review.dart';
import '../../core/providers/profile_providers.dart';

class ReviewInfoCard extends ConsumerWidget {
  final Review review;
  final Product product;
  final bool isLiked;
  final int likeCount;
  final int commentCount;
  final VoidCallback onToggleLike;
  final bool isDark;

  const ReviewInfoCard({
    super.key,
    required this.review,
    required this.product,
    required this.isLiked,
    required this.likeCount,
    required this.commentCount,
    required this.onToggleLike,
    required this.isDark,
  });

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

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final reviewAuthorProfileAsync = ref.watch(userProfileProvider(review.userId));
    const primaryColor = Color(0xFF13ec5b);
    final cardColor = isDark ? const Color(0xFF1C1C1E) : Colors.white;
    final textColor = isDark ? Colors.white : const Color(0xFF1F2937);
    final mutedTextColor = isDark ? const Color(0xFF9CA3AF) : const Color(0xFF6B7280);
    final borderColor = isDark ? const Color(0xFF374151) : const Color(0xFFE5E7EB);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: cardColor,
        border: Border(
          bottom: BorderSide(color: borderColor),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ユーザー情報
          Row(
            children: [
              reviewAuthorProfileAsync.when(
                data: (profile) {
                  final avatarUrl = profile?.avatarUrl;
                  return Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(color: primaryColor, width: 1),
                      image: avatarUrl != null && avatarUrl.isNotEmpty
                          ? DecorationImage(
                              image: CachedNetworkImageProvider(avatarUrl),
                              fit: BoxFit.cover,
                            )
                          : null,
                      color: Colors.grey[300],
                    ),
                    child: avatarUrl == null || avatarUrl.isEmpty
                        ? const Icon(Icons.person, size: 20)
                        : null,
                  );
                },
                loading: () => Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: Colors.grey[300],
                  ),
                ),
                error: (error, stack) => Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: Colors.grey[300],
                  ),
                  child: const Icon(Icons.error, size: 20),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      reviewAuthorProfileAsync.when(
                        data: (p) => p?.username ?? 'ユーザー',
                        loading: () => '読み込み中...',
                        error: (error, stack) => 'ユーザー',
                      ),
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: textColor,
                      ),
                    ),
                    Text(
                      '@${reviewAuthorProfileAsync.when(
                        data: (p) => p?.username.toLowerCase().replaceAll(' ', '_') ?? 'user',
                        loading: () => 'loading',
                        error: (error, stack) => 'user',
                      )}',
                      style: TextStyle(
                        fontSize: 14,
                        color: mutedTextColor,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),

          const SizedBox(height: 16),

          // 商品名
          Text(
            product.name,
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: textColor,
            ),
          ),

          const SizedBox(height: 8),

          // 評価
          Row(
            children: [
              ...List.generate(5, (index) {
                if (index < review.rating.floor()) {
                  return const Icon(
                    Icons.star,
                    size: 18,
                    color: Color(0xFFFBBF24),
                  );
                } else if (index < review.rating && review.rating % 1 >= 0.5) {
                  return const Icon(
                    Icons.star_half,
                    size: 18,
                    color: Color(0xFFFBBF24),
                  );
                } else {
                  return Icon(
                    Icons.star,
                    size: 18,
                    color: isDark ? const Color(0xFF4B5563) : const Color(0xFFD1D5DB),
                  );
                }
              }),
              const SizedBox(width: 4),
              Text(
                review.rating.toStringAsFixed(1),
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: textColor,
                ),
              ),
            ],
          ),

          const SizedBox(height: 8),

          // サブカテゴリ
          if (product.subcategoryTags.isNotEmpty)
            Text(
              '#${product.subcategoryTags.first}',
              style: const TextStyle(
                fontSize: 14,
                color: primaryColor,
              ),
            ),

          const SizedBox(height: 12),

          // レビューテキスト
          Text(
            review.reviewText,
            style: TextStyle(
              fontSize: 16,
              color: textColor,
              height: 1.5,
            ),
          ),

          const SizedBox(height: 12),

          // いいね・コメント数、投稿日時
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  // いいねボタン
                  InkWell(
                    onTap: onToggleLike,
                    borderRadius: BorderRadius.circular(20),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      child: Row(
                        children: [
                          Icon(
                            isLiked ? Icons.favorite : Icons.favorite_border,
                            size: 20,
                            color: isLiked ? Colors.red : mutedTextColor,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            likeCount.toString(),
                            style: TextStyle(
                              fontSize: 14,
                              color: mutedTextColor,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  // コメント数
                  Row(
                    children: [
                      Icon(
                        Icons.chat_bubble_outline,
                        size: 20,
                        color: mutedTextColor,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        commentCount.toString(),
                        style: TextStyle(
                          fontSize: 14,
                          color: mutedTextColor,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              Text(
                _formatDate(review.createdAt),
                style: TextStyle(
                  fontSize: 14,
                  color: mutedTextColor,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
