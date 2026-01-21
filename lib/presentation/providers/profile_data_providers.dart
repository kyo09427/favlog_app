import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../domain/models/review.dart';
import '../../domain/models/product.dart';
import '../../domain/models/review_stats.dart';
import '../../data/repositories/supabase_review_repository.dart';
import '../../data/repositories/supabase_like_repository.dart';
import '../../data/repositories/supabase_product_repository.dart';
import '../../data/repositories/supabase_comment_repository.dart';

/// ユーザーのレビュー一覧を取得するプロバイダー
final userReviewsProvider = FutureProvider.autoDispose.family<List<Review>, String>((ref, userId) {
  ref.keepAlive(); // キャッシュを保持
  final repository = ref.watch(reviewRepositoryProvider);
  return repository.getReviewsByUserId(userId);
});

/// ユーザーがいいねしたレビューID一覧を取得するプロバイダー
final userLikedReviewIdsProvider = FutureProvider.autoDispose.family<List<String>, String>((ref, userId) {
  ref.keepAlive(); // キャッシュを保持
  final repository = ref.watch(likeRepositoryProvider);
  return repository.getAllUserLikedReviewIds(userId);
});

/// 商品情報を取得するプロバイダー（キャッシュ付き）
final productProvider = FutureProvider.autoDispose.family<Product, String>((ref, productId) {
  ref.keepAlive();
  final repository = ref.watch(productRepositoryProvider);
  return repository.getProductById(productId);
});

/// レビュー統計情報（コメント数、いいね数）を取得するプロバイダー
final reviewStatsProvider = FutureProvider.autoDispose.family<ReviewStats, String>((ref, reviewId) {
  ref.keepAlive();
  final commentRepo = ref.watch(commentRepositoryProvider);
  final likeRepo = ref.watch(likeRepositoryProvider);
  
  return Future.wait([
    commentRepo.getCommentsByReviewId(reviewId),
    likeRepo.getLikeCounts([reviewId]),
  ]).then((results) {
    final comments = results[0] as List;
    final likes = results[1] as Map<String, int>;
    return ReviewStats(
      reviewId: reviewId,
      likeCount: likes[reviewId] ?? 0,
      commentCount: comments.length,
    );
  });
});

/// 特定レビューのいいね状態を取得するプロバイダー
final reviewLikeStatusProvider = FutureProvider.autoDispose.family<bool, ({String reviewId, String userId})>((ref, params) {
  ref.keepAlive();
  final repository = ref.watch(likeRepositoryProvider);
  return repository.hasUserLiked(params.reviewId, params.userId);
});
