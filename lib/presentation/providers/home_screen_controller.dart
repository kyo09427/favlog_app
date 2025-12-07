import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../data/repositories/supabase_auth_repository.dart';
import '../../data/repositories/supabase_product_repository.dart';
import '../../data/repositories/supabase_review_repository.dart';
import '../../domain/models/product.dart';
import '../../domain/models/product_stats.dart';
import '../../domain/models/review.dart';

class ProductWithReviewAndStats {
  final Product product;
  final Review? latestReview;
  final ProductStats stats;

  ProductWithReviewAndStats({
    required this.product,
    this.latestReview,
    required this.stats,
  });

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;

    return other is ProductWithReviewAndStats &&
        other.product == product &&
        other.latestReview == latestReview &&
        other.stats == stats;
  }

  @override
  int get hashCode => product.hashCode ^ latestReview.hashCode ^ stats.hashCode;
}

class HomeScreenState {
  final List<ProductWithReviewAndStats> products;
  final bool isLoading;
  final bool isRefreshing; // 追加: プルリフレッシュ用
  final String? error;
  final String selectedCategory;
  final String searchQuery;
  final DateTime? lastFetchTime; // 追加: キャッシュ管理用

  HomeScreenState({
    required this.products,
    this.isLoading = false,
    this.isRefreshing = false,
    this.error,
    this.selectedCategory = 'すべて',
    this.searchQuery = '',
    this.lastFetchTime,
  });

  HomeScreenState copyWith({
    List<ProductWithReviewAndStats>? products,
    bool? isLoading,
    bool? isRefreshing,
    String? error,
    String? selectedCategory,
    String? searchQuery,
    DateTime? lastFetchTime,
  }) {
    return HomeScreenState(
      products: products ?? this.products,
      isLoading: isLoading ?? this.isLoading,
      isRefreshing: isRefreshing ?? this.isRefreshing,
      error: error,
      selectedCategory: selectedCategory ?? this.selectedCategory,
      searchQuery: searchQuery ?? this.searchQuery,
      lastFetchTime: lastFetchTime ?? this.lastFetchTime,
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
  Completer<void>? _fetchCompleter; // 追加: 重複リクエスト防止

  HomeScreenController(this._ref) : super(HomeScreenState(products: [])) {
    fetchProducts();
  }

  @override
  void dispose() {
    _isDisposed = true;
    _debounce?.cancel();
    _fetchCompleter = null;
    super.dispose();
  }

  // 重複リクエスト防止のヘルパー
  Future<void> _executeFetch(Future<void> Function() fetchFunction) async {
    if (_fetchCompleter != null && !_fetchCompleter!.isCompleted) {
      // 既にリクエスト中なら待つ
      return _fetchCompleter!.future;
    }

    _fetchCompleter = Completer<void>();
    try {
      await fetchFunction();
      if (!_isDisposed) {
        _fetchCompleter?.complete();
      }
    } catch (e) {
      if (!_isDisposed) {
        _fetchCompleter?.completeError(e);
      }
      rethrow;
    } finally {
      _fetchCompleter = null;
    }
  }

  Future<void> fetchProducts({
    String? category,
    String? searchQuery,
    bool isRefresh = false,
    bool forceUpdate = false, // 追加
  }) async {
    return _executeFetch(() => _fetchProductsImpl(
          category: category,
          searchQuery: searchQuery,
          isRefresh: isRefresh,
          forceUpdate: forceUpdate, // 追加
        ));
  }

  Future<void> _fetchProductsImpl({
    String? category,
    String? searchQuery,
    bool isRefresh = false,
    bool forceUpdate = false, // 追加: 強制更新フラグ
  }) async {
    if (_isDisposed) return;

    // キャッシュチェック: カテゴリや検索クエリが変更された場合はスキップしない
    final targetCategory = category ?? 'すべて';
    final targetSearchQuery = searchQuery ?? '';
    final categoryChanged = targetCategory != state.selectedCategory;
    final searchQueryChanged = targetSearchQuery != state.searchQuery;
    
    if (!isRefresh &&
        !forceUpdate &&
        !categoryChanged &&
        !searchQueryChanged &&
        state.lastFetchTime != null &&
        DateTime.now().difference(state.lastFetchTime!) <
            const Duration(seconds: 30)) {
      return;
    }

    state = state.copyWith(
      isLoading: !isRefresh,
      isRefreshing: isRefresh,
      error: null,
    );

    try {
      final productRepository = _ref.read(productRepositoryProvider);
      final reviewRepository = _ref.read(reviewRepositoryProvider);

      final categoryFilter =
          (category == null || category == 'すべて') ? null : category;

      final products = await productRepository.getProducts(
        category: categoryFilter,
        searchQuery: searchQuery,
      );

      if (_isDisposed) return;

      if (products.isEmpty) {
        state = state.copyWith(
          products: [],
          isLoading: false,
          isRefreshing: false,
          selectedCategory: category ?? 'すべて',
          searchQuery: searchQuery ?? '',
          lastFetchTime: DateTime.now(),
        );
        return;
      }

      final productIds = products.map((p) => p.id).toList();
      final currentUserId = _ref.read(authRepositoryProvider).getCurrentUser()?.id; // Add this line

      // Get latest reviews and stats in parallel
      final results = await Future.wait([
        reviewRepository.getLatestReviewsByProductIds(productIds, currentUserId: currentUserId), // Modify this line
        reviewRepository.getProductStats(productIds),
      ]);

      final latestReviewsMap = results[0] as Map<String, Review>;
      final productStatsList = results[1] as List<ProductStats>;
      final productStatsMap = {
        for (var stat in productStatsList) stat.productId: stat
      };

      final productsWithData = products.map((product) {
        return ProductWithReviewAndStats(
          product: product,
          latestReview: latestReviewsMap[product.id],
          stats:
              productStatsMap[product.id] ?? ProductStats.empty(),
        );
      }).toList();

      if (_isDisposed) return;

      state = state.copyWith(
        products: productsWithData,
        isLoading: false,
        isRefreshing: false,
        selectedCategory: category ?? 'すべて',
        searchQuery: searchQuery ?? '',
        lastFetchTime: DateTime.now(),
      );
    } on PostgrestException catch (e) {
      if (_isDisposed) return;

      // JWTエラー処理の改善
      if (_isJWTError(e)) {
        await _handleAuthenticationError();
      } else {
        _setError('データ取得エラー: ${e.message}');
      }
    } on AuthException {
      if (_isDisposed) return;
      await _handleAuthenticationError();
    } catch (e) {
      if (_isDisposed) return;
      _setError('予期しないエラー: ${e.toString()}');
    }
  }

  bool _isJWTError(PostgrestException e) {
    final message = e.message.toLowerCase();
    return message.contains('jwt') &&
        (message.contains('expired') ||
            message.contains('invalid') ||
            message.contains('malformed'));
  }

  Future<void> _handleAuthenticationError() async {
    try {
      final authRepository = _ref.read(authRepositoryProvider);
      await authRepository.signOut();

      if (!_isDisposed) {
        state = HomeScreenState(
          products: [],
          error: 'セッションが期限切れです。再度ログインしてください。',
        );
      }
    } catch (signOutError) {
      if (!_isDisposed) {
        _setError('認証エラーが発生しました: ${signOutError.toString()}');
      }
    }
  }

  void _setError(String error) {
    if (_isDisposed) return;
    state = state.copyWith(
      isLoading: false,
      isRefreshing: false,
      error: error,
    );
  }

  void updateSearchQuery(String query) {
    if (_isDisposed) return;

    state = state.copyWith(searchQuery: query);
    _debounce?.cancel();

    if (query.isEmpty) {
      fetchProducts(
        category: state.selectedCategory,
        searchQuery: '',
        forceUpdate: true, // 追加
      );
      return;
    }

    // デバウンス処理
    _debounce = Timer(const Duration(milliseconds: 500), () {
      if (!_isDisposed) {
        fetchProducts(
          category: state.selectedCategory,
          searchQuery: query,
          forceUpdate: true, // 追加
        );
      }
    });
  }

  void selectCategory(String category) {
    if (_isDisposed) return;

    // 同じカテゴリが選択された場合は何もしない
    if (category == state.selectedCategory) return;

    // forceUpdate: trueで強制的に取得
    fetchProducts(
      category: category,
      searchQuery: state.searchQuery,
      forceUpdate: true,
    );
  }

  Future<void> refresh() async {
    return fetchProducts(
      category: state.selectedCategory,
      searchQuery: state.searchQuery,
      isRefresh: true,
    );
  }

  Future<void> signOut() async {
    if (_isDisposed) return;

    try {
      final authRepository = _ref.read(authRepositoryProvider);
      await authRepository.signOut();

      if (!_isDisposed) {
        state = HomeScreenState(products: []);
      }
    } catch (e) {
      if (!_isDisposed) {
        _setError('サインアウトに失敗しました: ${e.toString()}');
      }
    }
  }
}