import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:favlog_app/domain/models/product.dart'; // Still need Product model for displayedProduct type
import 'package:favlog_app/presentation/widgets/review_item.dart';
import 'package:favlog_app/presentation/screens/add_review_to_product_screen.dart';
import 'package:favlog_app/presentation/providers/review_detail_controller.dart';
import 'package:favlog_app/domain/models/review.dart'; // Import Review model
import 'package:shimmer/shimmer.dart';
import 'package:favlog_app/data/repositories/supabase_auth_repository.dart'; // Add this import

class ReviewDetailScreen extends ConsumerWidget {
  final String productId; // Now takes productId

  const ReviewDetailScreen({super.key, required this.productId}); // Updated constructor

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final reviewDetailState = ref.watch(reviewDetailControllerProvider(productId)); // Pass productId
    final reviewDetailController = ref.read(reviewDetailControllerProvider(productId).notifier); // Pass productId

    // Use currentProduct from state for display
    final displayedProduct = reviewDetailState.currentProduct;

    if (displayedProduct.id == Product.empty().id) { // Check for empty placeholder product
      return Scaffold(
        appBar: AppBar(title: const Text('詳細')),
        body: Center(child: reviewDetailState.isLoading ? const CircularProgressIndicator() : Text('製品の読み込みエラー: ${reviewDetailState.error ?? "不明なエラー"}')),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(displayedProduct.name), // Use displayedProduct
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (displayedProduct.imageUrl != null) // Use displayedProduct
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 8.0),
                child: CachedNetworkImage(
                  imageUrl: displayedProduct.imageUrl!, // Use displayedProduct
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
              displayedProduct.name, // Use displayedProduct
              style: Theme.of(context).textTheme.headlineMedium,
            ),
            if (displayedProduct.url != null) // Use displayedProduct
              Padding(
                padding: const EdgeInsets.only(top: 4.0),
                child: Text(
                  'URL: ${displayedProduct.url}', // Use displayedProduct
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: Colors.blue),
                ),
              ),
            if (displayedProduct.category != null) // Use displayedProduct
              Padding(
                padding: const EdgeInsets.only(top: 4.0),
                child: Text(
                  'カテゴリ: ${displayedProduct.category}', // Use displayedProduct
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
              ),
            if (displayedProduct.subcategory != null) // Use displayedProduct
              Padding(
                padding: const EdgeInsets.only(top: 4.0),
                child: Text(
                  'サブカテゴリ: ${displayedProduct.subcategory}', // Use displayedProduct
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
              ),
            const SizedBox(height: 20),
            reviewDetailState.isLoading && displayedProduct.id != Product.empty().id // Only show indicator if not initial load
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
                                  product: displayedProduct, // Pass displayedProduct
                                  review: review,
                                  onReviewEdited: () {
                                    reviewDetailController.refreshAll(); // Refresh all
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
              builder: (context) => AddReviewToProductScreen(product: displayedProduct), // Use displayedProduct
            ),
          );
          // Refresh products and reviews after returning
          reviewDetailController.refreshAll();
        },
        child: const Icon(Icons.add),
      ),
    );
  }
}