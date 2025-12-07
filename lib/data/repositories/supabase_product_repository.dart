import 'dart:typed_data';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../domain/models/product.dart';
import '../../domain/repositories/product_repository.dart';
import '../../main.dart';

final productRepositoryProvider = Provider<ProductRepository>((ref) {
  return SupabaseProductRepository(ref.watch(supabaseProvider));
});

class SupabaseProductRepository implements ProductRepository {
  final SupabaseClient _supabaseClient;

  SupabaseProductRepository(this._supabaseClient);

  @override
  Future<List<Product>> getProducts({String? category, String? searchQuery, List<String>? tags}) async {
    try {
      var query = _supabaseClient.from('products').select();

      if (category != null && category != 'すべて') {
        query = query.eq('category', category);
      }

      if (searchQuery != null && searchQuery.isNotEmpty) {
        query = query.ilike('name', '%$searchQuery%');
      }
      
      if (tags != null && tags.isNotEmpty) {
        // subcategory_tagsはTEXT[]型なので、containsで複数のタグを含むかをチェック
        query = query.contains('subcategory_tags', tags);
      }

      final response = await query.order('created_at', ascending: false).limit(100);

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
  Future<void> updateProduct(Product product) async {
    try {
      // デバッグ用にログ出力
      print('Updating product: ${product.id}');
      print('User ID: ${_supabaseClient.auth.currentUser?.id}');
      print('Product user_id: ${product.userId}');
      print('Product data: ${product.toJson()}');
      
      // まず、商品が存在するか確認
      final existingProduct = await _supabaseClient
          .from('products')
          .select()
          .eq('id', product.id)
          .maybeSingle();
      
      print('Existing product: $existingProduct');
      
      if (existingProduct == null) {
        throw Exception('商品が見つかりません（ID: ${product.id}）');
      }
      
      // 更新を実行して結果を取得
      final result = await _supabaseClient
          .from('products')
          .update({
            'name': product.name,
            'url': product.url,
            'category': product.category,
            'subcategory_tags': product.subcategoryTags,
            'image_url': product.imageUrl,
          })
          .eq('id', product.id)
          .select();
      
      print('Update result: $result');
      
      // 更新された行が0行の場合はRLSポリシーで拒否された可能性が高い
      if (result.isEmpty) {
        throw Exception('商品の更新に失敗しました。この商品を編集する権限がない可能性があります。');
      }
      
      print('Update completed successfully');

      // 画像が変更された場合、古い画像を削除
      if (existingProduct['image_url'] != null && 
          existingProduct['image_url'] != product.imageUrl) {
        await deleteProductImage(existingProduct['image_url'] as String);
      }
    } on PostgrestException catch (e) {
      print('PostgrestException: ${e.message}');
      print('Details: ${e.details}');
      print('Hint: ${e.hint}');
      print('Code: ${e.code}');
      
      if (e.code == '42501') {
        throw Exception('更新権限がありません。この商品を編集する権限がない可能性があります。');
      }
      throw Exception('商品の更新に失敗しました: ${e.message}');
    } catch (e) {
      print('Update error: $e');
      rethrow;
    }
  }

  @override
  Future<void> deleteProduct(String productId) async {
    try {
      // 削除前に商品情報を取得して画像URLを確保
      final product = await getProductById(productId);
      
      await _supabaseClient.from('products').delete().eq('id', productId);

      // 画像があれば削除
      if (product.imageUrl != null) {
        await deleteProductImage(product.imageUrl!);
      }
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
  Future<String> uploadProductImage(String userId, Uint8List imageData, String fileExtension, {String contentType = 'image/webp'}) async {
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
          .toSet()
          .toList();
          
      return subcategories;
    } catch (e) {
      rethrow;
    }
  }
}
