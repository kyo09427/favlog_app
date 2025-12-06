import 'dart:typed_data';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../domain/models/product.dart';
import '../../domain/repositories/product_repository.dart';
import '../../main.dart'; // Import the main.dart to use supabaseProvider

final productRepositoryProvider = Provider<ProductRepository>((ref) {
  return SupabaseProductRepository(ref.watch(supabaseProvider));
});

class SupabaseProductRepository implements ProductRepository {
  final SupabaseClient _supabaseClient;

  SupabaseProductRepository(this._supabaseClient);

  @override
  Future<List<Product>> getProducts({String? category, String? searchQuery}) async {
    try {
      var query = _supabaseClient
          .from('products')
          .select(); // まず select() を呼び出し、FilterBuilder を取得

      if (category != null && category != 'すべて') {
        query = query.eq('category', category); // FilterBuilder に対して eq を適用
      }

      if (searchQuery != null && searchQuery.isNotEmpty) {
        query = query.ilike('name', '%$searchQuery%'); // Lightweight search by product name
      }

      // フィルタリングの後にソートを適用
      final response = await query.order('created_at', ascending: false).limit(100); // Limit to avoid fetching too much data
      return (response as List).map((json) => Product.fromJson(json)).toList();
    } catch (e) {
      rethrow;
    }
  }

  @override
  Future<Product> getProductById(String productId) async {
    try {
      final response = await _supabaseClient
          .from('products')
          .select()
          .eq('id', productId)
          .single();
      return Product.fromJson(response);
    } catch (e) {
      rethrow;
    }
  }

  @override
  Future<Product> createProduct(Product product) async {
    try {
      final response = await _supabaseClient
          .from('products')
          .insert(product.toJson())
          .select()
          .single();
      return Product.fromJson(response);
    } catch (e) {
      rethrow;
    }
  }

  @override
  Future<Product> updateProduct(Product product) async {
    try {
      final response = await _supabaseClient
          .from('products')
          .update(product.toJson())
          .eq('id', product.id)
          .select()
          .single();
      return Product.fromJson(response);
    } catch (e) {
      rethrow;
    }
  }

  @override
  Future<void> deleteProduct(String productId) async {
    try {
      await _supabaseClient.from('products').delete().eq('id', productId);
    } catch (e) {
      rethrow;
    }
  }

  @override
  Future<void> deleteProductImage(String imageUrl) async {
    try {
      final fileName = imageUrl.split('/').last;
      await _supabaseClient.storage.from('product_images').remove([fileName]);
    } catch (e) {
      // 失敗してもエラーを投げない（例: ファイルが存在しない場合など）
    }
  }

  @override
  Future<String> uploadProductImage(String userId, Uint8List imageData, String fileExtension, {String contentType = 'image/jpeg'}) async {
    try {
      final fileName = '${userId}_${DateTime.now().microsecondsSinceEpoch}.$fileExtension';
      await _supabaseClient.storage
          .from('product_images')
          .uploadBinary(fileName, imageData,
              fileOptions: FileOptions(upsert: false, contentType: contentType));
      
      return _supabaseClient.storage.from('product_images').getPublicUrl(fileName);
    } on StorageException catch (e) {
      throw Exception('Failed to upload image: ${e.message}');
    } catch (e) {
      throw Exception('Failed to upload image: $e');
    }
  }

  @override
  Future<List<String>> getSubcategories(String category) async {
    try {
      final response = await _supabaseClient
          .from('products')
          .select('subcategory')
          .eq('category', category)
          .not('subcategory', 'is', null);

      final subcategories = (response as List)
          .map((json) => json['subcategory'] as String)
          .toSet() // Remove duplicates
          .toList();
          
      return subcategories;
    } catch (e) {
      rethrow;
    }
  }
}