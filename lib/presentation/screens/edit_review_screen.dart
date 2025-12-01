import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:favlog_app/domain/models/product.dart';
import 'package:favlog_app/domain/models/review.dart';
import 'package:favlog_app/presentation/providers/edit_review_controller.dart';
import 'package:favlog_app/presentation/widgets/error_dialog.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:shimmer/shimmer.dart';

/// レビュー編集画面
/// - 編集可能: 星評価、レビュー本文のみ
/// - 表示のみ: 商品情報（名前、画像、カテゴリなど）
class EditReviewScreen extends ConsumerStatefulWidget {
  final String productId;
  final String reviewId;

  const EditReviewScreen({
    super.key,
    required this.productId,
    required this.reviewId,
  });

  @override
  ConsumerState<EditReviewScreen> createState() => _EditReviewScreenState();
}

class _EditReviewScreenState extends ConsumerState<EditReviewScreen> {
  static const Color primaryColor = Color(0xFF4CAF50);
  static const Color backgroundLight = Color(0xFFF6F8F6);
  static const Color backgroundDark = Color(0xFF102216);

  final formKey = GlobalKey<FormState>();
  late TextEditingController _reviewTextController;

  @override
  void initState() {
    super.initState();
    _reviewTextController = TextEditingController();
  }

  @override
  void dispose() {
    _reviewTextController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final editReviewState = ref.watch(
      editReviewControllerProvider({
        'productId': widget.productId,
        'reviewId': widget.reviewId,
      }),
    );
    final editReviewController = ref.read(
      editReviewControllerProvider({
        'productId': widget.productId,
        'reviewId': widget.reviewId,
      }).notifier,
    );

    // エラー監視
    ref.listen<EditReviewState>(
      editReviewControllerProvider({
        'productId': widget.productId,
        'reviewId': widget.reviewId,
      }),
      (previous, next) {
        if (next.error != null && next.error != previous?.error) {
          ErrorDialog.show(context, next.error!);
        }
      },
    );

    // 初期ロード中の表示
    if (editReviewState.isLoading &&
        editReviewState.product.id == Product.empty().id) {
      return Scaffold(
        appBar: AppBar(title: const Text('レビューを編集')),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    final Product currentProduct = editReviewState.product;
    final Review currentReview = editReviewState.review;

    // レビュー本文の初期値をセット（一度だけ）
    if (_reviewTextController.text.isEmpty && currentReview.reviewText.isNotEmpty) {
      _reviewTextController.text = currentReview.reviewText;
    }

    final theme = Theme.of(context);
    final bgColor =
        theme.brightness == Brightness.dark ? backgroundDark : backgroundLight;

    // 保存処理
    Future<void> handleSubmit() async {
      if (!formKey.currentState!.validate()) return;

      await editReviewController.updateReview();

      if (!mounted) return;

      final latestState = ref.read(
        editReviewControllerProvider({
          'productId': widget.productId,
          'reviewId': widget.reviewId,
        }),
      );
      
      if (latestState.error == null && !latestState.isLoading) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('レビューを更新しました!')),
        );
        Navigator.of(context).pop(true);
      }
    }

    // 星アイコン構築（0.5刻み）
    Widget buildStar(int index) {
      final double rating = currentReview.rating;
      final int starPos = index + 1;

      IconData icon;
      Color color;

      if (rating >= starPos) {
        icon = Icons.star;
        color = primaryColor;
      } else if (rating >= starPos - 0.5) {
        icon = Icons.star_half;
        color = primaryColor;
      } else {
        icon = Icons.star_border;
        color = theme.brightness == Brightness.dark
            ? Colors.grey[600]!
            : Colors.grey[400]!;
      }

      return IconButton(
        iconSize: 32,
        padding: EdgeInsets.zero,
        onPressed: editReviewState.isLoading
            ? null
            : () {
                double newRating;
                final double full = starPos.toDouble();
                final double half = starPos - 0.5;

                if (rating == full) {
                  newRating = half;
                } else if (rating == half) {
                  newRating = starPos - 1.0;
                  if (newRating < 1.0) newRating = 1.0;
                } else {
                  newRating = full;
                }

                if (newRating > 5.0) newRating = 5.0;

                editReviewController.updateRating(newRating);
              },
        icon: Icon(icon, color: color),
      );
    }

    return Scaffold(
      backgroundColor: bgColor,
      body: SafeArea(
        child: Stack(
          children: [
            // メインコンテンツ
            Positioned.fill(
              child: SingleChildScrollView(
                padding: const EdgeInsets.only(bottom: 96),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // ヘッダー
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
                          Expanded(
                            child: Center(
                              child: Text(
                                'レビューを編集',
                                style: theme.textTheme.titleMedium?.copyWith(
                                  fontWeight: FontWeight.bold,
                                  letterSpacing: -0.3,
                                ),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ),
                          SizedBox(
                            width: 48,
                            child: TextButton(
                              onPressed:
                                  editReviewState.isLoading ? null : handleSubmit,
                              child: Text(
                                '更新',
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  color: editReviewState.isLoading
                                      ? Colors.grey
                                      : primaryColor,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),

                    // フォーム本体
                    Padding(
                      padding: const EdgeInsets.all(16),
                      child: Form(
                        key: formKey,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // 商品情報表示（編集不可）
                            Container(
                              padding: const EdgeInsets.all(16),
                              decoration: BoxDecoration(
                                color: theme.brightness == Brightness.dark
                                    ? Colors.white.withOpacity(0.05)
                                    : Colors.grey.shade100,
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(
                                  color: theme.brightness == Brightness.dark
                                      ? Colors.white12
                                      : Colors.grey.shade300,
                                ),
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    '商品情報',
                                    style: theme.textTheme.titleSmall?.copyWith(
                                      fontWeight: FontWeight.w600,
                                      color: theme.brightness == Brightness.dark
                                          ? Colors.grey[400]
                                          : Colors.grey[600],
                                    ),
                                  ),
                                  const SizedBox(height: 12),
                                  Row(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      // 商品画像
                                      if (currentProduct.imageUrl != null)
                                        ClipRRect(
                                          borderRadius: BorderRadius.circular(8),
                                          child: CachedNetworkImage(
                                            imageUrl: currentProduct.imageUrl!,
                                            width: 80,
                                            height: 80,
                                            fit: BoxFit.cover,
                                            placeholder: (context, url) =>
                                                Shimmer.fromColors(
                                              baseColor: Colors.grey[300]!,
                                              highlightColor: Colors.grey[100]!,
                                              child: Container(
                                                width: 80,
                                                height: 80,
                                                color: Colors.white,
                                              ),
                                            ),
                                            errorWidget: (context, url, error) =>
                                                Container(
                                              width: 80,
                                              height: 80,
                                              color: Colors.grey[300],
                                              child: const Icon(Icons.broken_image),
                                            ),
                                          ),
                                        )
                                      else
                                        Container(
                                          width: 80,
                                          height: 80,
                                          decoration: BoxDecoration(
                                            color: Colors.grey[300],
                                            borderRadius: BorderRadius.circular(8),
                                          ),
                                          child: const Icon(
                                            Icons.image_not_supported,
                                            color: Colors.grey,
                                          ),
                                        ),
                                      const SizedBox(width: 12),
                                      // 商品情報テキスト
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              currentProduct.name,
                                              style: theme.textTheme.titleMedium
                                                  ?.copyWith(
                                                fontWeight: FontWeight.bold,
                                              ),
                                              maxLines: 2,
                                              overflow: TextOverflow.ellipsis,
                                            ),
                                            if (currentProduct.category != null ||
                                                currentProduct.subcategory != null)
                                              ...[
                                              const SizedBox(height: 8),
                                              Wrap(
                                                spacing: 4,
                                                runSpacing: 4,
                                                children: [
                                                  if (currentProduct.category !=
                                                      null)
                                                    Chip(
                                                      label: Text(
                                                        currentProduct.category!,
                                                        style: theme
                                                            .textTheme.bodySmall
                                                            ?.copyWith(
                                                          color: Colors.white,
                                                        ),
                                                      ),
                                                      backgroundColor:
                                                          primaryColor,
                                                      materialTapTargetSize:
                                                          MaterialTapTargetSize
                                                              .shrinkWrap,
                                                      padding: const EdgeInsets
                                                          .symmetric(
                                                          horizontal: 4),
                                                    ),
                                                  if (currentProduct
                                                          .subcategory !=
                                                      null)
                                                    Chip(
                                                      label: Text(
                                                        currentProduct
                                                            .subcategory!,
                                                        style: theme
                                                            .textTheme.bodySmall,
                                                      ),
                                                      backgroundColor: theme
                                                                  .brightness ==
                                                              Brightness.dark
                                                          ? Colors.white12
                                                          : Colors.grey.shade200,
                                                      materialTapTargetSize:
                                                          MaterialTapTargetSize
                                                              .shrinkWrap,
                                                      padding: const EdgeInsets
                                                          .symmetric(
                                                          horizontal: 4),
                                                    ),
                                                ],
                                              ),
                                            ],
                                          ],
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),

                            const SizedBox(height: 32),

                            // 評価（編集可能）
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
                            const SizedBox(height: 8),
                            Text(
                              '現在の評価: ${currentReview.rating.toStringAsFixed(1)}',
                              style: theme.textTheme.bodySmall?.copyWith(
                                color: theme.brightness == Brightness.dark
                                    ? Colors.grey[400]
                                    : Colors.grey[600],
                              ),
                            ),

                            const SizedBox(height: 32),

                            // レビュー本文（編集可能）
                            const Text(
                              'レビュー本文',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            const SizedBox(height: 8),
                            TextFormField(
                              controller: _reviewTextController,
                              maxLines: 8,
                              decoration: InputDecoration(
                                hintText: '商品の感想を書いてください',
                                filled: true,
                                fillColor: theme.brightness == Brightness.dark
                                    ? Colors.white10
                                    : Colors.grey.shade100,
                                border: OutlineInputBorder(
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
                                    color: primaryColor,
                                    width: 1.5,
                                  ),
                                ),
                                contentPadding: const EdgeInsets.all(15),
                              ),
                              onChanged: editReviewController.updateReviewText,
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
                            const SizedBox(height: 8),
                            Text(
                              '${_reviewTextController.text.length} 文字',
                              style: theme.textTheme.bodySmall?.copyWith(
                                color: theme.brightness == Brightness.dark
                                    ? Colors.grey[400]
                                    : Colors.grey[600],
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

            // 下部の更新ボタン
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
                      onPressed: editReviewState.isLoading ? null : handleSubmit,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: primaryColor,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(999),
                        ),
                        elevation: 6,
                        shadowColor: primaryColor.withOpacity(0.4),
                      ),
                      child: editReviewState.isLoading
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                valueColor: AlwaysStoppedAnimation<Color>(
                                  Colors.white,
                                ),
                              ),
                            )
                          : const Text(
                              'レビューを更新する',
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