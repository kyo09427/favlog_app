import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:favlog_app/domain/models/product.dart';
import 'package:favlog_app/presentation/widgets/review_item.dart';
import 'package:favlog_app/presentation/screens/add_review_to_product_screen.dart';
import 'package:favlog_app/presentation/providers/review_detail_controller.dart';
import 'package:favlog_app/domain/models/review.dart';
import 'package:shimmer/shimmer.dart';
import 'package:favlog_app/data/repositories/supabase_auth_repository.dart';
import 'package:favlog_app/data/repositories/supabase_review_repository.dart';

class ReviewDetailScreen extends ConsumerWidget {
  final String productId;

  const ReviewDetailScreen({super.key, required this.productId});

  Future<void> _deleteReview(
    BuildContext context,
    WidgetRef ref,
    Review review,
  ) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('レビューの削除'),
        content: const Text('このレビューを削除してもよろしいですか？\nこの操作は取り消せません。'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('キャンセル'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: TextButton.styleFrom(
              foregroundColor: Colors.red,
            ),
            child: const Text('削除'),
          ),
        ],
      ),
    );

    if (confirmed != true || !context.mounted) return;

    try {
      final reviewRepository = ref.read(reviewRepositoryProvider);
      await reviewRepository.deleteReview(review.id);

      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('レビューを削除しました')),
        );
        
        // レビューリストを更新
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

    if (displayedProduct.id == Product.empty().id) {
      return Scaffold(
        appBar: AppBar(title: const Text('詳細')),
        body: Center(
          child: reviewDetailState.isLoading
              ? const CircularProgressIndicator()
              : Text('製品の読み込みエラー: ${reviewDetailState.error ?? "不明なエラー"}'),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(displayedProduct.name),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () => reviewDetailController.refreshAll(),
            tooltip: '更新',
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () => reviewDetailController.refreshAll(),
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (displayedProduct.imageUrl != null)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 8.0),
                  child: CachedNetworkImage(
                    imageUrl: displayedProduct.imageUrl!,
                    height: 200,
                    width: double.infinity,
                    fit: BoxFit.cover,
                    placeholder: (context, url) => Shimmer.fromColors(
                      baseColor: Colors.grey[300]!,
                      highlightColor: Colors.grey[100]!,
                      child: Container(
                        height: 200,
                        width: double.infinity,
                        color: Colors.white,
                      ),
                    ),
                    errorWidget: (context, url, error) =>
                        const Icon(Icons.broken_image, size: 200),
                  ),
                ),
              Text(
                displayedProduct.name,
                style: Theme.of(context).textTheme.headlineMedium,
              ),
              if (displayedProduct.url != null)
                Padding(
                  padding: const EdgeInsets.only(top: 4.0),
                  child: Text(
                    'URL: ${displayedProduct.url}',
                    style: Theme.of(context)
                        .textTheme
                        .bodyMedium
                        ?.copyWith(color: Colors.blue),
                  ),
                ),
              if (displayedProduct.category != null)
                Padding(
                  padding: const EdgeInsets.only(top: 4.0),
                  child: Text(
                    'カテゴリ: ${displayedProduct.category}',
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                ),
              if (displayedProduct.subcategory != null)
                Padding(
                  padding: const EdgeInsets.only(top: 4.0),
                  child: Text(
                    'サブカテゴリ: ${displayedProduct.subcategory}',
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                ),
              const SizedBox(height: 20),
              reviewDetailState.isLoading &&
                      displayedProduct.id != Product.empty().id
                  ? const Center(child: CircularProgressIndicator())
                  : reviewDetailState.error != null
                      ? Center(
                          child: Text(
                              'レビューの読み込みエラー: ${reviewDetailState.error}'))
                      : reviewDetailState.reviews.isEmpty
                          ? const Text('まだレビューがありません。')
                          : Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'レビュー (${reviewDetailState.reviews.length}件):',
                                  style: Theme.of(context).textTheme.headlineSmall,
                                ),
                                const SizedBox(height: 10),
                                ...reviewDetailState.reviews.map((review) {
                                  final isOwner = currentUserId != null &&
                                      currentUserId == review.userId;
                                  return Card(
                                    margin: const EdgeInsets.only(bottom: 8),
                                    child: Column(
                                      children: [
                                        ReviewItem(
                                          product: displayedProduct,
                                          review: review,
                                        ),
                                        if (isOwner)
                                          Padding(
                                            padding: const EdgeInsets.symmetric(
                                              horizontal: 8.0,
                                              vertical: 4.0,
                                            ),
                                            child: Row(
                                              mainAxisAlignment:
                                                  MainAxisAlignment.end,
                                              children: [
                                                TextButton.icon(
                                                  onPressed: () => _deleteReview(
                                                    context,
                                                    ref,
                                                    review,
                                                  ),
                                                  icon: const Icon(
                                                    Icons.delete_outline,
                                                    size: 18,
                                                  ),
                                                  label: const Text('削除'),
                                                  style: TextButton.styleFrom(
                                                    foregroundColor: Colors.red,
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ),
                                      ],
                                    ),
                                  );
                                }).toList(),
                              ],
                            ),
            ],
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () async {
          await Navigator.of(context).push(
            MaterialPageRoute(
              builder: (context) =>
                  AddReviewToProductScreen(product: displayedProduct),
            ),
          );
          reviewDetailController.refreshAll();
        },
        child: const Icon(Icons.add),
      ),
    );
  }
}