import 'package:flutter/material.dart';
import 'package:flynse/features/analytics/widgets/expense_analytics_view.dart';
import 'package:flynse/features/analytics/widgets/monthly_analytics_view.dart';
import 'package:flynse/features/analytics/widgets/yearly_analytics_view.dart';

/// Helper class for passing arguments to this page.
class AnalyticsPageArgs {
  final int selectedYear;
  final int selectedMonth;

  AnalyticsPageArgs({required this.selectedYear, required this.selectedMonth});
}

/// A top-level page that displays financial analytics using a TabBar interface.
///
/// This widget has been refactored to act as a container for the different
/// analytics views, improving code organization and readability.
class AnalyticsPage extends StatefulWidget {
  final int selectedYear;
  final int selectedMonth;

  const AnalyticsPage({
    super.key,
    required this.selectedYear,
    required this.selectedMonth,
  });

  @override
  State<AnalyticsPage> createState() => _AnalyticsPageState();
}

class _AnalyticsPageState extends State<AnalyticsPage>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Financial Analytics'),
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: 'Monthly'),
            Tab(text: 'Yearly'),
            Tab(text: 'Expenses'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          MonthlyAnalyticsView(
            selectedYear: widget.selectedYear,
            selectedMonth: widget.selectedMonth,
          ),
          YearlyAnalyticsView(selectedYear: widget.selectedYear),
          ExpenseAnalyticsView(initialSelectedYear: widget.selectedYear),
        ],
      ),
    );
  }
}
