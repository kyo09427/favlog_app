import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../domain/models/review.dart';
import '../../domain/models/product.dart';
import '../../data/repositories/supabase_review_repository.dart';
import '../../data/repositories/supabase_product_repository.dart';

class ReviewDetailState {
  final List<Review> reviews;
  final bool isLoading;
  final String? error;
  final Product currentProduct;

  ReviewDetailState({
    required this.reviews,
    this.isLoading = false,
    this.error,
    required this.currentProduct,
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

final reviewDetailControllerProvider =
    StateNotifierProvider.family<ReviewDetailController, ReviewDetailState, String>(
  (ref, productId) => ReviewDetailController(ref, productId),
);

class ReviewDetailController extends StateNotifier<ReviewDetailState> {
  final Ref _ref;
  final String _productId;
  // productRepositoryProvider は既存の SupabaseProductRepository の Provider を利用
  final _productRepository = productRepositoryProvider;

  ReviewDetailController(this._ref, this._productId)
      : super(
          ReviewDetailState(
            reviews: const [],
            currentProduct: Product.empty(),
            isLoading: true,
          ),
        ) {
    _init();
  }

  Future<void> _init() async {
    await refreshAll();
  }

  /// 商品情報とレビューをまとめて再取得
  Future<void> refreshAll() async {
    state = state.copyWith(isLoading: true, error: null);

    try {
      final productRepository = _ref.read(_productRepository);
      final reviewRepository = _ref.read(reviewRepositoryProvider);

      // 既存の Repository メソッド名をそのまま使用
      final fetchedProduct =
          await productRepository.getProductById(_productId);
      final productReviews =
          await reviewRepository.getReviewsByProductId(_productId);

      state = state.copyWith(
        reviews: productReviews,
        currentProduct: fetchedProduct,
        isLoading: false,
      );
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: e.toString(),
      );
    }
  }

  /// レビュー編集後などから呼び出す用のラッパー
  Future<void> refreshReviews() async {
    await refreshAll();
  }
}
