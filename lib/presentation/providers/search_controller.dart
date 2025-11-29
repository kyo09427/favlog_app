import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/repositories/supabase_product_repository.dart';
import '../../data/repositories/supabase_review_repository.dart';
import '../../domain/models/product.dart';
import '../../domain/models/review.dart';

// 検索結果を格納するクラス
class SearchResult {
  final Product product;
  final Review? latestReview;

  SearchResult({required this.product, this.latestReview});
}

// 検索画面の状態
class SearchScreenState {
  final String searchQuery;
  final String selectedFilter; // 'すべて', '商品', 'サービス', 'ユーザー'
  final List<SearchResult> searchResults;
  final List<String> searchHistory;
  final bool isLoading;
  final String? error;

  SearchScreenState({
    this.searchQuery = '',
    this.selectedFilter = 'すべて',
    this.searchResults = const [],
    this.searchHistory = const [],
    this.isLoading = false,
    this.error,
  });

  SearchScreenState copyWith({
    String? searchQuery,
    String? selectedFilter,
    List<SearchResult>? searchResults,
    List<String>? searchHistory,
    bool? isLoading,
    String? error,
  }) {
    return SearchScreenState(
      searchQuery: searchQuery ?? this.searchQuery,
      selectedFilter: selectedFilter ?? this.selectedFilter,
      searchResults: searchResults ?? this.searchResults,
      searchHistory: searchHistory ?? this.searchHistory,
      isLoading: isLoading ?? this.isLoading,
      error: error,
    );
  }
}

// 検索コントローラーのプロバイダー
final searchControllerProvider =
    StateNotifierProvider<SearchController, SearchScreenState>((ref) {
  return SearchController(ref);
});

class SearchController extends StateNotifier<SearchScreenState> {
  final Ref _ref;
  Timer? _debounce;

  SearchController(this._ref) : super(SearchScreenState()) {
    _loadSearchHistory();
  }

  @override
  void dispose() {
    _debounce?.cancel();
    super.dispose();
  }

  // 検索履歴の読み込み（簡易実装：メモリ内のみ）
  void _loadSearchHistory() {
    // TODO: SharedPreferencesなどで永続化する場合はここで読み込み
    state = state.copyWith(searchHistory: [
      'オーガニックコーヒー',
      'ワイヤレスイヤホン',
      '新宿 カフェ',
    ]);
  }

  // 検索クエリの更新（デバウンス付き）
  void updateSearchQuery(String query) {
    state = state.copyWith(searchQuery: query);
    
    _debounce?.cancel();
    
    if (query.isEmpty) {
      state = state.copyWith(searchResults: [], isLoading: false);
      return;
    }

    _debounce = Timer(const Duration(milliseconds: 500), () {
      performSearch(query);
    });
  }

  // フィルターの選択
  void selectFilter(String filter) {
    state = state.copyWith(selectedFilter: filter);
    if (state.searchQuery.isNotEmpty) {
      performSearch(state.searchQuery);
    }
  }

  // 検索の実行
  Future<void> performSearch(String query) async {
    if (query.isEmpty) return;

    state = state.copyWith(isLoading: true, error: null);

    try {
      final productRepository = _ref.read(productRepositoryProvider);
      final reviewRepository = _ref.read(reviewRepositoryProvider);

      // フィルターに応じてカテゴリを設定
      String? categoryFilter;
      if (state.selectedFilter == '商品') {
        // 商品カテゴリのみ（本、家電、食品、ファッション、ゲーム、映画/音楽、その他）
        categoryFilter = null; // 全カテゴリから商品を検索（サービスを除外するロジックは後述）
      } else if (state.selectedFilter == 'サービス') {
        categoryFilter = 'サービス';
      }
      // 'すべて'または'ユーザー'の場合はcategoryFilterはnull

      // 商品を検索
      List<Product> products;
      if (state.selectedFilter == 'ユーザー') {
        // ユーザー検索は未実装のため空リストを返す
        // TODO: ユーザー検索機能の実装
        products = [];
      } else {
        products = await productRepository.getProducts(
          category: categoryFilter,
          searchQuery: query,
        );

        // '商品'フィルター時は'サービス'カテゴリを除外
        if (state.selectedFilter == '商品') {
          products = products.where((p) => p.category != 'サービス').toList();
        }
      }

      // 各商品の最新レビューを取得
      List<SearchResult> results = [];
      for (var product in products) {
        final reviews = await reviewRepository.getReviewsByProductId(product.id);
        final latestReview = reviews.isNotEmpty ? reviews.first : null;
        results.add(SearchResult(product: product, latestReview: latestReview));
      }

      state = state.copyWith(
        searchResults: results,
        isLoading: false,
      );

      // 検索履歴に追加
      _addToSearchHistory(query);
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: '検索に失敗しました: ${e.toString()}',
      );
    }
  }

  // 検索履歴に追加
  void _addToSearchHistory(String query) {
    final history = List<String>.from(state.searchHistory);
    
    // 既存の同じクエリを削除
    history.remove(query);
    
    // 先頭に追加
    history.insert(0, query);
    
    // 最大10件まで保持
    if (history.length > 10) {
      history.removeLast();
    }

    state = state.copyWith(searchHistory: history);
    
    // TODO: SharedPreferencesなどで永続化
  }

  // 検索履歴をすべてクリア
  void clearAllHistory() {
    state = state.copyWith(searchHistory: []);
    // TODO: SharedPreferencesなどで永続化
  }

  // 検索履歴から1件削除
  void removeHistoryItem(int index) {
    final history = List<String>.from(state.searchHistory);
    history.removeAt(index);
    state = state.copyWith(searchHistory: history);
    // TODO: SharedPreferencesなどで永続化
  }

  // 検索履歴から検索を実行
  void searchFromHistory(String query) {
    updateSearchQuery(query);
  }

  // 検索をクリア
  void clearSearch() {
    state = state.copyWith(
      searchQuery: '',
      searchResults: [],
      isLoading: false,
      error: null,
    );
  }
}