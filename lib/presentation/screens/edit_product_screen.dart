import 'package:go_router/go_router.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:shimmer/shimmer.dart';
import '../../domain/models/product.dart';
import '../providers/edit_product_controller.dart';
import '../widgets/error_dialog.dart';

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
  late final TextEditingController _tagInputController; // Add this

  @override
  void initState() {
    super.initState();
    _productNameController = TextEditingController(text: widget.product.name);
    _productUrlController = TextEditingController(text: widget.product.url ?? '');
    _tagInputController = TextEditingController(); // Initialize
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
    _tagInputController.dispose(); // Dispose
    super.dispose();
  }

  void _showImageSourceDialog() {
    final theme = Theme.of(context);
    final editProductController = ref.read(editProductControllerProvider(widget.product).notifier);

    showModalBottomSheet(
      context: context,
      backgroundColor: theme.brightness == Brightness.dark
          ? const Color(0xFF1C1C1E)
          : Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: const Icon(Icons.camera_alt, color: Color(0xFF22A06B)),
                title: const Text('カメラで撮影'),
                onTap: () {
                  context.pop();
                  editProductController.pickImage(ImageSource.camera);
                },
              ),
              ListTile(
                leading: const Icon(Icons.photo_library, color: Color(0xFF22A06B)),
                title: const Text('ギャラリーから選択'),
                onTap: () {
                  context.pop();
                  editProductController.pickImage(ImageSource.gallery);
                },
              ),
            ],
          ),
        ),
      ),
    );
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
                      Text(
                        '商品画像',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: theme.brightness == Brightness.dark
                              ? Colors.white
                              : Colors.black87,
                        ),
                      ),
                      const SizedBox(height: 8),
                      GestureDetector(
                        onTap: editProductState.isLoading
                            ? null
                            : _showImageSourceDialog,
                        child: Container(
                          width: double.infinity,
                          height: 200,
                          decoration: BoxDecoration(
                            color: theme.brightness == Brightness.dark
                                ? Colors.white.withOpacity(0.04)
                                : Colors.white,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: theme.brightness == Brightness.dark
                                  ? Colors.white24
                                  : Colors.grey.shade300,
                            ),
                          ),
                          child: editProductState.newImageFile != null
                              ? Stack(
                                  children: [
                                    ClipRRect(
                                      borderRadius: BorderRadius.circular(12),
                                      child: Image.file(
                                        editProductState.newImageFile!,
                                        width: double.infinity,
                                        height: double.infinity,
                                        fit: BoxFit.cover,
                                      ),
                                    ),
                                    Positioned(
                                      top: 8,
                                      right: 8,
                                      child: Container(
                                        decoration: BoxDecoration(
                                          color: Colors.black54,
                                          borderRadius: BorderRadius.circular(20),
                                        ),
                                        child: IconButton(
                                          icon: const Icon(
                                            Icons.close,
                                            color: Colors.white,
                                            size: 20,
                                          ),
                                          onPressed: () {
                                            editProductController.clearImage();
                                          },
                                        ),
                                      ),
                                    ),
                                  ],
                                )
                              : editProductState.existingImageUrl != null
                                  ? Stack(
                                      children: [
                                        ClipRRect(
                                          borderRadius: BorderRadius.circular(12),
                                          child: CachedNetworkImage(
                                            imageUrl: editProductState.existingImageUrl!,
                                            width: double.infinity,
                                            height: double.infinity,
                                            fit: BoxFit.cover,
                                            placeholder: (context, url) => Shimmer.fromColors(
                                              baseColor: theme.brightness == Brightness.dark
                                                  ? Colors.grey[800]!
                                                  : Colors.grey[300]!,
                                              highlightColor: theme.brightness == Brightness.dark
                                                  ? Colors.grey[700]!
                                                  : Colors.grey[100]!,
                                              child: Container(color: Colors.white),
                                            ),
                                            errorWidget: (context, url, error) => Container(
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
                                        Positioned(
                                          bottom: 8,
                                          right: 8,
                                          child: Container(
                                            padding: const EdgeInsets.symmetric(
                                              horizontal: 12,
                                              vertical: 6,
                                            ),
                                            decoration: BoxDecoration(
                                              color: Colors.black54,
                                              borderRadius: BorderRadius.circular(20),
                                            ),
                                            child: const Row(
                                              mainAxisSize: MainAxisSize.min,
                                              children: [
                                                Icon(
                                                  Icons.edit,
                                                  color: Colors.white,
                                                  size: 16,
                                                ),
                                                SizedBox(width: 4),
                                                Text(
                                                  '画像を変更',
                                                  style: TextStyle(
                                                    color: Colors.white,
                                                    fontSize: 12,
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ),
                                        ),
                                      ],
                                    )
                                  : Column(
                                      mainAxisAlignment: MainAxisAlignment.center,
                                      children: [
                                        Icon(
                                          Icons.add_photo_alternate_outlined,
                                          size: 48,
                                          color: theme.brightness == Brightness.dark
                                              ? Colors.grey[600]
                                              : Colors.grey[400],
                                        ),
                                        const SizedBox(height: 8),
                                        Text(
                                          '画像を追加',
                                          style: TextStyle(
                                            color: theme.brightness == Brightness.dark
                                                ? Colors.grey[400]
                                                : Colors.grey[600],
                                            fontSize: 14,
                                          ),
                                        ),
                                        const SizedBox(height: 4),
                                        Text(
                                          'タップして選択',
                                          style: TextStyle(
                                            color: theme.brightness == Brightness.dark
                                                ? Colors.grey[600]
                                                : Colors.grey[400],
                                            fontSize: 12,
                                          ),
                                        ),
                                      ],
                                    ),
                        ),
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
                              ? Colors.white.withOpacity(0.04)
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
                              ? Colors.white.withOpacity(0.04)
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
                      Text(
                        'カテゴリ',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: theme.brightness == Brightness.dark
                              ? Colors.white
                              : Colors.black87,
                        ),
                      ),
                      const SizedBox(height: 8),
                      FormField<String>(
                        initialValue: editProductState.selectedCategory,
                        validator: (value) {
                          if (editProductState.selectedCategory.isEmpty) {
                            return 'カテゴリを1つ選択してください';
                          }
                          return null;
                        },
                        builder: (field) {
                          return Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Wrap(
                                spacing: 8,
                                runSpacing: 8,
                                children: editProductState.categories
                                    .map<Widget>((category) {
                                  final selected =
                                      editProductState.selectedCategory == category;
                                  return ChoiceChip(
                                    label: Text(
                                      category,
                                      style: TextStyle(
                                        fontSize: 14,
                                        fontWeight: FontWeight.w500,
                                        color: selected
                                            ? const Color(0xFF102216)
                                            : (theme.brightness == Brightness.dark
                                                ? Colors.white
                                                : Colors.black87),
                                      ),
                                    ),
                                    selected: selected,
                                    selectedColor: const Color(0xFF22A06B),
                                    backgroundColor: theme.brightness == Brightness.dark
                                        ? Colors.white10
                                        : Colors.grey.shade100,
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(20),
                                      side: BorderSide(
                                        color: selected
                                            ? const Color(0xFF22A06B)
                                            : (theme.brightness == Brightness.dark
                                                ? Colors.white24
                                                : Colors.grey.shade300),
                                      ),
                                    ),
                                    onSelected: editProductState.isLoading
                                        ? null
                                        : (_) {
                                            editProductController
                                                .updateSelectedCategory(category);
                                            field.didChange(category);
                                          },
                                  );
                                }).toList(),
                              ),
                              if (field.hasError)
                                Padding(
                                  padding: const EdgeInsets.only(top: 4.0),
                                  child: Text(
                                    field.errorText!,
                                    style: const TextStyle(
                                      color: Colors.redAccent,
                                      fontSize: 12,
                                    ),
                                  ),
                                ),
                            ],
                          );
                        },
                      ),
                      const SizedBox(height: 24),

                      // サブカテゴリ
                      Text(
                        'サブカテゴリ（任意）',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: theme.brightness == Brightness.dark
                              ? Colors.white
                              : Colors.black87,
                        ),
                      ),
                      const SizedBox(height: 8),
                      TextField(
                        controller: _tagInputController,
                        style: TextStyle(color: theme.textTheme.bodyMedium?.color),
                        decoration: InputDecoration(
                          hintText: '例: カフェ / スイーツ / 本 など（入力後Enterで追加）',
                          filled: true,
                          fillColor: theme.brightness == Brightness.dark
                              ? Colors.white.withOpacity(0.04)
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
                          suffixIcon: IconButton(
                            icon: const Icon(Icons.add),
                            onPressed: () {
                              if (_tagInputController.text.trim().isNotEmpty) {
                                editProductController.addSubcategoryTag(_tagInputController.text.trim());
                                _tagInputController.clear();
                              }
                            },
                          ),
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 15,
                            vertical: 14,
                          ),
                        ),
                        onSubmitted: (value) {
                          if (value.trim().isNotEmpty) {
                            editProductController.addSubcategoryTag(value.trim());
                            _tagInputController.clear();
                          }
                        },
                      ),
                      if (editProductState.subcategoryTags.isNotEmpty) ...[
                        const SizedBox(height: 12),
                        Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: editProductState.subcategoryTags.map((tag) {
                            return Chip(
                              label: Text('#$tag'),
                              deleteIcon: const Icon(Icons.close, size: 16),
                              onDeleted: () => editProductController.removeSubcategoryTag(tag),
                              backgroundColor: const Color(0xFF22A06B).withOpacity(0.2),
                              labelStyle: const TextStyle(
                                color: Color(0xFF22A06B),
                                fontWeight: FontWeight.w500,
                              ),
                              deleteIconColor: const Color(0xFF22A06B),
                            );
                          }).toList(),
                        ),
                      ],
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