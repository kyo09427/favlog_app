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
import '../../core/providers/common_providers.dart';
import '../../core/services/image_compressor.dart';

/// レビュー追加画面の状態
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
    bool clearImageFile = false,
  }) {
    return AddReviewState(
      productUrl: productUrl ?? this.productUrl,
      productName: productName ?? this.productName,
      subcategory: subcategory ?? this.subcategory,
      selectedCategory: selectedCategory ?? this.selectedCategory,
      reviewText: reviewText ?? this.reviewText,
      rating: rating ?? this.rating,
      imageFile: clearImageFile ? null : imageFile ?? this.imageFile,
      isLoading: isLoading ?? this.isLoading,
      error: error,
      categories: categories ?? this.categories,
      subcategorySuggestions: subcategorySuggestions ?? this.subcategorySuggestions,
    );
  }
}

/// レビュー追加コントローラーのプロバイダー
final addReviewControllerProvider =
    StateNotifierProvider<AddReviewController, AddReviewState>((ref) {
  final imageCompressor = ref.watch(imageCompressorProvider);
  return AddReviewController(ref, imageCompressor);
});

/// レビュー追加コントローラー
class AddReviewController extends StateNotifier<AddReviewState> {
  final Ref _ref;
  final ImageCompressor _imageCompressor;
  final ImagePicker _picker = ImagePicker();
  bool _isDisposed = false;

  AddReviewController(this._ref, this._imageCompressor) : super(AddReviewState()) {
    _loadCategories();
  }

  @override
  void dispose() {
    _isDisposed = true;
    super.dispose();
  }

  /// カテゴリ一覧を読み込む
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
        state = state.copyWith(error: 'カテゴリの読み込みに失敗しました: ${e.toString()}');
      }
    }
  }

  /// 商品名を更新
  void updateProductName(String name) {
    if (_isDisposed) return;
    state = state.copyWith(productName: name);
  }

  /// 商品URLを更新
  void updateProductUrl(String url) {
    if (_isDisposed) return;
    state = state.copyWith(productUrl: url);
  }

  /// 選択されたカテゴリを更新し、サブカテゴリ候補を取得
  void updateSelectedCategory(String category) {
    if (_isDisposed) return;
    
    // カテゴリ変更時はサブカテゴリをクリア
    state = state.copyWith(selectedCategory: category, subcategory: '');
    
    // カテゴリが選択されている場合のみサブカテゴリ候補を取得
    if (category.isNotEmpty) {
      fetchSubcategorySuggestions(category);
    } else {
      // カテゴリが空の場合はサブカテゴリ候補をクリア
      if (!_isDisposed) {
        state = state.copyWith(subcategorySuggestions: []);
      }
    }
  }

  /// サブカテゴリの候補を取得
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
      // サブカテゴリ候補の取得失敗は致命的エラーではないので、
      // エラーを表示せず候補リストを空にするだけ
      if (!_isDisposed) {
        state = state.copyWith(subcategorySuggestions: []);
      }
    }
  }

  /// サブカテゴリを更新
  void updateSubcategory(String subcategory) {
    if (_isDisposed) return;
    state = state.copyWith(subcategory: subcategory);
  }

  /// レビューテキストを更新
  void updateReviewText(String text) {
    if (_isDisposed) return;
    state = state.copyWith(reviewText: text);
  }

  /// 評価を更新（1.0〜5.0の範囲に制限）
  void updateRating(double rating) {
    if (_isDisposed) return;
    final clampedRating = rating.clamp(1.0, 5.0);
    state = state.copyWith(rating: clampedRating);
  }

  /// ギャラリーから画像を選択
  Future<void> pickImage(ImageSource source) async {
    if (_isDisposed) return;

    try {
      final pickedFile = await _picker.pickImage(
        source: source,
        maxWidth: 1920,
        maxHeight: 1920,
        imageQuality: 85,
      );

      if (pickedFile != null && !_isDisposed) {
        state = state.copyWith(imageFile: File(pickedFile.path));
      }
    } catch (e) {
      if (!_isDisposed) {
        state = state.copyWith(error: '画像の選択に失敗しました: ${e.toString()}');
      }
    }
  }

  /// 選択した画像をクリア
  void clearImage() {
    if (_isDisposed) return;
    state = state.copyWith(clearImageFile: true);
  }

  /// レビューを投稿
  Future<void> submitReview() async {
    if (_isDisposed) return;
    
    state = state.copyWith(isLoading: true, error: null);
    
    try {
      final authRepository = _ref.read(authRepositoryProvider);
      final productRepository = _ref.read(productRepositoryProvider);
      final reviewRepository = _ref.read(reviewRepositoryProvider);

      // ユーザー認証チェック
      final user = authRepository.getCurrentUser();
      if (user == null) {
        throw Exception('ユーザーがログインしていません。');
      }

      // 画像のアップロード処理
      String? imageUrl;
      if (state.imageFile != null) {
        try {
          final imageBytes = await state.imageFile!.readAsBytes();
          // 画像を圧縮
          final compressedBytes = await _imageCompressor.compressImage(
            imageBytes,
            maxWidth: 1024,
            quality: 80,
          );
          
          const fileExtension = 'jpg';
          
          // Supabase Storageにアップロード
          imageUrl = await productRepository.uploadProductImage(
            user.id,
            compressedBytes,
            fileExtension,
            contentType: 'image/jpeg',
          );
        } catch (imageError) {
          throw Exception('画像のアップロードに失敗しました: ${imageError.toString()}');
        }
      }

      // 商品情報を作成
      final newProduct = Product(
        userId: user.id,
        url: state.productUrl.isEmpty ? null : state.productUrl,
        name: state.productName,
        category: state.selectedCategory.isEmpty ? null : state.selectedCategory,
        subcategory: state.subcategory.isEmpty ? null : state.subcategory,
        imageUrl: imageUrl,
      );

      // 商品を登録
      await productRepository.createProduct(newProduct);

      // レビュー情報を作成
      final newReview = Review(
        userId: user.id,
        productId: newProduct.id,
        reviewText: state.reviewText,
        rating: state.rating,
      );

      // レビューを登録
      await reviewRepository.createReview(newReview);

      // 成功したら状態をリセット（カテゴリリストは保持）
      if (!_isDisposed) {
        state = AddReviewState(categories: state.categories);
      }
    } on AuthException catch (e) {
      // 認証エラー
      if (!_isDisposed) {
        state = state.copyWith(
          isLoading: false,
          error: '認証エラー: ${e.message}',
        );
      }
    } catch (e) {
      // その他のエラー
      if (!_isDisposed) {
        state = state.copyWith(
          isLoading: false,
          error: e.toString(),
        );
      }
    }
  }
}