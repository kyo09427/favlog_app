import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:favlog_app/domain/models/product.dart';
import 'package:favlog_app/presentation/widgets/review_item.dart';
import 'package:favlog_app/presentation/screens/add_review_to_product_screen.dart';
import 'package:favlog_app/presentation/providers/review_detail_controller.dart';
import 'package:favlog_app/domain/models/review.dart'; // Import Review model
import 'package:shimmer/shimmer.dart';
// ... (imports)

class ReviewDetailScreen extends ConsumerWidget {
  final Product product;

  const ReviewDetailScreen({super.key, required this.product});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final reviewDetailState = ref.watch(reviewDetailControllerProvider(product));
    final reviewDetailController = ref.read(reviewDetailControllerProvider(product).notifier);

    return Scaffold(
      appBar: AppBar(
        title: Text(product.name),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (product.imageUrl != null)
              Padding(                padding: const EdgeInsets.symmetric(vertical: 8.0),
                child: CachedNetworkImage(
                  imageUrl: product.imageUrl!,
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
                  errorWidget: (context, url, error) => const Icon(Icons.broken_image, size: 200),
                ),
              ),
            Text(
              product.name,
              style: Theme.of(context).textTheme.headlineMedium,
            ),
            if (product.url != null)
              Padding(
                padding: const EdgeInsets.only(top: 4.0),
                child: Text(
                  'URL: ${product.url}',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: Colors.blue),
                ),
              ),
            if (product.category != null)
              Padding(
                padding: const EdgeInsets.only(top: 4.0),
                child: Text(
                  'カテゴリ: ${product.category}',
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
              ),
            if (product.subcategory != null)
              Padding(
                padding: const EdgeInsets.only(top: 4.0),
                child: Text(
                  'サブカテゴリ: ${product.subcategory}',
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
              ),
            const SizedBox(height: 20),
            reviewDetailState.isLoading
                ? const Center(child: CircularProgressIndicator())
                : reviewDetailState.error != null
                    ? Center(child: Text('レビューの読み込みエラー: ${reviewDetailState.error}'))
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
                                return ReviewItem(
                                  product: product,
                                  review: review,
                                  onReviewEdited: () {
                                    reviewDetailController.refreshReviews();
                                  },
                                );
                              }).toList(),
                            ],
                          ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () async {
          await Navigator.of(context).push(
            MaterialPageRoute(
              builder: (context) => AddReviewToProductScreen(product: product),
            ),
          );
          // Refresh reviews after returning from AddReviewToProductScreen
          reviewDetailController.refreshReviews();
        },
        child: const Icon(Icons.add),
      ),
    );
  }
}