import '../models/review.dart';

abstract class ReviewRepository {
  Future<List<Review>> getReviews({String? category});
  Future<List<Review>> getReviewsByProductId(String productId); // 新しいメソッドを追加
  Future<void> createReview(Review review);
  Future<void> updateReview(Review review);
  Future<void> deleteReview(String reviewId); // Added delete functionality
}