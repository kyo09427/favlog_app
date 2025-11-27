import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../domain/models/review.dart';
import '../../domain/repositories/review_repository.dart';
import '../../main.dart'; // Import the main.dart to use supabaseProvider

final reviewRepositoryProvider = Provider<ReviewRepository>((ref) {
  return SupabaseReviewRepository(ref.watch(supabaseProvider));
});

class SupabaseReviewRepository implements ReviewRepository {
  final SupabaseClient _supabaseClient;

  SupabaseReviewRepository(this._supabaseClient);

  @override
  Future<List<Review>> getReviews({String? category}) async {
    try {
      // Supabase does not directly support filtering by product category here.
      // This might need to be handled differently, e.g., by fetching products first
      // and then their reviews, or by joining tables if RLS allows.
      // For now, fetching all reviews and filtering in memory (if category is provided)
      // or fetching only products and their reviews for a given category.

      // As per the original README, category filtering is on the home screen for reviews.
      // Assuming 'reviews' table doesn't have category directly. Category is on 'products'.
      // This method would typically fetch reviews related to a product, or all reviews.
      // The category filtering will need to happen at a higher level (e.g., when fetching products).
      // Let's assume for this method, we fetch all reviews for now.
      final response = await _supabaseClient
          .from('reviews')
          .select()
          .order('created_at', ascending: false)
          .limit(100); // Limit to avoid fetching too much data

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
      await _supabaseClient.from('reviews').update(review.toJson()).eq('id', review.id);
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