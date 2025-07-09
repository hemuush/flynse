import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

/// A reusable widget to display a single transaction item in a list.
///
/// This widget is used across the app (e.g., on the dashboard and the
/// full transaction history page) to ensure a consistent appearance.
class TransactionListItem extends StatelessWidget {
  final Map<String, dynamic> transaction;
  final bool isLocked;
  final VoidCallback onTap;

  const TransactionListItem({
    super.key,
    required this.transaction,
    required this.isLocked,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final type = transaction['type'] as String? ?? '';
    final color = _getColorForType(context, type);
    final iconData = _getIconForType(type);

    String title = transaction['description'];
    String subtitle = transaction['category'] as String? ?? '';
    if (transaction['sub_category'] != null &&
        transaction['sub_category'].isNotEmpty) {
      subtitle = '$subtitle (${transaction['sub_category']})';
    }
    
    return Card(
      elevation: 0,
      color: theme.colorScheme.surfaceContainer,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16.0)),
      margin: const EdgeInsets.symmetric(vertical: 6),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16.0),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: color.withAlpha(25),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(iconData, color: color, size: 24),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 2),
                    Text(
                      subtitle,
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant.withAlpha(178),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    '₹${NumberFormat.decimalPattern('en_IN').format(transaction['amount'])}',
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: color,
                    ),
                  ),
                  if (isLocked) ...[
                    const SizedBox(height: 4),
                    Icon(Icons.lock, size: 14, color: theme.colorScheme.onSurfaceVariant.withAlpha(128)),
                  ]
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  IconData _getIconForType(String type) {
    return switch (type) {
      'Income' => Icons.arrow_downward_rounded,
      'Saving' => Icons.savings_rounded,
      'Expense' => Icons.arrow_upward_rounded,
      _ => Icons.circle_outlined,
    };
  }

  Color _getColorForType(BuildContext context, String type) {
    final theme = Theme.of(context);
    return switch (type) {
      'Income' => theme.colorScheme.tertiary,
      'Saving' => Colors.lightGreen.shade500,
      'Expense' => theme.colorScheme.secondary,
      _ => theme.colorScheme.onSurface,
    };
  }
}
