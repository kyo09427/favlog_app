import 'package:go_router/go_router.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:favlog_app/domain/models/product.dart';
import 'package:favlog_app/presentation/providers/add_review_to_product_controller.dart';
import 'package:favlog_app/presentation/widgets/error_dialog.dart';

class AddReviewToProductScreen extends ConsumerStatefulWidget {
  final Product product; // 既存の商品

  const AddReviewToProductScreen({super.key, required this.product});

  @override
  ConsumerState<AddReviewToProductScreen> createState() =>
      _AddReviewToProductScreenState();
}

class _AddReviewToProductScreenState
    extends ConsumerState<AddReviewToProductScreen> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _reviewTextController;

  @override
  void initState() {
    super.initState();
    final addReviewToProductState =
        ref.read(addReviewToProductControllerProvider(widget.product));
    _reviewTextController =
        TextEditingController(text: addReviewToProductState.reviewText);
  }

  @override
  void dispose() {
    _reviewTextController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final product = widget.product;
    final addReviewToProductState =
        ref.watch(addReviewToProductControllerProvider(product));
    final addReviewToProductController =
        ref.read(addReviewToProductControllerProvider(product).notifier);

    // エラー監視
    ref.listen<AddReviewToProductState>(
      addReviewToProductControllerProvider(product),
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
      if (!_formKey.currentState!.validate()) return;

      await addReviewToProductController.submitReview();

      final latestState =
          ref.read(addReviewToProductControllerProvider(product));
      if (context.mounted && latestState.error == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('レビューを投稿しました！')),
        );
        context.pop();
      }
    }

    // 星表示（0.5刻み）
    List<Widget> buildStars() {
      final rating = addReviewToProductState.rating;
      return List.generate(5, (index) {
        final starPosition = index + 1;

        IconData icon;


        if (rating >= starPosition) {
          icon = Icons.star;

        } else if (rating >= starPosition - 0.5 &&
            rating < starPosition) {
          icon = Icons.star_half;

        } else {
          icon = Icons.star_border;

        }

        return IconButton(
          iconSize: 32,
          padding: EdgeInsets.zero,
          onPressed: addReviewToProductState.isLoading
              ? null
              : () {
                  double newRating;
                  if (rating == starPosition.toDouble()) {
                    newRating = starPosition - 0.5;
                  } else {
                    newRating = starPosition.toDouble();
                  }
                  if (newRating < 1) newRating = 1;
                  if (newRating > 5) newRating = 5;
                  addReviewToProductController.updateRating(newRating);
                },
          icon: Icon(icon, color: const Color(0xFF22A06B)),
        );
      });
    }

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
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'レビューを追加',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 18,
                            letterSpacing: -0.3,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          product.name,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontSize: 13,
                            color: theme.brightness == Brightness.dark
                                ? Colors.grey[300]
                                : Colors.grey[700],
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

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
                            addReviewToProductState.rating
                                .toStringAsFixed(1),
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

                      // レビュー本文
                      Text(
                        'レビュー本文',
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
                        maxLines: 6,
                        decoration: InputDecoration(
                          hintText:
                              '感じたことや良かったところ、イマイチだったところなどをメモしておきましょう。',
                          filled: true,
                          fillColor: theme.brightness == Brightness.dark
                              ? Colors.white.withValues(alpha: 0.04)
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
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide(
                              color: const Color(0xFF22A06B),
                              width: 1.5,
                            ),
                          ),
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 15,
                            vertical: 14,
                          ),
                        ),
                        onChanged:
                            addReviewToProductController.updateReviewText,
                        validator: (value) {
                          if (value == null ||
                              value.trim().length < 10) {
                            return 'レビュー本文は10文字以上で入力してください';
                          }
                          return null;
                        },
                      ),
                    ],
                  ),
                ),
              ),
            ),

            // 下部ボタン
            Container(
              padding: const EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 12,
              ),
              decoration: BoxDecoration(
                color: theme.brightness == Brightness.dark
                    ? const Color(0xFF050B07)
                    : Colors.white,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.06),
                    blurRadius: 10,
                    offset: const Offset(0, -2),
                  ),
                ],
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      addReviewToProductState.isLoading
                          ? '投稿中...'
                          : '内容を確認したら、「投稿」ボタンを押してください。',
                      style: TextStyle(
                        fontSize: 12,
                        color: theme.brightness == Brightness.dark
                            ? Colors.grey[300]
                            : Colors.grey[700],
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  SizedBox(
                    height: 44,
                    child: ElevatedButton(
                      onPressed: addReviewToProductState.isLoading
                          ? null
                          : handleSubmit,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF22A06B),
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(999),
                        ),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 24,
                          vertical: 10,
                        ),
                      ),
                      child: addReviewToProductState.isLoading
                          ? const SizedBox(
                              width: 18,
                              height: 18,
                              child: CircularProgressIndicator(),
                            )
                          : const Text(
                              '投稿',
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
