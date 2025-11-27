import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart'; // Import Riverpod
import 'package:favlog_app/domain/models/product.dart';
import 'package:favlog_app/domain/models/review.dart';
import 'package:favlog_app/presentation/providers/edit_review_controller.dart'; // Import the controller
import 'package:favlog_app/presentation/widgets/error_dialog.dart'; // Add this import

class EditReviewScreen extends ConsumerWidget { // Change to ConsumerWidget
  final Product product;
  final Review review;

  const EditReviewScreen({super.key, required this.product, required this.review});

  @override
  Widget build(BuildContext context, WidgetRef ref) { // Add WidgetRef ref
    final editReviewState = ref.watch(editReviewControllerProvider({'product': product, 'review': review}));
    final editReviewController = ref.read(editReviewControllerProvider({'product': product, 'review': review}).notifier);

    final _formKey = GlobalKey<FormState>();

    // Listen for error changes
    ref.listen<EditReviewState>(
      editReviewControllerProvider({'product': product, 'review': review}),
      (previous, next) {
        if (next.error != null && next.error != previous?.error) {
          ErrorDialog.show(context, next.error!);
        }
      },
    );

    return Scaffold(
      appBar: AppBar(
        title: const Text('レビューを編集'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              TextFormField(
                initialValue: editReviewState.productName,
                decoration: const InputDecoration(
                  labelText: '商品名',
                  border: OutlineInputBorder(),
                ),
                onChanged: editReviewController.updateProductName,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return '商品名を入力してください。';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16.0),
              TextFormField(
                initialValue: editReviewState.productUrl,
                keyboardType: TextInputType.url,
                decoration: const InputDecoration(
                  labelText: '商品URL (オプション)',
                  border: OutlineInputBorder(),
                ),
                onChanged: editReviewController.updateProductUrl,
              ),
              const SizedBox(height: 16.0),
              DropdownButtonFormField<String>(
                value: editReviewState.selectedCategory,
                decoration: const InputDecoration(
                  labelText: 'カテゴリ',
                  border: OutlineInputBorder(),
                ),
                items: editReviewState.categories.map((String category) {
                  return DropdownMenuItem<String>(
                    value: category,
                    child: Text(category),
                  );
                }).toList(),
                onChanged: (String? newValue) {
                  if (newValue != null) {
                    editReviewController.updateSelectedCategory(newValue);
                  }
                },
                validator: (value) {
                  if (value == null || value == '選択してください') {
                    return 'カテゴリを選択してください。';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16.0),
              TextFormField(
                initialValue: editReviewState.subcategory,
                decoration: const InputDecoration(
                  labelText: 'サブカテゴリ (オプション)',
                  border: OutlineInputBorder(),
                ),
                onChanged: editReviewController.updateSubcategory,
              ),
              const SizedBox(height: 16.0),
              GestureDetector(
                onTap: editReviewController.pickImage,
                child: Container(
                  height: 150,
                  color: Colors.grey[200],
                  alignment: Alignment.center,
                  child: editReviewState.imageFile != null
                      ? Image.file(editReviewState.imageFile!, fit: BoxFit.cover)
                      : (editReviewState.currentImageUrl != null
                          ? Image.network(editReviewState.currentImageUrl!, fit: BoxFit.cover)
                          : const Text('画像をタップして選択 (オプション)')),
                ),
              ),
              if (editReviewState.imageFile != null || editReviewState.currentImageUrl != null)
                TextButton(
                  onPressed: editReviewController.clearImage,
                  child: const Text('画像を削除'),
                ),
              const SizedBox(height: 16.0),
              Text('評価: ${editReviewState.rating.toInt()} / 5'),
              Slider(
                value: editReviewState.rating,
                min: 1,
                max: 5,
                divisions: 4,
                label: editReviewState.rating.round().toString(),
                onChanged: (newRating) {
                  editReviewController.updateRating(newRating);
                },
              ),
              const SizedBox(height: 16.0),
              TextFormField(
                initialValue: editReviewState.reviewText,
                maxLines: 5,
                decoration: const InputDecoration(
                  labelText: 'レビュー',
                  hintText: '商品の感想を書いてください',
                  border: OutlineInputBorder(),
                ),
                onChanged: editReviewController.updateReviewText,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'レビューを入力してください。';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 24.0),
              editReviewState.isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : ElevatedButton(
                      onPressed: () async {
                        if (_formKey.currentState!.validate()) {
                          await editReviewController.updateReview();
                          if (context.mounted && editReviewState.error == null) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text('レビューを更新しました！')),
                            );
                            Navigator.of(context).pop();
                          }
                        }
                      },
                      child: const Text('レビューを更新'),
                    ),
            ],
          ),
        ),
      ),
    );
  }
}