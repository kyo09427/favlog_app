import 'package:supabase_flutter/supabase_flutter.dart';
import '../../domain/repositories/category_repository.dart';

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

      final keywords = result.map((e) {
        final keyword = e['keyword'] as String;
        return '#$keyword';
      }).toList();
      return keywords;

    } catch (e) {
      // For now, we'll just rethrow the error.
      // In a real application, you would want to log this to a service.
      rethrow;
    }
  }
}
