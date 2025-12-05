import 'package:flutter/material.dart';
import '../../core/ui_constants.dart'; // SESUAIKAN path kalau beda

class Categories extends StatelessWidget {
  const Categories({
    super.key,
    required this.categories,
    required this.selectedLabel,
    required this.onSelected,
  });

  /// Wajib diisi, tidak boleh null
  final List<String> categories;
  final String? selectedLabel;
  final ValueChanged<String> onSelected;

  @override
  Widget build(BuildContext context) {
    // Safety: kalau list kosong, tidak usah gambar apa-apa
    if (categories.isEmpty) return const SizedBox.shrink();

    return SizedBox(
      height: 34,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: categories.length,
        separatorBuilder: (_, __) => const SizedBox(width: 12),
        itemBuilder: (context, index) {
          final label = categories[index];
          final isSelected = label == (selectedLabel ?? 'All');

          return GestureDetector(
            onTap: () => onSelected(label),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                    color: isSelected ? kTextColor : kTextLightColor,
                  ),
                ),
                const SizedBox(height: 4),
                Container(
                  height: 2,
                  width: 22,
                  decoration: BoxDecoration(
                    color: isSelected ? kTextColor : Colors.transparent,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
