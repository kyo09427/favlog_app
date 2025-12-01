import '../models/review.dart';

abstract class ReviewRepository {
  Future<List<Review>> getReviews({String? category});
  Future<List<Review>> getReviewsByProductId(String productId);
  Future<Review> getReviewById(String reviewId); // 新しいメソッドを追加
  Future<void> createReview(Review review);
  Future<void> deleteReview(String reviewId); // Added delete functionality
}