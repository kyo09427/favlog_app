import '../models/comment.dart';

abstract class CommentRepository {
  Future<List<Comment>> getCommentsByReviewId(String reviewId);
  Future<void> addComment(Comment comment);
  Future<void> updateComment(Comment comment);
  Future<void> deleteComment(String commentId);
  Future<Map<String, int>> getCommentCounts(List<String> reviewIds);
}