import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../data/repositories/supabase_auth_repository.dart';
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
  SharedPreferences? _prefs;
  static const _searchHistoryKey = 'search_history';

  SearchController(this._ref) : super(SearchScreenState()) {
    _init();
  }

  Future<void> _init() async {
    _prefs = await SharedPreferences.getInstance();
    final history = _prefs?.getStringList(_searchHistoryKey) ?? [];
    state = state.copyWith(searchHistory: history);

    // 認証状態の変更を監視し、ログアウト時に履歴を削除
    _ref.read(authRepositoryProvider).authStateChanges.listen((data) {
      if (data.event == AuthChangeEvent.signedOut) {
        clearAllHistory();
      }
    });
  }

  @override
  void dispose() {
    _debounce?.cancel();
    super.dispose();
  }

  // 検索クエリの状態を更新（検索は実行しない）
  void setSearchQuery(String query) {
    state = state.copyWith(searchQuery: query);
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
    _debounce?.cancel(); // 連続実行を防ぐ
    final trimmedQuery = query.trim();
    if (trimmedQuery.isEmpty) return;

    // 検索実行時にクエリをstateにセットし、ローディング開始
    state =
        state.copyWith(searchQuery: trimmedQuery, isLoading: true, error: null);

    try {
      final productRepository = _ref.read(productRepositoryProvider);
      final reviewRepository = _ref.read(reviewRepositoryProvider);

      List<String>? tagsFilter;
      String? nameSearchQuery;

      if (trimmedQuery.startsWith('#')) {
        tagsFilter = [trimmedQuery.substring(1)]; // #を削除してタグとして扱う
        nameSearchQuery = null; // タグ検索の場合は商品名検索を行わない
      } else {
        nameSearchQuery = trimmedQuery;
        tagsFilter = null;
      }

      // フィルターに応じてカテゴリを設定
      String? categoryFilter;
      if (state.selectedFilter == '商品') {
        categoryFilter = null; // 全カテゴリから商品を検索（サービスを除外するロジックは後述）
      } else if (state.selectedFilter == 'サービス') {
        categoryFilter = 'サービス';
      }
      // 'すべて'または'ユーザー'の場合はcategoryFilterはnull

      // 商品を検索
      List<Product> products;
      if (state.selectedFilter == 'ユーザー') {
        // ユーザー検索は未実装のため空リストを返す
        products = [];
      } else {
        products = await productRepository.getProducts(
          category: categoryFilter,
          searchQuery: nameSearchQuery, // 商品名検索クエリを渡す
          tags: tagsFilter, // タグフィルタを渡す
        );

        // '商品'フィルター時は'サービス'カテゴリを除外
        if (state.selectedFilter == '商品') {
          products = products.where((p) => p.category != 'サービス').toList();
        }
      }

      // 各商品の最新レビューを一括で取得
      List<SearchResult> results = [];
      if (products.isNotEmpty) {
        final productIds = products.map((p) => p.id).toList();
        final latestReviews = await reviewRepository.getLatestReviewsByProductIds(productIds);

        results = products.map((product) {
          return SearchResult(
            product: product,
            latestReview: latestReviews[product.id],
          );
        }).toList();
      }

      state = state.copyWith(
        searchResults: results,
        isLoading: false,
      );

      // 検索履歴に追加
      _addToSearchHistory(trimmedQuery);
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: '検索に失敗しました: ${e.toString()}',
      );
    }
  }

  Future<void> _saveSearchHistory(List<String> history) async {
    await _prefs?.setStringList(_searchHistoryKey, history);
    state = state.copyWith(searchHistory: history);
  }

  // 検索履歴に追加
  void _addToSearchHistory(String query) {
    final history = List<String>.from(state.searchHistory);
    
    // 既存の同じクエリを削除
    history.remove(query);
    
    // 先頭に追加
    history.insert(0, query);
    
    // 最大5件まで保持
    if (history.length > 5) {
      history.removeLast();
    }

    _saveSearchHistory(history);
  }

  // 検索履歴をすべてクリア
  void clearAllHistory() {
    _saveSearchHistory([]);
  }

  // 検索履歴から1件削除
  void removeHistoryItem(int index) {
    final history = List<String>.from(state.searchHistory);
    history.removeAt(index);
    _saveSearchHistory(history);
  }

  // 検索履歴から検索を実行
  void searchFromHistory(String query) {
    performSearch(query);
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