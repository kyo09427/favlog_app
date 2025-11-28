import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../domain/models/review.dart';
import '../../domain/models/product.dart';
import '../../data/repositories/supabase_review_repository.dart';
import '../../data/repositories/supabase_product_repository.dart'; // Import product repository

class ReviewDetailState {
  final List<Review> reviews;
  final bool isLoading;
  final String? error;
  final Product currentProduct; // Add currentProduct

  ReviewDetailState({
    required this.reviews,
    this.isLoading = false,
    this.error,
    required this.currentProduct, // Make it required
  });

  ReviewDetailState copyWith({
    List<Review>? reviews,
    bool? isLoading,
    String? error,
    Product? currentProduct,
  }) {
    return ReviewDetailState(
      reviews: reviews ?? this.reviews,
      isLoading: isLoading ?? this.isLoading,
      error: error,
      currentProduct: currentProduct ?? this.currentProduct,
    );
  }
}

final reviewDetailControllerProvider = StateNotifierProvider.family<ReviewDetailController, ReviewDetailState, String>((ref, productId) {
  return ReviewDetailController(ref, productId);
});

class ReviewDetailController extends StateNotifier<ReviewDetailState> {
  final Ref _ref;
  final String _productId; // Changed to productId
  final _productRepository = productRepositoryProvider; // Access product repository

  ReviewDetailController(this._ref, this._productId) // Changed to productId
      : super(ReviewDetailState(reviews: [], currentProduct: Product.empty())) { // Use empty product as initial
    _init(); // Call init method
  }

  Future<void> _init() async {
    await refreshAll(); // Fetch product and reviews on init
  }

  Future<void> refreshAll() async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final productRepository = _ref.read(_productRepository);
      final reviewRepository = _ref.read(reviewRepositoryProvider);

      final fetchedProduct = await productRepository.getProductById(_productId); // Fetch latest product details using productId
      final productReviews = await reviewRepository.getReviewsByProductId(_productId); // Use productId

      state = state.copyWith(
        reviews: productReviews,
        currentProduct: fetchedProduct,
        isLoading: false,
      );
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  // No longer needed, as refreshAll handles both
  // Future<void> fetchReviews() async { ... }

  // This will be called from ReviewItem's onReviewEdited
  Future<void> refreshReviews() async {
    await refreshAll(); // Now refreshes both product and reviews
  }
}