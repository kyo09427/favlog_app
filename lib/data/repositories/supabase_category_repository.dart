import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../domain/repositories/category_repository.dart';


class SupabaseCategoryRepository implements CategoryRepository {
  final SupabaseClient _client;

  SupabaseCategoryRepository(this._client);

  @override
  Future<List<String>> getCategories() async {
    // 今回のタスクでは実装不要
    throw UnimplementedError();
  }

  @override
  Future<List<String>> getPopularKeywords() async {
    try {
      final List<dynamic> result = await _client.rpc(
        'get_popular_keywords',
        params: {'limit_count': 5},
      );

      if (result.isEmpty) {
        return [];
      }

      final keywords = result.map((e) => e['keyword'] as String).toList();
      return keywords;

    } catch (e) {
      // TODO: より詳細なエラーハンドリングを実装
      print('Failed to fetch popular keywords: $e');
      rethrow;
    }
  }
}
