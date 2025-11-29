import 'package:uuid/uuid.dart';

class Review {
  final String id;
  final DateTime createdAt;
  final String userId;
  final String productId;
  final String reviewText;
  final double rating; // Changed from int to double

  Review({
    String? id,
    DateTime? createdAt,
    required this.userId,
    required this.productId,
    required this.reviewText,
    required this.rating, // Type is now double
  })  : id = id ?? const Uuid().v4(),
        createdAt = createdAt ?? DateTime.now();

  factory Review.empty() {
    return Review(
      id: const Uuid().v4(), // Generate a new ID for empty review
      createdAt: DateTime.now(),
      userId: '', // Empty user ID
      productId: '', // Empty product ID
      reviewText: '', // Empty review text
      rating: 3.0, // Default rating within valid range (1.0-5.0)
    );
  }

  factory Review.fromJson(Map<String, dynamic> json) {
    return Review(
      id: json['id'] as String,
      createdAt: DateTime.parse(json['created_at'] as String),
      userId: json['user_id'] as String,
      productId: json['product_id'] as String,
      reviewText: json['review_text'] as String,
      rating: (json['rating'] as num).toDouble(), // Changed from int to double parsing
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
    double? rating, // Changed from int to double
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