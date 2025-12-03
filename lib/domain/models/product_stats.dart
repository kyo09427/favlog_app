class ProductStats {
  final String productId;
  final double averageRating;
  final int reviewCount;

  ProductStats({
    required this.productId,
    required this.averageRating,
    required this.reviewCount,
  });

  factory ProductStats.fromMap(Map<String, dynamic> map) {
    return ProductStats(
      productId: map['product_id'] as String,
      averageRating: (map['average_rating'] as num).toDouble(),
      reviewCount: map['review_count'] as int,
    );
  }

  static ProductStats empty() {
    return ProductStats(
      productId: '',
      averageRating: 0.0,
      reviewCount: 0,
    );
  }
}
