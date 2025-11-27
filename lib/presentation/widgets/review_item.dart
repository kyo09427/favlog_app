import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart'; // Import Riverpod
import 'package:favlog_app/domain/models/product.dart';
import 'package:favlog_app/domain/models/review.dart';
import 'package:favlog_app/data/repositories/supabase_auth_repository.dart'; // Import authRepositoryProvider
import 'package:favlog_app/presentation/screens/edit_review_screen.dart'; // Import EditReviewScreen
import 'package:favlog_app/presentation/screens/review_detail_screen.dart'; // New import

class ReviewItem extends ConsumerStatefulWidget { // Change to ConsumerStatefulWidget
  final Product product;
  final Review review;
  final VoidCallback onReviewEdited; // Callback to refresh home screen

  const ReviewItem({
    super.key,
    required this.product,
    required this.review,
    required this.onReviewEdited,
  });

  @override
  ConsumerState<ReviewItem> createState() => _ReviewItemState(); // Change State to ConsumerState
}

class _ReviewItemState extends ConsumerState<ReviewItem> with SingleTickerProviderStateMixin {
  late AnimationController _scaleController;
  late Animation<double> _scaleAnimation;
  late final String? _currentUserId;
  late final bool _isOwner;

  @override
  void initState() {
    super.initState();
    _currentUserId = ref.read(authRepositoryProvider).getCurrentUser()?.id; // Use authRepositoryProvider
    _isOwner = _currentUserId == widget.review.userId; // Use model property

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
      _scaleController.reverse(); // Revert animation
      Navigator.of(context).push(
        MaterialPageRoute(
          builder: (context) => EditReviewScreen(
            product: widget.product,
            review: widget.review,
          ),
        ),
      ).then((_) => widget.onReviewEdited()); // Call callback to refresh after returning
    }
  }

  void _onLongPressCancel() {
    if (_isOwner) {
      _scaleController.reverse();
    }
  }

  @override
  Widget build(BuildContext context) {
    return ScaleTransition(
      scale: _scaleAnimation,
      child: GestureDetector(
        onLongPressStart: _onLongPressStart,
        onLongPressEnd: _onLongPressEnd,
        onLongPressCancel: _onLongPressCancel,
        onTap: () { // New onTap callback for detail view
          // The onTap to ReviewDetailScreen from here is redundant,
          // as HomeScreen already handles navigation to ReviewDetailScreen
          // via GestureDetector on the whole Card.
          // This onTap will be removed or changed based on desired UX.
        },
        child: Padding(
          padding: const EdgeInsets.only(top: 8.0, left: 8.0), // Original padding
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: List.generate(5, (starIndex) {
                  return Icon(
                    starIndex < widget.review.rating ? Icons.star : Icons.star_border, // Use model property
                    color: Colors.amber,
                    size: 16,
                  );
                }),
              ),
              Text(widget.review.reviewText), // Use model property
              Text(
                '投稿日: ${widget.review.createdAt.toLocal().toString().split('.')[0]}', // Use model property
                style: Theme.of(context).textTheme.bodySmall?.copyWith(color: Colors.grey),
              ),
              if (_isOwner)
                Row(
                  children: [
                    const Icon(Icons.edit, size: 12, color: Colors.blueGrey),
                    const SizedBox(width: 4),
                    const Text(
                      '(長押しで編集)',
                      style: TextStyle(fontSize: 10, color: Colors.blueGrey),
                    ),
                  ],
                ),
            ],
          ),
        ),
      ),
    );
  }
}
