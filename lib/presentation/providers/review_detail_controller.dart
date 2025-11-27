import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../domain/models/review.dart';
import '../../domain/models/product.dart';
import '../../data/repositories/supabase_review_repository.dart';

class ReviewDetailState {
  final List<Review> reviews;
  final bool isLoading;
  final String? error;

  ReviewDetailState({
    required this.reviews,
    this.isLoading = false,
    this.error,
  });

  ReviewDetailState copyWith({
    List<Review>? reviews,
    bool? isLoading,
    String? error,
  }) {
    return ReviewDetailState(
      reviews: reviews ?? this.reviews,
      isLoading: isLoading ?? this.isLoading,
      error: error,
    );
  }
}

final reviewDetailControllerProvider = StateNotifierProvider.family<ReviewDetailController, ReviewDetailState, Product>((ref, product) {
  return ReviewDetailController(ref, product);
});

class ReviewDetailController extends StateNotifier<ReviewDetailState> {
  final Ref _ref;
  final Product _product;

  ReviewDetailController(this._ref, this._product) : super(ReviewDetailState(reviews: [])) {
    fetchReviews();
  }

  Future<void> fetchReviews() async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final reviewRepository = _ref.read(reviewRepositoryProvider);
      final productReviews = await reviewRepository.getReviewsByProductId(_product.id);

      state = state.copyWith(reviews: productReviews, isLoading: false);
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  // This will be called from ReviewItem's onReviewEdited
  Future<void> refreshReviews() async {
    await fetchReviews();
  }
}