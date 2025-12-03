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
  Future<List<Review>> getReviews({String? category}) async {
    try {
      final response = await _supabaseClient
          .from('reviews')
          .select()
          .order('created_at', ascending: false)
          .limit(100);

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
  Future<Map<String, Review>> getLatestReviewsByProductIds(List<String> productIds) async {
    if (productIds.isEmpty) {
      return {};
    }
    try {
      final response = await _supabaseClient
          .from('reviews')
          .select()
          .in_('product_id', productIds)
          .order('created_at', ascending: false);

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
}