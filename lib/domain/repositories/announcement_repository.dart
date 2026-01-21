import '../models/announcement.dart';

/// お知らせリポジトリのインターフェース
abstract class AnnouncementRepository {
  /// 全お知らせを取得（新しい順）
  Future<List<Announcement>> getAnnouncements();

  /// IDでお知らせを取得
  Future<Announcement?> getAnnouncementById(String id);

  /// 未読お知らせの数を取得
  Future<int> getUnreadCount();

  /// お知らせを既読にする
  Future<void> markAsRead(String announcementId);

  /// お知らせを作成
  Future<Announcement> createAnnouncement({
    required String title,
    required String content,
    required String category,
    required int priority,
    DateTime? publishedAt,
  });

  /// お知らせを更新
  Future<Announcement> updateAnnouncement({
    required String id,
    required String title,
    required String content,
    required String category,
    required int priority,
    DateTime? publishedAt,
  });

  /// お知らせを削除
  Future<void> deleteAnnouncement(String id);
}
