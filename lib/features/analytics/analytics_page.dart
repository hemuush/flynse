import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flynse/core/providers/analytics_provider.dart';
import 'package:flynse/core/providers/app_provider.dart';
import 'package:flynse/core/providers/dashboard_provider.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

// Helper class for passing arguments to this page.
class AnalyticsPageArgs {
  final int selectedYear;
  final int selectedMonth;

  AnalyticsPageArgs({required this.selectedYear, required this.selectedMonth});
}

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
  late int _selectedAnalyticsYear;

  final List<String> _monthNames = [
    'January', 'February', 'March', 'April', 'May', 'June', 'July',
    'August', 'September', 'October', 'November', 'December'
  ];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _selectedAnalyticsYear = widget.selectedYear;
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
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
          _buildMonthlyView(context, theme),
          _buildYearlyView(context, theme),
          _buildExpenseView(context, theme),
        ],
      ),
    );
  }

  // --- BUILDER FOR THE EXPENSE VIEW (REFACTORED) ---
  Widget _buildExpenseView(BuildContext context, ThemeData theme) {
    final appProvider = context.read<AppProvider>();
    return Consumer<AnalyticsProvider>(
      builder: (context, provider, child) {
        if (provider.isAnalyticsLoading) {
          return const Center(child: CircularProgressIndicator());
        }
        
        final monthlyTotals = provider.monthlyExpenseTotals;

        return Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: DropdownButtonFormField<int>(
                value: _selectedAnalyticsYear,
                items: appProvider.availableYears
                    .map((year) =>
                        DropdownMenuItem(value: year, child: Text("Year $year")))
                    .toList(),
                onChanged: (value) {
                  if (value != null) {
                    setState(() {
                      _selectedAnalyticsYear = value;
                    });
                    provider.fetchAnalyticsData(value);
                  }
                },
                decoration: const InputDecoration(
                  filled: true,
                  contentPadding: EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.all(Radius.circular(16.0)),
                    borderSide: BorderSide.none
                  )
                ),
              ),
            ),
            Expanded(
              child: monthlyTotals.isEmpty
                  ? const Center(child: Text('No expense data for this year.'))
                  : ListView.builder(
                      padding: const EdgeInsets.fromLTRB(16, 0, 16, 100),
                      itemCount: monthlyTotals.length,
                      itemBuilder: (context, index) {
                        final monthData = monthlyTotals[index];
                        final monthIndex = int.parse(monthData['month']) - 1;
                        final monthName = _monthNames[monthIndex];
                        final total = monthData['total'] as double;

                        return Card(
                           margin: const EdgeInsets.only(bottom: 12.0),
                           clipBehavior: Clip.antiAlias,
                           child: ExpansionTile(
                             title: Text(monthName, style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
                             trailing: Text(
                               NumberFormat.currency(locale: 'en_IN', symbol: '₹', decimalDigits: 0).format(total),
                               style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold, color: theme.colorScheme.secondary),
                             ),
                             children: [
                               FutureBuilder<List<Map<String, dynamic>>>(
                                 future: provider.getMonthlyCategoryBreakdown(_selectedAnalyticsYear, monthIndex + 1),
                                 builder: (context, snapshot) {
                                   if (snapshot.connectionState == ConnectionState.waiting) {
                                     return const Padding(
                                       padding: EdgeInsets.all(16.0),
                                       child: Center(child: CircularProgressIndicator()),
                                     );
                                   }
                                   if (!snapshot.hasData || snapshot.data!.isEmpty) {
                                     return const ListTile(title: Text('No expenses for this month.'));
                                   }
                                   final breakdown = snapshot.data!;
                                   return _buildMonthlyExpenseDetails(theme, provider, breakdown, monthIndex + 1);
                                 },
                               )
                             ],
                           ),
                        );
                      },
                    ),
            ),
          ],
        );
      },
    );
  }

  // --- NEW WIDGET FOR DETAILED MONTHLY EXPENSE BREAKDOWN ---
  Widget _buildMonthlyExpenseDetails(ThemeData theme, AnalyticsProvider provider,
      List<Map<String, dynamic>> categoryBreakdown, int month) {
        
    final totalExpense = categoryBreakdown.fold<double>(0, (sum, item) => sum + (item['total'] as num));

    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Donut Chart
          SizedBox(
            height: 200,
            child: PieChart(
              PieChartData(
                sectionsSpace: 4,
                centerSpaceRadius: 60,
                sections: categoryBreakdown.asMap().entries.map((entry) {
                  final item = entry.value;
                  final percentage = totalExpense > 0 ? (item['total'] / totalExpense) * 100 : 0.0;
                  return PieChartSectionData(
                    value: item['total'] as double,
                    title: '${percentage.toStringAsFixed(0)}%',
                    color: _getColorForCategory(context, item['category'] as String),
                    radius: 40,
                    titleStyle: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.white),
                  );
                }).toList(),
              ),
            ),
          ),
          const SizedBox(height: 24),
          // Detailed List
          Text("Breakdown", style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
          const Divider(height: 24),
          ...categoryBreakdown.map((categoryData) {
            final categoryName = categoryData['category'] as String;
            final categoryTotal = categoryData['total'] as double;
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildDetailRow(theme, categoryName, categoryTotal, isCategory: true),
                _buildSubBreakdown(provider, theme, categoryName, month),
                const SizedBox(height: 8),
              ],
            );
          }).toList(),
        ],
      ),
    );
  }

  // --- NEW HELPER FOR DISPLAYING SUB-BREAKDOWNS ---
  Widget _buildSubBreakdown(AnalyticsProvider provider, ThemeData theme, String categoryName, int month) {
    Future<List<Map<String, dynamic>>> future;
    String nameKey;

    switch (categoryName) {
      case 'Debt Repayment':
        future = provider.getDebtRepaymentBreakdownForMonth(_selectedAnalyticsYear, month);
        nameKey = 'name';
        break;
      case 'Friends':
        future = provider.getFriendExpenseBreakdownForMonth(_selectedAnalyticsYear, month);
        nameKey = 'name';
        break;
      default:
        future = provider.getSubCategoryBreakdownForMonth(_selectedAnalyticsYear, month, categoryName);
        nameKey = 'sub_category';
    }

    return FutureBuilder<List<Map<String, dynamic>>>(
      future: future,
      builder: (context, subSnapshot) {
        if (!subSnapshot.hasData || subSnapshot.data!.isEmpty) {
          return const SizedBox.shrink();
        }
        final subBreakdown = subSnapshot.data!;
        return Padding(
          padding: const EdgeInsets.only(left: 16.0, top: 4.0, bottom: 8.0),
          child: Column(
            children: subBreakdown.map((sub) {
              return _buildDetailRow(theme, sub[nameKey], sub['total']);
            }).toList(),
          ),
        );
      },
    );
  }


  Widget _buildDetailRow(ThemeData theme, String title, double value, {bool isCategory = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            title,
            style: isCategory
                ? theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold)
                : theme.textTheme.bodyMedium?.copyWith(color: theme.colorScheme.onSurfaceVariant),
          ),
          Text(
            NumberFormat.currency(locale: 'en_IN', symbol: '₹', decimalDigits: 0).format(value),
            style: isCategory
                ? theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold)
                : theme.textTheme.bodyMedium?.copyWith(color: theme.colorScheme.onSurfaceVariant, fontWeight: FontWeight.w600),
          ),
        ],
      ),
    );
  }


  // --- BUILDER FOR THE MONTHLY VIEW ---
  Widget _buildMonthlyView(BuildContext context, ThemeData theme) {
    return Consumer<DashboardProvider>(
      builder: (context, provider, child) {
        if (provider.isLoading) {
          return const Center(child: CircularProgressIndicator());
        }

        final totals = provider.monthlyTotals;
        final breakdown = provider.monthlyCategoryBreakdown;
        final moneyLeft = (totals['Income'] ?? 0) -
            (totals['Expense'] ?? 0) -
            (totals['Saving'] ?? 0);

        return ListView(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 100),
          children: [
            Text(
              '${DateFormat.MMMM().format(DateTime(0, widget.selectedMonth))} ${widget.selectedYear}',
              style: theme.textTheme.headlineSmall,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            _buildTotalsCard(
              theme: theme,
              title: 'Net for the Month',
              amount: moneyLeft,
              income: totals['Income'] ?? 0.0,
              expense: totals['Expense'] ?? 0.0,
              saving: totals['Saving'] ?? 0.0,
            ),
            const SizedBox(height: 24),
            _buildBreakdownCard(
              theme: theme,
              title: 'Monthly Expense Breakdown',
              breakdown: breakdown,
            ),
          ],
        );
      },
    );
  }

  // --- BUILDER FOR THE YEARLY VIEW ---
  Widget _buildYearlyView(BuildContext context, ThemeData theme) {
    return Consumer<AnalyticsProvider>(
      builder: (context, provider, child) {
        if (provider.isAnalyticsLoading) {
          return const Center(child: CircularProgressIndicator());
        }
        final totals = provider.yearlyTotals;
        final breakdown = provider.yearlyCategoryBreakdown;
        final moneyLeft = (totals['Income'] ?? 0) -
            (totals['Expense'] ?? 0) -
            (totals['Saving'] ?? 0);

        return ListView(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 100),
          children: [
            Text(
              '${widget.selectedYear} Summary',
              style: theme.textTheme.headlineSmall,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            _buildTotalsCard(
              theme: theme,
              title: 'Net for the Year',
              amount: moneyLeft,
              income: totals['Income'] ?? 0.0,
              expense: totals['Expense'] ?? 0.0,
              saving: totals['Saving'] ?? 0.0,
            ),
            const SizedBox(height: 24),
            _buildYearlyTrendChart(theme, provider.yearlyMonthlyBreakdown),
            const SizedBox(height: 24),
            _buildBreakdownCard(
              theme: theme,
              title: 'Yearly Expense Breakdown',
              breakdown: breakdown,
            ),
          ],
        );
      },
    );
  }


  // --- COMMON WIDGETS ---

  Widget _buildTotalsCard({
    required ThemeData theme,
    required String title,
    required double amount,
    required double income,
    required double expense,
    required double saving,
  }) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          children: [
            Text(title, style: theme.textTheme.titleMedium),
            const SizedBox(height: 8),
            Text(
              NumberFormat.currency(
                      locale: 'en_IN', symbol: '₹', decimalDigits: 2)
                  .format(amount),
              style: theme.textTheme.displayMedium?.copyWith(
                fontWeight: FontWeight.bold,
                color: amount >= 0
                    ? theme.colorScheme.tertiary
                    : theme.colorScheme.error,
              ),
            ),
            const Divider(height: 32),
            _buildSummaryRow(
                'Income', income, theme.colorScheme.tertiary, theme),
            const SizedBox(height: 12),
            _buildSummaryRow(
                'Expense', expense, theme.colorScheme.secondary, theme),
            const SizedBox(height: 12),
            _buildSummaryRow(
                'Saving', saving, Colors.lightGreen.shade400, theme),
          ],
        ),
      ),
    );
  }

  Widget _buildSummaryRow(
      String label, double value, Color color, ThemeData theme) {
    return Row(
      children: [
        Container(
          width: 10,
          height: 10,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 12),
        Text(label, style: theme.textTheme.bodyLarge),
        const Spacer(),
        Text(
          NumberFormat.currency(
                  locale: 'en_IN', symbol: '₹', decimalDigits: 2)
              .format(value),
          style:
              theme.textTheme.bodyLarge?.copyWith(fontWeight: FontWeight.bold),
        ),
      ],
    );
  }

  Widget _buildBreakdownCard({
    required ThemeData theme,
    required String title,
    required List<Map<String, dynamic>> breakdown,
  }) {
    final totalExpense = breakdown.fold<double>(
        0, (sum, item) => sum + (item['total'] as num));

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          children: [
            Text(title, style: theme.textTheme.titleLarge),
            const SizedBox(height: 24),
            if (breakdown.isEmpty)
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 48.0),
                child: Text('No expense data for this period.'),
              )
            else
              Column(
                children: [
                  SizedBox(
                    height: 200,
                    child: Stack(
                      alignment: Alignment.center,
                      children: [
                        PieChart(
                          PieChartData(
                            sectionsSpace: 4, // Gap between slices
                            centerSpaceRadius: 70, // Donut hole radius
                            sections: breakdown.map((item) {
                              final percentage = totalExpense > 0
                                  ? (item['total'] / totalExpense) * 100
                                  : 0.0;
                              return PieChartSectionData(
                                value: item['total'] as double,
                                title: '${percentage.toStringAsFixed(0)}%',
                                color: _getColorForCategory(
                                    context, item['category'] as String),
                                radius: 50,
                                titleStyle: const TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                ),
                              );
                            }).toList(),
                          ),
                        ),
                        Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text('Expense',
                                style: theme.textTheme.bodyLarge?.copyWith(
                                    color:
                                        theme.colorScheme.onSurfaceVariant)),
                            Text(
                              NumberFormat.currency(
                                      locale: 'en_IN',
                                      symbol: '₹',
                                      decimalDigits: 0)
                                  .format(totalExpense),
                              style: theme.textTheme.headlineSmall
                                  ?.copyWith(fontWeight: FontWeight.bold),
                            ),
                          ],
                        )
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),
                  _buildLegend(theme, breakdown),
                ],
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildLegend(ThemeData theme, List<Map<String, dynamic>> breakdown) {
    return Wrap(
      spacing: 24, // horizontal spacing
      runSpacing: 12, // vertical spacing
      alignment: WrapAlignment.center,
      children: breakdown.map((item) {
        return Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 12,
              height: 12,
              decoration: BoxDecoration(
                color: _getColorForCategory(context, item['category']),
                shape: BoxShape.circle,
              ),
            ),
            const SizedBox(width: 8),
            Text(item['category']),
          ],
        );
      }).toList(),
    );
  }

  Widget _buildYearlyTrendChart(
      ThemeData theme, List<Map<String, dynamic>> yearlyBreakdown) {
    // Process data for the chart
    final Map<int, double> incomeData = {};
    final Map<int, double> expenseData = {};

    for (var item in yearlyBreakdown) {
      final month = int.parse(item['month']);
      final total = (item['total'] as num).toDouble();
      if (item['type'] == 'Income') {
        incomeData[month] = total;
      } else if (item['type'] == 'Expense') {
        expenseData[month] = total;
      }
    }

    final List<FlSpot> incomeSpots = [];
    final List<FlSpot> expenseSpots = [];

    for (int i = 1; i <= 12; i++) {
      incomeSpots.add(FlSpot(i.toDouble(), incomeData[i] ?? 0));
      expenseSpots.add(FlSpot(i.toDouble(), expenseData[i] ?? 0));
    }

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            Text("Yearly Trends", style: theme.textTheme.titleLarge),
            const SizedBox(height: 24),
            SizedBox(
              height: 200,
              child: LineChart(
                LineChartData(
                  gridData: const FlGridData(show: false),
                  titlesData: FlTitlesData(
                      leftTitles: const AxisTitles(
                          sideTitles: SideTitles(showTitles: false)),
                      rightTitles: const AxisTitles(
                          sideTitles: SideTitles(showTitles: false)),
                      topTitles: const AxisTitles(
                          sideTitles: SideTitles(showTitles: false)),
                      bottomTitles: AxisTitles(
                          sideTitles: SideTitles(
                        showTitles: true,
                        getTitlesWidget: (value, meta) {
                          if (value % 2 != 0) return const SizedBox.shrink(); // Show every other month
                          return SideTitleWidget(
                            axisSide: meta.axisSide,
                            child: Text(DateFormat.MMM()
                                .format(DateTime(0, value.toInt()))),
                          );
                        },
                        interval: 1,
                        reservedSize: 30,
                      ))),
                  borderData: FlBorderData(show: false),
                  lineBarsData: [
                    _lineChartBarData(incomeSpots, theme.colorScheme.tertiary),
                    _lineChartBarData(
                        expenseSpots, theme.colorScheme.secondary),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  LineChartBarData _lineChartBarData(List<FlSpot> spots, Color color) {
    return LineChartBarData(
      spots: spots,
      isCurved: true,
      color: color,
      barWidth: 4,
      isStrokeCapRound: true,
      dotData: const FlDotData(show: false),
      belowBarData: BarAreaData(
        show: true,
        gradient: LinearGradient(
          colors: [
            color.withAlpha(77),
            color.withAlpha(0),
          ],
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
        ),
      ),
    );
  }

  // Helper to get consistent colors for categories.
  Color _getColorForCategory(BuildContext context, String category) {
    final colors = [
      Colors.blue.shade400,
      Colors.green.shade400,
      Colors.orange.shade400,
      Colors.purple.shade400,
      Colors.red.shade400,
      Colors.teal.shade400,
      Colors.pink.shade400,
      Colors.amber.shade400,
      Colors.indigo.shade400,
      Colors.cyan.shade400,
      Colors.lime.shade400,
      Colors.brown.shade400,
    ];
    final index = category.hashCode % colors.length;
    return colors[index];
  }
}
