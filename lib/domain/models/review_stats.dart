class ReviewStats {
  final String reviewId;
  final int likeCount;
  final int commentCount;

  ReviewStats({
    required this.reviewId,
    required this.likeCount,
    required this.commentCount,
  });

  factory ReviewStats.fromMap(Map<String, dynamic> map) {
    return ReviewStats(
      reviewId: map['review_id'] as String,
      likeCount: map['like_count'] as int? ?? 0,
      commentCount: map['comment_count'] as int? ?? 0,
    );
  }

  static ReviewStats empty(String reviewId) {
    return ReviewStats(
      reviewId: reviewId,
      likeCount: 0,
      commentCount: 0,
    );
  }
}