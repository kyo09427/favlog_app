import 'package:favlog_app/domain/models/product_stats.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../domain/models/review.dart';
import '../../domain/repositories/review_repository.dart';
import '../../main.dart';

final reviewRepositoryProvider = Provider<ReviewRepository>((ref) {
  return SupabaseReviewRepository(ref.watch(supabaseProvider));
});

class SupabaseReviewRepository implements ReviewRepository {
  final SupabaseClient _supabaseClient;

  SupabaseReviewRepository(this._supabaseClient);

  @override
  Future<List<Review>> getReviews({String? category, String? visibility, String? currentUserId}) async {
    try {
      var query = _supabaseClient
          .from('reviews')
          .select();

      if (category != null && category != 'すべて') {
        query = query.eq('category', category);
      }

      if (currentUserId != null) {
        // 現在のユーザーIDに基づいてフィルタリング
        query = query.or('visibility.eq.public,'
                        'and(visibility.eq.friends,user_id.eq.$currentUserId),' // フォロー機能未実装のため、一旦自身のみ
                        'and(visibility.eq.private,user_id.eq.$currentUserId)');
      } else {
        // ログインしていないユーザーは公開レビューのみ閲覧可能
        query = query.eq('visibility', 'public');
      }

      final response = await query.order('created_at', ascending: false).limit(100);

      return (response as List).map((json) => Review.fromJson(json)).toList();
    } catch (e) {
      throw Exception('Failed to get reviews: $e');
    }
  }

  @override
  Future<List<Review>> getReviewsByProductId(String productId) async {
    try {
      final response = await _supabaseClient
          .from('reviews')
          .select()
          .eq('product_id', productId)
          .order('created_at', ascending: false);
      return (response as List).map((json) => Review.fromJson(json)).toList();
    } catch (e) {
      throw Exception('Failed to get reviews for product $productId: $e');
    }
  }

  @override
  Future<List<Review>> getReviewsByUserId(String userId) async {
    try {
      final response = await _supabaseClient
          .from('reviews')
          .select()
          .eq('user_id', userId)
          .order('created_at', ascending: false);
      return (response as List).map((json) => Review.fromJson(json)).toList();
    } catch (e) {
      throw Exception('Failed to get reviews for user $userId: $e');
    }
  }

  @override
  Future<Map<String, Review>> getLatestReviewsByProductIds(List<String> productIds, {String? currentUserId}) async {
    if (productIds.isEmpty) {
      return {};
    }
    try {
      final Map<String, dynamic> params = {'p_product_ids': productIds};
      if (currentUserId != null) {
        params['p_current_user_id'] = currentUserId;
      }

      final response = await _supabaseClient.rpc(
        'get_latest_reviews_by_product_ids',
        params: params,
      );

      final reviews = (response as List).map((json) => Review.fromJson(json)).toList();

      final latestReviews = <String, Review>{};
      for (final review in reviews) {
        if (!latestReviews.containsKey(review.productId)) {
          latestReviews[review.productId] = review;
        }
      }
      return latestReviews;
    } catch (e) {
      throw Exception('Failed to get latest reviews by product IDs: $e');
    }
  }

  @override
  Future<Review> getReviewById(String reviewId) async {
    try {
      final response = await _supabaseClient
          .from('reviews')
          .select()
          .eq('id', reviewId)
          .single();
      return Review.fromJson(response);
    } catch (e) {
      throw Exception('Failed to get review by ID $reviewId: $e');
    }
  }

  @override
  Future<void> createReview(Review review) async {
    try {
      await _supabaseClient.from('reviews').insert(review.toJson());
    } catch (e) {
      throw Exception('Failed to create review: $e');
    }
  }

  @override
  Future<void> updateReview(Review review) async {
    try {
      await _supabaseClient
          .from('reviews')
          .update(review.toJson())
          .eq('id', review.id);
    } catch (e) {
      throw Exception('Failed to update review: $e');
    }
  }

  @override
  Future<void> deleteReview(String reviewId) async {
    try {
      await _supabaseClient.from('reviews').delete().eq('id', reviewId);
    } catch (e) {
      throw Exception('Failed to delete review: $e');
    }
  }

  @override
  Future<List<ProductStats>> getProductStats(List<String> productIds) async {
    if (productIds.isEmpty) {
      return [];
    }
    try {
      final response = await _supabaseClient.rpc(
        'get_product_rating_stats',
        params: {'p_product_ids': productIds},
      );
      return (response as List)
          .map((json) => ProductStats.fromMap(json))
          .toList();
    } catch (e) {
      throw Exception('Failed to get product stats: $e');
    }
  }
}

