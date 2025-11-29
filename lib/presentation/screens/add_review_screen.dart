import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:favlog_app/presentation/providers/add_review_controller.dart';
import 'package:favlog_app/presentation/widgets/error_dialog.dart';

class AddReviewScreen extends ConsumerWidget {
  const AddReviewScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final addReviewState = ref.watch(addReviewControllerProvider);
    final addReviewController = ref.read(addReviewControllerProvider.notifier);

    final formKey = GlobalKey<FormState>();

    // エラー発生時にダイアログ表示（元の処理を引き継ぎ）
    ref.listen<AddReviewState>(
      addReviewControllerProvider,
      (previous, next) {
        if (next.error != null && next.error != previous?.error) {
          ErrorDialog.show(context, next.error!);
        }
      },
    );

    final theme = Theme.of(context);
    final bgColor = theme.brightness == Brightness.dark
        ? const Color(0xFF102216) // background-dark
        : const Color(0xFFF6F8F6); // background-light

    Future<void> handleSubmit() async {
      if (!formKey.currentState!.validate()) {
        return;
      }

      await addReviewController.submitReview();

      // 最新の状態を読んでエラーがなければ戻る
      final latestState = ref.read(addReviewControllerProvider);
      if (context.mounted && latestState.error == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('レビューと商品情報を追加しました！')),
        );
        Navigator.of(context).pop();
      }
    }

    // 星の表示（1〜5）
    List<Widget> buildStars() {
      final rating = addReviewState.rating;
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
          onPressed: addReviewState.isLoading
              ? null
              : () {
                  // タップで 0.5 刻みっぽく切り替え
                  double newRating;
                  if (rating == starIndex.toDouble()) {
                    newRating = starIndex - 0.5;
                  } else {
                    newRating = starIndex.toDouble();
                  }
                  if (newRating < 1) newRating = 1;
                  if (newRating > 5) newRating = 5;
                  addReviewController.updateRating(newRating);
                },
          icon: Icon(icon, color: color),
        );
      });
    }

    // 公開範囲（いまはダミー表示のみ）
    const visibilityLabel = '親しい友達'; // TODO: 状態管理したくなったらProvider追加

    return Scaffold(
      backgroundColor: bgColor,
      body: SafeArea(
        child: Stack(
          children: [
            // スクロールコンテンツ
            Positioned.fill(
              child: SingleChildScrollView(
                padding: const EdgeInsets.only(bottom: 96),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // 上部カスタムヘッダー（close + タイトル + 投稿）
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
                              onPressed: addReviewState.isLoading
                                  ? null
                                  : handleSubmit,
                              child: Text(
                                '投稿',
                                style: TextStyle(
                                  color: Colors.greenAccent[400] ??
                                      Colors.green,
                                  fontWeight: FontWeight.bold,
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
                            // 商品・サービス名
                            const Text(
                              '商品・サービス名',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            const SizedBox(height: 8),
                            TextFormField(
                              initialValue: addReviewState.productName,
                              decoration: InputDecoration(
                                hintText: '例：お気に入りの本',
                                filled: true,
                                fillColor:
                                    theme.brightness == Brightness.dark
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
                                contentPadding: const EdgeInsets.symmetric(
                                  horizontal: 15,
                                  vertical: 15,
                                ),
                              ),
                              onChanged:
                                  addReviewController.updateProductName,
                              validator: (value) {
                                if (value == null || value.isEmpty) {
                                  return '商品名を入力してください。';
                                }
                                return null;
                              },
                            ),

                            const SizedBox(height: 16),

                            // 商品URL（任意）
                            Text(
                              '商品URL (任意)',
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w500,
                                color: theme.brightness == Brightness.dark
                                    ? Colors.grey[400]
                                    : Colors.grey[600],
                              ),
                            ),
                            const SizedBox(height: 8),
                            TextFormField(
                              initialValue: addReviewState.productUrl,
                              keyboardType: TextInputType.url,
                              decoration: InputDecoration(
                                hintText: '例：https://example.com',
                                filled: true,
                                fillColor:
                                    theme.brightness == Brightness.dark
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
                                contentPadding: const EdgeInsets.symmetric(
                                  horizontal: 15,
                                  vertical: 15,
                                ),
                              ),
                              onChanged: addReviewController.updateProductUrl,
                            ),

                            const SizedBox(height: 24),

                            // カテゴリ（ChoiceChip）
                            const Text(
                              'カテゴリ',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            const SizedBox(height: 8),
                            FormField<String>(
                              validator: (value) {
                                if (value == null || value.isEmpty) {
                                  return 'カテゴリを選択してください。';
                                }
                                return null;
                              },
                              initialValue: addReviewState.selectedCategory,
                              builder: (field) {
                                return Column(
                                  crossAxisAlignment:
                                      CrossAxisAlignment.start,
                                  children: [
                                    Wrap(
                                      spacing: 8,
                                      runSpacing: 8,
                                      children: addReviewState.categories
                                          .map((category) {
                                        final selected =
                                            addReviewState.selectedCategory ==
                                                category;
                                        return ChoiceChip(
                                          label: Text(
                                            category,
                                            style: TextStyle(
                                              fontWeight: selected
                                                  ? FontWeight.bold
                                                  : FontWeight.w500,
                                            ),
                                          ),
                                          selected: selected,
                                          onSelected: addReviewState
                                                  .isLoading
                                              ? null
                                              : (_) {
                                                  addReviewController
                                                      .updateSelectedCategory(
                                                          category);
                                                  field.didChange(category);
                                                },
                                          selectedColor:
                                              Colors.greenAccent[400],
                                          labelStyle: TextStyle(
                                            color: selected
                                                ? const Color(0xFF102216)
                                                : (theme.brightness ==
                                                        Brightness.dark
                                                    ? Colors.grey[200]
                                                    : Colors.grey[800]),
                                          ),
                                          backgroundColor: theme.brightness ==
                                                  Brightness.dark
                                              ? Colors.white10
                                              : Colors.grey.shade100,
                                          shape: RoundedRectangleBorder(
                                            borderRadius:
                                                BorderRadius.circular(999),
                                          ),
                                        );
                                      }).toList(),
                                    ),
                                    if (field.errorText != null)
                                      Padding(
                                        padding: const EdgeInsets.only(
                                            top: 8.0),
                                        child: Text(
                                          field.errorText!,
                                          style: TextStyle(
                                            color:
                                                theme.colorScheme.error,
                                            fontSize: 12,
                                          ),
                                        ),
                                      ),
                                  ],
                                );
                              },
                            ),

                            const SizedBox(height: 24),

                            // サブカテゴリ（任意）※元はAutocompleteだったのを簡略化
                            Text(
                              'サブカテゴリ (任意)',
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w500,
                                color: theme.brightness == Brightness.dark
                                    ? Colors.grey[400]
                                    : Colors.grey[600],
                              ),
                            ),
                            const SizedBox(height: 8),
                            TextFormField(
                              initialValue: addReviewState.subcategory,
                              decoration: InputDecoration(
                                hintText:
                                    '例：ミステリー小説、ワイヤレスイヤホン',
                                filled: true,
                                fillColor:
                                    theme.brightness == Brightness.dark
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
                                contentPadding: const EdgeInsets.symmetric(
                                  horizontal: 15,
                                  vertical: 15,
                                ),
                              ),
                              onChanged:
                                  addReviewController.updateSubcategory,
                            ),

                            const SizedBox(height: 24),

                            // 評価（星）
                            const Text(
                              '評価',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Row(children: buildStars()),

                            const SizedBox(height: 24),

                            // 写真を追加（1枚想定：元の state に合わせて単一ファイル）
                            const Text(
                              '写真を追加',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            const SizedBox(height: 8),
                            GestureDetector(
                              onTap: addReviewState.isLoading
                                  ? null
                                  : addReviewController.pickImage,
                              child: Container(
                                height: 110,
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(12),
                                  color: theme.brightness == Brightness.dark
                                      ? Colors.white10
                                      : Colors.grey.shade100,
                                  border: Border.all(
                                    color: theme.brightness ==
                                            Brightness.dark
                                        ? Colors.white24
                                        : Colors.grey.shade300,
                                    width: 1.5,
                                  ),
                                ),
                                child: addReviewState.imageFile == null
                                    ? Column(
                                        mainAxisAlignment:
                                            MainAxisAlignment.center,
                                        children: [
                                          Icon(
                                            Icons
                                                .add_photo_alternate_outlined,
                                            size: 28,
                                            color: theme.brightness ==
                                                    Brightness.dark
                                                ? Colors.grey[400]
                                                : Colors.grey[500],
                                          ),
                                          const SizedBox(height: 4),
                                          Text(
                                            '写真を追加',
                                            style: TextStyle(
                                              fontSize: 12,
                                              color: theme.brightness ==
                                                      Brightness.dark
                                                  ? Colors.grey[400]
                                                  : Colors.grey[600],
                                            ),
                                          ),
                                        ],
                                      )
                                    : ClipRRect(
                                        borderRadius:
                                            BorderRadius.circular(12),
                                        child: Image.file(
                                          addReviewState.imageFile!,
                                          fit: BoxFit.cover,
                                          width: double.infinity,
                                        ),
                                      ),
                              ),
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
                              initialValue: addReviewState.reviewText,
                              maxLines: 6,
                              decoration: InputDecoration(
                                hintText:
                                    '良かった点、気になった点など、自由にレビューを書きましょう。',
                                filled: true,
                                fillColor:
                                    theme.brightness == Brightness.dark
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
                              onChanged:
                                  addReviewController.updateReviewText,
                              validator: (value) {
                                if (value == null || value.isEmpty) {
                                  return 'レビューを入力してください。';
                                }
                                return null;
                              },
                            ),

                            const SizedBox(height: 24),

                            // 公開範囲（見た目だけ、それっぽく）
                            const Text(
                              '公開範囲',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Container(
                              height: 56,
                              padding:
                                  const EdgeInsets.symmetric(horizontal: 12),
                              decoration: BoxDecoration(
                                color: theme.brightness == Brightness.dark
                                    ? Colors.white10
                                    : Colors.grey.shade100,
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  Row(
                                    children: [
                                      Container(
                                        height: 32,
                                        width: 32,
                                        decoration: BoxDecoration(
                                          color: (Colors.greenAccent[400] ??
                                                  Colors.green)
                                              .withOpacity(0.2),
                                          shape: BoxShape.circle,
                                        ),
                                        child: Icon(
                                          Icons.group,
                                          size: 18,
                                          color: Colors.greenAccent[400] ??
                                              Colors.green,
                                        ),
                                      ),
                                      const SizedBox(width: 12),
                                      const Text(
                                        visibilityLabel,
                                        style: TextStyle(fontSize: 16),
                                      ),
                                    ],
                                  ),
                                  Icon(
                                    Icons.arrow_forward_ios,
                                    size: 18,
                                    color: theme.brightness == Brightness.dark
                                        ? Colors.grey[500]
                                        : Colors.grey[400],
                                  ),
                                ],
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

            // 下部「レビューを投稿する」ボタン
            Positioned(
              left: 0,
              right: 0,
              bottom: 0,
              child: Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 16, vertical: 12),
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
                      onPressed: addReviewState.isLoading
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
                      child: addReviewState.isLoading
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                valueColor:
                                    AlwaysStoppedAnimation<Color>(
                                  Colors.black,
                                ),
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
