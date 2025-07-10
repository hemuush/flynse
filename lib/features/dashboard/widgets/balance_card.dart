import 'package:flutter/material.dart';
import 'package:flynse/core/providers/app_provider.dart';
import 'package:flynse/core/providers/dashboard_provider.dart';
import 'package:flynse/features/dashboard/widgets/financial_details_sheet.dart';
import 'package:flynse/shared/widgets/animated_count.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

/// A simplified, central card on the dashboard that visualizes
/// the monthly financial summary.
///
/// It includes:
/// - A prominent display of the cumulative balance.
/// - A tappable area to view more detailed monthly information.
class BalanceCard extends StatelessWidget {
  const BalanceCard({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final provider = context.watch<DashboardProvider>();
    final appProvider = context.watch<AppProvider>();

    final cumulativeIncome = provider.cumulativeTotals['Income'] ?? 0.0;
    final cumulativeExpense = provider.cumulativeTotals['Expense'] ?? 0.0;
    final cumulativeSaving = provider.cumulativeTotals['Saving'] ?? 0.0;
    final netBalance = cumulativeIncome - cumulativeExpense - cumulativeSaving;

    final monthName =
        DateFormat.MMMM().format(DateTime(0, appProvider.selectedMonth));

    return Card(
      elevation: 4,
      shadowColor: theme.colorScheme.primary.withAlpha(51),
      clipBehavior: Clip.antiAlias,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(24.0),
      ),
      child: InkWell(
        onTap: () {
          showModalBottomSheet(
            context: context,
            isScrollControlled: true,
            backgroundColor: Colors.transparent,
            builder: (_) => const FinancialDetailsSheet(sheetType: SheetType.monthly),
          );
        },
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 32.0),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                theme.colorScheme.primary.withAlpha(26),
                theme.colorScheme.surface,
              ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Balance till $monthName',
                style: theme.textTheme.titleMedium?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: 8),
              FittedBox(
                fit: BoxFit.scaleDown,
                child: AnimatedCount(
                  begin: 0,
                  end: netBalance,
                  style: theme.textTheme.displayMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: netBalance >= 0
                        ? theme.colorScheme.tertiary
                        : theme.colorScheme.error,
                  ),
                  decimalDigits: 2,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}