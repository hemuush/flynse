import 'package:flutter/material.dart';
import 'package:flynse/core/providers/savings_provider.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

class SavingsByCategoryCard extends StatelessWidget {
  const SavingsByCategoryCard({super.key});

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<SavingsProvider>();
    final savingsByCategory = provider.savingsByCategory;
    final theme = Theme.of(context);
    final isDarkMode = theme.brightness == Brightness.dark;

    if (savingsByCategory.isEmpty) {
      return const SizedBox.shrink();
    }

    return Card(
      elevation: 0,
      color: theme.colorScheme.surfaceContainer,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16.0),
        side: BorderSide(
          color: isDarkMode ? Colors.grey.shade800 : Colors.grey.shade200,
          width: 1,
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Savings by Category',
              style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            ...savingsByCategory.map((item) {
              return Padding(
                padding: const EdgeInsets.symmetric(vertical: 8.0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(item['category'], style: theme.textTheme.bodyLarge),
                    Text(
                      '₹${NumberFormat.decimalPattern().format(item['total'])}',
                      style: theme.textTheme.bodyLarge?.copyWith(fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
              );
            }),
          ],
        ),
      ),
    );
  }
}