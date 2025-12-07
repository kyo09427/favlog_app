import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../data/repositories/supabase_product_repository.dart';
import '../../data/repositories/supabase_auth_repository.dart';
import '../../data/repositories/asset_category_repository.dart';
import '../../domain/models/product.dart';
import '../../core/providers/common_providers.dart';
import '../../core/services/image_compressor.dart';
import 'home_screen_controller.dart';
import 'search_controller.dart';
import 'review_detail_controller.dart';

/// 商品編集画面の状態
class EditProductState {
  final String productName;
  final String productUrl;
  final String selectedCategory;
  final String subcategory;
  final String? existingImageUrl;
  final File? newImageFile;
  final Uint8List? newImageBytes; // Web用に追加
  final bool isLoading;
  final String? error;
  final Product originalProduct;
  final List<String> categories;
  final List<String> subcategorySuggestions;

  EditProductState({
    required this.productName,
    required this.productUrl,
    required this.selectedCategory,
    required this.subcategory,
    this.existingImageUrl,
    this.newImageFile,
    this.newImageBytes,
    this.isLoading = false,
    this.error,
    required this.originalProduct,
    this.categories = const [],
    this.subcategorySuggestions = const [],
  });

  EditProductState copyWith({
    String? productName,
    String? productUrl,
    String? selectedCategory,
    String? subcategory,
    String? existingImageUrl,
    File? newImageFile,
    Uint8List? newImageBytes,
    bool? isLoading,
    String? error,
    Product? originalProduct,
    List<String>? categories,
    List<String>? subcategorySuggestions,
    bool clearNewImageFile = false,
    bool clearNewImageBytes = false,
  }) {
    return EditProductState(
      productName: productName ?? this.productName,
      productUrl: productUrl ?? this.productUrl,
      selectedCategory: selectedCategory ?? this.selectedCategory,
      subcategory: subcategory ?? this.subcategory,
      existingImageUrl: existingImageUrl ?? this.existingImageUrl,
      newImageFile: clearNewImageFile ? null : newImageFile ?? this.newImageFile,
      newImageBytes: clearNewImageBytes ? null : newImageBytes ?? this.newImageBytes,
      isLoading: isLoading ?? this.isLoading,
      error: error,
      originalProduct: originalProduct ?? this.originalProduct,
      categories: categories ?? this.categories,
      subcategorySuggestions: subcategorySuggestions ?? this.subcategorySuggestions,
    );
  }
}

/// 商品編集コントローラーのプロバイダー
final editProductControllerProvider = StateNotifierProvider.family<
    EditProductController, EditProductState, Product>((ref, product) {
  final imageCompressor = ref.watch(imageCompressorProvider);
  return EditProductController(ref, product, imageCompressor);
});

/// 商品編集コントローラー
class EditProductController extends StateNotifier<EditProductState> {
  final Ref _ref;
  final ImageCompressor _imageCompressor;
  final ImagePicker _picker = ImagePicker();
  bool _isDisposed = false;

  EditProductController(this._ref, Product product, this._imageCompressor)
      : super(EditProductState(
          productName: product.name,
          productUrl: product.url ?? '',
          selectedCategory: product.category ?? '',
          subcategory: product.subcategoryTags.isNotEmpty ? product.subcategoryTags.first : '',
          existingImageUrl: product.imageUrl,
          originalProduct: product,
        )) {
    _loadCategories();
    if (product.category != null && product.category!.isNotEmpty) {
      fetchSubcategorySuggestions(product.category!);
    }
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
        if (kIsWeb) {
          final imageBytes = await pickedFile.readAsBytes();
          state = state.copyWith(
            newImageBytes: imageBytes,
            newImageFile: null,
            clearNewImageFile: true,
          );
        } else {
          state = state.copyWith(
            newImageFile: File(pickedFile.path),
            newImageBytes: null,
            clearNewImageBytes: true,
          );
        }
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
    state = state.copyWith(
      clearNewImageFile: true,
      clearNewImageBytes: true,
    );
  }

  /// 商品情報を更新
  Future<void> updateProduct() async {
    if (_isDisposed) return;

    state = state.copyWith(isLoading: true, error: null);

    try {
      final authRepository = _ref.read(authRepositoryProvider);
      final productRepository = _ref.read(productRepositoryProvider);

      // ユーザー認証チェック
      final user = authRepository.getCurrentUser();
      if (user == null) {
        throw Exception('ユーザーがログインしていません。');
      }

      // 画像のアップロード処理（新しい画像が選択されている場合）
      String? imageUrl = state.existingImageUrl;
      final hasNewImage = state.newImageFile != null || state.newImageBytes != null;

      if (hasNewImage) {
        try {
          final Uint8List imageBytes;
          
          if (kIsWeb) {
            imageBytes = state.newImageBytes!;
          } else {
            imageBytes = await state.newImageFile!.readAsBytes();
          }

          // 画像を圧縮
          final compressedBytes = await _imageCompressor.compressImage(
            imageBytes,
            maxWidth: 1024,
            quality: 80,
          );

          // プラットフォームに応じて拡張子とContent-Typeを設定
          final fileExtension = kIsWeb ? 'jpg' : 'webp';
          final contentType = kIsWeb ? 'image/jpeg' : 'image/webp';

          // Supabase Storageにアップロード
          imageUrl = await productRepository.uploadProductImage(
            user.id,
            compressedBytes,
            fileExtension,
            contentType: contentType,
          );
        } catch (imageError) {
          throw Exception('画像のアップロードに失敗しました: ${imageError.toString()}');
        }
      }

      // 更新された商品情報を作成
      final updatedProduct = state.originalProduct.copyWith(
        name: state.productName,
        url: state.productUrl.isEmpty ? null : state.productUrl,
        category: state.selectedCategory.isEmpty ? null : state.selectedCategory,
        subcategoryTags: state.subcategory.isEmpty ? [] : [state.subcategory],
        imageUrl: imageUrl,
      );

      // 商品を更新
      await productRepository.updateProduct(updatedProduct);

      // 関連するプロバイダーを無効化してデータを再取得させる
      _ref.invalidate(homeScreenControllerProvider);
      _ref.invalidate(searchControllerProvider);
      
      // 商品詳細画面のプロバイダーも無効化
      _ref.invalidate(reviewDetailControllerProvider(state.originalProduct.id));

      // 成功したら状態を更新
      if (!_isDisposed) {
        state = state.copyWith(
          isLoading: false,
          originalProduct: updatedProduct,
          existingImageUrl: updatedProduct.imageUrl,
          clearNewImageFile: true,
          clearNewImageBytes: true,
        );
      }
    } on AuthException catch (e) {
      if (!_isDisposed) {
        state = state.copyWith(
          isLoading: false,
          error: '認証エラー: ${e.message}',
        );
      }
    } catch (e) {
      if (!_isDisposed) {
        state = state.copyWith(
          isLoading: false,
          error: e.toString(),
        );
      }
    }
  }
}
