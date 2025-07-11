import 'package:flutter/material.dart';
import 'package:flynse/core/providers/debt_provider.dart';
import 'package:flynse/features/debt/ui/pages/closed_debts_page.dart';
import 'package:flynse/features/debt/ui/widgets/debt_card.dart';
import 'package:flynse/features/debt/ui/widgets/total_debt_card.dart';
import 'package:provider/provider.dart';

/// A widget that displays a list of the user's personal debts.
/// It no longer handles friend-related loans.
class DebtListView extends StatelessWidget {
  const DebtListView({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<DebtProvider>(
      builder: (context, provider, child) {
        if (provider.isLoading) {
          return const Center(child: CircularProgressIndicator());
        }
        return _buildContent(
          context,
          provider.userDebts,
          provider.totalPendingDebt,
        );
      },
    );
  }

  Widget _buildContent(
      BuildContext context, List<Map<String, dynamic>> activeDebts, double totalValue) {
    final theme = Theme.of(context);
    final isDarkMode = theme.brightness == Brightness.dark;

    return ListView(
      padding: const EdgeInsets.fromLTRB(16.0, 16.0, 16.0, 100.0),
      children: [
        TotalDebtCard(
          title: 'Total You Owe',
          total: totalValue,
          isUserDebtor: true, // This card is always for user debts now
        ),
        const SizedBox(height: 16),
        Card(
          elevation: 0,
          color: theme.colorScheme.surfaceContainer,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16.0),
            side: BorderSide(
              color: isDarkMode ? Colors.grey.shade800 : Colors.grey.shade200,
              width: 1,
            ),
          ),
          child: InkWell(
            onTap: () {
              Navigator.of(context).push(MaterialPageRoute(
                // Navigate to the page showing only closed personal debts.
                builder: (context) =>
                    const ClosedDebtsPage(),
              ));
            },
            borderRadius: BorderRadius.circular(16),
            child: const Padding(
              padding:
                  EdgeInsets.symmetric(horizontal: 16.0, vertical: 20.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('View Closed',
                      style: TextStyle(fontWeight: FontWeight.bold)),
                  Icon(Icons.history_rounded),
                ],
              ),
            ),
          ),
        ),
        if (activeDebts.isEmpty)
          const Padding(
            padding: EdgeInsets.only(top: 48.0),
            child: Center(
              child: Text(
                'You have no active debts. Tap + to add one.',
                textAlign: TextAlign.center,
              ),
            ),
          )
        else ...[
          _buildListHeader('Active Debts', theme),
          ...activeDebts.map((debt) => DebtCard(key: ValueKey(debt['id']), debt: debt)),
        ],
      ],
    );
  }

  Widget _buildListHeader(String title, ThemeData theme) {
    return Padding(
      padding: const EdgeInsets.only(top: 24.0, bottom: 8.0, left: 8.0),
      child: Text(
        title,
        style: theme.textTheme.titleSmall?.copyWith(
          fontWeight: FontWeight.bold,
          color: theme.textTheme.bodySmall?.color?.withAlpha(179),
        ),
      ),
    );
  }
}
