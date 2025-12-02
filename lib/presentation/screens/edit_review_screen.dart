import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shimmer/shimmer.dart';
import '../../domain/models/review.dart';
import '../../domain/models/product.dart';
import '../providers/edit_review_controller.dart';
import '../widgets/error_dialog.dart';

class EditReviewScreen extends ConsumerStatefulWidget {
  final Review review;
  final Product product;

  const EditReviewScreen({
    super.key,
    required this.review,
    required this.product,
  });

  @override
  ConsumerState<EditReviewScreen> createState() => _EditReviewScreenState();
}

class _EditReviewScreenState extends ConsumerState<EditReviewScreen> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _reviewTextController;

  @override
  void initState() {
    super.initState();
    _reviewTextController =
        TextEditingController(text: widget.review.reviewText);
  }

  @override
  void dispose() {
    _reviewTextController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final editReviewState =
        ref.watch(editReviewControllerProvider(widget.review));
    final editReviewController =
        ref.read(editReviewControllerProvider(widget.review).notifier);

    // エラー発生時にダイアログ表示
    ref.listen<EditReviewState>(
      editReviewControllerProvider(widget.review),
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

      await editReviewController.updateReview();

      final latestState =
          ref.read(editReviewControllerProvider(widget.review));
      if (context.mounted && latestState.error == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('レビューを更新しました！')),
        );
        Navigator.of(context).pop(true); // 更新成功を通知
      }
    }

    // 星表示（0.5刻み）
    List<Widget> buildStars() {
      final rating = editReviewState.rating;
      return List.generate(5, (index) {
        final starIndex = index + 1;
        final isFilled = rating >= starIndex;
        final isHalf = rating >= starIndex - 0.5 && rating < starIndex;

        IconData icon;
        Color color;

        if (isFilled) {
          icon = Icons.star;
          color = Colors.greenAccent[400] ?? Colors.green;
        } else if (isHalf) {
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
          onPressed: editReviewState.isLoading
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
                  editReviewController.updateRating(newRating);
                },
          icon: Icon(icon, color: color),
        );
      });
    }

    return Scaffold(
      backgroundColor: bgColor,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.only(bottom: 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 上部カスタムヘッダー
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
                    // 左：閉じるボタン
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
                    // 中央：タイトル
                    const Expanded(
                      child: Center(
                        child: Text(
                          'レビューを編集',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            letterSpacing: -0.3,
                          ),
                        ),
                      ),
                    ),
                    // 右：更新ボタン
                    SizedBox(
                      width: 48,
                      child: TextButton(
                        onPressed: editReviewState.isLoading
                            ? null
                            : handleSubmit,
                        child: Text(
                          '更新',
                          style: TextStyle(
                            color:
                                Colors.greenAccent[400] ?? Colors.green,
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
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // 商品情報（表示のみ）
                      Container(
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: theme.brightness == Brightness.dark
                              ? Colors.white10
                              : Colors.white,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                            color: theme.brightness == Brightness.dark
                                ? Colors.white24
                                : Colors.grey.shade300,
                          ),
                        ),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // サムネイル
                            if (widget.product.imageUrl != null &&
                                widget.product.imageUrl!.isNotEmpty)
                              ClipRRect(
                                borderRadius: BorderRadius.circular(8),
                                child: CachedNetworkImage(
                                  imageUrl: widget.product.imageUrl!,
                                  width: 64,
                                  height: 64,
                                  fit: BoxFit.cover,
                                  placeholder: (context, url) =>
                                      Shimmer.fromColors(
                                    baseColor: Colors.grey[300]!,
                                    highlightColor: Colors.grey[100]!,
                                    child: Container(
                                      width: 64,
                                      height: 64,
                                      color: Colors.white,
                                    ),
                                  ),
                                  errorWidget: (context, url, error) =>
                                      Container(
                                    width: 64,
                                    height: 64,
                                    decoration: BoxDecoration(
                                      borderRadius:
                                          BorderRadius.circular(8),
                                      color: theme.brightness ==
                                              Brightness.dark
                                          ? Colors.white12
                                          : Colors.grey.shade200,
                                    ),
                                    child: Icon(
                                      Icons.image_not_supported_outlined,
                                      color: theme.brightness ==
                                              Brightness.dark
                                          ? Colors.white54
                                          : Colors.grey.shade500,
                                    ),
                                  ),
                                ),
                              )
                            else
                              Container(
                                width: 64,
                                height: 64,
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(8),
                                  color: theme.brightness == Brightness.dark
                                      ? Colors.white12
                                      : Colors.grey.shade200,
                                ),
                                child: Icon(
                                  Icons.image_not_supported_outlined,
                                  color: theme.brightness == Brightness.dark
                                      ? Colors.white54
                                      : Colors.grey.shade500,
                                ),
                              ),
                            const SizedBox(width: 12),
                            // 商品情報テキスト
                            Expanded(
                              child: Column(
                                crossAxisAlignment:
                                    CrossAxisAlignment.start,
                                children: [
                                  // 商品名
                                  Text(
                                    widget.product.name,
                                    style: theme.textTheme.titleMedium
                                        ?.copyWith(
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  const SizedBox(height: 6),

                                  // カテゴリ / サブカテゴリ
                                  Wrap(
                                    spacing: 8,
                                    runSpacing: 4,
                                    children: [
                                      if (widget.product.category != null)
                                        Chip(
                                          label: Text(
                                            widget.product.category!,
                                            style: theme
                                                .textTheme.bodySmall
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
                                      if (widget.product.subcategory !=
                                          null)
                                        Chip(
                                          label: Text(
                                            widget.product.subcategory!,
                                            style: theme
                                                .textTheme.bodySmall
                                                ?.copyWith(
                                              color: theme.brightness ==
                                                      Brightness.dark
                                                  ? Colors.white
                                                  : Colors.black87,
                                            ),
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

                                  // URL
                                  if (widget.product.url != null &&
                                      widget.product.url!.isNotEmpty) ...[
                                    const SizedBox(height: 6),
                                    Text(
                                      widget.product.url!,
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: theme.textTheme.bodySmall
                                          ?.copyWith(
                                        color: Colors.blueAccent,
                                        decoration:
                                            TextDecoration.underline,
                                      ),
                                    ),
                                  ],
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(height: 24),

                      // 評価
                      const Text(
                        '評価',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: buildStars(),
                      ),

                      const SizedBox(height: 24),

                      // レビュー本文
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
                              color: theme.brightness == Brightness.dark
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
                          counterText:
                              '${editReviewState.reviewText.length}文字',
                        ),
                        onChanged: editReviewController.updateReviewText,
                        validator: (value) {
                          if (value == null || value.trim().isEmpty) {
                            return 'レビューを入力してください。';
                          }
                          if (value.trim().length < 10) {
                            return 'レビューは10文字以上入力してください。';
                          }
                          return null;
                        },
                      ),

                      const SizedBox(height: 24),

                      if (editReviewState.isLoading)
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
    );
  }
}