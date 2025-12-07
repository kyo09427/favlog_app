import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../data/repositories/supabase_product_repository.dart';
import '../../data/repositories/supabase_review_repository.dart';
import '../../data/repositories/supabase_auth_repository.dart';
import '../../domain/models/product.dart';
import '../../domain/models/review.dart';
import '../../core/providers/common_providers.dart';
import '../../core/services/image_compressor.dart';

/// レビュー追加画面の状態
class AddReviewState {
  final Product? selectedProduct; // 選択された商品
  final String reviewText;
  final double rating;
  final List<ImageData> images; // 複数画像対応
  final List<String> subcategoryTags; // サブカテゴリタグ
  final String visibility; // 公開範囲
  final bool isLoading;
  final String? error;

  AddReviewState({
    this.selectedProduct,
    this.reviewText = '',
    this.rating =3.5,
    this.images = const [],
    this.subcategoryTags = const [],
    this.visibility = 'public',
    this.isLoading = false,
    this.error,
  });

  AddReviewState copyWith({
    Product? selectedProduct,
    String? reviewText,
    double? rating,
    List<ImageData>? images,
    List<String>? subcategoryTags,
    String? visibility,
    bool? isLoading,
    String? error,
  }) {
    return AddReviewState(
      selectedProduct: selectedProduct ?? this.selectedProduct,
      reviewText: reviewText ?? this.reviewText,
      rating: rating ?? this.rating,
      images: images ?? this.images,
      subcategoryTags: subcategoryTags ?? this.subcategoryTags,
      visibility: visibility ?? this.visibility,
      isLoading: isLoading ?? this.isLoading,
      error: error,
    );
  }
}

/// 画像データクラス
class ImageData {
  final File? file; // モバイル用
  final Uint8List? bytes; // Web用
  final String? id; // 一意のID

  ImageData({
    this.file,
    this.bytes,
    String? id,
  }) : id = id ?? DateTime.now().millisecondsSinceEpoch.toString();

  bool get hasData => file != null || bytes != null;
}

/// レビュー追加コントローラーのプロバイダー
final addReviewControllerProvider =
    StateNotifierProvider.autoDispose<AddReviewController, AddReviewState>((ref) {
  final imageCompressor = ref.watch(imageCompressorProvider);
  return AddReviewController(ref, imageCompressor);
});

/// レビュー追加コントローラー
class AddReviewController extends StateNotifier<AddReviewState> {
  final Ref _ref;
  final ImageCompressor _imageCompressor;
  final ImagePicker _picker = ImagePicker();
  bool _isDisposed = false;

  AddReviewController(this._ref, this._imageCompressor, {Product? selectedProduct})
      : super(AddReviewState(selectedProduct: selectedProduct));

  @override
  void dispose() {
    _isDisposed = true;
    super.dispose();
  }

  /// 商品を設定
  void setProduct(Product product) {
    if (_isDisposed) return;
    state = state.copyWith(selectedProduct: product);
  }

  /// レビューテキストを更新
  void updateReviewText(String text) {
    if (_isDisposed) return;
    state = state.copyWith(reviewText: text);
  }

  /// 評価を更新（0.5刻み、1.0〜5.0の範囲）
  void updateRating(double rating) {
    if (_isDisposed) return;
    // 0.5刻みに丸める
    final roundedRating = (rating * 2).round() / 2;
    final clampedRating = roundedRating.clamp(0.5, 5.0);
    state = state.copyWith(rating: clampedRating);
  }

  /// 画像を追加（最大3枚まで）
  Future<void> addImage(ImageSource source) async {
    if (_isDisposed) return;
    
    // 最大3枚まで
    if (state.images.length >= 3) {
      state = state.copyWith(error: '画像は最大3枚までです');
      return;
    }

    try {
      final pickedFile = await _picker.pickImage(
        source: source,
        maxWidth: 1920,
        maxHeight: 1920,
        imageQuality: 85,
      );

      if (pickedFile != null && !_isDisposed) {
        ImageData imageData;
        if (kIsWeb) {
          final bytes = await pickedFile.readAsBytes();
          imageData = ImageData(bytes: bytes);
        } else {
          imageData = ImageData(file: File(pickedFile.path));
        }
        
        final updatedImages = List<ImageData>.from(state.images)..add(imageData);
        state = state.copyWith(images: updatedImages);
      }
    } catch (e) {
      if (!_isDisposed) {
        state = state.copyWith(error: '画像の選択に失敗しました: ${e.toString()}');
      }
    }
  }

  /// 画像を削除
  void removeImage(String imageId) {
    if (_isDisposed) return;
    final updatedImages = state.images.where((img) => img.id != imageId).toList();
    state = state.copyWith(images: updatedImages);
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

  /// 公開範囲を更新
  void updateVisibility(String visibility) {
    if (_isDisposed) return;
    state = state.copyWith(visibility: visibility);
  }

  /// レビューを投稿
  Future<bool> submitReview() async {
    if (_isDisposed) return false;
    
    // バリデーション
    if (state.selectedProduct == null) {
      state = state.copyWith(error: '商品が選択されていません');
      return false;
    }
    
    if (state.reviewText.trim().isEmpty) {
      state = state.copyWith(error: 'レビュー本文を入力してください');
      return false;
    }
    
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

      // 複数画像のアップロード処理
      final List<String> imageUrls = [];
      for (final imageData in state.images) {
        try {
          final imageBytes = kIsWeb
              ? imageData.bytes!
              : await imageData.file!.readAsBytes();
          
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
          final imageUrl = await productRepository.uploadProductImage(
            user.id,
            compressedBytes,
            fileExtension,
            contentType: contentType,
          );
          
          imageUrls.add(imageUrl);
        } catch (imageError) {
          throw Exception('画像のアップロードに失敗しました: ${imageError.toString()}');
        }
      }

      // レビュー情報を作成
      final newReview = Review(
        userId: user.id,
        productId: state.selectedProduct!.id,
        reviewText: state.reviewText,
        rating: state.rating,
        imageUrls: imageUrls,
        subcategoryTags: state.subcategoryTags,
        visibility: state.visibility,
      );

      // レビューを登録
      await reviewRepository.createReview(newReview);

      // 成功したら状態をリセット
      if (!_isDisposed) {
        state = AddReviewState(
          selectedProduct: null,
          isLoading: false,
          error: null,
        );
      }
      
      return true;
    } on AuthException catch (e) {
      // 認証エラー
      if (!_isDisposed) {
        state = state.copyWith(
          isLoading: false,
          error: '認証エラー: ${e.message}',
        );
      }
      return false;
    } catch (e) {
      // その他のエラー
      if (!_isDisposed) {
        state = state.copyWith(
          isLoading: false,
          error: e.toString(),
        );
      }
      return false;
    }
  }
}
