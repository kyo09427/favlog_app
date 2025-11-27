import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../data/repositories/supabase_review_repository.dart';
import '../../data/repositories/supabase_auth_repository.dart';
import '../../domain/models/product.dart';
import '../../domain/models/review.dart';

class AddReviewToProductState {
  final String reviewText;
  final double rating;
  final bool isLoading;
  final String? error;

  AddReviewToProductState({
    this.reviewText = '',
    this.rating = 3.0,
    this.isLoading = false,
    this.error,
  });

  AddReviewToProductState copyWith({
    String? reviewText,
    double? rating,
    bool? isLoading,
    String? error,
  }) {
    return AddReviewToProductState(
      reviewText: reviewText ?? this.reviewText,
      rating: rating ?? this.rating,
      isLoading: isLoading ?? this.isLoading,
      error: error,
    );
  }
}

final addReviewToProductControllerProvider =
    StateNotifierProvider.family<AddReviewToProductController, AddReviewToProductState, Product>((ref, product) {
  return AddReviewToProductController(ref, product);
});

class AddReviewToProductController extends StateNotifier<AddReviewToProductState> {
  final Ref _ref;
  final Product _product;

  AddReviewToProductController(this._ref, this._product) : super(AddReviewToProductState());

  void updateReviewText(String text) {
    state = state.copyWith(reviewText: text);
  }

  void updateRating(double rating) {
    state = state.copyWith(rating: rating);
  }

  Future<void> submitReview() async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final authRepository = _ref.read(authRepositoryProvider);
      final reviewRepository = _ref.read(reviewRepositoryProvider);

      final user = authRepository.getCurrentUser();
      if (user == null) {
        throw Exception('ユーザーがログインしていません。');
      }

      final newReview = Review(
        userId: user.id,
        productId: _product.id,
        reviewText: state.reviewText,
        rating: state.rating.toInt(),
      );

      await reviewRepository.createReview(newReview);

      state = AddReviewToProductState(); // Reset form
    } on AuthException catch (e) {
      state = state.copyWith(isLoading: false, error: e.message);
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }
}