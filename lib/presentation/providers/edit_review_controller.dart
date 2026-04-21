import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../data/repositories/supabase_review_repository.dart';
import '../../data/repositories/supabase_auth_repository.dart';
import '../../data/repositories/supabase_product_repository.dart';
import '../../domain/models/review.dart';
import '../../core/providers/common_providers.dart';
import '../../core/services/image_compressor.dart';
import '../../core/config/constants.dart';

class EditReviewState {
  final String reviewText;
  final double rating;
  final List<ImageData> images;
  final bool isLoading;
  final String? error;
  final Review originalReview;

  EditReviewState({
    required this.reviewText,
    required this.rating,
    this.images = const [],
    this.isLoading = false,
    this.error,
    required this.originalReview,
  });

  EditReviewState copyWith({
    String? reviewText,
    double? rating,
    List<ImageData>? images,
    bool? isLoading,
    String? error,
    Review? originalReview,
  }) {
    return EditReviewState(
      reviewText: reviewText ?? this.reviewText,
      rating: rating ?? this.rating,
      images: images ?? this.images,
      isLoading: isLoading ?? this.isLoading,
      error: error,
      originalReview: originalReview ?? this.originalReview,
    );
  }
}

class ImageData {
  final File? file;
  final Uint8List? bytes;
  final String? id;
  final String? url;

  ImageData({this.file, this.bytes, String? id, this.url})
    : id = id ?? DateTime.now().millisecondsSinceEpoch.toString();

  bool get hasData => file != null || bytes != null || url != null;
}

final editReviewControllerProvider =
    StateNotifierProvider.family<EditReviewController, EditReviewState, Review>(
      (ref, review) {
        final imageCompressor = ref.watch(imageCompressorProvider);
        return EditReviewController(ref, review, imageCompressor);
      },
    );

class EditReviewController extends StateNotifier<EditReviewState> {
  final Ref _ref;
  final ImageCompressor _imageCompressor;
  final ImagePicker _picker = ImagePicker();
  bool _isDisposed = false;

  EditReviewController(this._ref, Review review, this._imageCompressor)
    : super(
        EditReviewState(
          reviewText: review.reviewText,
          rating: review.rating,
          images: review.imageUrls
              .map((url) => ImageData(url: url, id: url))
              .toList(),
          originalReview: review,
        ),
      );

  @override
  void dispose() {
    _isDisposed = true;
    super.dispose();
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

  Future<void> updateReview() async {
    if (_isDisposed) return;

    final trimmedText = state.reviewText.trim();
    if (trimmedText.isEmpty) {
      state = state.copyWith(error: 'レビュー本文を入力してください');
      return;
    }

    if (trimmedText.length > ValidationLimits.reviewTextMaxLength) {
      state = state.copyWith(
        error: 'レビュー本文は${ValidationLimits.reviewTextMaxLength}文字以内で入力してください',
      );
      return;
    }

    state = state.copyWith(isLoading: true, error: null);

    try {
      final authRepository = _ref.read(authRepositoryProvider);
      final reviewRepository = _ref.read(reviewRepositoryProvider);
      final productRepository = _ref.read(productRepositoryProvider);

      final user = authRepository.getCurrentUser();
      if (user == null) {
        throw Exception('ユーザーがログインしていません。');
      }

      if (state.originalReview.userId != user.id) {
        throw Exception('このレビューを編集する権限がありません。');
      }

      final List<String> imagesToKeep = [];
      final List<ImageData> imagesToUpload = [];

      for (final imgData in state.images) {
        if (imgData.url != null) {
          imagesToKeep.add(imgData.url!);
        } else {
          imagesToUpload.add(imgData);
        }
      }

      final imagesToDelete = state.originalReview.imageUrls
          .where((url) => !imagesToKeep.contains(url))
          .toList();
      for (final imageUrl in imagesToDelete) {
        await productRepository.deleteProductImage(imageUrl);
      }

      final uploadedImageUrls = <String>[];
      for (final imageData in imagesToUpload) {
        try {
          final imageBytes = kIsWeb
              ? imageData.bytes!
              : await imageData.file!.readAsBytes();

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
          uploadedImageUrls.add(imageUrl);
        } catch (imageError) {
          throw Exception('画像のアップロードに失敗しました: ${imageError.toString()}');
        }
      }

      final newImageUrls = [...imagesToKeep, ...uploadedImageUrls];

      final updatedReview = state.originalReview.copyWith(
        reviewText: state.reviewText,
        rating: state.rating,
        imageUrls: newImageUrls,
      );

      await reviewRepository.updateReview(updatedReview);

      if (!_isDisposed) {
        state = state.copyWith(isLoading: false, originalReview: updatedReview);
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
