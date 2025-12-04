import 'package:uuid/uuid.dart';

class Comment {
  final String id;
  final DateTime createdAt;
  final String userId;
  final String reviewId;
  final String commentText;

  Comment({
    String? id,
    DateTime? createdAt,
    required this.userId,
    required this.reviewId,
    required this.commentText,
  })  : id = id ?? const Uuid().v4(),
        createdAt = createdAt ?? DateTime.now();

  factory Comment.fromJson(Map<String, dynamic> json) {
    return Comment(
      id: json['id'] as String,
      createdAt: DateTime.parse(json['created_at'] as String),
      userId: json['user_id'] as String,
      reviewId: json['review_id'] as String,
      commentText: json['comment_text'] as String,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'created_at': createdAt.toIso8601String(),
      'user_id': userId,
      'review_id': reviewId,
      'comment_text': commentText,
    };
  }

  Comment copyWith({
    String? id,
    DateTime? createdAt,
    String? userId,
    String? reviewId,
    String? commentText,
  }) {
    return Comment(
      id: id ?? this.id,
      createdAt: createdAt ?? this.createdAt,
      userId: userId ?? this.userId,
      reviewId: reviewId ?? this.reviewId,
      commentText: commentText ?? this.commentText,
    );
  }
}