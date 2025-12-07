import 'package:go_router/go_router.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shimmer/shimmer.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import 'package:flutter/foundation.dart' show kIsWeb;

import '../../domain/models/review.dart';
import '../../domain/models/product.dart';
import '../providers/edit_review_controller.dart';
import '../widgets/error_dialog.dart';

class EditReviewScreen extends ConsumerStatefulWidget {
  final Review review;
  final Product product;

  const EditReviewScreen({
    super.key,
    required this.review,
    required this.product,
  });

  @override
  ConsumerState<EditReviewScreen> createState() =>
      _EditReviewScreenState();
}

class _EditReviewScreenState extends ConsumerState<EditReviewScreen> {
  final TextEditingController _reviewTextController = TextEditingController();
  final TextEditingController _tagInputController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _reviewTextController.text = widget.review.reviewText;
  }

  @override
  void dispose() {
    _reviewTextController.dispose();
    _tagInputController.dispose();
    super.dispose();
  }

  Future<void> _handleSubmit() async {
    final controller = ref.read(editReviewControllerProvider(widget.review).notifier);
    await controller.updateReview();
    
    final latestState = ref.read(editReviewControllerProvider(widget.review));
    if (mounted && latestState.error == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('レビューを更新しました！')),
      );
      context.pop(true); // 成功したら前の画面に戻る
    }
  }

  Future<void> _showImageSourceDialog() async {
    showModalBottomSheet(
      context: context,
      builder: (context) => SafeArea(
        child: Wrap(
          children: [
            ListTile(
              leading: const Icon(Icons.photo_library),
              title: const Text('ギャラリーから選択'),
              onTap: () {
                context.pop();
                ref.read(editReviewControllerProvider(widget.review).notifier).addImage(ImageSource.gallery);
              },
            ),
            ListTile(
              leading: const Icon(Icons.photo_camera),
              title: const Text('カメラで撮影'),
              onTap: () {
                context.pop();
                ref.read(editReviewControllerProvider(widget.review).notifier).addImage(ImageSource.camera);
              },
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _showVisibilityDialog() async {
    final currentVisibility = ref.read(editReviewControllerProvider(widget.review)).visibility;
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('公開範囲'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _buildVisibilityOption('public', '全体に公開', Icons.public, currentVisibility),
            _buildVisibilityOption('friends', '親しい友達', Icons.group, currentVisibility),
            _buildVisibilityOption('private', '非公開', Icons.lock, currentVisibility),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => context.pop(),
            child: const Text('閉じる'),
          ),
        ],
      ),
    );
  }

  Widget _buildVisibilityOption(String value, String label, IconData icon, String currentValue) {
    final isSelected = value == currentValue;
    const primaryColor = Color(0xFF13ec5b);
    
    return ListTile(
      leading: Icon(icon, color: isSelected ? primaryColor : null),
      title: Text(label),
      trailing: isSelected ? const Icon(Icons.check, color: primaryColor) : null,
      selected: isSelected,
      onTap: () {
        ref.read(editReviewControllerProvider(widget.review).notifier).updateVisibility(value);
        context.pop();
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(editReviewControllerProvider(widget.review));
    final controller = ref.read(editReviewControllerProvider(widget.review).notifier);
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    const primaryColor = Color(0xFF13ec5b);
    final backgroundColor = isDark ? const Color(0xFF102216) : const Color(0xFFF6F8F6);
    final cardColor = isDark ? const Color(0xFF1C1C1E) : Colors.white;
    final textColor = isDark ? Colors.white : const Color(0xFF1F2937);
    final mutedTextColor = isDark ? const Color(0xFF9CA3AF) : const Color(0xFF6B7280);
    final borderColor = isDark ? const Color(0xFF374151) : const Color(0xFFE5E7EB);

    // エラー表示
    if (state.error != null) {
      Future.microtask(() {
        ErrorDialog.show(context, state.error!);
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
                        // 商品画像
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
                        // 商品名
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

                    // 写真を追加
                    Text(
                      '写真を追加',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                        color: textColor,
                      ),
                    ),
                    const SizedBox(height: 12),
                    _buildImageGrid(state, controller, cardColor, borderColor, textColor, mutedTextColor),
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
                        fillColor: isDark ? Colors.white.withOpacity(0.1) : const Color(0xFFF3F4F6),
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
                    const SizedBox(height: 32),

                    // サブカテゴリ
                    Text(
                      'サブカテゴリ (任意)',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                        color: mutedTextColor,
                      ),
                    ),
                    const SizedBox(height: 8),
                    TextField(
                      controller: _tagInputController,
                      style: TextStyle(color: textColor),
                      decoration: InputDecoration(
                        hintText: '例：ミステリー小説、ワイヤレスイヤホン',
                        hintStyle: TextStyle(color: mutedTextColor),
                        filled: true,
                        fillColor: isDark ? Colors.white.withOpacity(0.1) : const Color(0xFFF3F4F6),
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
                        suffixIcon: IconButton(
                          icon: const Icon(Icons.add),
                          onPressed: () {
                            if (_tagInputController.text.trim().isNotEmpty) {
                              controller.addSubcategoryTag(_tagInputController.text.trim());
                              _tagInputController.clear();
                            }
                          },
                        ),
                        contentPadding: const EdgeInsets.symmetric(horizontal: 15, vertical: 14),
                      ),
                      onSubmitted: (value) {
                        if (value.trim().isNotEmpty) {
                          controller.addSubcategoryTag(value.trim());
                          _tagInputController.clear();
                        }
                      },
                    ),
                    if (state.subcategoryTags.isNotEmpty) ...[
                      const SizedBox(height: 12),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: state.subcategoryTags.map((tag) {
                          return Chip(
                            label: Text('#$tag'),
                            deleteIcon: const Icon(Icons.close, size: 16),
                            onDeleted: () => controller.removeSubcategoryTag(tag),
                            backgroundColor: primaryColor.withOpacity(0.2),
                            labelStyle: const TextStyle(
                              color: primaryColor,
                              fontWeight: FontWeight.w500,
                            ),
                            deleteIconColor: primaryColor,
                          );
                        }).toList(),
                      ),
                    ],
                    const SizedBox(height: 32),

                    // 公開範囲
                    Text(
                      '公開範囲',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                        color: textColor,
                      ),
                    ),
                    const SizedBox(height: 8),
                    InkWell(
                      onTap: _showVisibilityDialog,
                      borderRadius: BorderRadius.circular(12),
                      child: Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: isDark ? Colors.white.withOpacity(0.1) : const Color(0xFFF3F4F6),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Row(
                          children: [
                            Container(
                              width: 32,
                              height: 32,
                              decoration: BoxDecoration(
                                color: primaryColor.withOpacity(0.2),
                                shape: BoxShape.circle,
                              ),
                              child: Icon(
                                _getVisibilityIcon(state.visibility),
                                color: primaryColor,
                                size: 18,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Text(
                                _getVisibilityLabel(state.visibility),
                                style: TextStyle(
                                  fontSize: 16,
                                  color: textColor,
                                ),
                              ),
                            ),
                            Icon(Icons.arrow_forward_ios, size: 16, color: mutedTextColor),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 100), // ボタン用のスペース
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
            colors: [
              backgroundColor.withOpacity(0),
              backgroundColor,
            ],
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
                disabledBackgroundColor: primaryColor.withOpacity(0.5),
                elevation: 0,
                shadowColor: primaryColor.withOpacity(0.3),
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
            // タップした星の位置で評価を設定
            controller.updateRating(starValue.toDouble());
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
    EditReviewState state,
    EditReviewController controller,
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
                    image: imageData.url != null
                        ? CachedNetworkImageProvider(imageData.url!) as ImageProvider
                        : (kIsWeb
                            ? MemoryImage(imageData.bytes!)
                            : FileImage(imageData.file!) as ImageProvider),
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
