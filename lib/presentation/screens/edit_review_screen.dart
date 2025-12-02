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
  ConsumerState<EditReviewScreen> createState() =>
      _EditReviewScreenState();
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

    // エラー発生時ダイアログ
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
        Navigator.of(context).pop(true);
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
          icon: Icon(icon, color: const Color(0xFF22A06B)),
        );
      });
    }

    return Scaffold(
      backgroundColor: bgColor,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.only(bottom: 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ヘッダー
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 8,
                ),
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
                      onPressed: () => Navigator.of(context).pop(),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'レビューを編集',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 18,
                              letterSpacing: -0.3,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            widget.product.name,
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

              const SizedBox(height: 12),

              // 商品カード
              Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 16.0),
                child: Container(
                  decoration: BoxDecoration(
                    color: theme.brightness == Brightness.dark
                        ? const Color(0xFF050B07)
                        : Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: theme.brightness == Brightness.dark
                          ? Colors.white24
                          : Colors.grey.shade300,
                    ),
                  ),
                  child: Row(
                    children: [
                      ClipRRect(
                        borderRadius: const BorderRadius.horizontal(
                          left: Radius.circular(12),
                        ),
                        child: SizedBox(
                          width: 96,
                          height: 96,
                          child: CachedNetworkImage(
                            imageUrl: widget.product.imageUrl ?? '',
                            fit: BoxFit.cover,
                            placeholder: (context, url) =>
                                Shimmer.fromColors(
                              baseColor: theme.brightness == Brightness.dark
                                  ? Colors.grey[800]!
                                  : Colors.grey[300]!,
                              highlightColor:
                                  theme.brightness == Brightness.dark
                                      ? Colors.grey[700]!
                                      : Colors.grey[100]!,
                              child: Container(
                                color: Colors.grey[300],
                              ),
                            ),
                            errorWidget: (context, url, error) =>
                                Container(
                              color: theme.brightness == Brightness.dark
                                  ? Colors.grey[900]
                                  : Colors.grey[200],
                              child: Icon(
                                Icons.image_not_supported_outlined,
                                color: theme.brightness == Brightness.dark
                                    ? Colors.grey[700]
                                    : Colors.grey[500],
                              ),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Padding(
                          padding: const EdgeInsets.symmetric(
                            vertical: 12,
                            horizontal: 4,
                          ),
                          child: Column(
                            crossAxisAlignment:
                                CrossAxisAlignment.start,
                            children: [
                              Text(
                                widget.product.name,
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.bold,
                                  color: theme.brightness ==
                                          Brightness.dark
                                      ? Colors.white
                                      : Colors.black,
                                ),
                              ),
                              const SizedBox(height: 4),
                              if (widget.product.category != null)
                                Text(
                                  widget.product.category!,
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: theme.brightness ==
                                            Brightness.dark
                                        ? Colors.grey[400]
                                        : Colors.grey[700],
                                  ),
                                ),
                              if (widget.product.subcategory != null &&
                                  widget.product.subcategory!
                                      .isNotEmpty)
                                Padding(
                                  padding: const EdgeInsets.only(
                                      top: 4.0),
                                  child: Text(
                                    widget.product.subcategory!,
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: theme.brightness ==
                                              Brightness.dark
                                          ? Colors.grey[500]
                                          : Colors.grey[600],
                                    ),
                                  ),
                                ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 16),

              // 評価
              Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
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
                          editReviewState.rating.toStringAsFixed(1),
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
                  ],
                ),
              ),

              const SizedBox(height: 24),

              // レビュー本文
              Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
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
                    Form(
                      key: _formKey,
                      child: TextFormField(
                        controller: _reviewTextController,
                        maxLines: 6,
                        decoration: InputDecoration(
                          hintText:
                              '感じたことや良かったところ、イマイチだったところなどをメモしておきましょう。',
                          filled: true,
                          fillColor: theme.brightness == Brightness.dark
                              ? Colors.white.withOpacity(0.04)
                              : Colors.white,
                          border: OutlineInputBorder(
                            borderRadius:
                                BorderRadius.circular(12),
                            borderSide: BorderSide(
                              color: theme.brightness ==
                                      Brightness.dark
                                  ? Colors.white24
                                  : Colors.grey.shade300,
                            ),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius:
                                BorderRadius.circular(12),
                            borderSide: BorderSide(
                              color: theme.brightness ==
                                      Brightness.dark
                                  ? Colors.white24
                                  : Colors.grey.shade300,
                            ),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius:
                                BorderRadius.circular(12),
                            borderSide: BorderSide(
                              color: const Color(0xFF22A06B) ??
                                  Colors.green,
                              width: 1.5,
                            ),
                          ),
                          contentPadding:
                              const EdgeInsets.symmetric(
                            horizontal: 15,
                            vertical: 14,
                          ),
                        ),
                        onChanged:
                            editReviewController.updateReviewText,
                        validator: (value) {
                          if (value == null ||
                              value.trim().length < 10) {
                            return 'レビュー本文は10文字以上で入力してください';
                          }
                          return null;
                        },
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 24),

              // 下部ボタン
              Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 16.0),
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 12,
                  ),
                  decoration: BoxDecoration(
                    color: theme.brightness == Brightness.dark
                        ? const Color(0xFF050B07)
                        : Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: theme.brightness == Brightness.dark
                          ? Colors.white24
                          : Colors.grey.shade300,
                    ),
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: Text(
                          editReviewState.isLoading
                              ? '更新中...'
                              : '内容を確認したら、「更新」ボタンを押してください。',
                          style: TextStyle(
                            fontSize: 12,
                            color: theme.brightness ==
                                    Brightness.dark
                                ? Colors.grey[300]
                                : Colors.grey[700],
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      SizedBox(
                        height: 44,
                        child: ElevatedButton(
                          onPressed: editReviewState.isLoading
                              ? null
                              : handleSubmit,
                          style: ElevatedButton.styleFrom(
                            backgroundColor:
                                const Color(0xFF22A06B),
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(
                              borderRadius:
                                  BorderRadius.circular(999),
                            ),
                            padding:
                                const EdgeInsets.symmetric(
                              horizontal: 24,
                              vertical: 10,
                            ),
                          ),
                          child: editReviewState.isLoading
                              ? const SizedBox(
                                  width: 18,
                                  height: 18,
                                  child:
                                      CircularProgressIndicator(),
                                )
                              : const Text(
                                  '更新',
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
              ),
            ],
          ),
        ),
      ),
    );
  }
}
