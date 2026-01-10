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
      
      // 通知の生成（いいね追加時）
      await _createLikeNotification(reviewId, userId);
    } catch (e) {
      throw Exception('いいねの追加に失敗しました: $e');
    }
  }

  /// いいね追加時に通知を作成
  Future<void> _createLikeNotification(String reviewId, String likerId) async {
    try {

      
      // レビュー情報を取得してレビュー投稿者を特定
      final reviewResponse = await _supabaseClient
          .from('reviews')
          .select('user_id, product_id')
          .eq('id', reviewId)
          .single();
      
      final reviewOwnerId = reviewResponse['user_id'] as String;
      final productId = reviewResponse['product_id'] as String;
      
      // 自分のレビューに自分でいいねした場合は通知しない
      if (reviewOwnerId == likerId) {

        return;
      }
      
      // 商品名を取得
      String productName = '商品';
      try {
        final productResponse = await _supabaseClient
            .from('products')
            .select('name')
            .eq('id', productId)
            .single();
        productName = productResponse['name'] as String? ?? '商品';
      } catch (_) {
      }
      
      // レビュー投稿者の通知設定を確認
      final settingsResponse = await _supabaseClient
          .from('user_settings')
          .select('enable_like_notifications')
          .eq('id', reviewOwnerId)
          .maybeSingle();
      
      // 設定が存在しない場合はデフォルトでtrue
      final enableNotifications = settingsResponse == null 
          ? true 
          : (settingsResponse['enable_like_notifications'] as bool? ?? true);
      
      if (enableNotifications) {
        await _supabaseClient.from('notifications').insert({
          'user_id': reviewOwnerId,
          'type': 'like',
          'title': 'いいねされました',
          'body': '$productNameのレビューにいいねされました',
          'related_review_id': reviewId,
          'related_user_id': likerId,
        });

      } else {

      }
    } catch (_) {
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