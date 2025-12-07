import 'package:flutter/material.dart';
import '../../providers/edit_product_controller.dart';

class EditProductTagsInput extends StatelessWidget {
  final EditProductState state;
  final EditProductController controller;
  final TextEditingController tagInputController;

  const EditProductTagsInput({
    super.key,
    required this.state,
    required this.controller,
    required this.tagInputController,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
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
          controller: tagInputController,
          style: TextStyle(color: theme.textTheme.bodyMedium?.color),
          decoration: InputDecoration(
            hintText: '例: カフェ / スイーツ / 本 など（入力後Enterで追加）',
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
            suffixIcon: IconButton(
              icon: const Icon(Icons.add),
              onPressed: () {
                if (tagInputController.text.trim().isNotEmpty) {
                  controller.addSubcategoryTag(tagInputController.text.trim());
                  tagInputController.clear();
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
              controller.addSubcategoryTag(value.trim());
              tagInputController.clear();
            }
          },
        ),
        if (state.subcategoryTags.isNotEmpty) ...[
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: state.subcategoryTags.map((tag) {
              return Chip(
                label: Text('#$tag'),
                deleteIcon: const Icon(Icons.close, size: 16),
                onDeleted: () => controller.removeSubcategoryTag(tag),
                backgroundColor: const Color(0xFF22A06B).withValues(alpha: 0.2),
                labelStyle: const TextStyle(
                  color: Color(0xFF22A06B),
                  fontWeight: FontWeight.w500,
                ),
                deleteIconColor: const Color(0xFF22A06B),
              );
            }).toList(),
          ),
        ],
      ],
    );
  }
}
