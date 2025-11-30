import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../data/repositories/supabase_auth_repository.dart';
import '../../data/repositories/supabase_product_repository.dart';
import '../../data/repositories/supabase_review_repository.dart';
import '../../domain/models/product.dart';
import '../../domain/models/review.dart';

class ProductWithLatestReview {
  final Product product;
  final Review? latestReview;

  ProductWithLatestReview({required this.product, this.latestReview});
}

class HomeScreenState {
  final List<ProductWithLatestReview> products;
  final bool isLoading;
  final String? error;
  final String selectedCategory;
  final String searchQuery;

  HomeScreenState({
    required this.products,
    this.isLoading = false,
    this.error,
    this.selectedCategory = 'すべて',
    this.searchQuery = '',
  });

  HomeScreenState copyWith({
    List<ProductWithLatestReview>? products,
    bool? isLoading,
    String? error,
    String? selectedCategory,
    String? searchQuery,
  }) {
    return HomeScreenState(
      products: products ?? this.products,
      isLoading: isLoading ?? this.isLoading,
      error: error,
      selectedCategory: selectedCategory ?? this.selectedCategory,
      searchQuery: searchQuery ?? this.searchQuery,
    );
  }
}

final homeScreenControllerProvider =
    StateNotifierProvider<HomeScreenController, HomeScreenState>((ref) {
  return HomeScreenController(ref);
});

class HomeScreenController extends StateNotifier<HomeScreenState> {
  final Ref _ref;
  Timer? _debounce;
  bool _isDisposed = false;

  HomeScreenController(this._ref) : super(HomeScreenState(products: [])) {
    fetchProducts();
  }

  @override
  void dispose() {
    _isDisposed = true;
    _debounce?.cancel();
    super.dispose();
  }

  Future<void> fetchProducts({String? category, String? searchQuery}) async {
    if (_isDisposed) return;
    
    state = state.copyWith(isLoading: true, error: null);
    
    try {
      final productRepository = _ref.read(productRepositoryProvider);
      final reviewRepository = _ref.read(reviewRepositoryProvider);

      // カテゴリフィルター: "すべて"の場合はnullを渡す
      final categoryFilter = (category == null || category == 'すべて') ? null : category;
      
      final products = await productRepository.getProducts(
        category: categoryFilter,
        searchQuery: searchQuery,
      );

      if (_isDisposed) return;

      // 各商品の最新レビューを並行して取得（パフォーマンス改善）
      final List<ProductWithLatestReview> productsWithLatestReview = 
          await Future.wait(
        products.map((product) async {
          try {
            final productReviews = 
                await reviewRepository.getReviewsByProductId(product.id);
            final latestReview = productReviews.isNotEmpty ? productReviews.first : null;
            return ProductWithLatestReview(product: product, latestReview: latestReview);
          } catch (e) {
            // 個別のレビュー取得失敗は無視してnullを設定
            return ProductWithLatestReview(product: product, latestReview: null);
          }
        }),
      );

      if (_isDisposed) return;

      state = state.copyWith(
        products: productsWithLatestReview,
        isLoading: false,
        selectedCategory: category ?? 'すべて',
        searchQuery: searchQuery ?? '',
      );
    } on PostgrestException catch (e) {
      if (_isDisposed) return;
      
      // JWTエクスパイアのチェック
      if (e.message.toLowerCase().contains('jwt') && 
          (e.message.toLowerCase().contains('expired') || 
           e.message.toLowerCase().contains('invalid'))) {
        try {
          final authRepository = _ref.read(authRepositoryProvider);
          await authRepository.signOut();
          // サインアウト後は状態をリセット
          if (!_isDisposed) {
            state = HomeScreenState(products: [], error: 'セッションが期限切れです。再度ログインしてください。');
          }
        } catch (signOutError) {
          if (!_isDisposed) {
            state = state.copyWith(
              isLoading: false,
              error: '認証エラーが発生しました: ${signOutError.toString()}',
            );
          }
        }
      } else {
        state = state.copyWith(
          isLoading: false,
          error: 'データ取得エラー: ${e.message}',
        );
      }
    } catch (e) {
      if (_isDisposed) return;
      state = state.copyWith(
        isLoading: false,
        error: '予期しないエラー: ${e.toString()}',
      );
    }
  }

  void updateSearchQuery(String query) {
    if (_isDisposed) return;
    
    state = state.copyWith(searchQuery: query);
    _debounce?.cancel();
    
    // 検索クエリが空の場合は即座に実行
    if (query.isEmpty) {
      fetchProducts(category: state.selectedCategory, searchQuery: '');
      return;
    }
    
    // デバウンス処理
    _debounce = Timer(const Duration(milliseconds: 500), () {
      if (!_isDisposed) {
        fetchProducts(category: state.selectedCategory, searchQuery: query);
      }
    });
  }

  void selectCategory(String category) {
    if (_isDisposed) return;
    
    state = state.copyWith(selectedCategory: category);
    fetchProducts(category: category, searchQuery: state.searchQuery);
  }

  Future<void> signOut() async {
    if (_isDisposed) return;
    
    try {
      final authRepository = _ref.read(authRepositoryProvider);
      await authRepository.signOut();
      
      if (!_isDisposed) {
        // サインアウト成功後、状態をクリア
        state = HomeScreenState(products: []);
      }
    } catch (e) {
      if (!_isDisposed) {
        state = state.copyWith(error: 'サインアウトに失敗しました: ${e.toString()}');
      }
    }
  }
}