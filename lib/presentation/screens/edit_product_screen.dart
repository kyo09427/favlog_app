import 'package:go_router/go_router.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../domain/models/product.dart';
import '../providers/edit_product_controller.dart';
import '../widgets/error_dialog.dart';
import '../widgets/edit_product/edit_product_image_picker.dart';
import '../widgets/edit_product/edit_product_category_selector.dart';
import '../widgets/edit_product/edit_product_tags_input.dart';

class EditProductScreen extends ConsumerStatefulWidget {
  final Product product;

  const EditProductScreen({
    super.key,
    required this.product,
  });

  @override
  ConsumerState<EditProductScreen> createState() => _EditProductScreenState();
}

class _EditProductScreenState extends ConsumerState<EditProductScreen> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _productNameController;
  late final TextEditingController _productUrlController;
  late final TextEditingController _tagInputController;

  @override
  void initState() {
    super.initState();
    _productNameController = TextEditingController(text: widget.product.name);
    _productUrlController = TextEditingController(text: widget.product.url ?? '');
    _tagInputController = TextEditingController();
    // Set initial tags from originalProduct
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final controller = ref.read(editProductControllerProvider(widget.product).notifier);
      for (var tag in widget.product.subcategoryTags) {
        controller.addSubcategoryTag(tag);
      }
    });
  }

  @override
  void dispose() {
    _productNameController.dispose();
    _productUrlController.dispose();
    _tagInputController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final editProductState = ref.watch(editProductControllerProvider(widget.product));
    final editProductController = ref.read(editProductControllerProvider(widget.product).notifier);

    // エラー発生時ダイアログ
    ref.listen<EditProductState>(
      editProductControllerProvider(widget.product),
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

      await editProductController.updateProduct();

      final latestState = ref.read(editProductControllerProvider(widget.product));
      if (context.mounted && latestState.error == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('商品情報を更新しました！')),
        );
        context.pop(true);
      }
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
                      onPressed: () => context.pop(),
                    ),
                    const SizedBox(width: 8),
                    const Expanded(
                      child: Text(
                        '商品情報を編集',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 18,
                          letterSpacing: -0.3,
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 12),

              Form(
                key: _formKey,
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // 画像セクション
                      EditProductImagePicker(
                        state: editProductState,
                        controller: editProductController,
                      ),
                      const SizedBox(height: 24),

                      // 商品名
                      Text(
                        '商品・サービス名',
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
                        controller: _productNameController,
                        decoration: InputDecoration(
                          hintText: '例: 隠れ家カフェ「L\'ombre」',
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
                          focusedBorder: const OutlineInputBorder(
                            borderRadius: BorderRadius.all(
                              Radius.circular(12),
                            ),
                            borderSide: BorderSide(
                              color: Color(0xFF22A06B),
                              width: 1.5,
                            ),
                          ),
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 15,
                            vertical: 14,
                          ),
                        ),
                        onChanged: editProductController.updateProductName,
                        validator: (value) {
                          if (value == null || value.trim().isEmpty) {
                            return '商品・サービス名を入力してください';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 24),

                      // URL
                      Text(
                        'URL（任意）',
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
                        controller: _productUrlController,
                        decoration: InputDecoration(
                          hintText: '例: https://example.com',
                          prefixIcon: Icon(
                            Icons.link,
                            color: theme.brightness == Brightness.dark
                                ? Colors.grey[300]
                                : Colors.grey[700],
                          ),
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
                          focusedBorder: const OutlineInputBorder(
                            borderRadius: BorderRadius.all(
                              Radius.circular(12),
                            ),
                            borderSide: BorderSide(
                              color: Color(0xFF22A06B),
                              width: 1.5,
                            ),
                          ),
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 15,
                            vertical: 14,
                          ),
                        ),
                        keyboardType: TextInputType.url,
                        onChanged: editProductController.updateProductUrl,
                      ),
                      const SizedBox(height: 24),

                      // カテゴリ
                      EditProductCategorySelector(
                        state: editProductState,
                        controller: editProductController,
                      ),
                      const SizedBox(height: 24),

                      // サブカテゴリ
                      EditProductTagsInput(
                        state: editProductState,
                        controller: editProductController,
                        tagInputController: _tagInputController,
                      ),
                      const SizedBox(height: 24),

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
                                editProductState.isLoading
                                    ? '更新中...'
                                    : '内容を確認したら、「更新」ボタンを押してください。',
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
                                onPressed: editProductState.isLoading
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
                                child: editProductState.isLoading
                                    ? const SizedBox(
                                        width: 18,
                                        height: 18,
                                        child: CircularProgressIndicator(),
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