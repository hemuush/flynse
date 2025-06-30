import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flynse/core/providers/savings_provider.dart';
import 'package:flynse/features/savings/widgets/goal_celebration_widget.dart';
import 'package:flynse/features/savings/widgets/savings_by_category_card.dart';
import 'package:flynse/features/savings/widgets/total_savings_card.dart';
import 'package:flynse/features/savings/widgets/savings_actions.dart';
import 'package:flynse/features/savings/widgets/goal_progress_card.dart';
import 'package:flynse/features/savings/widgets/savings_list.dart';

class SavingsPage extends StatefulWidget {
  const SavingsPage({super.key});

  @override
  State<SavingsPage> createState() => _SavingsPageState();
}

class _SavingsPageState extends State<SavingsPage> {
  bool _isCelebrating = false;

  void _celebrateGoalCompletion(String goalName) {
    setState(() {
      _isCelebrating = true;
    });

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const SizedBox(height: 20),
              Icon(Icons.emoji_events_rounded,
                  color: Theme.of(context).colorScheme.tertiary, size: 60),
              const SizedBox(height: 16),
              Text(
                'Goal Achieved!',
                style: Theme.of(context)
                    .textTheme
                    .headlineSmall
                    ?.copyWith(fontWeight: FontWeight.bold),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              Text(
                'Congratulations! You\'ve successfully reached your savings goal: "$goalName".',
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.bodyLarge,
              ),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: () => Navigator.of(context).pop(),
                style: ElevatedButton.styleFrom(
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12)),
                  padding:
                      const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                ),
                child: const Text('Awesome!'),
              ),
              const SizedBox(height: 8),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<SavingsProvider>(
      builder: (context, provider, child) {
        if (provider.lastCompletedGoalName != null) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            _celebrateGoalCompletion(provider.lastCompletedGoalName!);
            provider.clearLastCompletedGoal();
          });
        }

        if (provider.isLoading) {
          return const Center(child: CircularProgressIndicator());
        }

        return Stack(
          alignment: Alignment.topCenter,
          children: [
            ListView(
              // MODIFICATION: Increased bottom padding to prevent overlap with the navigation bar.
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 140),
              children: [
                const TotalSavingsCard(),
                const SizedBox(height: 16),
                const SavingsActions(),
                if (provider.activeSavingsGoal != null) ...[
                  const SizedBox(height: 16),
                  const GoalProgressCard(),
                ],
                const SizedBox(height: 16),
                const SavingsByCategoryCard(), // NEW
                const SizedBox(height: 24),
                SavingsList(transactions: provider.savingsTransactions),
              ],
            ),
            if (_isCelebrating)
              GoalCelebrationWidget(
                onAnimationComplete: () {
                  if (mounted) {
                    setState(() {
                      _isCelebrating = false;
                    });
                  }
                },
              ),
          ],
        );
      },
    );
  }
}
