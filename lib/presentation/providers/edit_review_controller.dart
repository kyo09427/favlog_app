import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../data/repositories/supabase_review_repository.dart';
import '../../data/repositories/supabase_auth_repository.dart';
import '../../data/repositories/supabase_product_repository.dart'; // For image upload
import '../../domain/models/review.dart';
import '../../core/providers/common_providers.dart'; // For imageCompressorProvider
import '../../core/services/image_compressor.dart'; // Add this import

/// レビュー編集画面の状態
class EditReviewState {
  final String reviewText;
  final double rating;
  final List<ImageData> images; // 複数画像対応
  final List<String> subcategoryTags; // サブカテゴリタグ
  final String visibility; // 公開範囲
  final bool isLoading;
  final String? error;
  final Review originalReview;

  EditReviewState({
    required this.reviewText,
    required this.rating,
    this.images = const [],
    this.subcategoryTags = const [],
    this.visibility = 'public',
    this.isLoading = false,
    this.error,
    required this.originalReview,
  });

  EditReviewState copyWith({
    String? reviewText,
    double? rating,
    List<ImageData>? images,
    List<String>? subcategoryTags,
    String? visibility,
    bool? isLoading,
    String? error,
    Review? originalReview,
  }) {
    return EditReviewState(
      reviewText: reviewText ?? this.reviewText,
      rating: rating ?? this.rating,
      images: images ?? this.images,
      subcategoryTags: subcategoryTags ?? this.subcategoryTags,
      visibility: visibility ?? this.visibility,
      isLoading: isLoading ?? this.isLoading,
      error: error,
      originalReview: originalReview ?? this.originalReview,
    );
  }
}

/// 画像データクラス
class ImageData {
  final File? file; // モバイル用
  final Uint8List? bytes; // Web用
  final String? id; // 一意のID
  final String? url; // 既存画像のURL

  ImageData({
    this.file,
    this.bytes,
    String? id,
    this.url,
  }) : id = id ?? DateTime.now().millisecondsSinceEpoch.toString();

  bool get hasData => file != null || bytes != null || url != null;
}

/// レビュー編集コントローラーのプロバイダー
final editReviewControllerProvider = StateNotifierProvider.family<
    EditReviewController, EditReviewState, Review>((ref, review) {
  final imageCompressor = ref.watch(imageCompressorProvider); // Add this line
  return EditReviewController(ref, review, imageCompressor); // Modify constructor
});

/// レビュー編集コントローラー
class EditReviewController extends StateNotifier<EditReviewState> {
  final Ref _ref;
  final ImageCompressor _imageCompressor; // Add this field
  final ImagePicker _picker = ImagePicker(); // Add this field
  bool _isDisposed = false;

  // Modify constructor
  EditReviewController(this._ref, Review review, this._imageCompressor)
      : super(EditReviewState(
          reviewText: review.reviewText,
          rating: review.rating,
          images: review.imageUrls.map((url) => ImageData(url: url, id: url)).toList(), // Initialize images from imageUrls, using url as id for existing images
          subcategoryTags: review.subcategoryTags, // Initialize subcategoryTags
          visibility: review.visibility, // Initialize visibility
          originalReview: review,
        ));

  @override
  void dispose() {
    _isDisposed = true;
    super.dispose();
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

  /// レビューを更新
  Future<void> updateReview() async {
    if (_isDisposed) return;

    state = state.copyWith(isLoading: true, error: null);

    try {
      final authRepository = _ref.read(authRepositoryProvider);
      final reviewRepository = _ref.read(reviewRepositoryProvider);
      final productRepository = _ref.read(productRepositoryProvider); // Add this line

      // ユーザー認証チェック
      final user = authRepository.getCurrentUser();
      if (user == null) {
        throw Exception('ユーザーがログインしていません。');
      }

      // 所有者チェック
      if (state.originalReview.userId != user.id) {
        throw Exception('このレビューを編集する権限がありません。');
      }

      // --- 画像の変更を処理 ---
      final List<String> newImageUrls = [];
      final List<String> imagesToKeep = [];
      final List<ImageData> imagesToUpload = [];

      // 既存の画像URLと新しいImageDataを比較
      final originalImageUrls = state.originalReview.imageUrls;
      
      for (final imgData in state.images) {
        if (imgData.url != null) {
          // 既存の画像（URLを持つ）
          imagesToKeep.add(imgData.url!);
        } else {
          // 新しく追加された画像（ファイルまたはバイトデータを持つ）
          imagesToUpload.add(imgData);
        }
      }

      // 削除された画像を特定し、Supabase Storageから削除
      final imagesToDelete = originalImageUrls.where((url) => !imagesToKeep.contains(url)).toList();
      for (final imageUrl in imagesToDelete) {
        await productRepository.deleteProductImage(imageUrl); // productRepositoryを流用
      }

      // 新しくアップロードされる画像のURL
      final uploadedImageUrls = <String>[];
      for (final imageData in imagesToUpload) {
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
          final imageUrl = await productRepository.uploadProductImage( // productRepositoryを流用
            user.id,
            compressedBytes,
            fileExtension,
            contentType: contentType,
          );
          uploadedImageUrls.add(imageUrl);
        } catch (imageError) {
          throw Exception('画像のアップロードに失敗しました: ${imageError.toString()}');
        }
      }

      // 最終的な画像URLリスト
      newImageUrls.addAll(imagesToKeep);
      newImageUrls.addAll(uploadedImageUrls);

      // 更新されたレビュー情報を作成
      final updatedReview = state.originalReview.copyWith(
        reviewText: state.reviewText,
        rating: state.rating,
        imageUrls: newImageUrls,
        subcategoryTags: state.subcategoryTags,
        visibility: state.visibility,
      );

      // レビューを更新
      await reviewRepository.updateReview(updatedReview);

      // 成功したら状態を更新
      if (!_isDisposed) {
        state = state.copyWith(
          isLoading: false,
          originalReview: updatedReview,
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