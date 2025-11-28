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
  final String? currentImageUrl; // Existing image URL from product
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

final editReviewControllerProvider =
    StateNotifierProvider.family<EditReviewController, EditReviewState, Map<String, dynamic>>((ref, args) {
  final String productId = args['productId']; // Now pass IDs
  final String reviewId = args['reviewId'];   // Now pass IDs
  return EditReviewController(ref, productId, reviewId);
});

class EditReviewController extends StateNotifier<EditReviewState> {
  final Ref _ref;
  final String _productId;
  final String _reviewId;
  final ImagePicker _picker = ImagePicker();

  EditReviewController(this._ref, this._productId, this._reviewId)
      : super(EditReviewState(
          product: Product.empty(), // Initial placeholder product
          review: Review.empty(),   // Initial placeholder review
          isLoading: true,
        )) {
    _loadData();
    _loadCategories();
  }

  Future<void> _loadData() async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final productRepository = _ref.read(productRepositoryProvider);
      final reviewRepository = _ref.read(reviewRepositoryProvider);

      final product = await productRepository.getProductById(_productId);
      final review = await reviewRepository.getReviewById(_reviewId);

      state = state.copyWith(
        product: product,
        review: review,
        currentImageUrl: product.imageUrl,
        isLoading: false,
      );
      fetchSubcategorySuggestions(product.category ?? ''); // Load initial suggestions based on fetched product
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
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
    state = state.copyWith(product: state.product.copyWith(name: name));
  }

  void updateProductUrl(String url) {
    state = state.copyWith(product: state.product.copyWith(url: url));
  }

  void updateSelectedCategory(String category) {
    final updatedProduct = state.product.copyWith(category: category, subcategory: '');
    state = state.copyWith(product: updatedProduct);
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
    state = state.copyWith(product: state.product.copyWith(subcategory: subcategory));
  }

  void updateReviewText(String text) {
    state = state.copyWith(review: state.review.copyWith(reviewText: text));
  }

  void updateRating(double rating) {
    state = state.copyWith(review: state.review.copyWith(rating: rating.toInt()));
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
      if (state.product.userId != user.id) {
        throw Exception('この製品を編集する権限がありません。');
      }
      // レビューの所有者であることを確認
      if (state.review.userId != user.id) {
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
      } else if (state.currentImageUrl == null && state.product.imageUrl != null) {
        newImageUrl = null;
      }

      final updatedProduct = state.product.copyWith(
        url: state.product.url,
        name: state.product.name,
        category: state.product.category,
        subcategory: state.product.subcategory,
        imageUrl: newImageUrl,
      );
      await productRepository.updateProduct(updatedProduct);

      final updatedReview = state.review.copyWith(
        reviewText: state.review.reviewText,
        rating: state.review.rating,
      );
      await reviewRepository.updateReview(updatedReview);

      state = state.copyWith(isLoading: false);
    } on AuthException catch (e) {
      state = state.copyWith(isLoading: false, error: e.message);
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }
}