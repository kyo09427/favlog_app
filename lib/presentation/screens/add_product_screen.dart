import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';

import 'package:flutter/foundation.dart' show kIsWeb;

import '../providers/add_product_controller.dart';
import '../widgets/error_dialog.dart';

class AddProductScreen extends ConsumerStatefulWidget {
  const AddProductScreen({super.key});

  @override
  ConsumerState<AddProductScreen> createState() => _AddProductScreenState();
}

class _AddProductScreenState extends ConsumerState<AddProductScreen> {
  final TextEditingController _productNameController = TextEditingController();
  final TextEditingController _productUrlController = TextEditingController();
  final TextEditingController _tagInputController = TextEditingController();

  @override
  void dispose() {
    _productNameController.dispose();
    _productUrlController.dispose();
    _tagInputController.dispose();
    super.dispose();
  }

  Future<void> _handleSubmit() async {
    final controller = ref.read(addProductControllerProvider.notifier);
    final product = await controller.submitProduct();

    if (product != null && mounted) {
      // 商品が作成されたら、その商品を選択してレビュー画面へ遷移
      context.go('/add-review', extra: {'product': product});
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
                ref.read(addProductControllerProvider.notifier).pickImage(ImageSource.gallery);
              },
            ),
            ListTile(
              leading: const Icon(Icons.photo_camera),
              title: const Text('カメラで撮影'),
              onTap: () {
                context.pop();
                ref.read(addProductControllerProvider.notifier).pickImage(ImageSource.camera);
              },
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(addProductControllerProvider);
    final controller = ref.read(addProductControllerProvider.notifier);
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
                      icon: Icon(Icons.arrow_back_ios_new, color: textColor, size: 20),
                    ),
                  ),
                  Expanded(
                    child: Text(
                      '新しい商品を追加',
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
                    // 商品・サービス名
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        RichText(
                          text: TextSpan(
                            text: '商品・サービス名',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: textColor,
                            ),
                            children: const [
                              TextSpan(
                                text: ' *',
                                style: TextStyle(color: Colors.red),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 8),
                        TextField(
                          controller: _productNameController,
                          onChanged: controller.updateProductName,
                          style: TextStyle(color: textColor),
                          decoration: InputDecoration(
                            hintText: '例：最高のワイヤレスイヤホン',
                            hintStyle: TextStyle(color: mutedTextColor),
                            filled: true,
                            fillColor: isDark ? Colors.white.withValues(alpha: 0.1) : const Color(0xFFF3F4F6),
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
                            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 32),

                    // 商品URL
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        RichText(
                          text: TextSpan(
                            text: '商品URL',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: textColor,
                            ),
                            children: [
                              TextSpan(
                                text: ' 任意',
                                style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w500,
                                  color: mutedTextColor,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 8),
                        TextField(
                          controller: _productUrlController,
                          onChanged: controller.updateProductUrl,
                          style: TextStyle(color: textColor),
                          keyboardType: TextInputType.url,
                          decoration: InputDecoration(
                            hintText: 'https://example.com',
                            hintStyle: TextStyle(color: mutedTextColor),
                            filled: true,
                            fillColor: isDark ? Colors.white.withValues(alpha: 0.1) : const Color(0xFFF3F4F6),
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
                            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 32),

                    // 商品画像
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        RichText(
                          text: TextSpan(
                            text: '商品画像',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: textColor,
                            ),
                            children: const [
                              TextSpan(
                                text: ' *',
                                style: TextStyle(color: Colors.red),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 12),
                        _buildImagePicker(state, controller, cardColor, borderColor, mutedTextColor),
                      ],
                    ),
                    const SizedBox(height: 32),

                    // カテゴリ
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'カテゴリ',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: textColor,
                          ),
                        ),
                        const SizedBox(height: 12),
                        Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: state.categories.map((category) {
                            final isSelected = state.selectedCategory == category;
                            return GestureDetector(
                              onTap: () => controller.selectCategory(category),
                              child: Container(
                                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                                decoration: BoxDecoration(
                                  color: isSelected
                                      ? primaryColor
                                      : (isDark ? Colors.white.withValues(alpha: 0.1) : const Color(0xFFE5E7EB)),
                                  borderRadius: BorderRadius.circular(24),
                                ),
                                child: Text(
                                  category,
                                  style: TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.bold,
                                    color: isSelected ? Colors.black : textColor,
                                  ),
                                ),
                              ),
                            );
                          }).toList(),
                        ),
                      ],
                    ),
                    const SizedBox(height: 32),

                    // サブカテゴリ
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        RichText(
                          text: TextSpan(
                            text: 'サブカテゴリ',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: textColor,
                            ),
                            children: [
                              TextSpan(
                                text: ' 任意',
                                style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w500,
                                  color: mutedTextColor,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 8),
                        TextField(
                          controller: _tagInputController,
                          style: TextStyle(color: textColor),
                          decoration: InputDecoration(
                            hintText: '例：ミステリー',
                            hintStyle: TextStyle(color: mutedTextColor),
                            filled: true,
                            fillColor: isDark ? Colors.white.withValues(alpha: 0.1) : const Color(0xFFF3F4F6),
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
                            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
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
                                backgroundColor: primaryColor.withValues(alpha: 0.2),
                                labelStyle: const TextStyle(
                                  color: primaryColor,
                                  fontWeight: FontWeight.w500,
                                ),
                                deleteIconColor: primaryColor,
                              );
                            }).toList(),
                          ),
                        ],
                      ],
                    ),
                    const SizedBox(height: 100), // ボタン用のスペース
                  ],
                ),
              ),
            ),
          ],
        ),
      ),

      // 登録ボタン（下部固定）
      bottomNavigationBar: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: backgroundColor,
          border: Border(top: BorderSide(color: borderColor)),
        ),
        child: SafeArea(
          top: false,
          child: SizedBox(
            width: double.infinity,
            height: 48,
            child: ElevatedButton(
              onPressed: state.isLoading ? null : _handleSubmit,
              style: ElevatedButton.styleFrom(
                backgroundColor: primaryColor,
                foregroundColor: Colors.black,
                disabledBackgroundColor: primaryColor.withValues(alpha: 0.5),
                elevation: 0,
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
                      '商品情報を登録する',
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

  Widget _buildImagePicker(
    AddProductState state,
    AddProductController controller,
    Color cardColor,
    Color borderColor,
    Color mutedTextColor,
  ) {
    return SizedBox(
      height: 120,
      child: state.hasImage
          ? Stack(
              children: [
                Container(
                  width: 120,
                  height: 120,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(12),
                    image: DecorationImage(
                      image: kIsWeb
                          ? MemoryImage(state.imageBytes!)
                          : FileImage(state.imageFile!) as ImageProvider,
                      fit: BoxFit.cover,
                    ),
                  ),
                ),
                Positioned(
                  top: -6,
                  right: -6,
                  child: IconButton(
                    onPressed: controller.clearImage,
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
            )
          : GestureDetector(
              onTap: _showImageSourceDialog,
              child: Container(
                width: 120,
                height: 120,
                decoration: BoxDecoration(
                  color: cardColor,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: borderColor, width: 2, style: BorderStyle.solid),
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.add_photo_alternate, color: const Color(0xFF13ec5b), size: 40),
                    const SizedBox(height: 4),
                    Text(
                      '追加',
                      style: TextStyle(
                        color: const Color(0xFF13ec5b),
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
            ),
    );
  }
}
