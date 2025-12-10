import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../data/repositories/supabase_category_repository.dart';
import '../../domain/repositories/category_repository.dart';

final categoryRepositoryProvider = Provider<CategoryRepository>((ref) {
  return SupabaseCategoryRepository(Supabase.instance.client);
});

final popularKeywordsProvider = FutureProvider<List<String>>((ref) {
  final categoryRepository = ref.watch(categoryRepositoryProvider);
  return categoryRepository.getPopularKeywords();
});
