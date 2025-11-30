import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:favlog_app/domain/models/product.dart';
import 'package:favlog_app/domain/models/review.dart';
import 'package:favlog_app/data/repositories/supabase_auth_repository.dart';
import 'package:favlog_app/presentation/screens/edit_review_screen.dart';

class ReviewItem extends ConsumerStatefulWidget {
  final Product product;
  final Review review;
  final VoidCallback onReviewEdited;

  const ReviewItem({
    super.key,
    required this.product,
    required this.review,
    required this.onReviewEdited,
  });

  @override
  ConsumerState<ReviewItem> createState() => _ReviewItemState();
}

class _ReviewItemState extends ConsumerState<ReviewItem> 
    with SingleTickerProviderStateMixin {
  late AnimationController _scaleController;
  late Animation<double> _scaleAnimation;
  String? _currentUserId;
  bool _isOwner = false;
  bool _isLongPressing = false;

  @override
  void initState() {
    super.initState();
    _initializeOwnership();
    
    _scaleController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 150),
      reverseDuration: const Duration(milliseconds: 100),
    );
    
    _scaleAnimation = Tween<double>(begin: 1.0, end: 0.95).animate(
      CurvedAnimation(
        parent: _scaleController,
        curve: Curves.easeOut,
        reverseCurve: Curves.easeIn,
      ),
    );
  }

  void _initializeOwnership() {
    _currentUserId = ref.read(authRepositoryProvider).getCurrentUser()?.id;
    _isOwner = _currentUserId == widget.review.userId;
  }

  @override
  void dispose() {
    _scaleController.dispose();
    super.dispose();
  }

  void _onLongPressStart(LongPressStartDetails details) {
    if (_isOwner && !_isLongPressing) {
      setState(() => _isLongPressing = true);
      _scaleController.forward();
    }
  }

  void _onLongPressEnd(LongPressEndDetails details) {
    if (_isOwner && _isLongPressing) {
      setState(() => _isLongPressing = false);
      _scaleController.reverse();
      _navigateToEdit();
    }
  }

  void _onLongPressCancel() {
    if (_isOwner && _isLongPressing) {
      setState(() => _isLongPressing = false);
      _scaleController.reverse();
    }
  }

  Future<void> _navigateToEdit() async {
    final result = await Navigator.of(context).push<bool>(
      MaterialPageRoute(
        builder: (context) => EditReviewScreen(
          productId: widget.product.id,
          reviewId: widget.review.id,
        ),
      ),
    );

    if (result == true && mounted) {
      widget.onReviewEdited();
    }
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
    } else {
      return '${date.year}/${date.month}/${date.day}';
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return ScaleTransition(
      scale: _scaleAnimation,
      child: GestureDetector(
        onLongPressStart: _onLongPressStart,
        onLongPressEnd: _onLongPressEnd,
        onLongPressCancel: _onLongPressCancel,
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 8.0),
          decoration: BoxDecoration(
            color: _isLongPressing
                ? (theme.brightness == Brightness.dark
                    ? Colors.white.withOpacity(0.05)
                    : Colors.grey.withOpacity(0.1))
                : Colors.transparent,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 星評価
              _buildRatingStars(),
              const SizedBox(height: 4),

              // レビュー本文
              Text(
                widget.review.reviewText.trim(),
                style: theme.textTheme.bodyMedium,
                maxLines: 3,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 4),

              // 投稿日時（相対時間表示）
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
                ],
              ),

              // 編集可能ヒント（所有者のみ）
              if (_isOwner) ...[
                const SizedBox(height: 4),
                Row(
                  children: [
                    Icon(
                      Icons.edit,
                      size: 12,
                      color: theme.colorScheme.primary.withOpacity(0.7),
                    ),
                    const SizedBox(width: 4),
                    Text(
                      '(長押しで編集)',
                      style: TextStyle(
                        fontSize: 10,
                        color: theme.colorScheme.primary.withOpacity(0.7),
                      ),
                    ),
                  ],
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}