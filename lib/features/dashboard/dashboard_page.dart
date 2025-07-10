import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flynse/core/providers/analytics_provider.dart';
import 'package:flynse/core/providers/app_provider.dart';
import 'package:flynse/core/providers/dashboard_provider.dart';
import 'package:flynse/core/providers/debt_provider.dart';
import 'package:flynse/core/providers/friend_provider.dart';
import 'package:flynse/core/providers/savings_provider.dart';
import 'package:flynse/core/providers/settings_provider.dart';
import 'package:flynse/core/routing/app_router.dart';
import 'package:flynse/features/dashboard/widgets/balance_card.dart';
import 'package:flynse/features/dashboard/widgets/comparison_card.dart';
import 'package:flynse/features/dashboard/widgets/financial_details_sheet.dart';
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
/// overview of the user's financial status with a stable header.
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
    final theme = Theme.of(context);
    final settingsProvider = context.watch<SettingsProvider>();
    final userName =
        settingsProvider.userName.isNotEmpty ? settingsProvider.userName : 'User';

    return Consumer<DashboardProvider>(
      builder: (context, provider, child) {
        // If the provider has finished loading, ensure the animation plays.
        if (!provider.isLoading && !_animationController.isCompleted) {
          _animationController.forward();
        }

        if (provider.isLoading && !_animationController.isAnimating) {
          return const Center(child: CircularProgressIndicator());
        }

        return Scaffold(
          backgroundColor: Colors.transparent,
          // --- FIX: A stable AppBar that contains all header controls ---
          appBar: AppBar(
            backgroundColor: Colors.transparent,
            elevation: 0,
            titleSpacing: 16,
            title: Text(
              'Hi, ${userName.split(' ').first}',
              style: theme.textTheme.headlineSmall
                  ?.copyWith(fontWeight: FontWeight.bold),
            ),
            actions: [
              // --- FIX: Restored the Yearly Summary Button ---
              IconButton(
                icon: const Icon(Icons.assessment_outlined),
                onPressed: () async {
                  HapticFeedback.lightImpact();
                  final appProvider = context.read<AppProvider>();
                  await context
                      .read<AnalyticsProvider>()
                      .fetchAnalyticsData(appProvider.selectedYear);
                  if (context.mounted) {
                    showModalBottomSheet(
                      context: context,
                      isScrollControlled: true,
                      backgroundColor: Colors.transparent,
                      builder: (_) => const FinancialDetailsSheet(sheetType: SheetType.yearly),
                    );
                  }
                },
                tooltip: 'Yearly Details',
              ),
              // Settings Button
              Padding(
                padding: const EdgeInsets.only(right: 16.0, left: 8.0),
                child: GestureDetector(
                  onTap: () {
                    HapticFeedback.lightImpact();
                    Navigator.of(context).pushNamed(AppRouter.settingsPage);
                  },
                  child: CircleAvatar(
                    radius: 20,
                    backgroundColor: theme.colorScheme.surfaceContainerHighest,
                    backgroundImage:
                        settingsProvider.profileImageBase64 != null &&
                                settingsProvider.profileImageBase64!.isNotEmpty
                            ? MemoryImage(
                                base64Decode(
                                    settingsProvider.profileImageBase64!))
                            : null,
                    child: (settingsProvider.profileImageBase64 == null ||
                            settingsProvider.profileImageBase64!.isEmpty)
                        ? (settingsProvider.userName.isNotEmpty
                            ? Text(
                                settingsProvider.userName[0].toUpperCase(),
                                style: theme.textTheme.titleMedium?.copyWith(
                                    color: theme.colorScheme.primary,
                                    fontWeight: FontWeight.bold),
                              )
                            : Icon(Icons.person_outline_rounded,
                                size: 24, color: theme.colorScheme.primary))
                        : null,
                  ),
                ),
              ),
            ],
          ),
          body: RefreshIndicator(
            onRefresh: () => context.read<AppProvider>().refreshAllData(),
            child: ListView(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 100),
              children: [
                const Center(child: PeriodSelector()),
                const SizedBox(height: 24),
                _buildAnimatedItem(
                  interval:
                      const Interval(0.2, 0.8, curve: Curves.easeOutCubic),
                  child: const BalanceCard(),
                ),
                const SizedBox(height: 24),
                _buildAnimatedItem(
                  interval:
                      const Interval(0.3, 0.9, curve: Curves.easeOutCubic),
                  child: const ComparisonCard(),
                ),
                const SizedBox(height: 24),
                _buildAnimatedItem(
                  interval:
                      const Interval(0.4, 0.9, curve: Curves.easeOutCubic),
                  child: _buildSummaryCards(theme),
                ),
                const SizedBox(height: 24),
                _buildAnimatedItem(
                  interval:
                      const Interval(0.5, 1.0, curve: Curves.easeOutCubic),
                  child: const MonthlyHighlights(),
                ),
                const SizedBox(height: 24),
                _buildAnimatedItem(
                  interval:
                      const Interval(0.6, 1.0, curve: Curves.easeOutCubic),
                  child: const RecentTransactionsList(),
                ),
              ],
            ),
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
  Widget _buildSummaryCards(ThemeData theme) {
    final savingsProvider = context.watch<SavingsProvider>();
    final debtProvider = context.watch<DebtProvider>();
    final friendProvider = context.watch<FriendProvider>();

    final nf = NumberFormat.currency(
      locale: 'en_IN',
      symbol: '₹',
      decimalDigits: 0,
    );

    final List<Widget> cards = [];

    // Card 1: Total Savings
    if (savingsProvider.totalSavings > 0) {
      cards.add(
        SummaryCard(
          title: "Total Savings",
          amount: nf.format(savingsProvider.totalSavings),
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
      );
    }

    // Card 2: You Owe
    final totalOwed =
        debtProvider.totalPendingDebt + friendProvider.totalOwedByUser;
    if (totalOwed > 0) {
      cards.add(
        SummaryCard(
          title: "You Owe",
          amount: nf.format(totalOwed),
          icon: Icons.arrow_circle_up_rounded,
          color: theme.colorScheme.secondary,
          onTap: () => context.read<AppProvider>().navigateToTab(2),
        ),
      );
    }

    // Card 3: Owed to You
    if (friendProvider.totalOwedToUser > 0) {
      cards.add(
        SummaryCard(
          title: "Owed to You",
          amount: nf.format(friendProvider.totalOwedToUser),
          icon: Icons.arrow_circle_down_rounded,
          color: theme.colorScheme.tertiary,
          onTap: () => context.read<AppProvider>().navigateToTab(3),
        ),
      );
    }

    if (cards.isEmpty) {
      return const SizedBox.shrink();
    }

    // Dynamic Layout Logic
    if (cards.length == 3) {
      return SizedBox(
        height: 180,
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Expanded(flex: 5, child: cards[0]),
            const SizedBox(width: 12),
            Expanded(
              flex: 4,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Expanded(child: cards[1]),
                  const SizedBox(height: 12),
                  Expanded(child: cards[2]),
                ],
              ),
            ),
          ],
        ),
      );
    } else {
      return SizedBox(
        height: 150,
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            for (int i = 0; i < cards.length; i++) ...[
              Expanded(child: cards[i]),
              if (i < cards.length - 1) const SizedBox(width: 16),
            ]
          ],
        ),
      );
    }
  }
}