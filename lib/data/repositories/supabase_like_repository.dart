import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../domain/repositories/like_repository.dart';
import '../../main.dart';

final likeRepositoryProvider = Provider<LikeRepository>((ref) {
  return SupabaseLikeRepository(ref.watch(supabaseProvider));
});

class SupabaseLikeRepository implements LikeRepository {
  final SupabaseClient _supabaseClient;

  SupabaseLikeRepository(this._supabaseClient);

  @override
  Future<void> addLike(String reviewId) async {
    try {
      final userId = _supabaseClient.auth.currentUser?.id;
      if (userId == null) {
        throw Exception('ユーザーがログインしていません');
      }

      await _supabaseClient.from('likes').insert({
        'user_id': userId,
        'review_id': reviewId,
      });
    } catch (e) {
      throw Exception('いいねの追加に失敗しました: $e');
    }
  }

  @override
  Future<void> removeLike(String reviewId) async {
    try {
      final userId = _supabaseClient.auth.currentUser?.id;
      if (userId == null) {
        throw Exception('ユーザーがログインしていません');
      }

      await _supabaseClient
          .from('likes')
          .delete()
          .eq('user_id', userId)
          .eq('review_id', reviewId);
    } catch (e) {
      throw Exception('いいねの削除に失敗しました: $e');
    }
  }

  @override
  Future<bool> hasUserLiked(String reviewId, String userId) async {
    try {
      final response = await _supabaseClient
          .from('likes')
          .select()
          .eq('user_id', userId)
          .eq('review_id', reviewId)
          .maybeSingle();

      return response != null;
    } catch (e) {
      throw Exception('いいね状態の取得に失敗しました: $e');
    }
  }

  @override
  Future<Map<String, int>> getLikeCounts(List<String> reviewIds) async {
    if (reviewIds.isEmpty) return {};

    try {
      final response = await _supabaseClient.rpc(
        'get_like_counts',
        params: {'review_ids': reviewIds},
      );

      final Map<String, int> counts = {};
      for (final row in response as List) {
        counts[row['review_id'] as String] = row['like_count'] as int;
      }
      return counts;
    } catch (e) {
      throw Exception('いいね数の取得に失敗しました: $e');
    }
  }

  @override
  Future<List<String>> getUserLikedReviewIds(
      String userId, List<String> reviewIds) async {
    if (reviewIds.isEmpty) return [];

    try {
      final response = await _supabaseClient
          .from('likes')
          .select('review_id')
          .eq('user_id', userId)
          .inFilter('review_id', reviewIds);

      return (response as List)
          .map((row) => row['review_id'] as String)
          .toList();
    } catch (e) {
      throw Exception('ユーザーのいいね状態の取得に失敗しました: $e');
    }
  }

  @override
  Future<List<String>> getAllUserLikedReviewIds(String userId) async {
    try {
      final response = await _supabaseClient
          .from('likes')
          .select('review_id')
          .eq('user_id', userId)
          .order('created_at', ascending: false);

      return (response as List)
          .map((row) => row['review_id'] as String)
          .toList();
    } catch (e) {
      throw Exception('ユーザーがいいねしたレビューの取得に失敗しました: $e');
    }
  }
}