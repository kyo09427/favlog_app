import 'dart:async'; // Import for Timer
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart'; // For AuthException
import '../../data/repositories/supabase_auth_repository.dart';
import '../../data/repositories/supabase_product_repository.dart';
import '../../data/repositories/supabase_review_repository.dart';
import '../../domain/models/product.dart';
import '../../domain/models/review.dart';

// Represents a product combined with its latest review for display on the home screen
class ProductWithLatestReview {
  final Product product;
  final Review? latestReview;

  ProductWithLatestReview({required this.product, this.latestReview});
}

// State for the HomeScreen
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
  Timer? _debounce; // Debounce timer

  HomeScreenController(this._ref) : super(HomeScreenState(products: [])) {
    fetchProducts();
  }

  @override
  void dispose() {
    _debounce?.cancel();
    super.dispose();
  }

  Future<void> fetchProducts({String? category, String? searchQuery}) async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final productRepository = _ref.read(productRepositoryProvider);
      final reviewRepository = _ref.read(reviewRepositoryProvider);
      
      final products = await productRepository.getProducts(category: category, searchQuery: searchQuery);

      List<ProductWithLatestReview> productsWithLatestReview = [];
      for (var product in products) {
        // Fetch only the latest review for this product using the new efficient method
        final productReviews = await reviewRepository.getReviewsByProductId(product.id);
        final latestReview = productReviews.isNotEmpty ? productReviews.first : null; 

        productsWithLatestReview.add(
            ProductWithLatestReview(product: product, latestReview: latestReview));
      }
      state = state.copyWith(
        products: productsWithLatestReview,
        isLoading: false,
        selectedCategory: category ?? 'すべて',
        searchQuery: searchQuery ?? '',
      );
    } on PostgrestException catch (e) {
      if (e.message.contains('JWT expired')) {
        // If token expired, sign out the user
        final authRepository = _ref.read(authRepositoryProvider);
        await authRepository.signOut();
      } else {
        state = state.copyWith(isLoading: false, error: e.toString());
      }
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  void updateSearchQuery(String query) {
    state = state.copyWith(searchQuery: query);
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 500), () {
      fetchProducts(category: state.selectedCategory, searchQuery: query);
    });
  }

  void selectCategory(String category) {
    state = state.copyWith(selectedCategory: category);
    fetchProducts(category: category, searchQuery: state.searchQuery);
  }

  // サインアウトメソッドを追加
  Future<void> signOut() async {
    try {
      final authRepository = _ref.read(authRepositoryProvider);
      await authRepository.signOut();
    } catch (e) {
      state = state.copyWith(error: 'サインアウトに失敗しました: ${e.toString()}');
    }
  }
}