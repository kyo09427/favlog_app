import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:favlog_app/main.dart';
import 'package:favlog_app/screens/edit_review_screen.dart'; // Import EditReviewScreen
import 'package:favlog_app/screens/review_detail_screen.dart'; // New import

class ReviewItem extends StatefulWidget {
  final Map<String, dynamic> product;
  final Map<String, dynamic> review;
  final SupabaseClient supabaseClient; // For ownership check
  final VoidCallback onReviewEdited; // Callback to refresh home screen

  const ReviewItem({
    super.key,
    required this.product,
    required this.review,
    required this.supabaseClient,
    required this.onReviewEdited,
  });

  @override
  State<ReviewItem> createState() => _ReviewItemState();
}

class _ReviewItemState extends State<ReviewItem> with SingleTickerProviderStateMixin {
  late AnimationController _scaleController;
  late Animation<double> _scaleAnimation;
  late final String? _currentUserId;
  late final bool _isOwner;

  @override
  void initState() {
    super.initState();
    _currentUserId = widget.supabaseClient.auth.currentUser?.id;
    _isOwner = _currentUserId == widget.review['user_id'];

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
        onLongPressEnd: (details) async { // Modified to handle navigation
          if (_isOwner) {
            _scaleController.reverse(); // Revert animation
            await Navigator.of(context).push(
              MaterialPageRoute(
                builder: (context) => EditReviewScreen(
                  product: widget.product,
                  review: widget.review,
                ),
              ),
            );
            widget.onReviewEdited(); // Call callback to refresh home screen
          }
        },
        onLongPressCancel: _onLongPressCancel,
        onTap: () { // New onTap callback for detail view
          Navigator.of(context).push(
            MaterialPageRoute(
              builder: (context) => ReviewDetailScreen(
                product: widget.product,
              ),
            ),
          );
        },
        child: Padding(
          padding: const EdgeInsets.only(top: 8.0, left: 8.0), // Original padding
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: List.generate(5, (starIndex) {
                  return Icon(
                    starIndex < widget.review['rating'] ? Icons.star : Icons.star_border,
                    color: Colors.amber,
                    size: 16,
                  );
                }),
              ),
              Text(widget.review['review_text']),
              Text(
                '投稿日: ${DateTime.parse(widget.review['created_at']).toLocal().toShortString()}',
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

extension on DateTime {
  String toShortString() {
    return '$year/${month.toString().padLeft(2, '0')}/${day.toString().padLeft(2, '0')} ${hour.toString().padLeft(2, '0')}:${minute.toString().padLeft(2, '0')}';
  }
}
