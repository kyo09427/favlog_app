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

class AddReviewState {
  final String productUrl;
  final String productName;
  final String subcategory;
  final String selectedCategory;
  final String reviewText;
  final double rating;
  final File? imageFile;
  final bool isLoading;
  final String? error;
  final List<String> categories;
  final List<String> subcategorySuggestions;

  AddReviewState({
    this.productUrl = '',
    this.productName = '',
    this.subcategory = '',
    this.selectedCategory = '',
    this.reviewText = '',
    this.rating = 3.0,
    this.imageFile,
    this.isLoading = false,
    this.error,
    this.categories = const [],
    this.subcategorySuggestions = const [],
  });

  AddReviewState copyWith({
    String? productUrl,
    String? productName,
    String? subcategory,
    String? selectedCategory,
    String? reviewText,
    double? rating,
    File? imageFile,
    bool? isLoading,
    String? error,
    List<String>? categories,
    List<String>? subcategorySuggestions,
  }) {
    return AddReviewState(
      productUrl: productUrl ?? this.productUrl,
      productName: productName ?? this.productName,
      subcategory: subcategory ?? this.subcategory,
      selectedCategory: selectedCategory ?? this.selectedCategory,
      reviewText: reviewText ?? this.reviewText,
      rating: rating ?? this.rating,
      imageFile: imageFile ?? this.imageFile,
      isLoading: isLoading ?? this.isLoading,
      error: error,
      categories: categories ?? this.categories,
      subcategorySuggestions: subcategorySuggestions ?? this.subcategorySuggestions,
    );
  }
}

final addReviewControllerProvider =
    StateNotifierProvider<AddReviewController, AddReviewState>((ref) {
  return AddReviewController(ref);
});

class AddReviewController extends StateNotifier<AddReviewState> {
  final Ref _ref;
  final ImagePicker _picker = ImagePicker();

  AddReviewController(this._ref) : super(AddReviewState()) {
    _loadCategories();
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
        state = state.copyWith(imageFile: File(pickedFile.path));
      }
    } catch (e) {
      state = state.copyWith(error: '画像の選択に失敗しました: ${e.toString()}');
    }
  }

  Future<void> submitReview() async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final authRepository = _ref.read(authRepositoryProvider);
      final productRepository = _ref.read(productRepositoryProvider);
      final reviewRepository = _ref.read(reviewRepositoryProvider);

      final user = authRepository.getCurrentUser();
      if (user == null) {
        throw Exception('ユーザーがログインしていません。');
      }

      String? imageUrl;
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
        
        imageUrl = await productRepository.uploadProductImage(user.id, compressedBytes, fileExtension);
      }

      final newProduct = Product(
        userId: user.id,
        url: state.productUrl.isEmpty ? null : state.productUrl,
        name: state.productName,
        category: state.selectedCategory.isEmpty ? null : state.selectedCategory,
        subcategory: state.subcategory.isEmpty ? null : state.subcategory,
        imageUrl: imageUrl,
      );

      await productRepository.createProduct(newProduct);

      final newReview = Review(
        userId: user.id,
        productId: newProduct.id,
        reviewText: state.reviewText,
        rating: state.rating.toInt(),
      );

      await reviewRepository.createReview(newReview);

      state = AddReviewState(categories: state.categories); // Reset form and keep categories
    } on AuthException catch (e) {
      state = state.copyWith(isLoading: false, error: e.message);
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }
}