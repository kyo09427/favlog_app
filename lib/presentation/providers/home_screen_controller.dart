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

  HomeScreenState({
    required this.products,
    this.isLoading = false,
    this.error,
    this.selectedCategory = 'すべて',
  });

  HomeScreenState copyWith({
    List<ProductWithLatestReview>? products,
    bool? isLoading,
    String? error,
    String? selectedCategory,
  }) {
    return HomeScreenState(
      products: products ?? this.products,
      isLoading: isLoading ?? this.isLoading,
      error: error,
      selectedCategory: selectedCategory ?? this.selectedCategory,
    );
  }
}

final homeScreenControllerProvider =
    StateNotifierProvider<HomeScreenController, HomeScreenState>((ref) {
  return HomeScreenController(ref);
});

class HomeScreenController extends StateNotifier<HomeScreenState> {
  final Ref _ref;

  HomeScreenController(this._ref) : super(HomeScreenState(products: [])) {
    fetchProducts();
  }

  Future<void> fetchProducts({String? category}) async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final productRepository = _ref.read(productRepositoryProvider);
      final reviewRepository = _ref.read(reviewRepositoryProvider);
      
      final products = await productRepository.getProducts(category: category);

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
      );
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  Future<void> signOut() async {
    try {
      final authRepository = _ref.read(authRepositoryProvider);
      await authRepository.signOut();
    } on AuthException catch (e) {
      state = state.copyWith(error: e.message);
    } catch (e) {
      state = state.copyWith(error: e.toString());
    }
  }

  void selectCategory(String category) {
    state = state.copyWith(selectedCategory: category);
    fetchProducts(category: category);
  }
}