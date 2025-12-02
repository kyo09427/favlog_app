import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:favlog_app/domain/models/product.dart';
import 'package:favlog_app/domain/models/review.dart';
import 'package:favlog_app/presentation/screens/edit_review_screen.dart';
import 'package:favlog_app/data/repositories/supabase_auth_repository.dart';

class ReviewItem extends ConsumerStatefulWidget {
  final Product product;
  final Review review;
  final VoidCallback? onReviewUpdated;

  const ReviewItem({
    super.key,
    required this.product,
    required this.review,
    this.onReviewUpdated,
  });

  @override
  ConsumerState<ReviewItem> createState() => _ReviewItemState();
}

class _ReviewItemState extends ConsumerState<ReviewItem>
    with SingleTickerProviderStateMixin {
  bool _isLongPressed = false;

  @override
  void initState() {
    super.initState();
  }

  Widget _buildRatingStars() {
    final theme = Theme.of(context);
    final rating = widget.review.rating;

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: List.generate(5, (starIndex) {
        final starPosition = starIndex + 1;

        IconData icon;
        Color color;

        if (rating >= starPosition) {
          icon = Icons.star;
          color = Colors.amber;
        } else if (rating >= starPosition - 0.5) {
          icon = Icons.star_half;
          color = Colors.amber;
        } else {
          icon = Icons.star_border;
          color = theme.brightness == Brightness.dark
              ? Colors.grey[600]!
              : Colors.grey[400]!;
        }

        return Icon(icon, color: color, size: 16);
      }),
    );
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final difference = now.difference(date);

    if (difference.inDays == 0) {
      if (difference.inHours == 0) {
        if (difference.inMinutes == 0) {
          return 'たった今';
        }
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

  Future<void> _handleEdit() async {
    final result = await Navigator.of(context).push<bool>(
      MaterialPageRoute(
        builder: (_) => EditReviewScreen(
          review: widget.review,
          product: widget.product,
        ),
      ),
    );

    // 編集が成功した場合、コールバックを実行
    if (result == true && widget.onReviewUpdated != null) {
      widget.onReviewUpdated!();
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final reviewText = widget.review.reviewText.trim();
    final currentUserId = ref.read(authRepositoryProvider).getCurrentUser()?.id;
    final isOwner = currentUserId != null && currentUserId == widget.review.userId;

    return GestureDetector(
      onLongPressStart: isOwner
          ? (_) {
              setState(() {
                _isLongPressed = true;
              });
            }
          : null,
      onLongPressEnd: isOwner
          ? (_) {
              setState(() {
                _isLongPressed = false;
              });
            }
          : null,
      onLongPress: isOwner ? _handleEdit : null,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 8.0),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(8),
          color: _isLongPressed
              ? (theme.brightness == Brightness.dark
                  ? Colors.white10
                  : Colors.grey.shade200)
              : Colors.transparent,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                _buildRatingStars(),
                Row(
                  children: [
                    Icon(
                      Icons.access_time,
                      size: 12,
                      color: theme.brightness == Brightness.dark
                          ? Colors.grey[400]
                          : Colors.grey[600],
                    ),
                    const SizedBox(width: 4),
                    Text(
                      _formatDate(widget.review.createdAt.toLocal()),
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.brightness == Brightness.dark
                            ? Colors.grey[400]
                            : Colors.grey[600],
                      ),
                    ),
                    if (isOwner) ...[
                      const SizedBox(width: 8),
                      GestureDetector(
                        onTap: _handleEdit,
                        child: Icon(
                          Icons.edit,
                          size: 16,
                          color: Colors.greenAccent[400] ?? Colors.green,
                        ),
                      ),
                    ],
                  ],
                ),
              ],
            ),
            const SizedBox(height: 6),
            Text(
              _truncateText(reviewText, 200),
              style: theme.textTheme.bodyMedium,
              maxLines: 3,
              overflow: TextOverflow.ellipsis,
            ),
            if (isOwner && _isLongPressed)
              Padding(
                padding: const EdgeInsets.only(top: 8.0),
                child: Text(
                  '長押しして編集',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: Colors.greenAccent[400] ?? Colors.green,
                    fontStyle: FontStyle.italic,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}