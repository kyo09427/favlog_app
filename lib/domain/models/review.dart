import 'package:uuid/uuid.dart';

class Review {
  final String id;
  final DateTime createdAt;
  final String userId;
  final String productId;
  final String reviewText;
  final double rating;

  Review({
    String? id,
    DateTime? createdAt,
    required this.userId,
    required this.productId,
    required this.reviewText,
    required this.rating,
  })  : id = id ?? const Uuid().v4(),
        // 修正: 明示的にUTCとして保存
        createdAt = createdAt ?? DateTime.now().toUtc();

  factory Review.empty() {
    return Review(
      id: const Uuid().v4(),
      createdAt: DateTime.now().toUtc(), // 修正: UTC指定
      userId: '',
      productId: '',
      reviewText: '',
      rating: 3.0,
    );
  }

  factory Review.fromJson(Map<String, dynamic> json) {
    return Review(
      id: json['id'] as String,
      // 修正: parseUtcを使用してUTCとして明示的にパース
      createdAt: DateTime.parse(json['created_at'] as String).toUtc(),
      userId: json['user_id'] as String,
      productId: json['product_id'] as String,
      reviewText: json['review_text'] as String,
      rating: (json['rating'] as num).toDouble(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      // 修正: toUtcを追加してUTCとして保存
      'created_at': createdAt.toUtc().toIso8601String(),
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
    double? rating,
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