import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/repositories/asset_category_repository.dart';
import '../../data/repositories/supabase_category_repository.dart';
import '../../domain/repositories/category_repository.dart';
import '../../main.dart';

// Supabase-based repository for categories
final supabaseCategoryRepositoryProvider = Provider<CategoryRepository>((ref) {
  return SupabaseCategoryRepository(ref.watch(supabaseProvider));
});

// Provides the list of categories including 'すべて'
final categoriesProvider = FutureProvider<List<String>>((ref) async {
  final categoryRepository = ref.watch(assetCategoryRepositoryProvider);
  return ['すべて', ...await categoryRepository.getCategories()];
});

// Provides the list of popular keywords
final popularKeywordsProvider = FutureProvider<List<String>>((ref) {
  final categoryRepository = ref.watch(supabaseCategoryRepositoryProvider);
  return categoryRepository.getPopularKeywords();
});
