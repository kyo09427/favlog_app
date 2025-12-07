import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import 'package:flutter/foundation.dart' show kIsWeb;

import '../../domain/models/product.dart';
import '../providers/add_review_controller.dart';
import '../widgets/error_dialog.dart';

class AddReviewScreen extends ConsumerStatefulWidget {
  final Product? selectedProduct;

  const AddReviewScreen({super.key, this.selectedProduct});

  @override
  ConsumerState<AddReviewScreen> createState() => _AddReviewScreenState();
}

class _AddReviewScreenState extends ConsumerState<AddReviewScreen> {
  final TextEditingController _reviewTextController = TextEditingController();
  final TextEditingController _tagInputController = TextEditingController();

  @override
  void initState() {
    super.initState();
    // 選択された商品がある場合、コントローラーに設定
    if (widget.selectedProduct != null) {
      Future.microtask(() {
        ref.read(addReviewControllerProvider.notifier).setProduct(widget.selectedProduct!);
      });
    }
  }

  @override
  void dispose() {
    _reviewTextController.dispose();
    _tagInputController.dispose();
    super.dispose();
  }

  Future<void> _handleSubmit() async {
    final controller = ref.read(addReviewControllerProvider.notifier);
    final selectedProduct = ref.read(addReviewControllerProvider).selectedProduct;
    final success = await controller.submitReview();
    
    if (success && mounted && selectedProduct != null) {
      // レビュー対象の商品詳細画面へ遷移
      // goを使うことで、ブラウザの戻るボタンで投稿画面に戻らないようにする
      context.go('/product/${selectedProduct.id}');
    }
  }

// ... (省略) ...

                  SizedBox(
                    width: 48,
                    height: 48,
                    child: IconButton(
                      onPressed: () {
                        if (context.canPop()) {
                          context.pop();
                        } else {
                          context.go('/');
                        }
                      },
                      icon: Icon(Icons.close, color: textColor, size: 24),
                    ),
                  ),

// ... (省略) ...

  Widget _buildStarRating(double rating, AddReviewController controller) {
    return Row(
      children: List.generate(5, (index) {
        final starValue = index + 1;
        final isFilled = rating >= starValue;
        final isHalf = rating >= starValue - 0.5 && rating < starValue;

        return GestureDetector(
          onTapUp: (details) {
            // アイコンのサイズは36.0
            // 左半分をタップしたら0.5、右半分なら1.0として計算
            final isLeftHalf = details.localPosition.dx < 18.0;
            final newRating = starValue - (isLeftHalf ? 0.5 : 0.0);
            controller.updateRating(newRating);
          },
          child: Icon(
            isFilled
                ? Icons.star
                : isHalf
                    ? Icons.star_half
                    : Icons.star_border,
            size: 36,
            color: isFilled || isHalf ? const Color(0xFF13ec5b) : Colors.grey[400],
          ),
        );
      }),
    );
  }

  Widget _buildImageGrid(
    AddReviewState state,
    AddReviewController controller,
    Color cardColor,
    Color borderColor,
    Color textColor,
    Color mutedTextColor,
  ) {
    return GridView.count(
      crossAxisCount: 3,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      mainAxisSpacing: 12,
      crossAxisSpacing: 12,
      children: [
        ...state.images.map((imageData) {
          return Stack(
            children: [
              Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(8),
                  image: DecorationImage(
                    image: kIsWeb
                        ? MemoryImage(imageData.bytes!)
                        : FileImage(imageData.file!) as ImageProvider,
                    fit: BoxFit.cover,
                  ),
                ),
              ),
              Positioned(
                top: -6,
                right: -6,
                child: IconButton(
                  onPressed: () => controller.removeImage(imageData.id!),
                  icon: Container(
                    width: 24,
                    height: 24,
                    decoration: BoxDecoration(
                      color: Colors.black87,
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.white, width: 2),
                    ),
                    child: const Icon(
                      Icons.close,
                      color: Colors.white,
                      size: 14,
                    ),
                  ),
                ),
              ),
            ],
          );
        }),
        if (state.images.length < 3)
          GestureDetector(
            onTap: _showImageSourceDialog,
            child: Container(
              decoration: BoxDecoration(
                color: cardColor,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: borderColor, width: 2, style: BorderStyle.solid),
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.add_photo_alternate, color: mutedTextColor, size: 32),
                  const SizedBox(height: 4),
                  Text(
                    '追加',
                    style: TextStyle(color: mutedTextColor, fontSize: 12),
                  ),
                ],
              ),
            ),
          ),
      ],
    );
  }

  IconData _getVisibilityIcon(String visibility) {
    switch (visibility) {
      case 'public':
        return Icons.public;
      case 'friends':
        return Icons.group;
      case 'private':
        return Icons.lock;
      default:
        return Icons.public;
    }
  }

  String _getVisibilityLabel(String visibility) {
    switch (visibility) {
      case 'public':
        return '全体に公開';
      case 'friends':
        return '親しい友達';
      case 'private':
        return '非公開';
      default:
        return '全体に公開';
    }
  }
}
