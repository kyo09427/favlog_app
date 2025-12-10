import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../data/repositories/supabase_category_repository.dart';
import '../../domain/repositories/category_repository.dart';

part 'category_providers.g.dart';

@riverpod
CategoryRepository categoryRepository(CategoryRepositoryRef ref) {
  return SupabaseCategoryRepository(Supabase.instance.client);
}

@riverpod
Future<List<String>> popularKeywords(PopularKeywordsRef ref) {
  final categoryRepository = ref.watch(categoryRepositoryProvider);
  return categoryRepository.getPopularKeywords();
}
