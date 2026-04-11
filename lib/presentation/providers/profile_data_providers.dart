import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../domain/models/review.dart';
import '../../domain/models/product.dart';
import '../../domain/models/review_stats.dart';
import '../../data/repositories/supabase_review_repository.dart';
import '../../data/repositories/supabase_like_repository.dart';
import '../../data/repositories/supabase_product_repository.dart';
import '../../data/repositories/supabase_comment_repository.dart';

/// ユーザーのレビュー一覧を取得するプロバイダー
final userReviewsProvider = FutureProvider.family<List<Review>, String>((
  ref,
  userId,
) {
  final repository = ref.watch(reviewRepositoryProvider);
  return repository.getReviewsByUserId(userId);
});

/// ユーザーがいいねしたレビューID一覧を取得するプロバイダー
final userLikedReviewIdsProvider = FutureProvider.family<List<String>, String>(
  (ref, userId) {
    final repository = ref.watch(likeRepositoryProvider);
    return repository.getAllUserLikedReviewIds(userId);
  },
);

/// 商品情報を取得するプロバイダー（キャッシュ付き）
final productProvider = FutureProvider.family<Product, String>((
  ref,
  productId,
) {
  final repository = ref.watch(productRepositoryProvider);
  return repository.getProductById(productId);
});

/// レビュー統計情報（コメント数、いいね数）を取得するプロバイダー
final reviewStatsProvider = FutureProvider.family<ReviewStats, String>((
  ref,
  reviewId,
) async {
  final commentRepo = ref.watch(commentRepositoryProvider);
  final likeRepo = ref.watch(likeRepositoryProvider);

  final (comments, likes) = await (
    commentRepo.getCommentsByReviewId(reviewId),
    likeRepo.getLikeCounts([reviewId]),
  ).wait;

  return ReviewStats(
    reviewId: reviewId,
    likeCount: likes[reviewId] ?? 0,
    commentCount: comments.length,
  );
});

/// 特定レビューのいいね状態を取得するプロバイダー
final reviewLikeStatusProvider = FutureProvider.family<
    bool,
    ({String reviewId, String userId})>((ref, params) {
  final repository = ref.watch(likeRepositoryProvider);
  return repository.hasUserLiked(params.reviewId, params.userId);
});
