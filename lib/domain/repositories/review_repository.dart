import '../models/review.dart';

abstract class ReviewRepository {
  Future<List<Review>> getReviews({String? category});
  Future<List<Review>> getReviewsByProductId(String productId);
  Future<Map<String, Review>> getLatestReviewsByProductIds(List<String> productIds);
  Future<Review> getReviewById(String reviewId);
  Future<void> createReview(Review review);
  Future<void> updateReview(Review review);
  Future<void> deleteReview(String reviewId);
}