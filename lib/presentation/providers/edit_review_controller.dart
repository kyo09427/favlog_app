import 'dart:io';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../data/repositories/supabase_product_repository.dart';
import '../../data/repositories/supabase_review_repository.dart';
import '../../data/repositories/asset_category_repository.dart';
import '../../data/repositories/supabase_auth_repository.dart';
import '../../domain/models/product.dart';
import '../../domain/models/review.dart';

class EditReviewState {
  final Product product;
  final Review review;
  final File? imageFile;
  final String? currentImageUrl;
  final bool isLoading;
  final String? error;
  final List<String> categories;
  final List<String> subcategorySuggestions;

  EditReviewState({
    required this.product,
    required this.review,
    this.imageFile,
    this.currentImageUrl,
    this.isLoading = false,
    this.error,
    this.categories = const [],
    this.subcategorySuggestions = const [],
  });

  EditReviewState copyWith({
    Product? product,
    Review? review,
    File? imageFile,
    String? currentImageUrl,
    bool? isLoading,
    String? error,
    List<String>? categories,
    List<String>? subcategorySuggestions,
  }) {
    return EditReviewState(
      product: product ?? this.product,
      review: review ?? this.review,
      imageFile: imageFile ?? this.imageFile,
      currentImageUrl: currentImageUrl ?? this.currentImageUrl,
      isLoading: isLoading ?? this.isLoading,
      error: error,
      categories: categories ?? this.categories,
      subcategorySuggestions: subcategorySuggestions ?? this.subcategorySuggestions,
    );
  }
}

final editReviewControllerProvider = StateNotifierProvider.family<
    EditReviewController, EditReviewState, Map<String, dynamic>>((ref, args) {
  final String productId = args['productId'];
  final String reviewId = args['reviewId'];
  return EditReviewController(ref, productId, reviewId);
});

class EditReviewController extends StateNotifier<EditReviewState> {
  final Ref _ref;
  final String _productId;
  final String _reviewId;
  final ImagePicker _picker = ImagePicker();
  bool _isDisposed = false;

  EditReviewController(this._ref, this._productId, this._reviewId)
      : super(EditReviewState(
          product: Product.empty(),
          review: Review.empty(),
          isLoading: true,
        )) {
    _loadData();
    _loadCategories();
  }

  @override
  void dispose() {
    _isDisposed = true;
    super.dispose();
  }

  Future<void> _loadData() async {
    if (_isDisposed) return;
    
    state = state.copyWith(isLoading: true, error: null);
    
    try {
      final productRepository = _ref.read(productRepositoryProvider);
      final reviewRepository = _ref.read(reviewRepositoryProvider);
      final authRepository = _ref.read(authRepositoryProvider);
      
      final currentUser = authRepository.getCurrentUser();
      if (currentUser == null) {
        throw Exception('ユーザーがログインしていません');
      }

      final product = await productRepository.getProductById(_productId);
      final review = await reviewRepository.getReviewById(_reviewId);

      // セキュリティチェック: レビューの所有者確認のみ
      if (review.userId != currentUser.id) {
        throw Exception('このレビューを編集する権限がありません');
      }

      if (_isDisposed) return;

      state = state.copyWith(
        product: product,
        review: review,
        currentImageUrl: product.imageUrl,
        isLoading: false,
      );
      
      // サブカテゴリ候補を初期読み込み（表示用）
      if (product.category != null && product.category!.isNotEmpty) {
        await fetchSubcategorySuggestions(product.category!);
      }
    } on AuthException catch (e) {
      if (!_isDisposed) {
        state = state.copyWith(isLoading: false, error: '認証エラー: ${e.message}');
      }
    } catch (e) {
      if (!_isDisposed) {
        state = state.copyWith(isLoading: false, error: e.toString());
      }
    }
  }

  Future<void> _loadCategories() async {
    if (_isDisposed) return;
    
    try {
      final categoryRepository = _ref.read(categoryRepositoryProvider);
      final fetchedCategories = await categoryRepository.getCategories();
      
      if (!_isDisposed) {
        state = state.copyWith(categories: fetchedCategories);
      }
    } catch (e) {
      // カテゴリ読み込み失敗は致命的ではない
    }
  }

  void updateProductName(String name) {
    if (_isDisposed) return;
    state = state.copyWith(product: state.product.copyWith(name: name));
  }

  void updateProductUrl(String url) {
    if (_isDisposed) return;
    state = state.copyWith(product: state.product.copyWith(url: url));
  }

  void updateSelectedCategory(String category) {
    if (_isDisposed) return;
    
    final updatedProduct = state.product.copyWith(
      category: category,
      subcategory: '',
    );
    state = state.copyWith(product: updatedProduct);
    fetchSubcategorySuggestions(category);
  }

  Future<void> fetchSubcategorySuggestions(String category) async {
    if (_isDisposed || category.isEmpty) {
      if (!_isDisposed) {
        state = state.copyWith(subcategorySuggestions: []);
      }
      return;
    }
    
    try {
      final productRepository = _ref.read(productRepositoryProvider);
      final suggestions = await productRepository.getSubcategories(category);
      
      if (!_isDisposed) {
        state = state.copyWith(subcategorySuggestions: suggestions);
      }
    } catch (e) {
      // サブカテゴリ候補取得失敗は無視
    }
  }

  void updateSubcategory(String subcategory) {
    if (_isDisposed) return;
    state = state.copyWith(product: state.product.copyWith(subcategory: subcategory));
  }

  void updateReviewText(String text) {
    if (_isDisposed) return;
    state = state.copyWith(review: state.review.copyWith(reviewText: text));
  }

  void updateRating(double rating) {
    if (_isDisposed) return;
    
    final clampedRating = rating.clamp(1.0, 5.0);
    state = state.copyWith(review: state.review.copyWith(rating: clampedRating));
  }

  Future<void> pickImage() async {
    if (_isDisposed) return;
    
    try {
      final pickedFile = await _picker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 1920,
        maxHeight: 1920,
        imageQuality: 85,
      );
      
      if (pickedFile != null && !_isDisposed) {
        state = state.copyWith(
          imageFile: File(pickedFile.path),
          currentImageUrl: null,
        );
      }
    } catch (e) {
      if (!_isDisposed) {
        state = state.copyWith(error: '画像選択失敗: ${e.toString()}');
      }
    }
  }

  void clearImage() {
    if (_isDisposed) return;
    state = state.copyWith(imageFile: null, currentImageUrl: null);
  }

  /// レビューを更新（レビュー本文と評価のみ）
  /// 商品情報は一切変更しない
  Future<void> updateReview() async {
    if (_isDisposed) return;
    
    state = state.copyWith(isLoading: true, error: null);
    
    try {
      final authRepository = _ref.read(authRepositoryProvider);
      final reviewRepository = _ref.read(reviewRepositoryProvider);

      final user = authRepository.getCurrentUser();
      if (user == null) {
        throw Exception('ユーザーがログインしていません');
      }

      // セキュリティチェック: レビューの所有者確認
      if (state.review.userId != user.id) {
        throw Exception('このレビューを編集する権限がありません');
      }

      // バリデーション
      final reviewText = state.review.reviewText.trim();
      if (reviewText.isEmpty) {
        throw Exception('レビュー本文を入力してください');
      }
      if (reviewText.length < 10) {
        throw Exception('レビューは10文字以上で入力してください');
      }
      if (state.review.rating < 1.0 || state.review.rating > 5.0) {
        throw Exception('評価は1〜5の範囲で設定してください');
      }

      // レビューのみを更新
      // 重要: productIdとuserIdは変更しない
      final updatedReview = Review(
        id: state.review.id,
        createdAt: state.review.createdAt,
        userId: state.review.userId,
        productId: state.review.productId,
        reviewText: reviewText,
        rating: state.review.rating,
      );
      
      await reviewRepository.updateReview(updatedReview);

      if (!_isDisposed) {
        state = state.copyWith(
          isLoading: false,
          review: updatedReview,
        );
      }
    } on AuthException catch (e) {
      if (!_isDisposed) {
        state = state.copyWith(isLoading: false, error: '認証エラー: ${e.message}');
      }
    } catch (e) {
      if (!_isDisposed) {
        state = state.copyWith(isLoading: false, error: e.toString());
      }
    }
  }

  Future<void> refresh() async {
    await _loadData();
  }
}