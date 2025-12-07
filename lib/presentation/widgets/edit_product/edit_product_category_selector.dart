import 'package:flutter/material.dart';
import '../../providers/edit_product_controller.dart';

class EditProductCategorySelector extends StatelessWidget {
  final EditProductState state;
  final EditProductController controller;

  const EditProductCategorySelector({
    super.key,
    required this.state,
    required this.controller,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
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
          initialValue: state.selectedCategory,
          validator: (value) {
            if (state.selectedCategory.isEmpty) {
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
                  children: state.categories.map<Widget>((category) {
                    final selected = state.selectedCategory == category;
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
                      onSelected: state.isLoading
                          ? null
                          : (_) {
                              controller.updateSelectedCategory(category);
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
      ],
    );
  }
}
