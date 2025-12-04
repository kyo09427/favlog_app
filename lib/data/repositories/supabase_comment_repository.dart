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
  Future<void> addComment(Comment comment) async {
    try {
      await _supabaseClient.from('comments').insert(comment.toJson());
    } catch (e) {
      throw Exception('コメントの追加に失敗しました: $e');
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