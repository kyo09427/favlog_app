import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:favlog_app/domain/models/product.dart';
import 'package:favlog_app/domain/models/review.dart';
import 'package:favlog_app/presentation/providers/edit_review_controller.dart';
import 'package:favlog_app/presentation/widgets/error_dialog.dart';

/// レビュー編集画面
/// - 編集できるのは「評価」と「レビュー本文」だけ
/// - 商品名などは state.product から読んで表示に使うだけ
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
  // デザイン共通カラー（home_screen.dartに合わせた落ち着いた色）
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
    // ★ provider 呼び出し
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

    // 初期ロード中（product がまだ empty）のときはローディング表示
    if (editReviewState.isLoading &&
        editReviewState.product.id == Product.empty().id) {
      return Scaffold(
        appBar: AppBar(title: const Text('レビューを編集')),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    // state から product / review を取得
    final Product currentProduct = editReviewState.product;
    final Review currentReview = editReviewState.review;

    // TextEditingControllerにテキストをセット（初回のみ）
    if (_reviewTextController.text.isEmpty && currentReview.reviewText.isNotEmpty) {
      _reviewTextController.text = currentReview.reviewText;
    }

    final theme = Theme.of(context);
    final bgColor =
        theme.brightness == Brightness.dark ? backgroundDark : backgroundLight;

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
      if (latestState.error == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('レビューを更新しました!')),
        );
        Navigator.of(context).pop(true); // trueを返して更新を通知
      }
    }

    // ⭐ 0.5刻み対応のスター UI
    Widget buildStar(int index) {
      final double rating = currentReview.rating.toDouble();
      final int starPos = index + 1; // 1〜5

      IconData icon;
      Color color;

      if (rating >= starPos) {
        // 完全に塗りつぶし
        icon = Icons.star;
        color = primaryColor;
      } else if (rating >= starPos - 0.5) {
        // 0.5 の位置
        icon = Icons.star_half;
        color = primaryColor;
      } else {
        // 枠のみ
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
                // 1.0 ↔ 0.5 をトグルするイメージで更新
                double newRating;
                final double full = starPos.toDouble();
                final double half = starPos - 0.5;

                if (rating == full) {
                  // ★ → ☆0.5
                  newRating = half;
                } else if (rating == half) {
                  // ☆0.5 → ひとつ前の整数（最低 1.0）
                  newRating = starPos - 1.0;
                  if (newRating < 1.0) newRating = 1.0;
                } else {
                  // その他 → この星を整数でセット
                  newRating = full;
                }

                if (newRating > 5.0) newRating = 5.0;

                editReviewController.updateRating(newRating);
              },
        icon: Icon(icon, color: color),
      );
    }

    InputDecoration buildTextDecoration({String? hint}) {
      return InputDecoration(
        hintText: hint,
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
          borderRadius: const BorderRadius.all(Radius.circular(12)),
          borderSide: BorderSide(
            color: primaryColor,
            width: 1.5,
          ),
        ),
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 15, vertical: 15),
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
                    // 上部ヘッダー（× + タイトル + 更新）
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

                    // 本文:商品名表示 + 評価 + 本文
                    Padding(
                      padding: const EdgeInsets.all(16),
                      child: Form(
                        key: formKey,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // 商品名表示（編集不可）
                            Text(
                              '商品名',
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w500,
                                color: theme.brightness == Brightness.dark
                                    ? Colors.grey[400]
                                    : Colors.grey[600],
                              ),
                            ),
                            const SizedBox(height: 8),
                            Container(
                              width: double.infinity,
                              padding: const EdgeInsets.all(15),
                              decoration: BoxDecoration(
                                color: theme.brightness == Brightness.dark
                                    ? Colors.white.withOpacity(0.05)
                                    : Colors.grey.shade50,
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(
                                  color: theme.brightness == Brightness.dark
                                      ? Colors.white12
                                      : Colors.grey.shade300,
                                ),
                              ),
                              child: Text(
                                currentProduct.name,
                                style: theme.textTheme.bodyLarge,
                              ),
                            ),

                            const SizedBox(height: 24),

                            // ⭐ 評価
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

                            // 📝 レビュー本文
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
                              decoration: buildTextDecoration(
                                hint:
                                    '商品の感想や良かった点・気になった点など、自由に書いてください。',
                              ),
                              onChanged: editReviewController.updateReviewText,
                              validator: (value) {
                                if (value == null || value.isEmpty) {
                                  return 'レビューを入力してください。';
                                }
                                return null;
                              },
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // 下部「レビューを更新する」ボタン
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