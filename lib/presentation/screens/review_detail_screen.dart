import 'package:go_router/go_router.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shimmer/shimmer.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../domain/models/product.dart';
import '../widgets/review_item.dart';

import '../providers/review_detail_controller.dart';

import '../../data/repositories/supabase_product_repository.dart';
import '../../data/repositories/supabase_review_repository.dart';

class ReviewDetailScreen extends ConsumerStatefulWidget {
  final String productId;

  const ReviewDetailScreen({super.key, required this.productId});

  @override
  ConsumerState<ReviewDetailScreen> createState() => _ReviewDetailScreenState();
}

class _ReviewDetailScreenState extends ConsumerState<ReviewDetailScreen> {
  static const Color _backgroundLight = Color(0xFFF6F8F6);
  static const Color _backgroundDark = Color(0xFF102216);
  static const Color _primary = Color(0xFF22A06B);

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // 画面に戻ってきたときにデータをリフレッシュ
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        ref.read(reviewDetailControllerProvider(widget.productId).notifier).refreshAll();
      }
    });
  }

  Future<void> _showProductMenu(
      BuildContext context, WidgetRef ref, Product product) async {
    final theme = Theme.of(context);
    await showModalBottomSheet(
      context: context,
      backgroundColor: theme.brightness == Brightness.dark
          ? const Color(0xFF1C1C1E)
          : Colors.white,
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
                leading: const Icon(Icons.edit_outlined, color: _primary),
                title: const Text('編集する'),
                onTap: () async {
                  context.pop(); // Close the bottom sheet
                  final result = await context.push('/edit-product', extra: product);
                  if (result == true && mounted) {
                    ref
                        .read(reviewDetailControllerProvider(product.id)
                            .notifier)
                        .refreshAll();
                  }
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

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

        // 最後のレビューが削除されたかチェック
        final reviews = ref.read(reviewDetailControllerProvider(widget.productId))
            .reviewsWithStats;

        // deleteReviewが成功した時点では、Stateのリストの長さはまだ1残っている
        if (reviews.length == 1) {
          final productRepository = ref.read(productRepositoryProvider);
          final product = ref.read(reviewDetailControllerProvider(widget.productId)).currentProduct;

          // 関連画像をStorageから削除
          if (product.imageUrl != null) {
            await productRepository.deleteProductImage(product.imageUrl!);
          }
          // 商品をDBから削除
          await productRepository.deleteProduct(product.id);

          if (context.mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('最後のレビューが削除されたため、商品も自動的に削除されました。')),
            );
            context.pop(); // 前の画面に戻る
          }
        } else {
          final controller = ref.read(reviewDetailControllerProvider(widget.productId).notifier);
          await controller.refreshAll();
        }
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
  Widget build(BuildContext context) {
    final reviewDetailState = ref.watch(reviewDetailControllerProvider(widget.productId));
    final reviewDetailController = ref.read(reviewDetailControllerProvider(widget.productId).notifier);


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
                    bottom: BorderSide(color: Colors.white.withValues(alpha: 0.1)),
                  ),
                ),
                child: Row(
                  children: [
                    SizedBox(
                      width: 40,
                      height: 40,
                      child: IconButton(
                        onPressed: () {
                          if (context.canPop()) {
                            context.pop();
                          } else {
                            context.go('/');
                          }
                        },
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
                                            if (displayedProduct.subcategoryTags.isNotEmpty) ...[
                                              const SizedBox(width: 6),
                                              Flexible(
                                                child: Text(
                                                  '#${displayedProduct.subcategoryTags.first}',
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
                            SizedBox(
                              width: 40,
                              child: IconButton(
                                alignment: Alignment.topRight,
                                padding: const EdgeInsets.all(0),
                                icon: const Icon(Icons.more_vert),
                                onPressed: () {
                                  _showProductMenu(context, ref, displayedProduct);
                                },
                              ),
                            ),
                          ],
                        ),
                      ),

                      // タブ
                      Container(
                        decoration: BoxDecoration(
                          border: Border(
                            bottom: BorderSide(color: Colors.white.withValues(alpha: 0.1)),
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


                            return Container(
                              decoration: BoxDecoration(
                                border: Border(
                                  bottom: BorderSide(color: Colors.white.withValues(alpha: 0.1)),
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
                                      // コメント画面に遷移
                                      context.push('/review/${review.id}');
                                    },
                                    onReviewUpdated: () => reviewDetailController.refreshAll(),
                                    onDelete: () => _deleteReview(context, ref, review.id),
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
          final result = await context.push(
            '/add-review', // 遷移先を/add-reviewに変更
            extra: {'product': displayedProduct}, // extraの形式をMap<String, dynamic>に変更
          );
          if (result == true && mounted) {
            reviewDetailController.refreshAll();
          }
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
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('このURLを開けませんでした')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (url == null || url!.isEmpty) {
      return const SizedBox.shrink();
    }
    return InkWell(
      onTap: () => _launchUrl(context, url!),
      child: Text(
        url!,
        style: const TextStyle(
          color: Colors.blue,
          decoration: TextDecoration.underline,
        ),
        overflow: TextOverflow.ellipsis,
      ),
    );
  }
}

class _SortTab extends StatelessWidget {
  final String label;
  final bool isActive;
  final bool isDark;
  final VoidCallback onTap;

  const _SortTab({
    required this.label,
    required this.isActive,
    required this.isDark,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final activeColor = isDark ? Colors.white : Colors.black;
    final inactiveColor = isDark ? Colors.grey[400] : Colors.grey[600];

    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
        decoration: BoxDecoration(
          border: Border(
            bottom: BorderSide(
              color: isActive ? const Color(0xFF22A06B) : Colors.transparent,
              width: 2,
            ),
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: isActive ? activeColor : inactiveColor,
            fontWeight: isActive ? FontWeight.bold : FontWeight.normal,
          ),
        ),
      ),
    );
  }
}
