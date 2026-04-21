import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../data/repositories/supabase_review_repository.dart';
import '../../data/repositories/supabase_auth_repository.dart';
import '../../domain/models/product.dart';
import '../../domain/models/review.dart';
import '../../core/config/constants.dart';

/// レビュー追加画面の状態
class AddReviewState {
  final Product? selectedProduct;
  final String reviewText;
  final double rating;
  final bool isLoading;
  final String? error;

  AddReviewState({
    this.selectedProduct,
    this.reviewText = '',
    this.rating = 3.5,
    this.isLoading = false,
    this.error,
  });

  AddReviewState copyWith({
    Product? selectedProduct,
    String? reviewText,
    double? rating,
    bool? isLoading,
    String? error,
  }) {
    return AddReviewState(
      selectedProduct: selectedProduct ?? this.selectedProduct,
      reviewText: reviewText ?? this.reviewText,
      rating: rating ?? this.rating,
      isLoading: isLoading ?? this.isLoading,
      error: error,
    );
  }
}

/// レビュー追加コントローラーのプロバイダー
final addReviewControllerProvider =
    StateNotifierProvider.autoDispose<AddReviewController, AddReviewState>((
      ref,
    ) {
      return AddReviewController(ref);
    });

/// レビュー追加コントローラー
class AddReviewController extends StateNotifier<AddReviewState> {
  final Ref _ref;
  bool _isDisposed = false;

  AddReviewController(this._ref) : super(AddReviewState());

  @override
  void dispose() {
    _isDisposed = true;
    super.dispose();
  }

  /// 商品を設定
  void setProduct(Product product) {
    if (_isDisposed) return;
    state = state.copyWith(selectedProduct: product);
  }

  /// レビューテキストを更新
  void updateReviewText(String text) {
    if (_isDisposed) return;
    state = state.copyWith(reviewText: text);
  }

  /// 評価を更新（0.5刻み、1.0〜5.0の範囲）
  void updateRating(double rating) {
    if (_isDisposed) return;
    final roundedRating = (rating * 2).round() / 2;
    final clampedRating = roundedRating.clamp(0.5, 5.0);
    state = state.copyWith(rating: clampedRating);
  }

  /// レビューを投稿
  Future<bool> submitReview() async {
    if (_isDisposed) return false;

    final selectedProduct = state.selectedProduct;
    if (selectedProduct == null) {
      state = state.copyWith(error: '商品が選択されていません');
      return false;
    }

    final trimmedText = state.reviewText.trim();
    if (trimmedText.isEmpty) {
      state = state.copyWith(error: 'レビュー本文を入力してください');
      return false;
    }

    if (trimmedText.length > ValidationLimits.reviewTextMaxLength) {
      state = state.copyWith(
        error: 'レビュー本文は${ValidationLimits.reviewTextMaxLength}文字以内で入力してください',
      );
      return false;
    }

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
        productId: selectedProduct.id,
        reviewText: state.reviewText,
        rating: state.rating,
        imageUrls: const [],
        subcategoryTags: const [],
        visibility: 'public',
      );

      await reviewRepository.createReview(newReview);

      if (!_isDisposed) {
        state = AddReviewState(
          selectedProduct: null,
          isLoading: false,
          error: null,
        );
      }

      return true;
    } on AuthException catch (e) {
      if (!_isDisposed) {
        state = state.copyWith(isLoading: false, error: '認証エラー: ${e.message}');
      }
      return false;
    } catch (e) {
      if (!_isDisposed) {
        state = state.copyWith(isLoading: false, error: e.toString());
      }
      return false;
    }
  }
}
