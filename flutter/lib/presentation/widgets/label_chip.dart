import 'package:flutter/material.dart';

class LabelChip extends StatelessWidget {
  final String label;
  final String color;
  final VoidCallback? onDelete;
  final bool isSelected;
  final VoidCallback? onTap;

  const LabelChip({
    super.key,
    required this.label,
    this.color = '#4285F4',
    this.onDelete,
    this.isSelected = false,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final labelColor = _hexToColor(color);
    
    return GestureDetector(
      onTap: onTap,
      child: Chip(
        label: Text(
          label,
          style: TextStyle(
            color: isSelected ? Colors.white : labelColor,
            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
          ),
        ),
        backgroundColor: isSelected ? labelColor : labelColor.withOpacity(0.15),
        deleteIcon: onDelete != null
            ? const Icon(Icons.close, size: 18)
            : null,
        onDeleted: onDelete,
        side: isSelected
            ? BorderSide(color: labelColor, width: 2)
            : null,
      ),
    );
  }

  Color _hexToColor(String hex) {
    try {
      if (hex.isEmpty || !hex.startsWith('#') || hex.length != 7) {
        return const Color(0xFF4285F4);
      }
      return Color(int.parse(hex.substring(1), radix: 16) + 0xFF000000);
    } catch (e) {
      return const Color(0xFF4285F4);
    }
  }
}
