import 'package:supabase_flutter/supabase_flutter.dart';
import '../../domain/models/announcement.dart';
import '../../domain/repositories/announcement_repository.dart';

/// Supabaseを使ったお知らせリポジトリの実装
class SupabaseAnnouncementRepository implements AnnouncementRepository {
  final SupabaseClient _client;

  SupabaseAnnouncementRepository(this._client);

  @override
  Future<List<Announcement>> getAnnouncements() async {
    try {
      final userId = _client.auth.currentUser?.id;
      if (userId == null) return [];

      // お知らせと既読情報を結合して取得
      final response = await _client
          .from('announcements')
          .select('*, announcement_reads!left(user_id)')
          .order('published_at', ascending: false);

      return (response as List).map((json) {
        final reads = json['announcement_reads'] as List?;
        final isRead = reads?.any((read) => read['user_id'] == userId) ?? false;
        
        return Announcement.fromJson({
          ...json,
          'is_read': isRead,
        });
      }).toList();
    } catch (e) {
      throw Exception('お知らせの取得に失敗しました: $e');
    }
  }

  @override
  Future<Announcement?> getAnnouncementById(String id) async {
    try {
      final userId = _client.auth.currentUser?.id;
      if (userId == null) return null;

      final response = await _client
          .from('announcements')
          .select('*, announcement_reads!left(user_id)')
          .eq('id', id)
          .single();

      final reads = response['announcement_reads'] as List?;
      final isRead = reads?.any((read) => read['user_id'] == userId) ?? false;

      return Announcement.fromJson({
        ...response,
        'is_read': isRead,
      });
    } catch (e) {
      throw Exception('お知らせの取得に失敗しました: $e');
    }
  }

  @override
  Future<int> getUnreadCount() async {
    try {
      final userId = _client.auth.currentUser?.id;
      if (userId == null) return 0;

      // 全お知らせ数を取得
      final allAnnouncementsResponse = await _client
          .from('announcements')
          .select('id');
      
      final allCount = (allAnnouncementsResponse as List).length;

      // 既読お知らせ数を取得
      final readAnnouncementsResponse = await _client
          .from('announcement_reads')
          .select('announcement_id')
          .eq('user_id', userId);
      
      final readCount = (readAnnouncementsResponse as List).length;

      return allCount - readCount;
    } catch (e) {
      // エラー時は0を返す（バッジを非表示）
      return 0;
    }
  }

  @override
  Future<void> markAsRead(String announcementId) async {
    try {
      final userId = _client.auth.currentUser?.id;
      if (userId == null) return;

      // 既読レコードを挿入（重複エラーは無視）
      await _client.from('announcement_reads').insert({
        'user_id': userId,
        'announcement_id': announcementId,
      });
    } catch (e) {
      // 既に既読の場合は重複エラーになるが、無視する
      if (!e.toString().contains('duplicate key value')) {
        throw Exception('既読マークの更新に失敗しました: $e');
      }
    }
  }

  @override
  Future<Announcement> createAnnouncement({
    required String title,
    required String content,
    required String category,
    required int priority,
    DateTime? publishedAt,
  }) async {
    try {
      final response = await _client.from('announcements').insert({
        'title': title,
        'content': content,
        'category': category,
        'priority': priority,
        'published_at': (publishedAt ?? DateTime.now()).toIso8601String(),
      }).select().single();

      return Announcement.fromJson({
        ...response,
        'is_read': false,
      });
    } catch (e) {
      throw Exception('お知らせの作成に失敗しました: $e');
    }
  }

  @override
  Future<Announcement> updateAnnouncement({
    required String id,
    required String title,
    required String content,
    required String category,
    required int priority,
    DateTime? publishedAt,
  }) async {
    try {
      final updateData = {
        'title': title,
        'content': content,
        'category': category,
        'priority': priority,
      };
      
      // publishedAtが指定されている場合のみ更新
      if (publishedAt != null) {
        updateData['published_at'] = publishedAt.toIso8601String();
      }
      
      final response = await _client.from('announcements')
          .update(updateData)
          .eq('id', id)
          .select()
          .single();

      final userId = _client.auth.currentUser?.id;
      final reads = response['announcement_reads'] as List?;
      final isRead = reads?.any((read) => read['user_id'] == userId) ?? false;

      return Announcement.fromJson({
        ...response,
        'is_read': isRead,
      });
    } catch (e) {
      throw Exception('お知らせの更新に失敗しました: $e');
    }
  }

  @override
  Future<void> deleteAnnouncement(String id) async {
    try {
      await _client.from('announcements').delete().eq('id', id);
    } catch (e) {
      throw Exception('お知らせの削除に失敗しました: $e');
    }
  }
}
