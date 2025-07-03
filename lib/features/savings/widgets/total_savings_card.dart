import 'package:flutter/material.dart';
import 'package:flynse/core/providers/savings_provider.dart';
import 'package:flynse/features/savings/widgets/savings_growth_sheet.dart';
import 'package:flynse/shared/widgets/animated_count.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';

class TotalSavingsCard extends StatelessWidget {
  const TotalSavingsCard({super.key});

  void _showSavingsGrowthSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => const SavingsGrowthSheet(),
    );
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<SavingsProvider>();
    final totalSavings = provider.totalSavings;
    final theme = Theme.of(context);
    final savingsColor = theme.colorScheme.tertiary;

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
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: savingsColor.withOpacity(0.15),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(Icons.savings_outlined, color: savingsColor, size: 20),
                ),
                const SizedBox(width: 12),
                Text(
                  'Total Savings',
                  style: theme.textTheme.titleMedium?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const Spacer(),
                IconButton(
                  icon: const Icon(Icons.show_chart_rounded),
                  onPressed: () => _showSavingsGrowthSheet(context),
                  tooltip: 'Show Savings Growth',
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ],
            ),
            const SizedBox(height: 16),
            Center(
              child: AnimatedCount(
                begin: 0,
                end: totalSavings,
                style: GoogleFonts.outfit(
                  color: savingsColor,
                  fontSize: 48,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
