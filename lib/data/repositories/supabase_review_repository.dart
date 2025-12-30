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
      final Map<String, dynamic> params = {
        'p_product_ids': productIds,
        'p_visibility': 'public',
        'p_current_user_id': currentUserId,
      };

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
      
      // 通知の生成（新規レビュー投稿時）
      await _createNewReviewNotifications(review);
    } catch (e) {
      throw Exception('Failed to create review: $e');
    }
  }

  /// 新規レビュー投稿時に通知を作成
  Future<void> _createNewReviewNotifications(Review review) async {
    try {
      print('🔔 通知生成開始: レビューID=${review.id}');
      
      // 商品情報を取得
      String productName = '商品';
      try {
        final productResponse = await _supabaseClient
            .from('products')
            .select('name')
            .eq('id', review.productId)
            .single();
        productName = productResponse['name'] as String? ?? '商品';
        print('✅ 商品名取得成功: $productName');
      } catch (e) {
        print('⚠️ 商品名の取得失敗: $e');
        // 商品名の取得失敗時はデフォルト値を使用
      }

      // 全ユーザーのリストを取得（投稿者以外）
      final allUsersResponse = await _supabaseClient
          .from('profiles')
          .select('id')
          .neq('id', review.userId);
      
      final allUserIds = (allUsersResponse as List)
          .map((user) => user['id'] as String)
          .toList();
      
      print('📋 通知対象ユーザー数: ${allUserIds.length}');
      
      if (allUserIds.isEmpty) {
        print('⚠️ 通知対象ユーザーなし');
        return;
      }

      // 各ユーザーの通知設定を確認
      int notificationsSent = 0;
      for (final userId in allUserIds) {
        try {
          final settingsResponse = await _supabaseClient
              .from('user_settings')
              .select('enable_new_review_notifications')
              .eq('id', userId)
              .maybeSingle();
          
          // 設定が存在しない場合はデフォルトでtrue、存在する場合は設定値を使用
          final enableNotifications = settingsResponse == null 
              ? true 
              : (settingsResponse['enable_new_review_notifications'] as bool? ?? true);
          
          if (enableNotifications) {
            // 通知を作成
            await _supabaseClient.from('notifications').insert({
              'user_id': userId,
              'type': 'new_review',
              'title': '新しいレビューが投稿されました',
              'body': '${productName}のレビューが投稿されました',
              'related_review_id': review.id,
              'related_user_id': review.userId,
            });
            notificationsSent++;
          }
        } catch (e) {
          print('❌ ユーザー $userId への通知作成失敗: $e');
        }
      }
      print('✅ 通知送信完了: $notificationsSent件');
    } catch (e) {
      print('❌ 通知生成全体の失敗: $e');
    }
  }

  @override
  Future<void> updateReview(Review review) async {
    try {
      // 更新前のレビューを取得して、削除された画像を特定
      final oldReview = await getReviewById(review.id);
      
      await _supabaseClient
          .from('reviews')
          .update(review.toJson())
          .eq('id', review.id);

      // 古いレビューにはあって新しいレビューにはない画像を削除
      final deletedUrls = oldReview.imageUrls
          .where((url) => !review.imageUrls.contains(url))
          .toList();

      if (deletedUrls.isNotEmpty) {
        try {
          final fileNames = deletedUrls.map((url) => url.split('/').last).toList();
          await _supabaseClient.storage.from('product_images').remove(fileNames);
        } catch (e) {
          // 画像削除の失敗はメイン処理に影響させない
          // print('Failed to delete old review images: $e');
        }
      }
    } catch (e) {
      throw Exception('Failed to update review: $e');
    }
  }

  @override
  Future<void> deleteReview(String reviewId) async {
    try {
      // 削除対象のレビューを取得（画像URLを取得するため）
      final review = await getReviewById(reviewId);

      await _supabaseClient.from('reviews').delete().eq('id', reviewId);

      // レビューに関連付けられた画像を削除
      if (review.imageUrls.isNotEmpty) {
        try {
          final fileNames = review.imageUrls.map((url) => url.split('/').last).toList();
          await _supabaseClient.storage.from('product_images').remove(fileNames);
        } catch (e) {
          // print('Failed to delete review images: $e');
        }
      }
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

