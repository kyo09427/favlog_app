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

class _ReviewItemState extends ConsumerState<ReviewItem> with SingleTickerProviderStateMixin {
  late AnimationController _scaleController;
  late Animation<double> _scaleAnimation;
  late final String? _currentUserId;
  late final bool _isOwner;

  @override
  void initState() {
    super.initState();
    _currentUserId = ref.read(authRepositoryProvider).getCurrentUser()?.id;
    _isOwner = _currentUserId == widget.review.userId;

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

  @override
  void dispose() {
    _scaleController.dispose();
    super.dispose();
  }

  void _onLongPressStart(LongPressStartDetails details) {
    if (_isOwner) {
      _scaleController.forward();
    }
  }

  void _onLongPressEnd(LongPressEndDetails details) {
    if (_isOwner) {
      _scaleController.reverse();
      Navigator.of(context).push(
        MaterialPageRoute(
          builder: (context) => EditReviewScreen(
            productId: widget.product.id,
            reviewId: widget.review.id,
          ),
        ),
      ).then((_) => widget.onReviewEdited());
    }
  }

  void _onLongPressCancel() {
    if (_isOwner) {
      _scaleController.reverse();
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
        child: Padding(
          padding: const EdgeInsets.only(top: 8.0, left: 8.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 星評価の表示
              Row(
                children: List.generate(5, (starIndex) {
                  final starPosition = starIndex + 1;
                  final rating = widget.review.rating;
                  
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
              ),
              const SizedBox(height: 4),
              
              // レビュー本文
              Text(
                widget.review.reviewText,
                style: theme.textTheme.bodyMedium,
                maxLines: 3,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 4),
              
              // 投稿日
              Text(
                '投稿日: ${widget.review.createdAt.toLocal().toString().split('.')[0]}',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.brightness == Brightness.dark
                      ? Colors.grey[400]
                      : Colors.grey[600],
                ),
              ),
              
              // 編集可能な場合のヒント
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