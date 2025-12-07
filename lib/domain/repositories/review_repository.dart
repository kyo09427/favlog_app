import '../models/product_stats.dart';
import '../models/review.dart';

abstract class ReviewRepository {
  Future<List<ProductStats>> getProductStats(List<String> productIds);
  Future<List<Review>> getReviews({String? category, String? visibility, String? currentUserId});
  Future<List<Review>> getReviewsByProductId(String productId);
  Future<List<Review>> getReviewsByUserId(String userId);
  Future<Map<String, Review>> getLatestReviewsByProductIds(List<String> productIds, {String? currentUserId});
  Future<Review> getReviewById(String reviewId);
  Future<void> createReview(Review review);
  Future<void> updateReview(Review review);
  Future<void> deleteReview(String reviewId);
}
