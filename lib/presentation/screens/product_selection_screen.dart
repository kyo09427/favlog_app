import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../domain/models/product.dart';
import '../../data/repositories/supabase_product_repository.dart';
import '../../data/repositories/supabase_review_repository.dart';

class ProductSelectionScreen extends ConsumerStatefulWidget {
  const ProductSelectionScreen({super.key});

  @override
  ConsumerState<ProductSelectionScreen> createState() => _ProductSelectionScreenState();
}

class _ProductSelectionScreenState extends ConsumerState<ProductSelectionScreen> {
  final TextEditingController _searchController = TextEditingController();
  List<Product> _recentProducts = [];
  List<Product> _searchResults = [];

  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadRecentProducts();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadRecentProducts() async {
    setState(() => _isLoading = true);
    
    try {
      final reviewRepository = ref.read(reviewRepositoryProvider);
      final productRepository = ref.read(productRepositoryProvider);
      
      // 全ユーザーの最近のレビューを取得（カテゴリやフィルタなし）
      final reviews = await reviewRepository.getReviews();
      
      // レビューを作成日時の降順でソート
      reviews.sort((a, b) => b.createdAt.compareTo(a.createdAt));
      
      // レビューから商品IDを抽出し、重複を排除（最大5件）
      final seenProductIds = <String>{};
      final productIds = <String>[];
      
      for (var review in reviews) {
        if (!seenProductIds.contains(review.productId)) {
          seenProductIds.add(review.productId);
          productIds.add(review.productId);
          if (productIds.length >= 5) break;
        }
      }
      
      // 商品情報を取得
      final products = <Product>[];
      for (var productId in productIds) {
        try {
          final product = await productRepository.getProductById(productId);
          products.add(product);
        } catch (e) {
          // 商品が見つからない場合はスキップ
          continue;
        }
      }
      
      setState(() {
        _recentProducts = products;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _searchProducts(String query) async {
    if (query.trim().isEmpty) {
      setState(() {
        _searchResults = [];
      });
      return;
    }



    try {
      final productRepository = ref.read(productRepositoryProvider);
      // すべての商品を取得してクライアント側でフィルタリング
      final allProducts = await productRepository.getProducts();
      final filteredProducts = allProducts
          .where((product) => product.name.toLowerCase().contains(query.toLowerCase()))
          .toList();
      
      setState(() {
        _searchResults = filteredProducts;
      });
    } catch (e) {
      setState(() => _searchResults = []);
    }
  }

  void _selectProduct(Product product) {
    context.push('/add-review', extra: {'product': product});
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    const primaryColor = Color(0xFF13ec5b);
    final textColor = isDark ? Colors.white : const Color(0xFF1F2937);
    final mutedTextColor = isDark ? const Color(0xFF9CA3AF) : const Color(0xFF6B7280);
    final backgroundColor = isDark ? const Color(0xFF102216) : const Color(0xFFF6F8F6);
    final cardColor = isDark ? const Color(0xFF1C1C1E) : Colors.white;
    final borderColor = isDark ? const Color(0xFF374151) : const Color(0xFFE5E7EB);

    final displayProducts = _searchController.text.isNotEmpty ? _searchResults : _recentProducts;

    return Scaffold(
      backgroundColor: backgroundColor,
      body: SafeArea(
        child: Column(
          children: [
            // ヘッダー
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: backgroundColor,
                border: Border(bottom: BorderSide(color: borderColor)),
              ),
              child: Row(
                children: [
                  SizedBox(
                    width: 48,
                    height: 48,
                    child: IconButton(
                      onPressed: () => context.pop(),
                      icon: Icon(Icons.close, color: textColor, size: 24),
                    ),
                  ),
                  Expanded(
                    child: Text(
                      'レビューする商品',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: textColor,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                  const SizedBox(width: 48),
                ],
              ),
            ),

            // 検索フィールド
            Padding(
              padding: const EdgeInsets.all(16),
              child: TextField(
                controller: _searchController,
                onChanged: _searchProducts,
                style: TextStyle(color: textColor),
                decoration: InputDecoration(
                  hintText: '商品やサービスを検索',
                  hintStyle: TextStyle(color: mutedTextColor),
                  prefixIcon: Icon(Icons.search, color: mutedTextColor),
                  filled: true,
                  fillColor: isDark ? Colors.white.withValues(alpha: 0.1) : const Color(0xFFF3F4F6),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(24),
                    borderSide: BorderSide(color: borderColor),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(24),
                    borderSide: BorderSide(color: borderColor),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(24),
                    borderSide: const BorderSide(color: primaryColor, width: 2),
                  ),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
                ),
              ),
            ),

            // コンテンツ
            Expanded(
              child: _isLoading
                  ? const Center(child: CircularProgressIndicator(color: primaryColor))
                  : displayProducts.isEmpty
                      ? Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                _searchController.text.isNotEmpty
                                    ? Icons.search_off
                                    : Icons.inbox_outlined,
                                size: 64,
                                color: mutedTextColor,
                              ),
                              const SizedBox(height: 16),
                              Text(
                                _searchController.text.isNotEmpty
                                    ? '商品が見つかりませんでした'
                                    : 'まだレビューがありません',
                                style: TextStyle(
                                  fontSize: 16,
                                  color: mutedTextColor,
                                ),
                              ),
                            ],
                          ),
                        )
                      : ListView(
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          children: [
                            if (_searchController.text.isEmpty) ...[
                              Text(
                                '最近レビューされた商品',
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold,
                                  color: mutedTextColor,
                                  letterSpacing: 0.5,
                                ),
                              ),
                              const SizedBox(height: 16),
                            ],
                            ...displayProducts.map((product) => _buildProductItem(
                                  product,
                                  textColor,
                                  mutedTextColor,
                                  cardColor,
                                  borderColor,
                                )),
                            const SizedBox(height: 24),
                            // 新しい商品を追加ボタン
                            Container(
                              padding: const EdgeInsets.only(top: 16),
                              decoration: BoxDecoration(
                                border: Border(top: BorderSide(color: borderColor)),
                              ),
                              child: Column(
                                children: [
                                  Text(
                                    'お探しの商品が見つかりませんか？',
                                    style: TextStyle(
                                      fontSize: 14,
                                      color: mutedTextColor,
                                    ),
                                    textAlign: TextAlign.center,
                                  ),
                                  const SizedBox(height: 16),
                                  SizedBox(
                                    width: double.infinity,
                                    height: 48,
                                    child: ElevatedButton.icon(
                                      onPressed: () {
                                        context.push('/add-product');
                                      },
                                      icon: const Icon(Icons.add_circle_outline),
                                      label: const Text('新しい商品を追加する'),
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: isDark
                                            ? Colors.white.withValues(alpha: 0.1)
                                            : const Color(0xFFE5E7EB),
                                        foregroundColor: textColor,
                                        elevation: 0,
                                        shape: RoundedRectangleBorder(
                                          borderRadius: BorderRadius.circular(12),
                                        ),
                                      ),
                                    ),
                                  ),
                                  const SizedBox(height: 16),
                                ],
                              ),
                            ),
                          ],
                        ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildProductItem(
    Product product,
    Color textColor,
    Color mutedTextColor,
    Color cardColor,
    Color borderColor,
  ) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: InkWell(
        onTap: () => _selectProduct(product),
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: cardColor,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: borderColor),
          ),
          child: Row(
            children: [
              // 商品画像
              ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: product.imageUrl != null
                    ? CachedNetworkImage(
                        imageUrl: product.imageUrl!,
                        width: 56,
                        height: 56,
                        fit: BoxFit.cover,
                        placeholder: (context, url) => Container(
                          width: 56,
                          height: 56,
                          color: Colors.grey[300],
                        ),
                        errorWidget: (context, url, error) => Container(
                          width: 56,
                          height: 56,
                          color: Colors.grey[300],
                          child: const Icon(Icons.image_not_supported),
                        ),
                      )
                    : Container(
                        width: 56,
                        height: 56,
                        color: Colors.grey[300],
                        child: const Icon(Icons.image),
                      ),
              ),
              const SizedBox(width: 16),
              // 商品情報
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      product.name,
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                        color: textColor,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      product.category ?? '',
                      style: TextStyle(
                        fontSize: 14,
                        color: mutedTextColor,
                      ),
                    ),
                  ],
                ),
              ),
              Icon(
                Icons.arrow_forward_ios,
                size: 16,
                color: mutedTextColor,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
