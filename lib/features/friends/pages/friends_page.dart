import 'package:flutter/material.dart';
import 'package:flynse/core/providers/friend_provider.dart';
import 'package:flynse/features/friends/pages/closed_friend_loans_page.dart';
import 'package:flynse/features/friends/widgets/friend_debt_card.dart';
import 'package:flynse/features/debt/ui/widgets/total_debt_card.dart';
import 'package:provider/provider.dart';

class FriendsPage extends StatelessWidget {
  const FriendsPage({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDarkMode = theme.brightness == Brightness.dark;

    return Consumer<FriendProvider>(
      builder: (context, provider, child) {
        if (provider.isLoading) {
          return const Center(child: CircularProgressIndicator());
        }

        final hasOwedToUser = provider.loansToFriends.isNotEmpty;
        final hasOwedByUser = provider.debtsToFriends.isNotEmpty;

        return ListView(
          padding: const EdgeInsets.fromLTRB(16.0, 16.0, 16.0, 100.0),
          children: [
            // Summary Cards
            Row(
              children: [
                Expanded(
                  child: TotalDebtCard(
                    title: 'Friends Owe You',
                    total: provider.totalOwedToUser,
                    isUserDebtor: false, // Owed to you
                    debtCount: provider.loansToFriends.length,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: TotalDebtCard(
                    title: 'You Owe Friends',
                    total: provider.totalOwedByUser,
                    isUserDebtor: true, // You are the debtor
                    debtCount: provider.debtsToFriends.length,
                  ),
                ),
              ],
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
                    builder: (context) => const ClosedFriendLoansPage(),
                  ));
                },
                borderRadius: BorderRadius.circular(16),
                child: const Padding(
                  padding:
                      EdgeInsets.symmetric(horizontal: 16.0, vertical: 20.0),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('View Closed History',
                          style: TextStyle(fontWeight: FontWeight.bold)),
                      Icon(Icons.history_rounded),
                    ],
                  ),
                ),
              ),
            ),
            
            // Friends Owe You Section
            if (hasOwedToUser) ...[
              _buildListHeader('Friends Owe You', Theme.of(context)),
              ...provider.loansToFriends.map((debt) => FriendDebtCard(key: ValueKey("loan-${debt['id']}"), debt: debt)),
            ],

            // You Owe Friends Section
            if (hasOwedByUser) ...[
              _buildListHeader('You Owe Friends', Theme.of(context)),
              ...provider.debtsToFriends.map((debt) => FriendDebtCard(key: ValueKey("debt-${debt['id']}"), debt: debt)),
            ],

            // Empty State
            if (!hasOwedToUser && !hasOwedByUser)
              Padding(
                padding: const EdgeInsets.only(top: 48.0),
                child: Center(
                  child: Text(
                    'No active debts with friends.\nTap + on the Friends tab to add one.',
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.bodyLarge,
                  ),
                ),
              ),
          ],
        );
      },
    );
  }

  Widget _buildListHeader(String title, ThemeData theme) {
    return Padding(
      padding: const EdgeInsets.only(top: 24.0, bottom: 8.0, left: 8.0),
      child: Text(
        title,
        style: theme.textTheme.titleLarge?.copyWith(
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }
}
