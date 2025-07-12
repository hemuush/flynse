import 'package:flutter/material.dart';

/// Provides a consistent color for a given category name.
Color getColorForCategory(BuildContext context, String category, int index) {
  final colors = [
    Colors.blue.shade400,
    Colors.green.shade400,
    Colors.orange.shade400,
    Colors.purple.shade400,
    Colors.red.shade400,
    Colors.teal.shade400,
    Colors.pink.shade400,
    Colors.amber.shade400,
    Colors.indigo.shade400,
    Colors.cyan.shade400,
    Colors.lime.shade400,
    Colors.brown.shade400,
  ];
  // Use a combination of hashcode and index to get more varied colors
  final colorIndex = (category.hashCode + index) % colors.length;
  return colors[colorIndex];
}