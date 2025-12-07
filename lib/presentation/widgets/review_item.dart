import 'package:go_router/go_router.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../domain/models/product.dart';
import '../../domain/models/review.dart';
import '../../domain/models/review_stats.dart';
import '../../data/repositories/supabase_auth_repository.dart';
import '../../core/providers/profile_providers.dart';

class ReviewItem extends ConsumerStatefulWidget {
  final Product product;
  final Review review;
  final ReviewStats? stats;
  final bool? isLiked;
  final VoidCallback? onLikeToggle;
  final VoidCallback? onCommentTap;
  final VoidCallback? onReviewUpdated;
  final VoidCallback? onDelete;

  const ReviewItem({
    super.key,
    required this.product,
    required this.review,
    this.stats,
    this.isLiked,
    this.onLikeToggle,
    this.onCommentTap,
    this.onReviewUpdated,
    this.onDelete,
  });



  @override

  ConsumerState<ReviewItem> createState() => _ReviewItemState();

}



class _ReviewItemState extends ConsumerState<ReviewItem> {

  bool _isExpanded = false;



  Widget _buildRatingStars(BuildContext context) {
    final theme = Theme.of(context);
    const calmGreen = Color(0xFF22A06B);

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: List.generate(5, (starIndex) {
        final starPosition = starIndex + 1;

        IconData icon;
        Color color;

        if (widget.review.rating >= starPosition) {
          icon = Icons.star;
          color = calmGreen;
        } else if (widget.review.rating >= starPosition - 0.5) {
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
      '/edit-review',
      extra: {
        'review': widget.review,
        'product': widget.product,
      },
    );

    if (result == true && widget.onReviewUpdated != null) {
      widget.onReviewUpdated!();
    }
  }

  void _showMenu(BuildContext context, WidgetRef ref) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    showModalBottomSheet(
      context: context,
      backgroundColor: isDark ? const Color(0xFF1C1C1E) : Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: const Icon(Icons.edit_outlined, color: Color(0xFF22A06B)),
                title: const Text('編集する'),
                onTap: () {
                  Navigator.pop(context);
                  _handleEdit(context);
                },
              ),
              ListTile(
                leading: const Icon(Icons.delete_outline, color: Colors.red),
                title: const Text('削除する', style: TextStyle(color: Colors.red)),
                onTap: () {
                  Navigator.pop(context);
                  if (widget.onDelete != null) {
                    widget.onDelete!();
                  }
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showImageViewer(BuildContext context, List<String> imageUrls, int initialIndex) {
    showDialog(
      context: context,
      barrierColor: Colors.black87,
      builder: (context) => ImageViewerDialog(
        imageUrls: imageUrls,
        initialIndex: initialIndex,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final reviewText = widget.review.reviewText.trim();
    final currentUserId = ref.read(authRepositoryProvider).getCurrentUser()?.id;
    final isOwner = currentUserId != null && currentUserId == widget.review.userId;

    final userProfileAsync = ref.watch(userProfileProvider(widget.review.userId));

    final likeCount = widget.stats?.likeCount ?? 0;
    final commentCount = widget.stats?.commentCount ?? 0;
    final liked = widget.isLiked ?? false;

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
                    _formatDate(widget.review.createdAt.toLocal()),
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
                  Icons.more_vert,
                  size: 20,
                  color: isDark ? Colors.grey[400] : Colors.grey[600],
                ),
                onPressed: () => _showMenu(context, ref),
                tooltip: 'メニュー',
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
              widget.review.rating.toStringAsFixed(1),
              style: theme.textTheme.bodyMedium?.copyWith(
                fontWeight: FontWeight.bold,
                color: isDark ? Colors.white : Colors.black,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        
        // レビュー画像（ある場合）
        if (widget.review.imageUrls.isNotEmpty) ...[
          SizedBox(
            height: 120,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              itemCount: widget.review.imageUrls.length,
              itemBuilder: (context, index) {
                final imageUrl = widget.review.imageUrls[index];
                return Padding(
                  padding: EdgeInsets.only(right: index < widget.review.imageUrls.length - 1 ? 8 : 0),
                  child: GestureDetector(
                    onTap: () => _showImageViewer(context, widget.review.imageUrls, index),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: CachedNetworkImage(
                        imageUrl: imageUrl,
                        width: 120,
                        height: 120,
                        fit: BoxFit.cover,
                        placeholder: (context, url) => Container(
                          width: 120,
                          height: 120,
                          color: isDark ? Colors.grey[800] : Colors.grey[200],
                          child: const Center(
                            child: CircularProgressIndicator(strokeWidth: 2),
                          ),
                        ),
                        errorWidget: (context, url, error) => Container(
                          width: 120,
                          height: 120,
                          color: isDark ? Colors.grey[800] : Colors.grey[200],
                          child: Icon(
                            Icons.image_not_supported_outlined,
                            color: isDark ? Colors.grey[600] : Colors.grey[400],
                          ),
                        ),
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
          const SizedBox(height: 12),
        ],
        
        // 本文
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              _isExpanded ? reviewText : _truncateText(reviewText, 200),
              style: theme.textTheme.bodyMedium?.copyWith(
                height: 1.5,
                color: isDark ? Colors.grey[200] : Colors.grey[800],
              ),
              maxLines: _isExpanded ? null : 4,
              overflow: _isExpanded ? null : TextOverflow.ellipsis,
            ),
            // 「もっと見る」ボタン（200文字以上または3行以上の場合に表示）
            if (reviewText.length > 200 || reviewText.split('\n').length > 3)
              GestureDetector(
                onTap: () {
                  setState(() {
                    _isExpanded = !_isExpanded;
                  });
                },
                child: Padding(
                  padding: const EdgeInsets.only(top: 4),
                  child: Text(
                    _isExpanded ? '閉じる' : 'もっと見る',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: const Color(0xFF22A06B),
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
          ],
        ),
        const SizedBox(height: 8),
        // アクション (いいね / コメント)
        Row(
          children: [
            InkWell(
              borderRadius: BorderRadius.circular(999),
              onTap: widget.onLikeToggle,
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
              onTap: widget.onCommentTap,
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

/// 画像拡大表示用のダイアログ
class ImageViewerDialog extends StatefulWidget {
  final List<String> imageUrls;
  final int initialIndex;

  const ImageViewerDialog({
    super.key,
    required this.imageUrls,
    this.initialIndex = 0,
  });

  @override
  State<ImageViewerDialog> createState() => _ImageViewerDialogState();
}

class _ImageViewerDialogState extends State<ImageViewerDialog> {
  late PageController _pageController;
  late int _currentIndex;

  @override
  void initState() {
    super.initState();
    _currentIndex = widget.initialIndex;
    _pageController = PageController(initialPage: widget.initialIndex);
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: EdgeInsets.zero,
      child: Stack(
        children: [
          // 画像表示エリア
          GestureDetector(
            onTap: () => Navigator.pop(context),
            child: Container(
              color: Colors.black87,
              child: PageView.builder(
                controller: _pageController,
                itemCount: widget.imageUrls.length,
                onPageChanged: (index) {
                  setState(() {
                    _currentIndex = index;
                  });
                },
                itemBuilder: (context, index) {
                  return InteractiveViewer(
                    minScale: 0.5,
                    maxScale: 4.0,
                    child: Center(
                      child: CachedNetworkImage(
                        imageUrl: widget.imageUrls[index],
                        fit: BoxFit.contain,
                        placeholder: (context, url) => const Center(
                          child: CircularProgressIndicator(
                            color: Colors.white,
                          ),
                        ),
                        errorWidget: (context, url, error) => const Center(
                          child: Icon(
                            Icons.error_outline,
                            color: Colors.white,
                            size: 48,
                          ),
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
          ),
          
          // 閉じるボタン
          Positioned(
            top: 40,
            right: 16,
            child: SafeArea(
              child: IconButton(
                icon: const Icon(
                  Icons.close,
                  color: Colors.white,
                  size: 32,
                ),
                onPressed: () => Navigator.pop(context),
              ),
            ),
          ),

          // インジケーター（複数画像がある場合）
          if (widget.imageUrls.length > 1)
            Positioned(
              bottom: 40,
              left: 0,
              right: 0,
              child: SafeArea(
                child: Center(
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: Colors.black54,
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Text(
                      '${_currentIndex + 1} / ${widget.imageUrls.length}',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
