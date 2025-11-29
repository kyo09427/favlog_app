import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart'; // Import Riverpod
import 'package:favlog_app/domain/models/product.dart';
import 'package:favlog_app/domain/models/review.dart';
import 'package:favlog_app/presentation/providers/edit_review_controller.dart'; // Import the controller
import 'package:favlog_app/presentation/widgets/error_dialog.dart'; // Add this import

class EditReviewScreen extends ConsumerWidget { // Change to ConsumerWidget
  final String productId; // Now takes IDs
  final String reviewId;   // Now takes IDs

  const EditReviewScreen({super.key, required this.productId, required this.reviewId}); // Updated constructor

  @override
  Widget build(BuildContext context, WidgetRef ref) { // Add WidgetRef ref
    final editReviewState = ref.watch(editReviewControllerProvider({'productId': productId, 'reviewId': reviewId})); // Pass IDs
    final editReviewController = ref.read(editReviewControllerProvider({'productId': productId, 'reviewId': reviewId}).notifier); // Pass IDs

    final _formKey = GlobalKey<FormState>();

    // Listen for error changes
    ref.listen<EditReviewState>(
      editReviewControllerProvider({'productId': productId, 'reviewId': reviewId}), // Pass IDs
      (previous, next) {
        if (next.error != null && next.error != previous?.error) {
          ErrorDialog.show(context, next.error!);
        }
      },
    );

    if (editReviewState.isLoading && editReviewState.product.id == Product.empty().id) { // Check if initial load is happening
      return Scaffold(
        appBar: AppBar(title: const Text('レビューを編集')),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    // Use product and review from state for UI
    final currentProduct = editReviewState.product;
    final currentReview = editReviewState.review;


    return Scaffold(
      appBar: AppBar(
        title: Text('レビューを編集: ${currentProduct.name}'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              TextFormField(
                initialValue: currentProduct.name, // Use currentProduct
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
                initialValue: currentProduct.url, // Use currentProduct
                keyboardType: TextInputType.url,
                decoration: const InputDecoration(
                  labelText: '商品URL (オプション)',
                  border: OutlineInputBorder(),
                ),
                onChanged: editReviewController.updateProductUrl,
              ),
              const SizedBox(height: 16.0),
              FormField<String>(
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'カテゴリを選択してください。';
                  }
                  return null;
                },
                initialValue: currentProduct.category, // Use currentProduct
                builder: (FormFieldState<String> field) {
                  return InputDecorator(
                    decoration: InputDecoration(
                      labelText: 'カテゴリ',
                      errorText: field.errorText,
                      border: InputBorder.none,
                    ),
                    child: Padding(
                      padding: const EdgeInsets.only(top: 8.0),
                      child: Wrap(
                        spacing: 8.0,
                        runSpacing: 8.0,
                        children: editReviewState.categories.map((String category) {
                          return ChoiceChip(
                            label: Text(category),
                            selected: currentProduct.category == category, // Use currentProduct
                            onSelected: (bool selected) {
                              if (selected) {
                                editReviewController.updateSelectedCategory(category);
                                field.didChange(category);
                              }
                            },
                          );
                        }).toList(),
                      ),
                    ),
                  );
                },
              ),
              const SizedBox(height: 16.0),
              Autocomplete<String>(
                optionsBuilder: (TextEditingValue textEditingValue) {
                  if (textEditingValue.text.isEmpty) {
                    return const Iterable<String>.empty();
                  }
                  return editReviewState.subcategorySuggestions.where((String option) {
                    return option.contains(textEditingValue.text.toLowerCase());
                  });
                },
                onSelected: (String selection) {
                  editReviewController.updateSubcategory(selection);
                },
                initialValue: TextEditingValue(text: currentProduct.subcategory ?? ''), // Use currentProduct
                fieldViewBuilder: (BuildContext context, TextEditingController textEditingController, FocusNode focusNode, VoidCallback onFieldSubmitted) {
                  return TextFormField(
                    controller: textEditingController,
                    focusNode: focusNode,
                    decoration: const InputDecoration(
                      labelText: 'サブカテゴリ (オプション)',
                      border: OutlineInputBorder(),
                    ),
                    onChanged: (value) {
                      textEditingController.text = value; // Keep controller in sync
                      editReviewController.updateSubcategory(value);
                    },
                  );
                },
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
              Text('評価: ${currentReview.rating.toStringAsFixed(1)} / 5'), // Use currentReview
              Slider(
                value: currentReview.rating, // Use currentReview
                min: 1,
                max: 5,
                divisions: 4,
                label: currentReview.rating.toStringAsFixed(1), // Use currentReview
                onChanged: (newRating) {
                  editReviewController.updateRating(newRating);
                },
              ),
              const SizedBox(height: 16.0),
              TextFormField(
                initialValue: currentReview.reviewText, // Use currentReview
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