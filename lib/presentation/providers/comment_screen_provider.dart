import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../domain/models/product.dart';
import '../../domain/models/review.dart';
import '../../data/repositories/supabase_product_repository.dart';
import '../../data/repositories/supabase_review_repository.dart';

final reviewDetailsProvider = FutureProvider.family<({Review review, Product product}), String>((ref, reviewId) async {
  final reviewRepository = ref.watch(reviewRepositoryProvider);
  final productRepository = ref.watch(productRepositoryProvider);

  // Fetch review first to get productId
  final review = await reviewRepository.getReviewById(reviewId);
  // Then fetch product
  final product = await productRepository.getProductById(review.productId);
  
  return (review: review, product: product);
});
