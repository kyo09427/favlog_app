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
import '../../core/config/constants.dart';

class AddReviewState {
  final Product? selectedProduct;
  final String reviewText;
  final double rating;
  final List<ImageData> images;
  final bool isLoading;
  final String? error;

  AddReviewState({
    this.selectedProduct,
    this.reviewText = '',
    this.rating = 3.5,
    this.images = const [],
    this.isLoading = false,
    this.error,
  });

  AddReviewState copyWith({
    Product? selectedProduct,
    String? reviewText,
    double? rating,
    List<ImageData>? images,
    bool? isLoading,
    String? error,
  }) {
    return AddReviewState(
      selectedProduct: selectedProduct ?? this.selectedProduct,
      reviewText: reviewText ?? this.reviewText,
      rating: rating ?? this.rating,
      images: images ?? this.images,
      isLoading: isLoading ?? this.isLoading,
      error: error,
    );
  }
}

class ImageData {
  final File? file;
  final Uint8List? bytes;
  final String? id;

  ImageData({this.file, this.bytes, String? id})
    : id = id ?? DateTime.now().millisecondsSinceEpoch.toString();

  bool get hasData => file != null || bytes != null;
}

final addReviewControllerProvider =
    StateNotifierProvider.autoDispose<AddReviewController, AddReviewState>((
      ref,
    ) {
      final imageCompressor = ref.watch(imageCompressorProvider);
      return AddReviewController(ref, imageCompressor);
    });

class AddReviewController extends StateNotifier<AddReviewState> {
  final Ref _ref;
  final ImageCompressor _imageCompressor;
  final ImagePicker _picker = ImagePicker();
  bool _isDisposed = false;

  AddReviewController(this._ref, this._imageCompressor)
    : super(AddReviewState());

  @override
  void dispose() {
    _isDisposed = true;
    super.dispose();
  }

  void setProduct(Product product) {
    if (_isDisposed) return;
    state = state.copyWith(selectedProduct: product);
  }

  void updateReviewText(String text) {
    if (_isDisposed) return;
    state = state.copyWith(reviewText: text);
  }

  void updateRating(double rating) {
    if (_isDisposed) return;
    final roundedRating = (rating * 2).round() / 2;
    final clampedRating = roundedRating.clamp(0.5, 5.0);
    state = state.copyWith(rating: clampedRating);
  }

  Future<void> addImage(ImageSource source) async {
    if (_isDisposed) return;

    if (state.images.length >= AppLimits.reviewImageMaxCount) {
      state = state.copyWith(error: '画像は最大${AppLimits.reviewImageMaxCount}枚までです');
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
        final ImageData imageData;
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

  void removeImage(String imageId) {
    if (_isDisposed) return;
    final updatedImages = state.images.where((img) => img.id != imageId).toList();
    state = state.copyWith(images: updatedImages);
  }

  Future<bool> submitReview() async {
    if (_isDisposed) return false;

    final selectedProduct = state.selectedProduct;
    if (selectedProduct == null) {
      state = state.copyWith(error: '商品が選択されていません');
      return false;
    }

    final trimmedText = state.reviewText.trim();
    if (trimmedText.isEmpty) {
      state = state.copyWith(error: 'レビュー本文を入力してください');
      return false;
    }

    if (trimmedText.length > ValidationLimits.reviewTextMaxLength) {
      state = state.copyWith(
        error: 'レビュー本文は${ValidationLimits.reviewTextMaxLength}文字以内で入力してください',
      );
      return false;
    }

    state = state.copyWith(isLoading: true, error: null);

    try {
      final authRepository = _ref.read(authRepositoryProvider);
      final productRepository = _ref.read(productRepositoryProvider);
      final reviewRepository = _ref.read(reviewRepositoryProvider);

      final user = authRepository.getCurrentUser();
      if (user == null) {
        throw Exception('ユーザーがログインしていません。');
      }

      final List<String> imageUrls = [];
      for (final imageData in state.images) {
        try {
          final Uint8List imageBytes;
          if (kIsWeb) {
            if (imageData.bytes == null) throw Exception('画像データが見つかりません');
            imageBytes = imageData.bytes!;
          } else {
            if (imageData.file == null) throw Exception('画像ファイルが見つかりません');
            imageBytes = await imageData.file!.readAsBytes();
          }

          final compressedBytes = await _imageCompressor.compressImage(
            imageBytes,
            maxWidth: 1024,
            quality: 80,
          );

          final isDesktop =
              !kIsWeb && (Platform.isWindows || Platform.isLinux || Platform.isFuchsia);
          final fileExtension = isDesktop ? 'jpg' : 'webp';
          final contentType = isDesktop ? 'image/jpeg' : 'image/webp';

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

      final newReview = Review(
        userId: user.id,
        productId: selectedProduct.id,
        reviewText: state.reviewText,
        rating: state.rating,
        imageUrls: imageUrls,
        subcategoryTags: const [],
        visibility: 'public',
      );

      await reviewRepository.createReview(newReview);

      if (!_isDisposed) {
        state = AddReviewState(selectedProduct: null, isLoading: false, error: null);
      }

      return true;
    } on AuthException catch (e) {
      if (!_isDisposed) {
        state = state.copyWith(isLoading: false, error: '認証エラー: ${e.message}');
      }
      return false;
    } catch (e) {
      if (!_isDisposed) {
        state = state.copyWith(isLoading: false, error: e.toString());
      }
      return false;
    }
  }
}
