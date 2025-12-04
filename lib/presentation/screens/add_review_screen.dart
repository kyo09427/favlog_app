import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';

import '../../domain/models/product.dart';
import '../providers/add_review_controller.dart';
import '../providers/category_providers.dart';
import 'email_verification_screen.dart';

class AddReviewScreen extends ConsumerStatefulWidget {
  const AddReviewScreen({super.key});

  @override
  ConsumerState<AddReviewScreen> createState() => _AddReviewScreenState();
}

class _AddReviewScreenState extends ConsumerState<AddReviewScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _urlController = TextEditingController();
  final _reviewController = TextEditingController();
  final _subcategoryController = TextEditingController();

  @override
  void dispose() {
    _nameController.dispose();
    _urlController.dispose();
    _reviewController.dispose();
    _subcategoryController.dispose();
    super.dispose();
  }

  Future<void> _pickImage(ImageSource source) async {
    final controller = ref.read(addReviewControllerProvider.notifier);
    await controller.pickImage(source);
  }

  Future<void> _submitReview() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    final controller = ref.read(addReviewControllerProvider.notifier);
    final state = ref.read(addReviewControllerProvider);

    if (state.selectedCategory == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('カテゴリを選択してください')),
      );
      return;
    }

    final success = await controller.submitReview(
      name: _nameController.text.trim(),
      url: _urlController.text.trim(),
      reviewText: _reviewController.text.trim(),
      subcategory: _subcategoryController.text.trim(),
    );

    if (success && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('レビューを投稿しました')),
      );
      Navigator.of(context).pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    final addReviewState = ref.watch(addReviewControllerProvider);
    final categoriesAsyncValue = ref.watch(categoriesProvider);

    ref.listen<AddReviewState>(addReviewControllerProvider, (previous, next) {
      if (next.error != null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(next.error!)),
        );
      }
    });

    return Scaffold(
      appBar: AppBar(
        title: const Text('レビューを追加'),
        elevation: 0,
      ),
      body: addReviewState.isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16.0),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // 画像選択セクション
                    _buildImageSection(addReviewState),
                    const SizedBox(height: 24),

                    // 商品名
                    TextFormField(
                      controller: _nameController,
                      decoration: const InputDecoration(
                        labelText: '商品名 *',
                        border: OutlineInputBorder(),
                        prefixIcon: Icon(Icons.shopping_bag),
                      ),
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return '商品名を入力してください';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),

                    // URL
                    TextFormField(
                      controller: _urlController,
                      decoration: const InputDecoration(
                        labelText: 'URL（任意）',
                        border: OutlineInputBorder(),
                        prefixIcon: Icon(Icons.link),
                        hintText: 'https://...',
                      ),
                      keyboardType: TextInputType.url,
                    ),
                    const SizedBox(height: 16),

                    // カテゴリ選択
                    _buildCategorySection(categoriesAsyncValue, addReviewState),
                    const SizedBox(height: 16),

                    // サブカテゴリ
                    _buildSubcategoryField(addReviewState),
                    const SizedBox(height: 16),

                    // 評価
                    _buildRatingSection(addReviewState),
                    const SizedBox(height: 16),

                    // レビュー本文
                    TextFormField(
                      controller: _reviewController,
                      decoration: InputDecoration(
                        labelText: 'レビュー *',
                        border: const OutlineInputBorder(),
                        prefixIcon: const Icon(Icons.rate_review),
                        hintText: 'この商品についての感想を書いてください',
                        counterText: '${_reviewController.text.length}文字',
                      ),
                      maxLines: 5,
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return 'レビューを入力してください';
                        }
                        if (value.trim().length < 10) {
                          return 'レビューは10文字以上で入力してください';
                        }
                        return null;
                      },
                      onChanged: (value) {
                        setState(() {});
                      },
                    ),
                    const SizedBox(height: 24),

                    // 投稿ボタン
                    ElevatedButton(
                      onPressed: addReviewState.isLoading ? null : _submitReview,
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      child: addReviewState.isLoading
                          ? const SizedBox(
                              height: 20,
                              width: 20,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : const Text(
                              '投稿する',
                              style: TextStyle(fontSize: 16),
                            ),
                    ),
                  ],
                ),
              ),
            ),
    );
  }

  Widget _buildImageSection(AddReviewState state) {
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text(
              '商品画像',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),
            if (state.imageFile != null)
              Stack(
                alignment: Alignment.topRight,
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: Image.file(
                      state.imageFile!,
                      height: 200,
                      width: double.infinity,
                      fit: BoxFit.cover,
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: IconButton(
                      icon: const Icon(Icons.close),
                      style: IconButton.styleFrom(
                        backgroundColor: Colors.white,
                        foregroundColor: Colors.red,
                      ),
                      onPressed: () {
                        ref
                            .read(addReviewControllerProvider.notifier)
                            .clearImage();
                      },
                    ),
                  ),
                ],
              )
            else
              Container(
                height: 150,
                decoration: BoxDecoration(
                  color: Colors.grey[200],
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.grey[400]!),
                ),
                child: const Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.image, size: 48, color: Colors.grey),
                      SizedBox(height: 8),
                      Text(
                        '画像を選択してください',
                        style: TextStyle(color: Colors.grey),
                      ),
                    ],
                  ),
                ),
              ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () => _pickImage(ImageSource.camera),
                    icon: const Icon(Icons.camera_alt),
                    label: const Text('カメラ'),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () => _pickImage(ImageSource.gallery),
                    icon: const Icon(Icons.photo_library),
                    label: const Text('ギャラリー'),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCategorySection(
      AsyncValue<List<String>> categoriesAsyncValue, AddReviewState state) {
    return categoriesAsyncValue.when(
      data: (categories) {
        final selectableCategories =
            categories.where((c) => c != 'すべて').toList();
        return FormField<String>(
          initialValue: state.selectedCategory,
          validator: (value) {
            if (value == null || value.isEmpty) {
              return 'カテゴリを選択してください';
            }
            return null;
          },
          builder: (formFieldState) {
            return InputDecorator(
              decoration: InputDecoration(
                labelText: 'カテゴリ *',
                border: const OutlineInputBorder(),
                errorText: formFieldState.errorText,
              ),
              child: Wrap(
                spacing: 8.0,
                runSpacing: 8.0,
                children: selectableCategories.map((category) {
                  final isSelected = state.selectedCategory == category;
                  return ChoiceChip(
                    label: Text(category),
                    selected: isSelected,
                    onSelected: (selected) {
                      if (selected) {
                        ref
                            .read(addReviewControllerProvider.notifier)
                            .updateSelectedCategory(category);
                        formFieldState.didChange(category);
                      }
                    },
                  );
                }).toList(),
              ),
            );
          },
        );
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (err, stack) => Text('エラー: $err'),
    );
  }

  Widget _buildSubcategoryField(AddReviewState state) {
    return Autocomplete<String>(
      optionsBuilder: (TextEditingValue textEditingValue) {
        if (textEditingValue.text.isEmpty) {
          return state.subcategorySuggestions;
        }
        return state.subcategorySuggestions.where((String option) {
          return option
              .toLowerCase()
              .contains(textEditingValue.text.toLowerCase());
        });
      },
      onSelected: (String selection) {
        _subcategoryController.text = selection;
      },
      fieldViewBuilder: (BuildContext context,
          TextEditingController fieldTextEditingController,
          FocusNode fieldFocusNode,
          VoidCallback onFieldSubmitted) {
        if (fieldTextEditingController.text.isEmpty &&
            _subcategoryController.text.isNotEmpty) {
          fieldTextEditingController.text = _subcategoryController.text;
        }
        fieldTextEditingController.addListener(() {
          _subcategoryController.text = fieldTextEditingController.text;
        });
        return TextFormField(
          controller: fieldTextEditingController,
          focusNode: fieldFocusNode,
          decoration: const InputDecoration(
            labelText: 'サブカテゴリ（任意）',
            border: OutlineInputBorder(),
            prefixIcon: Icon(Icons.category_outlined),
            hintText: '例: 小説、スマートフォン、お菓子',
          ),
        );
      },
    );
  }

  Widget _buildRatingSection(AddReviewState state) {
    return Card(
      elevation: 1,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              '評価 *',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                for (int i = 1; i <= 5; i++)
                  GestureDetector(
                    onTap: () {
                      final controller =
                          ref.read(addReviewControllerProvider.notifier);
                      final currentRating =
                          ref.read(addReviewControllerProvider).rating;
                      double newRating;
                      if (currentRating == i.toDouble()) {
                        newRating = i - 0.5;
                      } else {
                        newRating = i.toDouble();
                      }
                      controller.updateRating(newRating);
                    },
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 4.0),
                      child: Icon(
                        i <= state.rating
                            ? Icons.star
                            : (i - 0.5 <= state.rating
                                ? Icons.star_half
                                : Icons.star_border),
                        size: 40,
                        color: Colors.amber,
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 8),
            Center(
              child: Text(
                '${state.rating.toStringAsFixed(1)} / 5.0',
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
