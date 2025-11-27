import 'dart:io';
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
  Future<List<Product>> getProducts({String? category}) async {
    try {
      var query = _supabaseClient
          .from('products')
          .select(); // まず select() を呼び出し、FilterBuilder を取得

      if (category != null && category != '選択してください') {
        query = query.eq('category', category); // FilterBuilder に対して eq を適用
      }

      // フィルタリングの後にソートを適用
      final response = await query.order('created_at', ascending: false).limit(100); // Limit to avoid fetching too much data
      return (response as List).map((json) => Product.fromJson(json)).toList();
    } catch (e) {
      throw Exception('Failed to get products: $e');
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
      throw Exception('Failed to get product by ID: $e');
    }
  }

  @override
  Future<void> createProduct(Product product) async {
    try {
      await _supabaseClient.from('products').insert(product.toJson());
    } catch (e) {
      throw Exception('Failed to create product: $e');
    }
  }

  @override
  Future<void> updateProduct(Product product) async {
    try {
      await _supabaseClient.from('products').update(product.toJson()).eq('id', product.id);
    } catch (e) {
      throw Exception('Failed to update product: $e');
    }
  }

  @override
  Future<void> deleteProduct(String productId) async {
    try {
      await _supabaseClient.from('products').delete().eq('id', productId);
    } catch (e) {
      throw Exception('Failed to delete product: $e');
    }
  }

  @override
  Future<String> uploadProductImage(String userId, String imagePath) async {
    try {
      final file = File(imagePath);
      final fileExtension = file.path.split('.').last;
      final fileName = '${userId}_${DateTime.now().microsecondsSinceEpoch}.$fileExtension';
      final response = await _supabaseClient.storage
          .from('product_images')
          .upload(fileName, file,
              fileOptions: const FileOptions(upsert: false));
      if (response.isNotEmpty) {
        return _supabaseClient.storage.from('product_images').getPublicUrl(fileName);
      } else {
        throw Exception('Failed to upload image: response is empty');
      }
    } on StorageException catch (e) {
      throw Exception('Failed to upload image: ${e.message}');
    } catch (e) {
      throw Exception('Failed to upload image: $e');
    }
  }
}