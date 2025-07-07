import 'package:flutter/material.dart';
import 'package:flynse/core/providers/savings_provider.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

class GoalProgressCard extends StatelessWidget {
  const GoalProgressCard({super.key});

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<SavingsProvider>();
    final goal = provider.activeSavingsGoal!;
    final allTimeTotalSavings = provider.allTimeTotalSavings;
    final theme = Theme.of(context);
    final isDarkMode = theme.brightness == Brightness.dark;

    final targetAmount = goal['target_amount'] as double;
    final progress =
        targetAmount > 0 ? (allTimeTotalSavings / targetAmount).clamp(0.0, 1.0) : 0.0;

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
        child: Row(
          children: [
            // --- UI ENHANCEMENT: Circular Progress Indicator ---
            SizedBox(
              width: 60,
              height: 60,
              child: Stack(
                fit: StackFit.expand,
                children: [
                  CircularProgressIndicator(
                    value: progress,
                    strokeWidth: 6,
                    backgroundColor: theme.colorScheme.surface,
                    valueColor: AlwaysStoppedAnimation<Color>(Colors.lightGreen.shade400),
                  ),
                  Center(
                    child: Text(
                      '${(progress * 100).toStringAsFixed(0)}%',
                      style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold),
                    ),
                  )
                ],
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    goal['name'],
                    style: theme.textTheme.titleMedium
                        ?.copyWith(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  Text(
                      'Saved: ₹${NumberFormat.decimalPattern().format(allTimeTotalSavings)}',
                      style: theme.textTheme.bodyMedium
                          ?.copyWith(color: theme.colorScheme.onSurfaceVariant)),
                  const SizedBox(height: 4),
                   Text(
                      'Target: ₹${NumberFormat.decimalPattern().format(targetAmount)}',
                      style: theme.textTheme.bodyMedium
                          ?.copyWith(fontWeight: FontWeight.bold)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
