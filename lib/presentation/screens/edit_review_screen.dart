import 'package:go_router/go_router.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../domain/models/review.dart';
import '../../domain/models/product.dart';
import '../providers/edit_review_controller.dart';
import '../widgets/error_dialog.dart';
import 'package:favlog_app/core/config/constants.dart';

class EditReviewScreen extends ConsumerStatefulWidget {
  final Review review;
  final Product product;

  const EditReviewScreen({
    super.key,
    required this.review,
    required this.product,
  });

  @override
  ConsumerState<EditReviewScreen> createState() => _EditReviewScreenState();
}

class _EditReviewScreenState extends ConsumerState<EditReviewScreen> {
  final TextEditingController _reviewTextController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _reviewTextController.text = widget.review.reviewText;
  }

  @override
  void dispose() {
    _reviewTextController.dispose();
    super.dispose();
  }

  Future<void> _handleSubmit() async {
    final controller = ref.read(
      editReviewControllerProvider(widget.review).notifier,
    );
    await controller.updateReview();

    final latestState = ref.read(editReviewControllerProvider(widget.review));
    if (mounted && latestState.error == null) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('レビューを更新しました！')));
      context.pop(true);
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(editReviewControllerProvider(widget.review));
    final controller = ref.read(
      editReviewControllerProvider(widget.review).notifier,
    );
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    const primaryColor = AppColors.primary;
    final backgroundColor = isDark
        ? AppColors.backgroundDark
        : AppColors.backgroundLight;
    final textColor = isDark ? Colors.white : AppColors.textLight;
    final mutedTextColor = isDark
        ? AppColors.subtextDark
        : AppColors.subtextLight;
    final borderColor = isDark
        ? AppColors.dividerDark
        : AppColors.dividerLight;

    if (state.error != null) {
      Future.microtask(() {
        if (context.mounted) {
          ErrorDialog.show(context, state.error!);
        }
      });
    }

    return Scaffold(
      backgroundColor: backgroundColor,
      body: SafeArea(
        child: Column(
          children: [
            // ヘッダー
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: backgroundColor,
                border: Border(bottom: BorderSide(color: borderColor)),
              ),
              child: Row(
                children: [
                  SizedBox(
                    width: 48,
                    height: 48,
                    child: IconButton(
                      onPressed: () => context.pop(),
                      icon: Icon(Icons.close, color: textColor, size: 24),
                    ),
                  ),
                  Expanded(
                    child: Text(
                      'レビュー編集',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: textColor,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                  const SizedBox(width: 48),
                ],
              ),
            ),

            // コンテンツ
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // 商品情報
                    Row(
                      children: [
                        ClipRRect(
                          borderRadius: BorderRadius.circular(8),
                          child: widget.product.imageUrl != null
                              ? CachedNetworkImage(
                                  imageUrl: widget.product.imageUrl!,
                                  width: 80,
                                  height: 80,
                                  fit: BoxFit.cover,
                                )
                              : Container(
                                  width: 80,
                                  height: 80,
                                  color: Colors.grey[300],
                                  child: const Icon(Icons.image, size: 32),
                                ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Text(
                            widget.product.name,
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: textColor,
                            ),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 32),

                    // 評価
                    Text(
                      '評価',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                        color: textColor,
                      ),
                    ),
                    const SizedBox(height: 12),
                    _buildStarRating(state.rating, controller),
                    const SizedBox(height: 32),

                    // レビュー本文
                    Text(
                      'レビュー本文',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                        color: textColor,
                      ),
                    ),
                    const SizedBox(height: 8),
                    TextField(
                      controller: _reviewTextController,
                      onChanged: controller.updateReviewText,
                      maxLines: 8,
                      style: TextStyle(color: textColor),
                      decoration: InputDecoration(
                        hintText: '良かった点、気になった点など、自由にレビューを書きましょう。',
                        hintStyle: TextStyle(color: mutedTextColor),
                        filled: true,
                        fillColor: isDark
                            ? Colors.white.withValues(alpha: 0.1)
                            : AppColors.surfaceLight,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide(color: borderColor),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide(color: borderColor),
                        ),
                        focusedBorder: const OutlineInputBorder(
                          borderRadius: BorderRadius.all(Radius.circular(12)),
                          borderSide: BorderSide(color: primaryColor, width: 2),
                        ),
                        contentPadding: const EdgeInsets.all(15),
                      ),
                    ),
                    const SizedBox(height: 100),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),

      // 更新ボタン（下部固定）
      bottomNavigationBar: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [backgroundColor.withValues(alpha: 0), backgroundColor],
          ),
          border: Border(top: BorderSide(color: borderColor)),
        ),
        child: SafeArea(
          top: false,
          child: SizedBox(
            width: double.infinity,
            height: 56,
            child: ElevatedButton(
              onPressed: state.isLoading ? null : _handleSubmit,
              style: ElevatedButton.styleFrom(
                backgroundColor: primaryColor,
                foregroundColor: Colors.black,
                disabledBackgroundColor: primaryColor.withValues(alpha: 0.5),
                elevation: 0,
                shadowColor: primaryColor.withValues(alpha: 0.3),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: state.isLoading
                  ? const SizedBox(
                      height: 24,
                      width: 24,
                      child: CircularProgressIndicator(
                        color: Colors.black,
                        strokeWidth: 2,
                      ),
                    )
                  : const Text(
                      'レビューを更新する',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildStarRating(double rating, EditReviewController controller) {
    return Row(
      children: List.generate(5, (index) {
        final starValue = index + 1;
        final isFilled = rating >= starValue;
        final isHalf = rating >= starValue - 0.5 && rating < starValue;

        return GestureDetector(
          onTap: () {
            controller.updateRating(starValue.toDouble());
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
