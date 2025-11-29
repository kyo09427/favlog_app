import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:favlog_app/domain/models/product.dart';
import 'package:favlog_app/presentation/providers/add_review_to_product_controller.dart';
import 'package:favlog_app/presentation/widgets/error_dialog.dart';

class AddReviewToProductScreen extends ConsumerWidget {
  final Product product; // 既存の商品

  const AddReviewToProductScreen({super.key, required this.product});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final addReviewToProductState =
        ref.watch(addReviewToProductControllerProvider(product));
    final addReviewToProductController =
        ref.read(addReviewToProductControllerProvider(product).notifier);

    final formKey = GlobalKey<FormState>();

    // エラー監視（元ファイルの意図そのまま）
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
        ? const Color(0xFF102216) // background-dark っぽい色
        : const Color(0xFFF6F8F6); // background-light っぽい色

    Future<void> handleSubmit() async {
      if (!formKey.currentState!.validate()) return;

      await addReviewToProductController.submitReview();

      final latestState =
          ref.read(addReviewToProductControllerProvider(product));
      if (context.mounted && latestState.error == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('レビューを投稿しました！')),
        );
        Navigator.of(context).pop();
      }
    }

    // 星アイコン（0.5刻み表現）
    Widget buildStar(int index) {
      final rating = addReviewToProductState.rating;
      final starPosition = index + 1; // 1〜5

      IconData icon;
      Color color;

      if (rating >= starPosition) {
        icon = Icons.star;
        color = Colors.greenAccent[400] ?? Colors.green;
      } else if (rating >= starPosition - 0.5) {
        icon = Icons.star_half;
        color = Colors.greenAccent[400] ?? Colors.green;
      } else {
        icon = Icons.star_border;
        color = theme.brightness == Brightness.dark
            ? Colors.grey[600]!
            : Colors.grey[400]!;
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
        icon: Icon(icon, color: color),
      );
    }

    return Scaffold(
      backgroundColor: bgColor,
      body: SafeArea(
        child: Stack(
          children: [
            // メインコンテンツ（スクロール）
            Positioned.fill(
              child: SingleChildScrollView(
                padding: const EdgeInsets.only(bottom: 96),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // 上部のカスタムヘッダー（close + タイトル + 投稿）
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 8,
                      ),
                      decoration: BoxDecoration(
                        color: bgColor,
                        border: Border(
                          bottom: BorderSide(
                            color: theme.brightness == Brightness.dark
                                ? Colors.white10
                                : Colors.grey.shade300,
                          ),
                        ),
                      ),
                      child: Row(
                        children: [
                          SizedBox(
                            width: 48,
                            child: IconButton(
                              icon: Icon(
                                Icons.close,
                                color: theme.brightness == Brightness.dark
                                    ? Colors.white
                                    : Colors.black87,
                              ),
                              onPressed: () => Navigator.of(context).pop(),
                            ),
                          ),
                          const Expanded(
                            child: Center(
                              child: Text(
                                'レビュー投稿',
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                  letterSpacing: -0.3,
                                ),
                              ),
                            ),
                          ),
                          SizedBox(
                            width: 48,
                            child: TextButton(
                              onPressed: addReviewToProductState.isLoading
                                  ? null
                                  : handleSubmit,
                              child: Text(
                                '投稿',
                                style: TextStyle(
                                  color: Colors.greenAccent[400] ?? Colors.green,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),

                    // 本文
                    Padding(
                      padding: const EdgeInsets.all(16),
                      child: Form(
                        key: formKey,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // 🔹 商品情報（表示のみ：編集機能なし）
                            Container(
                              padding: const EdgeInsets.all(14),
                              decoration: BoxDecoration(
                                color: theme.brightness == Brightness.dark
                                    ? Colors.white10
                                    : Colors.white,
                                borderRadius: BorderRadius.circular(16),
                                border: Border.all(
                                  color: theme.brightness == Brightness.dark
                                      ? Colors.white12
                                      : Colors.grey.shade300,
                                ),
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  // 商品名
                                  Text(
                                    product.name,
                                    style:
                                        theme.textTheme.titleMedium?.copyWith(
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  const SizedBox(height: 6),

                                  // カテゴリ / サブカテゴリ
                                  Wrap(
                                    spacing: 8,
                                    runSpacing: 4,
                                    children: [
                                      if (product.category != null)
                                        Chip(
                                          label: Text(
                                            product.category!,
                                            style: theme.textTheme.bodySmall
                                                ?.copyWith(
                                              color: Colors.white,
                                            ),
                                          ),
                                          backgroundColor:
                                              Colors.greenAccent[400] ??
                                                  Colors.green,
                                          materialTapTargetSize:
                                              MaterialTapTargetSize
                                                  .shrinkWrap,
                                        ),
                                      if (product.subcategory != null)
                                        Chip(
                                          label: Text(
                                            product.subcategory!,
                                            style: theme.textTheme.bodySmall,
                                          ),
                                          backgroundColor:
                                              theme.brightness ==
                                                      Brightness.dark
                                                  ? Colors.white12
                                                  : Colors.grey.shade100,
                                          materialTapTargetSize:
                                              MaterialTapTargetSize
                                                  .shrinkWrap,
                                        ),
                                    ],
                                  ),

                                  // URL（あれば表示だけ）
                                  if (product.url != null &&
                                      product.url!.isNotEmpty) ...[
                                    const SizedBox(height: 6),
                                    Text(
                                      product.url!,
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style:
                                          theme.textTheme.bodySmall?.copyWith(
                                        color: theme.brightness ==
                                                Brightness.dark
                                            ? Colors.grey[300]
                                            : Colors.grey[600],
                                        decoration: TextDecoration.underline,
                                      ),
                                    ),
                                  ],

                                  // 画像（あれば）
                                  if (product.imageUrl != null) ...[
                                    const SizedBox(height: 10),
                                    ClipRRect(
                                      borderRadius: BorderRadius.circular(12),
                                      child: Image.network(
                                        product.imageUrl!,
                                        height: 120,
                                        width: double.infinity,
                                        fit: BoxFit.cover,
                                      ),
                                    ),
                                  ],
                                ],
                              ),
                            ),

                            const SizedBox(height: 24),

                            // 🔹 評価
                            const Text(
                              '評価',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Row(
                              children: List.generate(5, buildStar),
                            ),

                            const SizedBox(height: 24),

                            // 🔹 レビュー本文
                            const Text(
                              'レビュー本文',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            const SizedBox(height: 8),
                            TextFormField(
                              initialValue: addReviewToProductState.reviewText,
                              maxLines: 6,
                              decoration: InputDecoration(
                                hintText: '商品の感想を書いてください',
                                filled: true,
                                fillColor: theme.brightness == Brightness.dark
                                    ? Colors.white10
                                    : Colors.grey.shade100,
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                  borderSide: BorderSide(
                                    color: theme.brightness ==
                                            Brightness.dark
                                        ? Colors.white24
                                        : Colors.grey.shade300,
                                  ),
                                ),
                                focusedBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                  borderSide: BorderSide(
                                    color: Colors.greenAccent[400] ??
                                        Colors.green,
                                    width: 1.5,
                                  ),
                                ),
                                contentPadding: const EdgeInsets.all(15),
                              ),
                              onChanged: addReviewToProductController
                                  .updateReviewText,
                              validator: (value) {
                                if (value == null || value.isEmpty) {
                                  return 'レビューを入力してください。';
                                }
                                return null;
                              },
                            ),

                            const SizedBox(height: 24),

                            if (addReviewToProductState.isLoading)
                              const Center(
                                child: Padding(
                                  padding: EdgeInsets.only(top: 8.0),
                                  child: CircularProgressIndicator(),
                                ),
                              ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // 🔹 画面下部の「レビューを投稿する」ボタン
            Positioned(
              left: 0,
              right: 0,
              bottom: 0,
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.bottomCenter,
                    end: Alignment.topCenter,
                    colors: [
                      bgColor,
                      bgColor.withOpacity(0.0),
                    ],
                  ),
                ),
                child: SafeArea(
                  top: false,
                  child: SizedBox(
                    width: double.infinity,
                    height: 52,
                    child: ElevatedButton(
                      onPressed: addReviewToProductState.isLoading
                          ? null
                          : handleSubmit,
                      style: ElevatedButton.styleFrom(
                        backgroundColor:
                            Colors.greenAccent[400] ?? Colors.green,
                        foregroundColor: const Color(0xFF102216),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(999),
                        ),
                        elevation: 6,
                        shadowColor:
                            (Colors.greenAccent[400] ?? Colors.green)
                                .withOpacity(0.4),
                      ),
                      child: addReviewToProductState.isLoading
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                valueColor:
                                    AlwaysStoppedAnimation<Color>(Colors.black),
                              ),
                            )
                          : const Text(
                              'レビューを投稿する',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                              ),
                            ),
                    ),
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
