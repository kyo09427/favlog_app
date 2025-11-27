import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart'; // Import Riverpod
import 'package:favlog_app/presentation/providers/add_review_controller.dart'; // Import the controller
import 'package:favlog_app/presentation/widgets/error_dialog.dart'; // Add this import

class AddReviewScreen extends ConsumerWidget { // Change to ConsumerWidget
  const AddReviewScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) { // Add WidgetRef ref
    final addReviewState = ref.watch(addReviewControllerProvider);
    final addReviewController = ref.read(addReviewControllerProvider.notifier);

    final _formKey = GlobalKey<FormState>();

    // Listen for error changes
    ref.listen<AddReviewState>(
      addReviewControllerProvider,
      (previous, next) {
        if (next.error != null && next.error != previous?.error) {
          ErrorDialog.show(context, next.error!);
        }
      },
    );

    return Scaffold(
      appBar: AppBar(
        title: const Text('レビューを追加'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              TextFormField(
                initialValue: addReviewState.productName,
                decoration: const InputDecoration(
                  labelText: '商品名',
                  border: OutlineInputBorder(),
                ),
                onChanged: addReviewController.updateProductName,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return '商品名を入力してください。';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16.0),
              TextFormField(
                initialValue: addReviewState.productUrl,
                keyboardType: TextInputType.url,
                decoration: const InputDecoration(
                  labelText: '商品URL (オプション)',
                  border: OutlineInputBorder(),
                ),
                onChanged: addReviewController.updateProductUrl,
              ),
              const SizedBox(height: 16.0),
              DropdownButtonFormField<String>(
                value: addReviewState.selectedCategory,
                decoration: const InputDecoration(
                  labelText: 'カテゴリ',
                  border: OutlineInputBorder(),
                ),
                items: addReviewState.categories.map((String category) {
                  return DropdownMenuItem<String>(
                    value: category,
                    child: Text(category),
                  );
                }).toList(),
                onChanged: (String? newValue) {
                  if (newValue != null) {
                    addReviewController.updateSelectedCategory(newValue);
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
                initialValue: addReviewState.subcategory,
                decoration: const InputDecoration(
                  labelText: 'サブカテゴリ (オプション)',
                  border: OutlineInputBorder(),
                ),
                onChanged: addReviewController.updateSubcategory,
              ),
              const SizedBox(height: 16.0),
              GestureDetector(
                onTap: addReviewController.pickImage,
                child: Container(
                  height: 150,
                  color: Colors.grey[200],
                  alignment: Alignment.center,
                  child: addReviewState.imageFile == null
                      ? const Text('画像をタップして選択 (オプション)')
                      : Image.file(addReviewState.imageFile!, fit: BoxFit.cover),
                ),
              ),
              const SizedBox(height: 16.0),
              Text('評価: ${addReviewState.rating.toInt()} / 5'),
              Slider(
                value: addReviewState.rating,
                min: 1,
                max: 5,
                divisions: 4,
                label: addReviewState.rating.round().toString(),
                onChanged: (newRating) {
                  addReviewController.updateRating(newRating);
                },
              ),
              const SizedBox(height: 16.0),
              TextFormField(
                initialValue: addReviewState.reviewText,
                maxLines: 5,
                decoration: const InputDecoration(
                  labelText: 'レビュー',
                  hintText: '商品の感想を書いてください',
                  border: OutlineInputBorder(),
                ),
                onChanged: addReviewController.updateReviewText,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'レビューを入力してください。';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 24.0),
              addReviewState.isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : ElevatedButton(
                      onPressed: () async {
                        if (_formKey.currentState!.validate()) {
                          await addReviewController.submitReview();
                          if (context.mounted && addReviewState.error == null) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text('レビューと商品情報を追加しました！')),
                            );
                            Navigator.of(context).pop();
                          }
                        }
                      },
                      child: const Text('レビューを投稿'),
                    ),
            ],
          ),
        ),
      ),
    );
  }
}