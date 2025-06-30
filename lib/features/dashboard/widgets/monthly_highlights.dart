import 'package:flutter/material.dart';
import 'package:flynse/core/providers/dashboard_provider.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

class MonthlyHighlights extends StatelessWidget {
  const MonthlyHighlights({super.key});

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<DashboardProvider>();
    final theme = Theme.of(context);

    final highlightCards = [
      _HighlightCard(
        title: 'Highest Expense',
        icon: Icons.trending_up_rounded,
        iconColor: theme.colorScheme.secondary,
        currentAmount: provider.highestExpense?['amount'] ?? 0.0,
        previousAmount: provider.lastMonthExpenseTotal,
        description: provider.highestExpense?['description'],
        isDecreaseGood: true, // A decrease in the highest expense is good
      ),
      const SizedBox(width: 16),
      _HighlightCard(
        title: 'Lowest Expense',
        icon: Icons.trending_down_rounded,
        iconColor: theme.colorScheme.primary, // Use a different color for distinction
        currentAmount: provider.lowestExpense?['amount'] ?? 0.0,
        previousAmount: provider.lastMonthLowestExpenseAmount,
        description: provider.lowestExpense?['description'],
        isDecreaseGood: true, // A decrease in the lowest expense is also good
      ),
    ];

    // Only show the highlights if there is data to display
    if ((provider.highestExpense == null ||
            provider.highestExpense!['amount'] == 0.0) &&
        (provider.lowestExpense == null ||
            provider.lowestExpense!['amount'] == 0.0)) {
      return const SizedBox.shrink();
    }

    return SizedBox(
      height: 150, // Set a fixed height for the horizontal list
      child: ListView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 4),
        children: highlightCards,
      ),
    );
  }
}

class _HighlightCard extends StatelessWidget {
  final String title;
  final IconData icon;
  final Color iconColor;
  final double currentAmount;
  final double previousAmount;
  final String? description;
  final bool isDecreaseGood;

  const _HighlightCard({
    required this.title,
    required this.icon,
    required this.iconColor,
    required this.currentAmount,
    required this.previousAmount,
    this.description,
    required this.isDecreaseGood,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final nf = NumberFormat.currency(locale: 'en_IN', symbol: '₹', decimalDigits: 2);

    double percentageChange = 0;
    if (previousAmount > 0) {
      percentageChange = ((currentAmount - previousAmount) / previousAmount) * 100;
    }

    final bool isPositiveChange = percentageChange > 0;
    final bool isGoodChange = isDecreaseGood ? !isPositiveChange : isPositiveChange;
    
    final changeColor = previousAmount > 0
        ? (isGoodChange ? Colors.green.shade400 : Colors.red.shade400)
        : theme.colorScheme.onSurfaceVariant;

    final changeIcon = previousAmount > 0
        ? (isPositiveChange ? Icons.arrow_upward_rounded : Icons.arrow_downward_rounded)
        : null;

    return SizedBox(
      width: MediaQuery.of(context).size.width * 0.75, // Card width
      child: Card(
        elevation: 0,
        color: theme.colorScheme.surfaceContainer,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20.0),
          side: BorderSide(color: theme.colorScheme.outline, width: 1),
        ),
        clipBehavior: Clip.antiAlias,
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Icon(icon, color: iconColor, size: 24),
                  const SizedBox(width: 8),
                  Text(title, style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
                  const Spacer(),
                ],
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    nf.format(currentAmount),
                    style: theme.textTheme.headlineMedium?.copyWith(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      if (previousAmount > 0 && changeIcon != null) ...[
                        Text(
                          '${percentageChange.abs().toStringAsFixed(1)}%',
                          style: theme.textTheme.bodyMedium?.copyWith(
                            color: changeColor,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Icon(
                          changeIcon,
                          size: 16,
                          color: changeColor,
                        ),
                        const SizedBox(width: 8),
                      ],
                      if (description != null)
                        Expanded(
                          child: Text(
                            description!,
                            style: theme.textTheme.bodyMedium?.copyWith(color: theme.colorScheme.onSurfaceVariant),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                    ],
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}