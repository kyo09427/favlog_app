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
      context.go('/product/${selectedProduct.id}');
    }
  }

  Future<void> _showImageSourceDialog() async {
    final picker = ImagePicker();
    final source = await showDialog<ImageSource>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('画像の追加'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.camera_alt),
              title: const Text('カメラで撮影'),
              onTap: () => Navigator.pop(context, ImageSource.camera),
            ),
            ListTile(
              leading: const Icon(Icons.photo_library),
              title: const Text('アルバムから選択'),
              onTap: () => Navigator.pop(context, ImageSource.gallery),
            ),
          ],
        ),
      ),
    );

    if (source != null) {
      final XFile? image = await picker.pickImage(
        source: source,
        maxWidth: 1024,
        maxHeight: 1024,
        imageQuality: 85,
      );
      
      if (image != null) {
        ref.read(addReviewControllerProvider.notifier).addImage(File(image.path));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(addReviewControllerProvider);
    final controller = ref.read(addReviewControllerProvider.notifier);
    
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    
    final backgroundColor = isDark ? const Color(0xFF102216) : const Color(0xFFF6F8F6);
    final cardColor = isDark ? const Color(0xFF1C1C1E) : Colors.white;
    final textColor = isDark ? Colors.white : const Color(0xFF1F2937);
    final mutedTextColor = isDark ? const Color(0xFF9CA3AF) : const Color(0xFF6B7280);
    final borderColor = isDark ? const Color(0xFF374151) : const Color(0xFFE5E7EB);

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
                                color: Color(0xFF13ec5b),
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
                                      image: CachedNetworkImageProvider(state.selectedProduct!.imageUrl!),
                                      fit: BoxFit.cover,
                                    )
                                  : null,
                            ),
                            child: state.selectedProduct!.imageUrl == null
                                ? const Icon(Icons.shopping_bag, color: Colors.grey)
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
                                if (state.selectedProduct!.brand != null)
                                  Text(
                                    state.selectedProduct!.brand!,
                                    style: TextStyle(color: mutedTextColor, fontSize: 13),
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
                          borderSide: const BorderSide(color: Color(0xFF13ec5b)),
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),

                    // 写真
                    Text(
                      '写真',
                      style: TextStyle(
                        color: textColor,
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 12),
                    _buildImageGrid(state, controller, cardColor, borderColor, textColor, mutedTextColor),
                    const SizedBox(height: 24),

                    // タグ
                    Text(
                      'タグ',
                      style: TextStyle(
                        color: textColor,
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        ...state.tags.map((tag) => Chip(
                              label: Text(tag, style: const TextStyle(fontSize: 12)),
                              backgroundColor: cardColor,
                              side: BorderSide(color: borderColor),
                              onDeleted: () => controller.removeTag(tag),
                            )),
                        SizedBox(
                          width: 120,
                          child: TextField(
                            controller: _tagInputController,
                            style: TextStyle(fontSize: 13, color: textColor),
                            decoration: InputDecoration(
                              hintText: 'タグを追加',
                              hintStyle: TextStyle(color: mutedTextColor),
                              isDense: true,
                              contentPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(20),
                                borderSide: BorderSide(color: borderColor),
                              ),
                            ),
                            onSubmitted: (value) {
                              if (value.isNotEmpty) {
                                controller.addTag(value);
                                _tagInputController.clear();
                              }
                            },
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),

                    // 公開範囲
                    Text(
                      '公開範囲',
                      style: TextStyle(
                        color: textColor,
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Container(
                      decoration: BoxDecoration(
                        color: cardColor,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: borderColor),
                      ),
                      child: Column(
                        children: [
                          'public',
                          'friends',
                          'private'
                        ].map((visibility) {
                          final isSelected = state.visibility == visibility;
                          final isLast = visibility == 'private';
                          return Column(
                            children: [
                              RadioListTile<String>(
                                value: visibility,
                                groupValue: state.visibility,
                                onChanged: (value) {
                                  if (value != null) controller.updateVisibility(value);
                                },
                                title: Row(
                                  children: [
                                    Icon(
                                      _getVisibilityIcon(visibility),
                                      size: 20,
                                      color: isSelected ? const Color(0xFF13ec5b) : mutedTextColor,
                                    ),
                                    const SizedBox(width: 12),
                                    Text(
                                      _getVisibilityLabel(visibility),
                                      style: TextStyle(
                                        color: isSelected ? textColor : mutedTextColor,
                                        fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                                      ),
                                    ),
                                  ],
                                ),
                                activeColor: const Color(0xFF13ec5b),
                                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 0),
                                dense: true,
                              ),
                              if (!isLast) Divider(height: 1, color: borderColor),
                            ],
                          );
                        }).toList(),
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
