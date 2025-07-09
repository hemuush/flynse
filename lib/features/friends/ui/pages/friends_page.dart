import 'package:flutter/material.dart';
import 'package:flynse/core/providers/friend_provider.dart';
import 'package:flynse/features/debt/ui/widgets/debt_card.dart';
import 'package:flynse/features/debt/ui/widgets/total_debt_card.dart';
import 'package:provider/provider.dart';

class FriendsPage extends StatelessWidget {
  const FriendsPage({super.key});

  @override
  Widget build(BuildContext context) {
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
                    isUserDebtor: false,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: TotalDebtCard(
                    title: 'You Owe Friends',
                    total: provider.totalOwedByUser,
                    isUserDebtor: true,
                  ),
                ),
              ],
            ),
            
            // Friends Owe You Section
            if (hasOwedToUser) ...[
              _buildListHeader('Friends Owe You', Theme.of(context)),
              ...provider.loansToFriends.map((debt) => DebtCard(debt: debt)),
            ],

            // You Owe Friends Section
            if (hasOwedByUser) ...[
              _buildListHeader('You Owe Friends', Theme.of(context)),
              ...provider.debtsToFriends.map((debt) => DebtCard(debt: debt)),
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
