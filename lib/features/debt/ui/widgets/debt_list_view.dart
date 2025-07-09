import 'package:flutter/material.dart';
import 'package:flynse/core/providers/debt_provider.dart';
import 'package:flynse/core/providers/friend_provider.dart';
import 'package:flynse/features/debt/ui/pages/closed_loans_page.dart';
import 'package:flynse/features/debt/ui/widgets/debt_card.dart';
import 'package:flynse/features/debt/ui/widgets/total_debt_card.dart';
import 'package:provider/provider.dart';

class DebtListView extends StatelessWidget {
  final bool isUserDebtor;

  const DebtListView({super.key, required this.isUserDebtor});

  @override
  Widget build(BuildContext context) {
    // This widget now conditionally builds its UI based on the context
    // by consuming from either the DebtProvider or the new FriendProvider.
    if (isUserDebtor) {
      return _buildUserDebtView(context);
    } else {
      return _buildFriendLoanView(context);
    }
  }

  Widget _buildUserDebtView(BuildContext context) {
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

  Widget _buildFriendLoanView(BuildContext context) {
    return Consumer<FriendProvider>(
      builder: (context, provider, child) {
        if (provider.isLoading) {
          return const Center(child: CircularProgressIndicator());
        }
        // FIX: Changed friendLoans to loansToFriends to match the provider.
        return _buildContent(
          context,
          provider.loansToFriends,
          provider.totalOwedToUser,
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
          title: isUserDebtor ? 'Total You Owe' : 'Total Owed to You',
          total: totalValue,
          isUserDebtor: isUserDebtor,
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
                builder: (context) =>
                    ClosedLoansPage(isUserDebtorFilter: isUserDebtor),
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
          Padding(
            padding: const EdgeInsets.only(top: 48.0),
            child: Center(
              child: Text(
                isUserDebtor
                    ? 'You have no active debts. Tap + to add one.'
                    : 'No one owes you money right now.',
                textAlign: TextAlign.center,
              ),
            ),
          )
        else ...[
          _buildListHeader('Active', theme),
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
