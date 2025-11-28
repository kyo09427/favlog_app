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
  final String productUrl;
  final String productName;
  final String subcategory;
  final String selectedCategory;
  final String reviewText;
  final double rating;
  final File? imageFile;
  final String? currentImageUrl; // Existing image URL from product
  final bool isLoading;
  final String? error;
  final List<String> categories;
  final List<String> subcategorySuggestions;

  EditReviewState({
    required this.productUrl,
    required this.productName,
    required this.subcategory,
    required this.selectedCategory,
    required this.reviewText,
    required this.rating,
    this.imageFile,
    this.currentImageUrl,
    this.isLoading = false,
    this.error,
    this.categories = const [],
    this.subcategorySuggestions = const [],
  });

  EditReviewState copyWith({
    String? productUrl,
    String? productName,
    String? subcategory,
    String? selectedCategory,
    String? reviewText,
    double? rating,
    File? imageFile,
    String? currentImageUrl,
    bool? isLoading,
    String? error,
    List<String>? categories,
    List<String>? subcategorySuggestions,
  }) {
    return EditReviewState(
      productUrl: productUrl ?? this.productUrl,
      productName: productName ?? this.productName,
      subcategory: subcategory ?? this.subcategory,
      selectedCategory: selectedCategory ?? this.selectedCategory,
      reviewText: reviewText ?? this.reviewText,
      rating: rating ?? this.rating,
      imageFile: imageFile ?? this.imageFile,
      currentImageUrl: currentImageUrl ?? this.currentImageUrl,
      isLoading: isLoading ?? this.isLoading,
      error: error,
      categories: categories ?? this.categories,
      subcategorySuggestions: subcategorySuggestions ?? this.subcategorySuggestions,
    );
  }
}

final editReviewControllerProvider =
    StateNotifierProvider.family<EditReviewController, EditReviewState, Map<String, dynamic>>((ref, args) {
  final Product product = args['product'];
  final Review review = args['review'];
  return EditReviewController(ref, product, review);
});

class EditReviewController extends StateNotifier<EditReviewState> {
  final Ref _ref;
  final Product _initialProduct;
  final Review _initialReview;
  final ImagePicker _picker = ImagePicker();

  EditReviewController(this._ref, this._initialProduct, this._initialReview)
      : super(EditReviewState(
          productUrl: _initialProduct.url ?? '',
          productName: _initialProduct.name,
          subcategory: _initialProduct.subcategory ?? '',
          selectedCategory: _initialProduct.category ?? '',
          reviewText: _initialReview.reviewText,
          rating: _initialReview.rating.toDouble(),
          currentImageUrl: _initialProduct.imageUrl,
        )) {
    _loadCategories();
    fetchSubcategorySuggestions(_initialProduct.category ?? ''); // Load initial suggestions
  }

  Future<void> _loadCategories() async {
    try {
      final categoryRepository = _ref.read(categoryRepositoryProvider);
      final fetchedCategories = await categoryRepository.getCategories();
      state = state.copyWith(categories: fetchedCategories);
    } catch (e) {
      state = state.copyWith(error: 'カテゴリの読み込みに失敗しました: ${e.toString()}');
    }
  }

  void updateProductName(String name) {
    state = state.copyWith(productName: name);
  }

  void updateProductUrl(String url) {
    state = state.copyWith(productUrl: url);
  }

  void updateSelectedCategory(String category) {
    state = state.copyWith(selectedCategory: category, subcategory: ''); // Reset subcategory when category changes
    fetchSubcategorySuggestions(category);
  }

  Future<void> fetchSubcategorySuggestions(String category) async {
    if (category.isEmpty) { // Don't fetch if no category selected
      state = state.copyWith(subcategorySuggestions: []);
      return;
    }
    try {
      final productRepository = _ref.read(productRepositoryProvider);
      final suggestions = await productRepository.getSubcategories(category);
      state = state.copyWith(subcategorySuggestions: suggestions);
    } catch (e) {
      state = state.copyWith(error: 'サブカテゴリ候補の読み込みに失敗しました: ${e.toString()}');
    }
  }

  void updateSubcategory(String subcategory) {
    state = state.copyWith(subcategory: subcategory);
  }

  void updateReviewText(String text) {
    state = state.copyWith(reviewText: text);
  }

  void updateRating(double rating) {
    state = state.copyWith(rating: rating);
  }

  Future<void> pickImage() async {
    try {
      final pickedFile = await _picker.pickImage(source: ImageSource.gallery);
      if (pickedFile != null) {
        state = state.copyWith(imageFile: File(pickedFile.path), currentImageUrl: null);
      }
    } catch (e) {
      state = state.copyWith(error: '画像の選択に失敗しました: ${e.toString()}');
    }
  }

  void clearImage() {
    state = state.copyWith(imageFile: null, currentImageUrl: null);
  }

  Future<void> updateReview() async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final authRepository = _ref.read(authRepositoryProvider);
      final productRepository = _ref.read(productRepositoryProvider);
      final reviewRepository = _ref.read(reviewRepositoryProvider);

      final user = authRepository.getCurrentUser();
      if (user == null) {
        throw Exception('ユーザーがログインしていません。');
      }

      // 製品の所有者であることを確認
      if (_initialProduct.userId != user.id) {
        throw Exception('この製品を編集する権限がありません。');
      }
      // レビューの所有者であることを確認
      if (_initialReview.userId != user.id) {
        throw Exception('このレビューを編集する権限がありません。');
      }

      String? newImageUrl = state.currentImageUrl;

      if (state.imageFile != null) {
        // --- Image Compression Logic ---
        final imageBytes = await state.imageFile!.readAsBytes();
        img.Image? originalImage = img.decodeImage(imageBytes);

        if (originalImage == null) {
          throw Exception('画像のデコードに失敗しました。');
        }

        // Resize the image to a maximum width of 1024px, maintaining aspect ratio
        final resizedImage = img.copyResize(originalImage, width: 1024);
        
        // Encode the image to JPEG format with a quality of 85
        final compressedBytes = Uint8List.fromList(img.encodeJpg(resizedImage, quality: 85));
        
        final fileExtension = state.imageFile!.path.split('.').last;
        
        newImageUrl = await productRepository.uploadProductImage(user.id, compressedBytes, fileExtension);
      } else if (state.currentImageUrl == null && _initialProduct.imageUrl != null) {
        // User cleared the image, so remove it from storage.
        // This requires a way to get the old image file name from the URL.
        // For simplicity, we'll just set newImageUrl to null for now.
        // TODO: Implement actual image deletion from storage.
        newImageUrl = null;
      }

      final updatedProduct = _initialProduct.copyWith(
        url: state.productUrl.isEmpty ? null : state.productUrl,
        name: state.productName,
        category: state.selectedCategory.isEmpty ? null : state.selectedCategory,
        subcategory: state.subcategory.isEmpty ? null : state.subcategory,
        imageUrl: newImageUrl,
      );
      await productRepository.updateProduct(updatedProduct);

      final updatedReview = _initialReview.copyWith(
        reviewText: state.reviewText,
        rating: state.rating.toInt(),
      );
      await reviewRepository.updateReview(updatedReview);

      // Reset state or handle navigation
      state = state.copyWith(isLoading: false);
    } on AuthException catch (e) {
      state = state.copyWith(isLoading: false, error: e.message);
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }
}