import 'dart:typed_data';
import '../models/product.dart';

abstract class ProductRepository {
  Future<List<Product>> getProducts({String? category, String? searchQuery});
  Future<Product> getProductById(String productId);
  Future<Product> createProduct(Product product);
  Future<Product> updateProduct(Product product);
  Future<void> deleteProduct(String productId);
  Future<void> deleteProductImage(String imageUrl);
  Future<String> uploadProductImage(String userId, Uint8List imageData, String fileExtension, {String contentType});
  Future<List<String>> getSubcategories(String category);
}