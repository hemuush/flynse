import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class TotalDebtCard extends StatelessWidget {
  final String title;
  final double total;
  final bool isUserDebtor;
  final int? debtCount;

  const TotalDebtCard({
    super.key,
    required this.title,
    required this.total,
    required this.isUserDebtor,
    this.debtCount,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final Color color =
        isUserDebtor ? theme.colorScheme.secondary : theme.colorScheme.tertiary;
    final IconData icon = isUserDebtor
        ? Icons.arrow_circle_up_rounded
        : Icons.arrow_circle_down_rounded;

    final formattedTotal = NumberFormat.currency(
      locale: 'en_IN',
      symbol: '₹',
      decimalDigits: 0,
    ).format(total);

    return Card(
      elevation: 0,
      color: theme.colorScheme.surfaceContainer,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20.0),
        side: BorderSide(
          color: theme.colorScheme.outline,
          width: 1,
        ),
      ),
      clipBehavior: Clip.antiAlias,
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: color.withOpacity(0.15),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(icon, color: color, size: 24),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: theme.textTheme.titleMedium?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      if (debtCount != null && debtCount! > 0) ...[
                        const SizedBox(height: 2),
                        Text(
                          '$debtCount Active',
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: theme.colorScheme.onSurfaceVariant
                                .withOpacity(0.7),
                          ),
                        )
                      ]
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            FittedBox(
              fit: BoxFit.scaleDown,
              alignment: Alignment.centerLeft,
              child: Text(
                formattedTotal,
                style: theme.textTheme.displaySmall
                    ?.copyWith(fontWeight: FontWeight.bold, color: color),
                maxLines: 1,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
