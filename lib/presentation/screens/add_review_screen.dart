import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:favlog_app/presentation/providers/add_review_controller.dart';
import 'package:favlog_app/presentation/widgets/error_dialog.dart';

class AddReviewScreen extends ConsumerStatefulWidget {
  const AddReviewScreen({super.key});

  @override
  ConsumerState<AddReviewScreen> createState() => _AddReviewScreenState();
}

class _AddReviewScreenState extends ConsumerState<AddReviewScreen> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _productNameController;
  late final TextEditingController _productUrlController;
  late final TextEditingController _subcategoryController;
  late final TextEditingController _reviewTextController;

  @override
  void initState() {
    super.initState();
    final addReviewState = ref.read(addReviewControllerProvider);
    _productNameController =
        TextEditingController(text: addReviewState.productName);
    _productUrlController =
        TextEditingController(text: addReviewState.productUrl);
    _subcategoryController =
        TextEditingController(text: addReviewState.subcategory);
    _reviewTextController =
        TextEditingController(text: addReviewState.reviewText);
  }

  @override
  void dispose() {
    _productNameController.dispose();
    _productUrlController.dispose();
    _subcategoryController.dispose();
    _reviewTextController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final addReviewState = ref.watch(addReviewControllerProvider);
    final addReviewController = ref.read(addReviewControllerProvider.notifier);

    // エラー発生時にダイアログ表示
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
      if (!_formKey.currentState!.validate()) {
        return;
      }

      await addReviewController.submitReview();

      final latestState = ref.read(addReviewControllerProvider);
      if (context.mounted && latestState.error == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('レビューと商品情報を追加しました！')),
        );
        Navigator.of(context).pop();
      }
    }

    // 星表示（0.5刻み）
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

    const visibilityLabel = '親しい友達';

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
                                'レビュー投稿',
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                  letterSpacing: -0.3,
                                ),
                              ),
                            ),
                          ),
                          // 右：投稿ボタン
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

                    // 本文フォーム
                    Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 16,
                      ),
                      child: Form(
                        key: _formKey,
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
                              controller: _productNameController,
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
                              controller: _productUrlController,
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
                              onChanged:
                                  addReviewController.updateProductUrl,
                            ),

                            const SizedBox(height: 24),

                            // カテゴリ
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
                              initialValue:
                                  addReviewState.selectedCategory,
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
                                              fontSize: 14,
                                              fontWeight: FontWeight.w500,
                                              color: selected
                                                  ? const Color(0xFF102216)
                                                  : (theme.brightness ==
                                                          Brightness.dark
                                                      ? Colors.white
                                                      : Colors.black87),
                                            ),
                                          ),
                                          selected: selected,
                                          onSelected:
                                              addReviewState.isLoading
                                                  ? null
                                                  : (_) {
                                                      addReviewController
                                                          .updateSelectedCategory(
                                                              category);
                                                      field.didChange(
                                                          category);
                                                    },
                                          selectedColor:
                                              Colors.greenAccent[400],
                                          labelStyle: TextStyle(
                                            color: selected
                                                ? const Color(0xFF102216)
                                                : (theme.brightness ==
                                                        Brightness.dark
                                                    ? Colors.white
                                                    : Colors.black87),
                                          ),
                                          backgroundColor:
                                              theme.brightness ==
                                                      Brightness.dark
                                                  ? Colors.white10
                                                  : Colors.grey.shade100,
                                          shape: RoundedRectangleBorder(
                                            borderRadius:
                                                BorderRadius.circular(20),
                                            side: BorderSide(
                                              color: selected
                                                  ? Colors.greenAccent[400] ??
                                                      Colors.green
                                                  : (theme.brightness ==
                                                          Brightness.dark
                                                      ? Colors.white24
                                                      : Colors.grey.shade300),
                                            ),
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
                                            color: theme.colorScheme.error,
                                            fontSize: 12,
                                          ),
                                        ),
                                      ),
                                  ],
                                );
                              },
                            ),

                            const SizedBox(height: 24),

                            // サブカテゴリ（任意）
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
                              controller: _subcategoryController,
                              decoration: InputDecoration(
                                hintText:
                                    '例：カフェ、書籍、ガジェット、美容、サブスク など',
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

                            // 写真を追加
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
                                            Icons.add_a_photo,
                                            size: 28,
                                            color: Colors.greenAccent[400] ??
                                                Colors.green,
                                          ),
                                          const SizedBox(height: 8),
                                          Text(
                                            '写真を追加',
                                            style: TextStyle(
                                              color: theme.brightness ==
                                                      Brightness.dark
                                                  ? Colors.white
                                                  : Colors.black87,
                                            ),
                                          ),
                                        ],
                                      )
                                    : Row(
                                        children: [
                                          const SizedBox(width: 12),
                                          ClipRRect(
                                            borderRadius:
                                                BorderRadius.circular(8),
                                            child: Image.file(
                                              addReviewState.imageFile!,
                                              width: 80,
                                              height: 80,
                                              fit: BoxFit.cover,
                                            ),
                                          ),
                                          const SizedBox(width: 12),
                                          Expanded(
                                            child: Text(
                                              '写真が1枚選択されています',
                                              style: TextStyle(
                                                color: theme.brightness ==
                                                        Brightness.dark
                                                    ? Colors.white
                                                    : Colors.black87,
                                              ),
                                            ),
                                          ),
                                          const SizedBox(width: 8),
                                        ],
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
                              controller: _reviewTextController,
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
                                contentPadding: const EdgeInsets.symmetric(
                                  horizontal: 15,
                                  vertical: 15,
                                ),
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

                            // 公開範囲（カード）
                            const Text(
                              '公開範囲',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 12,
                              ),
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(12),
                                color: theme.brightness == Brightness.dark
                                    ? Colors.white10
                                    : Colors.white,
                                border: Border.all(
                                  color: theme.brightness == Brightness.dark
                                      ? Colors.white24
                                      : Colors.grey.shade300,
                                ),
                              ),
                              child: Row(
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
                                    style: TextStyle(
                                      fontSize: 16,
                                    ),
                                  ),
                                  const Spacer(),
                                  Icon(
                                    Icons.arrow_forward_ios,
                                    size: 18,
                                    color:
                                        theme.brightness == Brightness.dark
                                            ? Colors.grey[400]
                                            : Colors.grey[600],
                                  ),
                                ],
                              ),
                            ),

                            const SizedBox(height: 48),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // 下部固定の公開範囲説明
            Positioned(
              left: 0,
              right: 0,
              bottom: 0,
              child: Container(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
                decoration: BoxDecoration(
                  color: theme.brightness == Brightness.dark
                      ? const Color(0xFF050B07)
                      : Colors.white,
                  border: Border(
                    top: BorderSide(
                      color: theme.brightness == Brightness.dark
                          ? Colors.white10
                          : Colors.grey.shade300,
                    ),
                  ),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.info_outline,
                      size: 18,
                      color: theme.brightness == Brightness.dark
                          ? Colors.grey[400]
                          : Colors.grey[600],
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'このレビューは $visibilityLabel にのみ表示されます',
                        style: TextStyle(
                          fontSize: 13,
                          color: theme.brightness == Brightness.dark
                              ? Colors.grey[300]
                              : Colors.grey[700],
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
    );
  }
}
