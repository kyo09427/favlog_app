import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:favlog_app/domain/models/product.dart';
import 'package:favlog_app/domain/models/review.dart';
import 'package:favlog_app/domain/models/profile.dart';
import 'package:favlog_app/presentation/screens/edit_review_screen.dart';
import 'package:favlog_app/data/repositories/supabase_auth_repository.dart';
import 'package:favlog_app/core/providers/profile_providers.dart';

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

class _ReviewItemState extends ConsumerState<ReviewItem> {
  bool _isLongPressed = false;
  Profile? _userProfile;
  bool _isLoadingProfile = true;

  @override
  void initState() {
    super.initState();
    _loadUserProfile();
  }

  Future<void> _loadUserProfile() async {
    try {
      final profileRepository = ref.read(profileRepositoryProvider);
      final profile = await profileRepository.fetchProfile(widget.review.userId);
      if (mounted) {
        setState(() {
          _userProfile = profile;
          _isLoadingProfile = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoadingProfile = false;
        });
      }
    }
  }

  Widget _buildRatingStars() {
    final theme = Theme.of(context);
    final rating = widget.review.rating;
    const calmGreen = Color(0xFF22A06B);

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: List.generate(5, (starIndex) {
        final starPosition = starIndex + 1;

        IconData icon;
        Color color;

        if (rating >= starPosition) {
          icon = Icons.star;
          color = calmGreen;
        } else if (rating >= starPosition - 0.5) {
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

    if (result == true && widget.onReviewUpdated != null) {
      widget.onReviewUpdated!();
    }
  }

  Widget _buildUserAvatar() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    if (_isLoadingProfile) {
      return CircleAvatar(
        radius: 20,
        backgroundColor: isDark ? Colors.grey[700] : Colors.grey[300],
        child: const SizedBox(
          width: 16,
          height: 16,
          child: CircularProgressIndicator(strokeWidth: 2),
        ),
      );
    }

    if (_userProfile?.avatarUrl != null && _userProfile!.avatarUrl!.isNotEmpty) {
      return CircleAvatar(
        radius: 20,
        backgroundColor: isDark ? Colors.grey[700] : Colors.grey[300],
        backgroundImage: CachedNetworkImageProvider(_userProfile!.avatarUrl!),
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
  }

  String _getDisplayName() {
    final currentUserId = ref.read(authRepositoryProvider).getCurrentUser()?.id;
    final isOwner = currentUserId != null && currentUserId == widget.review.userId;
    
    if (isOwner) {
      return 'あなた';
    }
    
    if (_isLoadingProfile) {
      return '読み込み中...';
    }
    
    return _userProfile?.username ?? 'レビュアー';
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final reviewText = widget.review.reviewText.trim();
    final currentUserId = ref.read(authRepositoryProvider).getCurrentUser()?.id;
    final isOwner = currentUserId != null && currentUserId == widget.review.userId;
    final isDark = theme.brightness == Brightness.dark;

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
        padding: const EdgeInsets.symmetric(vertical: 4.0, horizontal: 0.0),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(8),
          color: _isLongPressed
              ? (isDark ? Colors.white10 : Colors.grey.shade200)
              : Colors.transparent,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 上部: アバター + ユーザー名 + 相対時間
            Row(
              children: [
                _buildUserAvatar(),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _getDisplayName(),
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
                      Icons.edit_outlined,
                      size: 20,
                      color: isDark ? Colors.grey[400] : Colors.grey[600],
                    ),
                    onPressed: _handleEdit,
                    tooltip: '編集',
                  ),
              ],
            ),
            const SizedBox(height: 8),
            // 星評価 + 数値
            Row(
              children: [
                _buildRatingStars(),
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
            // アクション (いいね / コメント) ※数値は現状ダミー
            Row(
              children: [
                InkWell(
                  borderRadius: BorderRadius.circular(999),
                  onTap: () {
                    // TODO: いいね機能を実装する場合はここ
                  },
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 4,
                      vertical: 4,
                    ),
                    child: Row(
                      children: [
                        Icon(
                          Icons.favorite_border,
                          size: 18,
                          color: isDark ? Colors.white : Colors.black,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          '0',
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
                  onTap: () {
                    // TODO: コメント機能を実装する場合はここ
                  },
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 4,
                      vertical: 4,
                    ),
                    child: Row(
                      children: [
                        Icon(
                          Icons.chat_bubble_outline,
                          size: 18,
                          color: isDark ? Colors.white : Colors.black,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          '0',
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
            if (isOwner && _isLongPressed)
              Padding(
                padding: const EdgeInsets.only(top: 8.0),
                child: Text(
                  '長押しまたは編集ボタンで編集',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: const Color(0xFF22A06B),
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