import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../data/repositories/supabase_review_repository.dart';
import '../../data/repositories/supabase_auth_repository.dart';
import '../../domain/models/review.dart';

/// レビュー編集画面の状態
class EditReviewState {
  final String reviewText;
  final double rating;
  final bool isLoading;
  final String? error;
  final Review originalReview;

  EditReviewState({
    required this.reviewText,
    required this.rating,
    this.isLoading = false,
    this.error,
    required this.originalReview,
  });

  EditReviewState copyWith({
    String? reviewText,
    double? rating,
    bool? isLoading,
    String? error,
    Review? originalReview,
  }) {
    return EditReviewState(
      reviewText: reviewText ?? this.reviewText,
      rating: rating ?? this.rating,
      isLoading: isLoading ?? this.isLoading,
      error: error,
      originalReview: originalReview ?? this.originalReview,
    );
  }
}

/// レビュー編集コントローラーのプロバイダー
final editReviewControllerProvider = StateNotifierProvider.family<
    EditReviewController, EditReviewState, Review>((ref, review) {
  return EditReviewController(ref, review);
});

/// レビュー編集コントローラー
class EditReviewController extends StateNotifier<EditReviewState> {
  final Ref _ref;
  bool _isDisposed = false;

  EditReviewController(this._ref, Review review)
      : super(EditReviewState(
          reviewText: review.reviewText,
          rating: review.rating,
          originalReview: review,
        ));

  @override
  void dispose() {
    _isDisposed = true;
    super.dispose();
  }

  /// レビューテキストを更新
  void updateReviewText(String text) {
    if (_isDisposed) return;
    state = state.copyWith(reviewText: text);
  }

  /// 評価を更新（1.0〜5.0の範囲に制限）
  void updateRating(double rating) {
    if (_isDisposed) return;
    final clampedRating = rating.clamp(1.0, 5.0);
    state = state.copyWith(rating: clampedRating);
  }

  /// レビューを更新
  Future<void> updateReview() async {
    if (_isDisposed) return;

    state = state.copyWith(isLoading: true, error: null);

    try {
      final authRepository = _ref.read(authRepositoryProvider);
      final reviewRepository = _ref.read(reviewRepositoryProvider);

      // ユーザー認証チェック
      final user = authRepository.getCurrentUser();
      if (user == null) {
        throw Exception('ユーザーがログインしていません。');
      }

      // 所有者チェック
      if (state.originalReview.userId != user.id) {
        throw Exception('このレビューを編集する権限がありません。');
      }

      // 更新されたレビュー情報を作成
      final updatedReview = state.originalReview.copyWith(
        reviewText: state.reviewText,
        rating: state.rating,
      );

      // レビューを更新
      await reviewRepository.updateReview(updatedReview);

      // 成功したら状態を更新
      if (!_isDisposed) {
        state = state.copyWith(
          isLoading: false,
          originalReview: updatedReview,
        );
      }
    } on AuthException catch (e) {
      if (!_isDisposed) {
        state = state.copyWith(
          isLoading: false,
          error: '認証エラー: ${e.message}',
        );
      }
    } catch (e) {
      if (!_isDisposed) {
        state = state.copyWith(
          isLoading: false,
          error: e.toString(),
        );
      }
    }
  }
}