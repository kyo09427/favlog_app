import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../domain/models/comment.dart';
import '../../domain/repositories/comment_repository.dart';
import '../../main.dart';

final commentRepositoryProvider = Provider<CommentRepository>((ref) {
  return SupabaseCommentRepository(ref.watch(supabaseProvider));
});

class SupabaseCommentRepository implements CommentRepository {
  final SupabaseClient _supabaseClient;

  SupabaseCommentRepository(this._supabaseClient);

  @override
  Future<List<Comment>> getCommentsByReviewId(String reviewId) async {
    try {
      final response = await _supabaseClient
          .from('comments')
          .select()
          .eq('review_id', reviewId)
          .order('created_at', ascending: true);

      return (response as List)
          .map((json) => Comment.fromJson(json))
          .toList();
    } catch (e) {
      throw Exception('コメントの取得に失敗しました: $e');
    }
  }

  @override
  Future<List<Comment>> getCommentsByUserId(String userId) async {
    try {
      final response = await _supabaseClient
          .from('comments')
          .select()
          .eq('user_id', userId)
          .order('created_at', ascending: false);

      return (response as List)
          .map((json) => Comment.fromJson(json))
          .toList();
    } catch (e) {
      throw Exception('ユーザーのコメント取得に失敗しました: $e');
    }
  }

  @override
  Future<void> addComment(Comment comment) async {
    try {
      await _supabaseClient.from('comments').insert(comment.toJson());
      
      // 通知の生成（コメント追加時）
      await _createCommentNotification(comment);
    } catch (e) {
      throw Exception('コメントの追加に失敗しました: $e');
    }
  }

  /// コメント追加時に通知を作成
  Future<void> _createCommentNotification(Comment comment) async {
    try {
      print('💬 コメント通知生成開始: レビューID=${comment.reviewId}');
      
      // レビュー情報を取得してレビュー投稿者を特定
      final reviewResponse = await _supabaseClient
          .from('reviews')
          .select('user_id, product_id')
          .eq('id', comment.reviewId)
          .single();
      
      final reviewOwnerId = reviewResponse['user_id'] as String;
      final productId = reviewResponse['product_id'] as String;
      
      // 自分のレビューに自分でコメントした場合は通知しない
      if (reviewOwnerId == comment.userId) {
        print('⚠️ 自分へのコメントのため通知スキップ');
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
      } catch (e) {
        print('⚠️ 商品名の取得失敗: $e');
      }
      
      // レビュー投稿者の通知設定を確認
      final settingsResponse = await _supabaseClient
          .from('user_settings')
          .select('enable_comment_notifications')
          .eq('id', reviewOwnerId)
          .maybeSingle();
      
      // 設定が存在しない場合はデフォルトでtrue
      final enableNotifications = settingsResponse == null 
          ? true 
          : (settingsResponse['enable_comment_notifications'] as bool? ?? true);
      
      if (enableNotifications) {
        await _supabaseClient.from('notifications').insert({
          'user_id': reviewOwnerId,
          'type': 'comment',
          'title': 'コメントが追加されました',
          'body': '${productName}のレビューにコメントが追加されました',
          'related_review_id': comment.reviewId,
          'related_user_id': comment.userId,
        });
        print('✅ コメント通知送信成功');
      } else {
        print('⚠️ コメント通知が無効のためスキップ');
      }
    } catch (e) {
      print('❌ コメント通知生成失敗: $e');
    }
  }

  @override
  Future<void> updateComment(Comment comment) async {
    try {
      await _supabaseClient
          .from('comments')
          .update(comment.toJson())
          .eq('id', comment.id);
    } catch (e) {
      throw Exception('コメントの更新に失敗しました: $e');
    }
  }

  @override
  Future<void> deleteComment(String commentId) async {
    try {
      await _supabaseClient.from('comments').delete().eq('id', commentId);
    } catch (e) {
      throw Exception('コメントの削除に失敗しました: $e');
    }
  }

  @override
  Future<Map<String, int>> getCommentCounts(List<String> reviewIds) async {
    if (reviewIds.isEmpty) return {};

    try {
      final response = await _supabaseClient.rpc(
        'get_comment_counts',
        params: {'review_ids': reviewIds},
      );

      final Map<String, int> counts = {};
      for (final row in response as List) {
        counts[row['review_id'] as String] = row['comment_count'] as int;
      }
      return counts;
    } catch (e) {
      throw Exception('コメント数の取得に失敗しました: $e');
    }
  }
}