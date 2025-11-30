import 'dart:io';
import 'dart:typed_data';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:image/image.dart' as img;
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

      // セキュリティチェック: 所有者確認
      if (product.userId != currentUser.id) {
        throw Exception('この商品を編集する権限がありません');
      }
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
      
      await fetchSubcategorySuggestions(product.category ?? '');
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
      if (!_isDisposed) {
        state = state.copyWith(error: 'カテゴリの読み込みに失敗: ${e.toString()}');
      }
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
      subcategory: '', // カテゴリ変更時にサブカテゴリをリセット
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
      if (!_isDisposed) {
        state = state.copyWith(error: 'サブカテゴリ候補取得失敗: ${e.toString()}');
      }
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
    
    // 評価は1.0〜5.0の範囲に制限
    final clampedRating = rating.clamp(1.0, 5.0);
    state = state.copyWith(review: state.review.copyWith(rating: clampedRating));
  }

  Future<void> pickImage() async {
    if (_isDisposed) return;
    
    try {
      final pickedFile = await _picker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 1920, // 最大幅を制限
        maxHeight: 1920, // 最大高さを制限
        imageQuality: 85, // 初期品質
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

  Future<void> updateReview() async {
    if (_isDisposed) return;
    
    state = state.copyWith(isLoading: true, error: null);
    
    try {
      final authRepository = _ref.read(authRepositoryProvider);
      final productRepository = _ref.read(productRepositoryProvider);
      final reviewRepository = _ref.read(reviewRepositoryProvider);

      final user = authRepository.getCurrentUser();
      if (user == null) {
        throw Exception('ユーザーがログインしていません');
      }

      // 二重チェック: 所有者確認
      if (state.product.userId != user.id) {
        throw Exception('この商品を編集する権限がありません');
      }
      if (state.review.userId != user.id) {
        throw Exception('このレビューを編集する権限がありません');
      }

      // バリデーション
      if (state.product.name.trim().isEmpty) {
        throw Exception('商品名を入力してください');
      }
      if (state.review.reviewText.trim().isEmpty) {
        throw Exception('レビュー本文を入力してください');
      }
      if (state.review.rating < 1.0 || state.review.rating > 5.0) {
        throw Exception('評価は1〜5の範囲で設定してください');
      }

      String? newImageUrl = state.currentImageUrl;

      // 新しい画像がある場合
      if (state.imageFile != null) {
        final imageBytes = await state.imageFile!.readAsBytes();
        img.Image? originalImage = img.decodeImage(imageBytes);

        if (originalImage == null) {
          throw Exception('画像のデコードに失敗しました');
        }

        // リサイズと圧縮
        final resizedImage = img.copyResize(originalImage, width: 1024);
        final compressedBytes = Uint8List.fromList(
          img.encodeJpg(resizedImage, quality: 85),
        );

        final fileExtension = state.imageFile!.path.split('.').last;
        
        newImageUrl = await productRepository.uploadProductImage(
          user.id,
          compressedBytes,
          fileExtension,
        );
      } else if (state.currentImageUrl == null && state.product.imageUrl != null) {
        // 画像がクリアされた場合
        newImageUrl = null;
      }

      // 商品情報を更新
      final updatedProduct = state.product.copyWith(imageUrl: newImageUrl);
      await productRepository.updateProduct(updatedProduct);

      // レビューを更新
      final updatedReview = state.review.copyWith();
      await reviewRepository.updateReview(updatedReview);

      if (!_isDisposed) {
        state = state.copyWith(isLoading: false);
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
}