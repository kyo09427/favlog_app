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
        // 修正: 明示的にUTCとして保存
        createdAt = createdAt ?? DateTime.now().toUtc();

  factory Comment.fromJson(Map<String, dynamic> json) {
    return Comment(
      id: json['id'] as String,
      // 修正: parseUtcを使用してUTCとして明示的にパース
      createdAt: DateTime.parse(json['created_at'] as String).toUtc(),
      userId: json['user_id'] as String,
      reviewId: json['review_id'] as String,
      commentText: json['comment_text'] as String,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      // 修正: toUtcを追加してUTCとして保存
      'created_at': createdAt.toUtc().toIso8601String(),
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