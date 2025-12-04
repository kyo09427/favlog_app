import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../domain/models/review.dart';
import '../../domain/models/product.dart';
import '../../domain/models/review_stats.dart';
import '../../data/repositories/supabase_review_repository.dart';
import '../../data/repositories/supabase_product_repository.dart';
import '../../data/repositories/supabase_like_repository.dart';
import '../../data/repositories/supabase_comment_repository.dart';
import '../../data/repositories/supabase_auth_repository.dart';

enum ReviewSortType {
  all,      // すべて（作成日時の新しい順）
  newest,   // 新しい順
  highRated // 高評価順
}

class ReviewWithStats {
  final Review review;
  final ReviewStats stats;
  final bool isLikedByCurrentUser;

  ReviewWithStats({
    required this.review,
    required this.stats,
    required this.isLikedByCurrentUser,
  });
}

class ReviewDetailState {
  final List<ReviewWithStats> reviewsWithStats;
  final bool isLoading;
  final String? error;
  final Product currentProduct;
  final ReviewSortType sortType;

  ReviewDetailState({
    required this.reviewsWithStats,
    this.isLoading = false,
    this.error,
    required this.currentProduct,
    this.sortType = ReviewSortType.all,
  });

  ReviewDetailState copyWith({
    List<ReviewWithStats>? reviewsWithStats,
    bool? isLoading,
    String? error,
    Product? currentProduct,
    ReviewSortType? sortType,
  }) {
    return ReviewDetailState(
      reviewsWithStats: reviewsWithStats ?? this.reviewsWithStats,
      isLoading: isLoading ?? this.isLoading,
      error: error,
      currentProduct: currentProduct ?? this.currentProduct,
      sortType: sortType ?? this.sortType,
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
  final _productRepository = productRepositoryProvider;

  ReviewDetailController(this._ref, this._productId)
      : super(
          ReviewDetailState(
            reviewsWithStats: const [],
            currentProduct: Product.empty(),
            isLoading: true,
          ),
        ) {
    _init();
  }

  Future<void> _init() async {
    await refreshAll();
  }

  /// ソートタイプを変更
  void changeSortType(ReviewSortType newSortType) {
    if (state.sortType == newSortType) return;
    
    state = state.copyWith(sortType: newSortType);
    _sortReviews();
  }

  /// 現在のソートタイプに基づいてレビューをソート
  void _sortReviews() {
    final sortedReviews = List<ReviewWithStats>.from(state.reviewsWithStats);
    
    switch (state.sortType) {
      case ReviewSortType.all:
      case ReviewSortType.newest:
        sortedReviews.sort((a, b) => 
          b.review.createdAt.compareTo(a.review.createdAt));
        break;
      case ReviewSortType.highRated:
        sortedReviews.sort((a, b) {
          final ratingComparison = b.review.rating.compareTo(a.review.rating);
          if (ratingComparison != 0) return ratingComparison;
          // 評価が同じ場合は新しい順
          return b.review.createdAt.compareTo(a.review.createdAt);
        });
        break;
    }
    
    state = state.copyWith(reviewsWithStats: sortedReviews);
  }

  /// 商品情報とレビューをまとめて再取得
  Future<void> refreshAll() async {
    state = state.copyWith(isLoading: true, error: null);

    try {
      final productRepository = _ref.read(_productRepository);
      final reviewRepository = _ref.read(reviewRepositoryProvider);
      final likeRepository = _ref.read(likeRepositoryProvider);
      final commentRepository = _ref.read(commentRepositoryProvider);

      // 商品情報とレビューを並列で取得
      final results = await Future.wait([
        productRepository.getProductById(_productId),
        reviewRepository.getReviewsByProductId(_productId),
      ]);

      final fetchedProduct = results[0] as Product;
      final reviews = results[1] as List<Review>;

      if (reviews.isEmpty) {
        state = state.copyWith(
          reviewsWithStats: [],
          currentProduct: fetchedProduct,
          isLoading: false,
        );
        return;
      }

      final reviewIds = reviews.map((r) => r.id).toList();

      // 現在のユーザーIDを取得
      final authRepository = _ref.read(authRepositoryProvider);
      final currentUserId = authRepository.getCurrentUser()?.id ?? '';

      // いいね数、コメント数、ユーザーのいいね状態を並列で取得
      final statsResults = await Future.wait([
        likeRepository.getLikeCounts(reviewIds),
        commentRepository.getCommentCounts(reviewIds),
        likeRepository.getUserLikedReviewIds(currentUserId, reviewIds),
      ]);

      final likeCounts = statsResults[0] as Map<String, int>;
      final commentCounts = statsResults[1] as Map<String, int>;
      final likedReviewIds = (statsResults[2] as List<String>).toSet();

      // ReviewWithStatsのリストを作成
      final reviewsWithStats = reviews.map((review) {
        final stats = ReviewStats(
          reviewId: review.id,
          likeCount: likeCounts[review.id] ?? 0,
          commentCount: commentCounts[review.id] ?? 0,
        );
        
        return ReviewWithStats(
          review: review,
          stats: stats,
          isLikedByCurrentUser: likedReviewIds.contains(review.id),
        );
      }).toList();

      state = state.copyWith(
        reviewsWithStats: reviewsWithStats,
        currentProduct: fetchedProduct,
        isLoading: false,
      );
      
      // ソートを適用
      _sortReviews();
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: e.toString(),
      );
    }
  }

  /// いいねをトグル
  Future<void> toggleLike(String reviewId) async {
    try {
      final likeRepository = _ref.read(likeRepositoryProvider);
      final reviewWithStats = state.reviewsWithStats
          .firstWhere((rws) => rws.review.id == reviewId);
      
      if (reviewWithStats.isLikedByCurrentUser) {
        await likeRepository.removeLike(reviewId);
      } else {
        await likeRepository.addLike(reviewId);
      }
      
      // 状態を更新
      await refreshAll();
    } catch (e) {
      state = state.copyWith(error: 'いいねの操作に失敗しました: $e');
    }
  }

  /// レビュー編集後などから呼び出す用のラッパー
  Future<void> refreshReviews() async {
    await refreshAll();
  }
}