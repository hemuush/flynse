import 'package:flutter/material.dart';
import 'package:flynse/core/providers/app_provider.dart';
import 'package:flynse/core/providers/dashboard_provider.dart';
import 'package:flynse/core/providers/debt_provider.dart';
import 'package:flynse/core/providers/friend_provider.dart';
import 'package:flynse/core/providers/savings_provider.dart';
import 'package:flynse/features/dashboard/widgets/balance_card.dart';
import 'package:flynse/features/dashboard/widgets/comparison_card.dart';
import 'package:flynse/features/dashboard/widgets/monthly_highlights.dart';
import 'package:flynse/features/dashboard/widgets/period_selector.dart';
import 'package:flynse/features/dashboard/widgets/recent_transactions_list.dart';
import 'package:flynse/features/dashboard/widgets/summary_card.dart';
import 'package:flynse/features/savings/widgets/yearly_savings_sheet.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

/// A completely redesigned dashboard page for a modern and intuitive user experience.
///
/// This page serves as the central hub of the application, providing a quick
/// overview of the user's financial status for a selected period.
class DashboardPage extends StatefulWidget {
  const DashboardPage({super.key});

  @override
  State<DashboardPage> createState() => _DashboardPageState();
}

class _DashboardPageState extends State<DashboardPage>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );
    // Trigger the animation once the provider is done loading.
    final provider = context.read<DashboardProvider>();
    if (!provider.isLoading) {
      _animationController.forward();
    }
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<DashboardProvider>(
      builder: (context, provider, child) {
        // If the provider has finished loading, ensure the animation plays.
        if (!provider.isLoading && !_animationController.isCompleted) {
          _animationController.forward();
        }

        if (provider.isLoading && !_animationController.isAnimating) {
          return const Center(child: CircularProgressIndicator());
        }

        return RefreshIndicator(
          onRefresh: () => context.read<AppProvider>().refreshAllData(),
          child: ListView(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 120),
            children: [
              // --- Header for selecting the month and year ---
              const PeriodSelector(),
              const SizedBox(height: 16),

              // --- Main card with balance chart and summary ---
              _buildAnimatedItem(
                interval: const Interval(0.2, 0.8, curve: Curves.easeOutCubic),
                child: const BalanceCard(),
              ),
              const SizedBox(height: 24),

              // --- NEW: Comparison Card ---
              _buildAnimatedItem(
                interval: const Interval(0.3, 0.9, curve: Curves.easeOutCubic),
                child: const ComparisonCard(),
              ),
              const SizedBox(height: 24),

              // --- Summary cards for Savings and Debts ---
              _buildAnimatedItem(
                interval: const Interval(0.4, 0.9, curve: Curves.easeOutCubic),
                child: _buildSummaryCards(),
              ),
              const SizedBox(height: 24),
              
              // --- Monthly Highlights Section ---
              _buildAnimatedItem(
                interval: const Interval(0.5, 1.0, curve: Curves.easeOutCubic),
                child: const MonthlyHighlights(),
              ),
              const SizedBox(height: 24),

              // --- List of recent transactions ---
              _buildAnimatedItem(
                interval: const Interval(0.6, 1.0, curve: Curves.easeOutCubic),
                child: const RecentTransactionsList(),
              ),
            ],
          ),
        );
      },
    );
  }

  /// A helper method to wrap widgets with a fade and slide animation.
  Widget _buildAnimatedItem(
      {required Widget child, required Interval interval}) {
    return FadeTransition(
      opacity: _animationController.drive(CurveTween(curve: interval)),
      child: SlideTransition(
        position: Tween<Offset>(
          begin: const Offset(0, 0.3),
          end: Offset.zero,
        ).animate(_animationController.drive(CurveTween(curve: interval))),
        child: child,
      ),
    );
  }

  /// Builds the layout for the Savings and Debt summary cards.
  /// This logic now robustly handles all cases to prevent layout errors.
  Widget _buildSummaryCards() {
    final theme = Theme.of(context);
    final savingsProvider = context.watch<SavingsProvider>();
    final debtProvider = context.watch<DebtProvider>();
    final friendProvider = context.watch<FriendProvider>();
    
    final savingsAmount = NumberFormat.currency(
      locale: 'en_IN',
      symbol: '₹',
      decimalDigits: 0,
    ).format(savingsProvider.totalSavings);
    
    // MODIFIED: "You Owe" now combines personal debt and debt to friends.
    final totalOwed = debtProvider.totalPendingDebt + friendProvider.totalOwedByUser;
    final debtAmount = NumberFormat.currency(
      locale: 'en_IN',
      symbol: '₹',
      decimalDigits: 0,
    ).format(totalOwed);

    final owedToUserAmount = NumberFormat.currency(
      locale: 'en_IN',
      symbol: '₹',
      decimalDigits: 0,
    ).format(friendProvider.totalOwedToUser);
    
    final hasDebt = totalOwed > 0;
    final hasOwedToUser = friendProvider.totalOwedToUser > 0;
    final hasSavings = savingsProvider.totalSavings > 0;

    if (!hasDebt && !hasSavings && !hasOwedToUser) {
      return const SizedBox.shrink();
    }

    // Build a list of card widgets to display.
    final List<Widget> summaryWidgets = [];

    if (hasSavings) {
      summaryWidgets.add(
        Expanded(
          child: SummaryCard(
            title: "Total Savings",
            amount: savingsAmount,
            icon: Icons.savings_rounded,
            color: Colors.green.shade400,
            onTap: () {
              showModalBottomSheet(
                context: context,
                isScrollControlled: true,
                backgroundColor: Colors.transparent,
                builder: (_) => const YearlySavingsSheet(),
              );
            },
          ),
        ),
      );
    }

    if (hasDebt) {
      if (summaryWidgets.isNotEmpty) {
        summaryWidgets.add(const SizedBox(width: 16));
      }
      summaryWidgets.add(
        Expanded(
          child: SummaryCard(
            title: "You Owe",
            amount: debtAmount,
            icon: Icons.arrow_circle_up_rounded,
            color: theme.colorScheme.secondary,
            onTap: () => context.read<AppProvider>().navigateToTab(2),
          ),
        ),
      );
    }

    if (hasOwedToUser) {
      if (summaryWidgets.isNotEmpty) {
        summaryWidgets.add(const SizedBox(width: 16));
      }
      summaryWidgets.add(
        Expanded(
          child: SummaryCard(
            title: "Owed to You",
            amount: owedToUserAmount,
            icon: Icons.arrow_circle_down_rounded,
            color: theme.colorScheme.tertiary,
            onTap: () => context.read<AppProvider>().navigateToTab(3),
          ),
        ),
      );
    }

    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: summaryWidgets,
      ),
    );
  }
}
