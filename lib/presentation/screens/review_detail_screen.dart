import 'package:go_router/go_router.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shimmer/shimmer.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../domain/models/product.dart';
import '../widgets/review_item.dart';
import 'add_review_to_product_screen.dart';
import 'comment_screen.dart';
import '../providers/review_detail_controller.dart';
import '../../data/repositories/supabase_auth_repository.dart';
import '../../data/repositories/supabase_review_repository.dart';

class ReviewDetailScreen extends ConsumerWidget {
  final String productId;

  const ReviewDetailScreen({super.key, required this.productId});

  static const Color _backgroundLight = Color(0xFFF6F8F6);
  static const Color _backgroundDark = Color(0xFF102216);
  static const Color _primary = Color(0xFF22A06B);

  Future<void> _deleteReview(
    BuildContext context,
    WidgetRef ref,
    String reviewId,
  ) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('レビューの削除'),
        content: const Text('このレビューを削除してもよろしいですか?\nこの操作は取り消せません。'),
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

    if (confirmed != true || !context.mounted) return;

    try {
      final reviewRepository = ref.read(reviewRepositoryProvider);
      await reviewRepository.deleteReview(reviewId);

      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('レビューを削除しました')),
        );
        final controller = ref.read(reviewDetailControllerProvider(productId).notifier);
        await controller.refreshAll();
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('削除に失敗しました: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final reviewDetailState = ref.watch(reviewDetailControllerProvider(productId));
    final reviewDetailController = ref.read(reviewDetailControllerProvider(productId).notifier);
    final currentUserId = ref.read(authRepositoryProvider).getCurrentUser()?.id;

    final displayedProduct = reviewDetailState.currentProduct;
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final backgroundColor = isDark ? _backgroundDark : _backgroundLight;

    if (displayedProduct.id == Product.empty().id) {
      return Scaffold(
        backgroundColor: backgroundColor,
        body: Center(
          child: reviewDetailState.isLoading
              ? const CircularProgressIndicator()
              : Text('製品の読み込みエラー: ${reviewDetailState.error ?? "不明なエラー"}'),
        ),
      );
    }

    final reviewsWithStats = reviewDetailState.reviewsWithStats;
    final reviewCount = reviewsWithStats.length;
    final averageRating = reviewCount == 0
        ? 0.0
        : reviewsWithStats
                .map((rws) => rws.review.rating)
                .fold<double>(0, (sum, r) => sum + r) /
            reviewCount;

    return Scaffold(
      backgroundColor: backgroundColor,
      body: SafeArea(
        child: Container(
          color: backgroundColor,
          child: Column(
            children: [
              // ヘッダー
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                decoration: BoxDecoration(
                  color: backgroundColor,
                  border: Border(
                    bottom: BorderSide(color: Colors.white.withOpacity(0.1)),
                  ),
                ),
                child: Row(
                  children: [
                    SizedBox(
                      width: 40,
                      height: 40,
                      child: IconButton(
                        onPressed: () => context.pop(),
                        icon: Icon(
                          Icons.arrow_back_ios_new_rounded,
                          size: 20,
                          color: isDark ? Colors.white : Colors.black,
                        ),
                      ),
                    ),
                    Expanded(
                      child: Text(
                        displayedProduct.name,
                        textAlign: TextAlign.center,
                        overflow: TextOverflow.ellipsis,
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: isDark ? Colors.white : Colors.black,
                        ),
                      ),
                    ),
                    const SizedBox(width: 40),
                  ],
                ),
              ),

              // 本文
              Expanded(
                child: RefreshIndicator(
                  onRefresh: () => reviewDetailController.refreshAll(),
                  child: ListView(
                    physics: const AlwaysScrollableScrollPhysics(),
                    children: [
                      // 店舗情報
                      Padding(
                        padding: const EdgeInsets.all(16),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            ClipRRect(
                              borderRadius: BorderRadius.circular(12),
                              child: SizedBox(
                                width: 64,
                                height: 64,
                                child: displayedProduct.imageUrl != null &&
                                        displayedProduct.imageUrl!.isNotEmpty
                                    ? CachedNetworkImage(
                                        imageUrl: displayedProduct.imageUrl!,
                                        fit: BoxFit.cover,
                                        placeholder: (context, url) => Shimmer.fromColors(
                                          baseColor: isDark ? Colors.grey[800]! : Colors.grey[300]!,
                                          highlightColor: isDark ? Colors.grey[700]! : Colors.grey[100]!,
                                          child: Container(color: Colors.white),
                                        ),
                                        errorWidget: (context, url, error) => Container(
                                          color: isDark ? Colors.grey[900] : Colors.grey[200],
                                          child: Icon(
                                            Icons.image_not_supported_outlined,
                                            color: isDark ? Colors.grey[700] : Colors.grey[500],
                                          ),
                                        ),
                                      )
                                    : Container(
                                        color: isDark ? Colors.grey[900] : Colors.grey[200],
                                        child: const Icon(Icons.image, size: 24),
                                      ),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    displayedProduct.name,
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis,
                                    style: theme.textTheme.titleMedium?.copyWith(
                                      fontWeight: FontWeight.bold,
                                      color: isDark ? Colors.white : Colors.black,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  _UrlLink(url: displayedProduct.url),
                                  const SizedBox(height: 6),
                                  Row(
                                    crossAxisAlignment: CrossAxisAlignment.center,
                                    children: [
                                      const Icon(Icons.star, size: 16, color: _primary),
                                      const SizedBox(width: 4),
                                      Text(
                                        reviewCount == 0 ? '-' : averageRating.toStringAsFixed(1),
                                        style: theme.textTheme.bodySmall?.copyWith(
                                          fontWeight: FontWeight.bold,
                                          color: isDark ? Colors.white : Colors.black,
                                        ),
                                      ),
                                      const SizedBox(width: 4),
                                      Text(
                                        '($reviewCount)',
                                        style: theme.textTheme.bodySmall?.copyWith(
                                          color: isDark ? Colors.grey[400] : Colors.grey[600],
                                        ),
                                      ),
                                      Container(
                                        width: 1,
                                        height: 12,
                                        margin: const EdgeInsets.symmetric(horizontal: 8),
                                        color: isDark ? Colors.grey[600] : Colors.grey[300],
                                      ),
                                      Text(
                                        displayedProduct.category ?? '',
                                        style: theme.textTheme.bodySmall?.copyWith(
                                          color: isDark ? Colors.grey[400] : Colors.grey[600],
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 6),
                                  Row(
                                    children: [
                                      Expanded(
                                        child: Row(
                                          children: [
                                            if (displayedProduct.category != null)
                                              Flexible(
                                                child: Text(
                                                  '#${displayedProduct.category}',
                                                  style: theme.textTheme.bodySmall?.copyWith(
                                                    color: _primary,
                                                    fontWeight: FontWeight.w500,
                                                  ),
                                                  overflow: TextOverflow.ellipsis,
                                                ),
                                              ),
                                            if (displayedProduct.subcategory != null &&
                                                displayedProduct.subcategory!.isNotEmpty) ...[
                                              const SizedBox(width: 6),
                                              Flexible(
                                                child: Text(
                                                  '#${displayedProduct.subcategory}',
                                                  style: theme.textTheme.bodySmall?.copyWith(
                                                    color: _primary,
                                                    fontWeight: FontWeight.w500,
                                                  ),
                                                  overflow: TextOverflow.ellipsis,
                                                ),
                                              ),
                                            ],
                                          ],
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),

                      // タブ
                      Container(
                        decoration: BoxDecoration(
                          border: Border(
                            bottom: BorderSide(color: Colors.white.withOpacity(0.1)),
                          ),
                        ),
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        child: Row(
                          children: [
                            _SortTab(
                              label: 'すべて',
                              isActive: reviewDetailState.sortType == ReviewSortType.all,
                              isDark: isDark,
                              onTap: () => reviewDetailController.changeSortType(ReviewSortType.all),
                            ),
                            _SortTab(
                              label: '新しい順',
                              isActive: reviewDetailState.sortType == ReviewSortType.newest,
                              isDark: isDark,
                              onTap: () => reviewDetailController.changeSortType(ReviewSortType.newest),
                            ),
                            _SortTab(
                              label: '高評価順',
                              isActive: reviewDetailState.sortType == ReviewSortType.highRated,
                              isDark: isDark,
                              onTap: () => reviewDetailController.changeSortType(ReviewSortType.highRated),
                            ),
                          ],
                        ),
                      ),

                      // レビュー一覧
                      if (reviewDetailState.isLoading)
                        const Padding(
                          padding: EdgeInsets.all(24.0),
                          child: Center(child: CircularProgressIndicator()),
                        )
                      else if (reviewDetailState.error != null)
                        Padding(
                          padding: const EdgeInsets.all(24.0),
                          child: Center(
                            child: Text(
                              'レビューの読み込みエラー: ${reviewDetailState.error}',
                              textAlign: TextAlign.center,
                            ),
                          ),
                        )
                      else if (reviewsWithStats.isEmpty)
                        const Padding(
                          padding: EdgeInsets.all(24.0),
                          child: Text('まだレビューがありません。'),
                        )
                      else
                        Column(
                          children: reviewsWithStats.map((reviewWithStats) {
                            final review = reviewWithStats.review;
                            final stats = reviewWithStats.stats;
                            final isLiked = reviewWithStats.isLikedByCurrentUser;
                            final isOwner = currentUserId != null && currentUserId == review.userId;

                            return Container(
                              decoration: BoxDecoration(
                                border: Border(
                                  bottom: BorderSide(color: Colors.white.withOpacity(0.1)),
                                ),
                              ),
                              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                              child: Column(
                                children: [
                                  ReviewItem(
                                    product: displayedProduct,
                                    review: review,
                                    stats: stats,
                                    isLiked: isLiked,
                                    onLikeToggle: () => reviewDetailController.toggleLike(review.id),
                                    onCommentTap: () {
                                      context.push(
                                        '/comment', // 新しいパスを定義する必要がある
                                        extra: {
                                          'reviewId': review.id,
                                          'productName': displayedProduct.name,
                                        },
                                      ).then((_) => reviewDetailController.refreshAll());
                                    },
                                    onReviewUpdated: () => reviewDetailController.refreshAll(),
                                  ),
                                  if (isOwner)
                                    Align(
                                      alignment: Alignment.centerRight,
                                      child: TextButton.icon(
                                        onPressed: () => _deleteReview(context, ref, review.id),
                                        icon: const Icon(Icons.delete_outline, size: 18),
                                        label: const Text('削除'),
                                        style: TextButton.styleFrom(foregroundColor: Colors.red),
                                      ),
                                    ),
                                ],
                              ),
                            );
                          }).toList(),
                        ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: _primary,
        onPressed: () async {
          await context.push(
            '/add-review-to-product', // 新しいパスを定義する必要がある
            extra: displayedProduct, // Productオブジェクトをextraとして渡す
          );
          reviewDetailController.refreshAll();
        },
        child: const Icon(Icons.add),
      ),
    );
  }
}

class _UrlLink extends StatelessWidget {
  final String? url;

  const _UrlLink({this.url});

  Future<void> _launchUrl(BuildContext context, String urlString) async {
    final uri = Uri.tryParse(urlString);
    if (uri == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('無効なURLです: $urlString')),
      );
      return;
    }

    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('このURLを開けませんでした: $urlString')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    if (url == null || url!.isEmpty) {
      return const SizedBox.shrink();
    }

    return InkWell(
      onTap: () => _launchUrl(context, url!),
      borderRadius: BorderRadius.circular(4),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 2.0),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Icon(Icons.link, size: 16, color: Colors.blue),
            const SizedBox(width: 6),
            Flexible(
              child: Text(
                url!,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: Colors.blue,
                      decoration: TextDecoration.underline,
                      decorationColor: Colors.blue.withOpacity(0.7),
                    ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SortTab extends StatelessWidget {
  const _SortTab({
    required this.label,
    required this.isActive,
    required this.isDark,
    required this.onTap,
  });

  final String label;
  final bool isActive;
  final bool isDark;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final baseColor = isDark ? Colors.grey[400]! : Colors.grey[600]!;

    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.only(right: 16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 4),
              child: Text(
                label,
                style: theme.textTheme.bodySmall?.copyWith(
                  fontWeight: isActive ? FontWeight.bold : FontWeight.w500,
                  color: isActive ? const Color(0xFF22A06B) : baseColor,
                ),
              ),
            ),
            AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              height: 2,
              width: 36,
              decoration: BoxDecoration(
                color: isActive ? const Color(0xFF22A06B) : Colors.transparent,
                borderRadius: BorderRadius.circular(999),
              ),
            ),
          ],
        ),
      ),
    );
  }
}