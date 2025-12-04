abstract class LikeRepository {
  Future<void> addLike(String reviewId);
  Future<void> removeLike(String reviewId);
  Future<bool> hasUserLiked(String reviewId, String userId);
  Future<Map<String, int>> getLikeCounts(List<String> reviewIds);
  Future<List<String>> getUserLikedReviewIds(String userId, List<String> reviewIds);
}