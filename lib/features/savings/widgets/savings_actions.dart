import 'package:flutter/material.dart';
import 'package:flynse/core/providers/savings_provider.dart';
import 'package:flynse/features/savings/widgets/savings_goal_dialog.dart';
import 'package:flynse/features/savings/widgets/use_savings_dialog.dart';
import 'package:provider/provider.dart';

class SavingsActions extends StatelessWidget {
  const SavingsActions({super.key});

  void _showGoalDialog(BuildContext context) {
    final provider = context.read<SavingsProvider>();
    showDialog(
      context: context,
      builder: (context) =>
          SavingsGoalDialog(currentGoal: provider.activeSavingsGoal),
    );
  }

  void _showUseSavingsDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => const UseSavingsDialog(),
    );
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<SavingsProvider>();
    // FIX: The button should only be enabled if there is a withdrawable balance in at least one category.
    final bool canUseSavings = provider.savingsByCategory.any((c) => (c['total'] as double? ?? 0.0) > 0);

    return Row(
      children: [
        Expanded(
          child: OutlinedButton.icon(
            onPressed: () => _showGoalDialog(context),
            icon: const Icon(Icons.flag_outlined),
            label: Text(
                provider.activeSavingsGoal != null ? 'Edit Goal' : 'Set Goal'),
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: OutlinedButton.icon(
            onPressed:
                canUseSavings ? () => _showUseSavingsDialog(context) : null,
            icon: const Icon(Icons.north_east),
            label: const Text('Use Savings'),
          ),
        ),
      ],
    );
  }
}
