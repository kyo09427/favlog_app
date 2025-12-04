import 'package:go_router/go_router.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:favlog_app/presentation/providers/add_review_controller.dart';
import 'package:favlog_app/presentation/widgets/error_dialog.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';

class AddReviewScreen extends ConsumerStatefulWidget {
  const AddReviewScreen({super.key});

  @override
  ConsumerState<AddReviewScreen> createState() => _AddReviewScreenState();
}

class _AddReviewScreenState extends ConsumerState<AddReviewScreen> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _productNameController;
  late final TextEditingController _productUrlController;
  late final TextEditingController _subcategoryController;
  late final TextEditingController _reviewTextController;

  @override
  void initState() {
    super.initState();
    final addReviewState = ref.read(addReviewControllerProvider);
    _productNameController =
        TextEditingController(text: addReviewState.productName);
    _productUrlController =
        TextEditingController(text: addReviewState.productUrl);
    _subcategoryController =
        TextEditingController(text: addReviewState.subcategory);
    _reviewTextController =
        TextEditingController(text: addReviewState.reviewText);
  }

  @override
  void dispose() {
    _productNameController.dispose();
    _productUrlController.dispose();
    _subcategoryController.dispose();
    _reviewTextController.dispose();
    super.dispose();
  }

  Future<void> _pickImage(ImageSource source) async {
    final controller = ref.read(addReviewControllerProvider.notifier);
    await controller.pickImage(source);
  }

  void _showImageSourceDialog() {
    final theme = Theme.of(context);
    showModalBottomSheet(
      context: context,
      backgroundColor: theme.brightness == Brightness.dark
          ? const Color(0xFF1C1C1E)
          : Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: const Icon(Icons.camera_alt, color: Color(0xFF22A06B)),
                title: const Text('カメラで撮影'),
                onTap: () {
                  context.pop();
                  _pickImage(ImageSource.camera);
                },
              ),
              ListTile(
                leading: const Icon(Icons.photo_library, color: Color(0xFF22A06B)),
                title: const Text('ギャラリーから選択'),
                onTap: () {
                  context.pop();
                  _pickImage(ImageSource.gallery);
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final addReviewState = ref.watch(addReviewControllerProvider);
    final addReviewController =
        ref.read(addReviewControllerProvider.notifier);

    // エラーをダイアログ表示
    ref.listen<AddReviewState>(
      addReviewControllerProvider,
      (previous, next) {
        if (next.error != null && next.error != previous?.error) {
          ErrorDialog.show(context, next.error!);
        }
      },
    );

    final theme = Theme.of(context);
    final bgColor = theme.brightness == Brightness.dark
        ? const Color(0xFF102216)
        : const Color(0xFFF6F8F6);

    Future<void> handleSubmit() async {
      if (!_formKey.currentState!.validate()) {
        return;
      }

      await addReviewController.submitReview();

      final latestState = ref.read(addReviewControllerProvider);
      if (context.mounted && latestState.error == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('レビューと商品情報を追加しました!')),
        );
        context.pop(true);
      }
    }

    // 星（0.5刻み）
    List<Widget> buildStars() {
      final rating = addReviewState.rating;
      return List.generate(5, (index) {
        final starIndex = index + 1;
        final isFilled = rating >= starIndex;
        final isHalf = rating >= starIndex - 0.5 && rating < starIndex;

        IconData icon;
        Color color;

        if (isFilled) {
          icon = Icons.star;
          color = const Color(0xFF22A06B);
        } else if (isHalf) {
          icon = Icons.star_half;
          color = const Color(0xFF22A06B);
        } else {
          icon = Icons.star_border;
          color = theme.brightness == Brightness.dark
              ? Colors.grey[600]!
              : Colors.grey[400]!;
        }

        return IconButton(
          iconSize: 32,
          padding: EdgeInsets.zero,
          onPressed: addReviewState.isLoading
              ? null
              : () {
                  double newRating;
                  if (rating == starIndex.toDouble()) {
                    newRating = starIndex - 0.5;
                  } else {
                    newRating = starIndex.toDouble();
                  }
                  if (newRating < 1) newRating = 1;
                  if (newRating > 5) newRating = 5;
                  addReviewController.updateRating(newRating);
                },
          icon: Icon(icon, color: color),
        );
      });
    }

    const visibilityLabel = '親しい友達';

    return Scaffold(
      backgroundColor: bgColor,
      body: SafeArea(
        child: Column(
          children: [
            // ヘッダー
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: bgColor,
                border: Border(
                  bottom: BorderSide(
                    color: theme.brightness == Brightness.dark
                        ? Colors.white24
                        : Colors.grey.shade300,
                  ),
                ),
              ),
              child: Row(
                children: [
                  IconButton(
                    icon: Icon(
                      Icons.arrow_back_ios_new,
                      size: 18,
                      color: theme.brightness == Brightness.dark
                          ? Colors.white
                          : Colors.black87,
                    ),
                    onPressed: () => context.pop(),
                  ),
                  const SizedBox(width: 8),
                  const Expanded(
                    child: Text(
                      'レビューを追加',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 18,
                        letterSpacing: -0.3,
                      ),
                    ),
                  ),
                  SizedBox(
                    width: 80,
                    child: TextButton(
                      onPressed:
                          addReviewState.isLoading ? null : handleSubmit,
                      style: TextButton.styleFrom(
                        foregroundColor:
                            theme.brightness == Brightness.dark
                                ? Colors.white
                                : Colors.black87,
                      ),
                      child: const Text(
                        '投稿',
                        style: TextStyle(
                          color: Color(0xFF22A06B),
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // 本文
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 16,
                ),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // 画像セクション
                      Text(
                        '商品画像',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: theme.brightness == Brightness.dark
                              ? Colors.white
                              : Colors.black87,
                        ),
                      ),
                      const SizedBox(height: 8),
                      GestureDetector(
                        onTap: addReviewState.isLoading
                            ? null
                            : _showImageSourceDialog,
                        child: Container(
                          width: double.infinity,
                          height: 200,
                          decoration: BoxDecoration(
                            color: theme.brightness == Brightness.dark
                                ? Colors.white.withOpacity(0.04)
                                : Colors.white,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: theme.brightness == Brightness.dark
                                  ? Colors.white24
                                  : Colors.grey.shade300,
                            ),
                          ),
                          child: addReviewState.imageFile != null
                              ? Stack(
                                  children: [
                                    ClipRRect(
                                      borderRadius: BorderRadius.circular(12),
                                      child: Image.file(
                                        addReviewState.imageFile!,
                                        width: double.infinity,
                                        height: double.infinity,
                                        fit: BoxFit.cover,
                                      ),
                                    ),
                                    Positioned(
                                      top: 8,
                                      right: 8,
                                      child: Container(
                                        decoration: BoxDecoration(
                                          color: Colors.black54,
                                          borderRadius: BorderRadius.circular(20),
                                        ),
                                        child: IconButton(
                                          icon: const Icon(
                                            Icons.close,
                                            color: Colors.white,
                                            size: 20,
                                          ),
                                          onPressed: () {
                                            addReviewController.clearImage();
                                          },
                                        ),
                                      ),
                                    ),
                                  ],
                                )
                              : Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(
                                      Icons.add_photo_alternate_outlined,
                                      size: 48,
                                      color: theme.brightness == Brightness.dark
                                          ? Colors.grey[600]
                                          : Colors.grey[400],
                                    ),
                                    const SizedBox(height: 8),
                                    Text(
                                      '画像を追加',
                                      style: TextStyle(
                                        color: theme.brightness == Brightness.dark
                                            ? Colors.grey[400]
                                            : Colors.grey[600],
                                        fontSize: 14,
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      'タップして選択',
                                      style: TextStyle(
                                        color: theme.brightness == Brightness.dark
                                            ? Colors.grey[600]
                                            : Colors.grey[400],
                                        fontSize: 12,
                                      ),
                                    ),
                                  ],
                                ),
                        ),
                      ),
                      const SizedBox(height: 24),

                      // 評価
                      Text(
                        '評価',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: theme.brightness == Brightness.dark
                              ? Colors.white
                              : Colors.black87,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          ...buildStars(),
                          const SizedBox(width: 8),
                          Text(
                            addReviewState.rating.toStringAsFixed(1),
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              color: theme.brightness == Brightness.dark
                                  ? Colors.white
                                  : Colors.black87,
                            ),
                          ),
                          const Text(' / 5.0'),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'タップすると0.5刻みで評価を変更できます',
                        style: TextStyle(
                          fontSize: 12,
                          color: theme.brightness == Brightness.dark
                              ? Colors.grey[300]
                              : Colors.grey[600],
                        ),
                      ),
                      const SizedBox(height: 24),

                      // 商品名
                      Text(
                        '商品・サービス名',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: theme.brightness == Brightness.dark
                              ? Colors.white
                              : Colors.black87,
                        ),
                      ),
                      const SizedBox(height: 8),
                      TextFormField(
                        controller: _productNameController,
                        decoration: InputDecoration(
                          hintText: '例: 隠れ家カフェ「L\'ombre」',
                          filled: true,
                          fillColor: theme.brightness == Brightness.dark
                              ? Colors.white.withOpacity(0.04)
                              : Colors.white,
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide(
                              color: theme.brightness == Brightness.dark
                                  ? Colors.white24
                                  : Colors.grey.shade300,
                            ),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide(
                              color: theme.brightness == Brightness.dark
                                  ? Colors.white24
                                  : Colors.grey.shade300,
                            ),
                          ),
                          focusedBorder: const OutlineInputBorder(
                            borderRadius: BorderRadius.all(
                              Radius.circular(12),
                            ),
                            borderSide: BorderSide(
                              color: Color(0xFF22A06B),
                              width: 1.5,
                            ),
                          ),
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 15,
                            vertical: 14,
                          ),
                        ),
                        onChanged: addReviewController.updateProductName,
                        validator: (value) {
                          if (value == null || value.trim().isEmpty) {
                            return '商品・サービス名を入力してください';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 24),

                      // URL
                      Text(
                        'URL（任意）',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: theme.brightness == Brightness.dark
                              ? Colors.white
                              : Colors.black87,
                        ),
                      ),
                      const SizedBox(height: 8),
                      TextFormField(
                        controller: _productUrlController,
                        decoration: InputDecoration(
                          hintText: '例: https://example.com',
                          prefixIcon: Icon(
                            Icons.link,
                            color: theme.brightness == Brightness.dark
                                ? Colors.grey[300]
                                : Colors.grey[700],
                          ),
                          filled: true,
                          fillColor: theme.brightness == Brightness.dark
                              ? Colors.white.withOpacity(0.04)
                              : Colors.white,
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide(
                              color: theme.brightness == Brightness.dark
                                  ? Colors.white24
                                  : Colors.grey.shade300,
                            ),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide(
                              color: theme.brightness == Brightness.dark
                                  ? Colors.white24
                                  : Colors.grey.shade300,
                            ),
                          ),
                          focusedBorder: const OutlineInputBorder(
                            borderRadius: BorderRadius.all(
                              Radius.circular(12),
                            ),
                            borderSide: BorderSide(
                              color: Color(0xFF22A06B),
                              width: 1.5,
                            ),
                          ),
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 15,
                            vertical: 14,
                          ),
                        ),
                        keyboardType: TextInputType.url,
                        onChanged: addReviewController.updateProductUrl,
                      ),
                      const SizedBox(height: 24),

                      // カテゴリ
                      Text(
                        'カテゴリ',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: theme.brightness == Brightness.dark
                              ? Colors.white
                              : Colors.black87,
                        ),
                      ),
                      const SizedBox(height: 8),
                      FormField<String>(
                        initialValue: addReviewState.selectedCategory,
                        validator: (value) {
                          if (addReviewState.selectedCategory == null) {
                            return 'カテゴリを1つ選択してください';
                          }
                          return null;
                        },
                        builder: (field) {
                          return Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Wrap(
                                spacing: 8,
                                runSpacing: 8,
                                children: addReviewState.categories
                                    .map<Widget>((category) {
                                  final selected =
                                      addReviewState.selectedCategory ==
                                          category;
                                  return ChoiceChip(
                                    label: Text(
                                      category,
                                      style: TextStyle(
                                        fontSize: 14,
                                        fontWeight: FontWeight.w500,
                                        color: selected
                                            ? const Color(0xFF102216)
                                            : (theme.brightness ==
                                                    Brightness.dark
                                                ? Colors.white
                                                : Colors.black87),
                                      ),
                                    ),
                                    selected: selected,
                                    selectedColor:
                                        const Color(0xFF22A06B),
                                    backgroundColor:
                                        theme.brightness ==
                                                Brightness.dark
                                            ? Colors.white10
                                            : Colors.grey.shade100,
                                    shape: RoundedRectangleBorder(
                                      borderRadius:
                                          BorderRadius.circular(20),
                                      side: BorderSide(
                                        color: selected
                                            ? const Color(0xFF22A06B)
                                            : (theme.brightness ==
                                                    Brightness.dark
                                                ? Colors.white24
                                                : Colors.grey.shade300),
                                      ),
                                    ),
                                    onSelected:
                                        addReviewState.isLoading
                                            ? null
                                            : (_) {
                                                addReviewController
                                                    .updateSelectedCategory(
                                                        category);
                                                field.didChange(category);
                                              },
                                  );
                                }).toList(),
                              ),
                              if (field.hasError)
                                Padding(
                                  padding:
                                      const EdgeInsets.only(top: 4.0),
                                  child: Text(
                                    field.errorText!,
                                    style: const TextStyle(
                                      color: Colors.redAccent,
                                      fontSize: 12,
                                    ),
                                  ),
                                ),
                            ],
                          );
                        },
                      ),
                      const SizedBox(height: 24),

                      // サブカテゴリ
                      Text(
                        'サブカテゴリ（任意）',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: theme.brightness == Brightness.dark
                              ? Colors.white
                              : Colors.black87,
                        ),
                      ),
                      const SizedBox(height: 8),
                      TextFormField(
                        controller: _subcategoryController,
                        decoration: InputDecoration(
                          hintText: '例: カフェ / スイーツ / 本 など',
                          filled: true,
                          fillColor: theme.brightness == Brightness.dark
                              ? Colors.white.withOpacity(0.04)
                              : Colors.white,
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide(
                              color: theme.brightness == Brightness.dark
                                  ? Colors.white24
                                  : Colors.grey.shade300,
                            ),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide(
                              color: theme.brightness == Brightness.dark
                                  ? Colors.white24
                                  : Colors.grey.shade300,
                            ),
                          ),
                          focusedBorder: const OutlineInputBorder(
                            borderRadius: BorderRadius.all(
                              Radius.circular(12),
                            ),
                            borderSide: BorderSide(
                              color: Color(0xFF22A06B),
                              width: 1.5,
                            ),
                          ),
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 15,
                            vertical: 14,
                          ),
                        ),
                        onChanged: addReviewController.updateSubcategory,
                      ),
                      const SizedBox(height: 24),

                      // レビュー本文
                      Text(
                        'レビュー',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: theme.brightness == Brightness.dark
                              ? Colors.white
                              : Colors.black87,
                        ),
                      ),
                      const SizedBox(height: 8),
                      TextFormField(
                        controller: _reviewTextController,
                        decoration: InputDecoration(
                          hintText: 'この商品・サービスについての感想を書いてください',
                          filled: true,
                          fillColor: theme.brightness == Brightness.dark
                              ? Colors.white.withOpacity(0.04)
                              : Colors.white,
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide(
                              color: theme.brightness == Brightness.dark
                                  ? Colors.white24
                                  : Colors.grey.shade300,
                            ),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide(
                              color: theme.brightness == Brightness.dark
                                  ? Colors.white24
                                  : Colors.grey.shade300,
                            ),
                          ),
                          focusedBorder: const OutlineInputBorder(
                            borderRadius: BorderRadius.all(
                              Radius.circular(12),
                            ),
                            borderSide: BorderSide(
                              color: Color(0xFF22A06B),
                              width: 1.5,
                            ),
                          ),
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 15,
                            vertical: 14,
                          ),
                        ),
                        maxLines: 6,
                        onChanged: addReviewController.updateReviewText,
                        validator: (value) {
                          if (value == null || value.trim().isEmpty) {
                            return 'レビューを入力してください';
                          }
                          if (value.trim().length < 10) {
                            return 'レビューは10文字以上で入力してください';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 24),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
