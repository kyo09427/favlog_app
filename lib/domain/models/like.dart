class Like {
  final String id;
  final DateTime createdAt;
  final String userId;
  final String reviewId;

  Like({
    required this.id,
    required this.createdAt,
    required this.userId,
    required this.reviewId,
  });

  factory Like.fromJson(Map<String, dynamic> json) {
    return Like(
      id: json['id'] as String,
      createdAt: DateTime.parse(json['created_at'] as String),
      userId: json['user_id'] as String,
      reviewId: json['review_id'] as String,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'created_at': createdAt.toIso8601String(),
      'user_id': userId,
      'review_id': reviewId,
    };
  }
}