import 'dart:convert';
import 'package:flutter/services.dart' show rootBundle;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../domain/repositories/category_repository.dart';

final categoryRepositoryProvider = Provider<CategoryRepository>((ref) {
  return AssetCategoryRepository();
});

class AssetCategoryRepository implements CategoryRepository {
  @override
  Future<List<String>> getCategories() async {
    final String response = await rootBundle.loadString('assets/categories.json');
    final data = await json.decode(response);
    return List<String>.from(data['categories']);
  }
}