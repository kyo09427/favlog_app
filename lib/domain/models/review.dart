import 'package:uuid/uuid.dart';

class Review {
  final String id;
  final DateTime createdAt;
  final String userId;
  final String productId;
  final String reviewText;
  final int rating;

  Review({
    String? id,
    DateTime? createdAt,
    required this.userId,
    required this.productId,
    required this.reviewText,
    required this.rating,
  })  : id = id ?? const Uuid().v4(),
        createdAt = createdAt ?? DateTime.now();

  factory Review.fromJson(Map<String, dynamic> json) {
    return Review(
      id: json['id'] as String,
      createdAt: DateTime.parse(json['created_at'] as String),
      userId: json['user_id'] as String,
      productId: json['product_id'] as String,
      reviewText: json['review_text'] as String,
      rating: json['rating'] as int,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'created_at': createdAt.toIso8601String(),
      'user_id': userId,
      'product_id': productId,
      'review_text': reviewText,
      'rating': rating,
    };
  }

  Review copyWith({
    String? id,
    DateTime? createdAt,
    String? userId,
    String? productId,
    String? reviewText,
    int? rating,
  }) {
    return Review(
      id: id ?? this.id,
      createdAt: createdAt ?? this.createdAt,
      userId: userId ?? this.userId,
      productId: productId ?? this.productId,
      reviewText: reviewText ?? this.reviewText,
      rating: rating ?? this.rating,
    );
  }
}