import 'package:uuid/uuid.dart';

class Review {
  final String id;
  final DateTime createdAt;
  final String userId;
  final String productId;
  final String reviewText;
  final double rating;
  final List<String> imageUrls; // 複数画像のURL
  final List<String> subcategoryTags; // サブカテゴリのタグ
  final String visibility; // 公開範囲: 'public', 'friends', 'private'

  Review({
    String? id,
    DateTime? createdAt,
    required this.userId,
    required this.productId,
    required this.reviewText,
    required this.rating,
    List<String>? imageUrls,
    List<String>? subcategoryTags,
    String? visibility,
  })  : id = id ?? const Uuid().v4(),
        createdAt = createdAt ?? DateTime.now().toUtc(),
        imageUrls = imageUrls ?? [],
        subcategoryTags = subcategoryTags ?? [],
        visibility = visibility ?? 'public';

  factory Review.empty() {
    return Review(
      id: const Uuid().v4(),
      createdAt: DateTime.now().toUtc(),
      userId: '',
      productId: '',
      reviewText: '',
      rating: 3.0,
      imageUrls: [],
      subcategoryTags: [],
      visibility: 'public',
    );
  }

  factory Review.fromJson(Map<String, dynamic> json) {
    return Review(
      id: json['id'] as String,
      createdAt: DateTime.parse(json['created_at'] as String).toUtc(),
      userId: json['user_id'] as String,
      productId: json['product_id'] as String,
      reviewText: json['review_text'] as String,
      rating: (json['rating'] as num).toDouble(),
      imageUrls: json['image_urls'] != null
          ? List<String>.from(json['image_urls'] as List)
          : [],
      subcategoryTags: json['subcategory_tags'] != null
          ? List<String>.from(json['subcategory_tags'] as List)
          : [],
      visibility: json['visibility'] as String? ?? 'public',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'created_at': createdAt.toUtc().toIso8601String(),
      'user_id': userId,
      'product_id': productId,
      'review_text': reviewText,
      'rating': rating,
      'image_urls': imageUrls,
      'subcategory_tags': subcategoryTags,
      'visibility': visibility,
    };
  }

  Review copyWith({
    String? id,
    DateTime? createdAt,
    String? userId,
    String? productId,
    String? reviewText,
    double? rating,
    List<String>? imageUrls,
    List<String>? subcategoryTags,
    String? visibility,
  }) {
    return Review(
      id: id ?? this.id,
      createdAt: createdAt ?? this.createdAt,
      userId: userId ?? this.userId,
      productId: productId ?? this.productId,
      reviewText: reviewText ?? this.reviewText,
      rating: rating ?? this.rating,
      imageUrls: imageUrls ?? this.imageUrls,
      subcategoryTags: subcategoryTags ?? this.subcategoryTags,
      visibility: visibility ?? this.visibility,
    );
  }
}