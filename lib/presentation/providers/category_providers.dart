import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:favlog_app/data/repositories/asset_category_repository.dart';

final categoriesProvider = FutureProvider<List<String>>((ref) async {
  final categoryRepository = ref.watch(categoryRepositoryProvider);
  return ['すべて', ...await categoryRepository.getCategories()];
});