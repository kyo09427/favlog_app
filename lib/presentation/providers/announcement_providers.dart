import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../domain/models/announcement.dart';
import '../../domain/repositories/announcement_repository.dart';
import '../../data/repositories/supabase_announcement_repository.dart';

/// お知らせリポジトリプロバイダー
final announcementRepositoryProvider = Provider<AnnouncementRepository>((ref) {
  return SupabaseAnnouncementRepository(Supabase.instance.client);
});

/// お知らせ一覧プロバイダー
final announcementsProvider = FutureProvider<List<Announcement>>((ref) async {
  final repository = ref.watch(announcementRepositoryProvider);
  return await repository.getAnnouncements();
});

/// 未読お知らせ数プロバイダー
final unreadAnnouncementCountProvider = FutureProvider<int>((ref) async {
  final repository = ref.watch(announcementRepositoryProvider);
  return await repository.getUnreadCount();
});
