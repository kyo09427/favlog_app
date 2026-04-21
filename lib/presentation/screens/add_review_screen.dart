import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:cached_network_image/cached_network_image.dart';

import '../../domain/models/product.dart';
import '../providers/add_review_controller.dart';
import 'package:favlog_app/core/config/constants.dart';

class AddReviewScreen extends ConsumerStatefulWidget {
  final Product? selectedProduct;

  const AddReviewScreen({super.key, this.selectedProduct});

  @override
  ConsumerState<AddReviewScreen> createState() => _AddReviewScreenState();
}

class _AddReviewScreenState extends ConsumerState<AddReviewScreen> {
  final TextEditingController _reviewTextController = TextEditingController();

  @override
  void initState() {
    super.initState();
    if (widget.selectedProduct != null) {
      Future.microtask(() {
        ref
            .read(addReviewControllerProvider.notifier)
            .setProduct(widget.selectedProduct!);
      });
    }
  }

  @override
  void dispose() {
    _reviewTextController.dispose();
    super.dispose();
  }

  Future<void> _handleSubmit() async {
    final controller = ref.read(addReviewControllerProvider.notifier);
    final selectedProduct = ref
        .read(addReviewControllerProvider)
        .selectedProduct;
    final success = await controller.submitReview();

    if (success && mounted && selectedProduct != null) {
      context.go('/product/${selectedProduct.id}');
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(addReviewControllerProvider);
    final controller = ref.read(addReviewControllerProvider.notifier);

    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    final backgroundColor = isDark
        ? AppColors.backgroundDark
        : AppColors.backgroundLight;
    final cardColor = isDark ? AppColors.cardDark : Colors.white;
    final textColor = isDark ? Colors.white : AppColors.textLight;
    final mutedTextColor = isDark
        ? AppColors.subtextDark
        : AppColors.subtextLight;
    final borderColor = isDark
        ? AppColors.dividerDark
        : AppColors.dividerLight;

    return Scaffold(
      backgroundColor: backgroundColor,
      body: SafeArea(
        child: Column(
          children: [
            // ヘッダー
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Row(
                children: [
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
                  Expanded(
                    child: Text(
                      'レビューを書く',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: textColor,
                      ),
                    ),
                  ),
                  SizedBox(
                    width: 48,
                    child: TextButton(
                      onPressed: state.isLoading ? null : _handleSubmit,
                      style: TextButton.styleFrom(
                        padding: EdgeInsets.zero,
                        minimumSize: Size.zero,
                        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      ),
                      child: state.isLoading
                          ? const SizedBox(
                              width: 16,
                              height: 16,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : const Text(
                              '投稿',
                              style: TextStyle(
                                color: AppColors.primary,
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                              ),
                            ),
                    ),
                  ),
                ],
              ),
            ),

            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // 商品情報
                    if (state.selectedProduct != null) ...[
                      Row(
                        children: [
                          Container(
                            width: 60,
                            height: 60,
                            decoration: BoxDecoration(
                              color: Colors.grey[200],
                              borderRadius: BorderRadius.circular(8),
                              image: state.selectedProduct!.imageUrl != null
                                  ? DecorationImage(
                                      image: CachedNetworkImageProvider(
                                        state.selectedProduct!.imageUrl!,
                                      ),
                                      fit: BoxFit.cover,
                                    )
                                  : null,
                            ),
                            child: state.selectedProduct!.imageUrl == null
                                ? const Icon(
                                    Icons.shopping_bag,
                                    color: Colors.grey,
                                  )
                                : null,
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  state.selectedProduct!.name,
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 16,
                                    color: textColor,
                                  ),
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 24),
                    ],

                    // 評価
                    Center(
                      child: Column(
                        children: [
                          Text(
                            '総合評価',
                            style: TextStyle(
                              color: textColor,
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 8),
                          _buildStarRating(state.rating, controller),
                        ],
                      ),
                    ),
                    const SizedBox(height: 32),

                    // レビュー本文
                    TextField(
                      controller: _reviewTextController,
                      maxLines: 5,
                      onChanged: controller.updateReviewText,
                      style: TextStyle(color: textColor),
                      decoration: InputDecoration(
                        hintText: 'レビュー詳細（任意）\n商品の良かった点・気になった点などを詳しく教えてください。',
                        hintStyle: TextStyle(color: mutedTextColor),
                        filled: true,
                        fillColor: cardColor,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide(color: borderColor),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide(color: borderColor),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: const BorderSide(
                            color: AppColors.primary,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 48),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStarRating(double rating, AddReviewController controller) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(5, (index) {
        final starValue = index + 1;
        final isFilled = rating >= starValue;
        final isHalf = rating >= starValue - 0.5 && rating < starValue;

        return GestureDetector(
          onTapUp: (details) {
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
            color: isFilled || isHalf
                ? AppColors.primary
                : Colors.grey[400],
          ),
        );
      }),
    );
  }
}
