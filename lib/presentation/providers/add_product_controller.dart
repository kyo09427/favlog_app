import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../data/repositories/supabase_product_repository.dart';
import '../../data/repositories/asset_category_repository.dart';
import '../../data/repositories/supabase_auth_repository.dart';
import '../../domain/models/product.dart';
import '../../core/providers/common_providers.dart';
import '../../core/services/image_compressor.dart';

/// 商品追加画面の状態
class AddProductState {
  final String productName;
  final String productUrl;
  final String? selectedCategory;
  final List<String> subcategoryTags;
  final File? imageFile;
  final Uint8List? imageBytes;
  final bool isLoading;
  final String? error;
  final List<String> categories;

  AddProductState({
    this.productName = '',
    this.productUrl = '',
    this.selectedCategory,
    this.subcategoryTags = const [],
    this.imageFile,
    this.imageBytes,
    this.isLoading = false,
    this.error,
    this.categories = const [],
  });

  AddProductState copyWith({
    String? productName,
    String? productUrl,
    String? selectedCategory,
    List<String>? subcategoryTags,
    File? imageFile,
    Uint8List? imageBytes,
    bool? isLoading,
    String? error,
    List<String>? categories,
    bool clearImage = false,
  }) {
    return AddProductState(
      productName: productName ?? this.productName,
      productUrl: productUrl ?? this.productUrl,
      selectedCategory: selectedCategory ?? this.selectedCategory,
      subcategoryTags: subcategoryTags ?? this.subcategoryTags,
      imageFile: clearImage ? null : (imageFile ?? this.imageFile),
      imageBytes: clearImage ? null : (imageBytes ?? this.imageBytes),
      isLoading: isLoading ?? this.isLoading,
      error: error,
      categories: categories ?? this.categories,
    );
  }

  bool get hasImage => imageFile != null || imageBytes != null;
}

/// 商品追加コントローラーのプロバイダー
final addProductControllerProvider =
    StateNotifierProvider.autoDispose<AddProductController, AddProductState>((ref) {
  final imageCompressor = ref.watch(imageCompressorProvider);
  return AddProductController(ref, imageCompressor);
});

/// 商品追加コントローラー
class AddProductController extends StateNotifier<AddProductState> {
  final Ref _ref;
  final ImageCompressor _imageCompressor;
  final ImagePicker _picker = ImagePicker();
  bool _isDisposed = false;

  AddProductController(this._ref, this._imageCompressor) : super(AddProductState()) {
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
      final categoryRepository = _ref.read(assetCategoryRepositoryProvider);
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

  /// カテゴリを選択
  void selectCategory(String category) {
    if (_isDisposed) return;
    state = state.copyWith(selectedCategory: category);
  }

  /// サブカテゴリタグを追加
  void addSubcategoryTag(String tag) {
    if (_isDisposed) return;
    final trimmedTag = tag.trim();
    if (trimmedTag.isEmpty) return;

    // 重複チェック
    if (state.subcategoryTags.contains(trimmedTag)) return;

    final updatedTags = List<String>.from(state.subcategoryTags)..add(trimmedTag);
    state = state.copyWith(subcategoryTags: updatedTags);
  }

  /// サブカテゴリタグを削除
  void removeSubcategoryTag(String tag) {
    if (_isDisposed) return;
    final updatedTags = state.subcategoryTags.where((t) => t != tag).toList();
    state = state.copyWith(subcategoryTags: updatedTags);
  }

  /// 画像を選択
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
          state = state.copyWith(imageBytes: imageBytes, imageFile: null);
        } else {
          state = state.copyWith(imageFile: File(pickedFile.path), imageBytes: null);
        }
      }
    } catch (e) {
      if (!_isDisposed) {
        state = state.copyWith(error: '画像の選択に失敗しました: ${e.toString()}');
      }
    }
  }

  /// 画像をクリア
  void clearImage() {
    if (_isDisposed) return;
    state = state.copyWith(clearImage: true);
  }

  /// バリデーション
  bool _validate() {
    if (state.productName.trim().isEmpty) {
      state = state.copyWith(error: '商品名を入力してください');
      return false;
    }

    if (state.selectedCategory == null) {
      state = state.copyWith(error: 'カテゴリを選択してください');
      return false;
    }

    if (!state.hasImage) {
      state = state.copyWith(error: '商品画像を追加してください');
      return false;
    }

    return true;
  }

  /// 商品を登録
  Future<Product?> submitProduct() async {
    if (_isDisposed) return null;

    // バリデーション
    if (!_validate()) {
      return null;
    }

    state = state.copyWith(isLoading: true, error: null);

    try {
      final authRepository = _ref.read(authRepositoryProvider);
      final productRepository = _ref.read(productRepositoryProvider);

      // ユーザー認証チェック
      final user = authRepository.getCurrentUser();
      if (user == null) {
        throw Exception('ユーザーがログインしていません。');
      }

      // 画像のアップロード処理
      String? imageUrl;
      try {
        final imageBytes = kIsWeb
            ? state.imageBytes!
            : await state.imageFile!.readAsBytes();

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

      // 商品情報を作成
      final newProduct = Product(
        userId: user.id,
        url: state.productUrl.isEmpty ? null : state.productUrl,
        name: state.productName,
        category: state.selectedCategory,
        subcategoryTags: state.subcategoryTags,
        imageUrl: imageUrl,
      );

      // 商品を登録し、DBから返された情報を取得
      final createdProduct = await productRepository.createProduct(newProduct);

      // 成功したら状態をリセット
      if (!_isDisposed) {
        state = AddProductState(categories: state.categories);
      }

      return createdProduct;
    } on AuthException catch (e) {
      // 認証エラー
      if (!_isDisposed) {
        state = state.copyWith(
          isLoading: false,
          error: '認証エラー: ${e.message}',
        );
      }
      return null;
    } catch (e) {
      // その他のエラー
      if (!_isDisposed) {
        state = state.copyWith(
          isLoading: false,
          error: e.toString(),
        );
      }
      return null;
    }
  }
}
