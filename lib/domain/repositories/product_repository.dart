import '../models/product.dart';

abstract class ProductRepository {
  Future<List<Product>> getProducts({String? category});
  Future<Product> getProductById(String productId);
  Future<void> createProduct(Product product);
  Future<void> updateProduct(Product product);
  Future<void> deleteProduct(String productId);
  Future<String> uploadProductImage(String userId, String imagePath);
}