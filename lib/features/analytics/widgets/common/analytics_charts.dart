import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

/// A reusable card for displaying the yearly income vs. expense trend chart.
class YearlyTrendChart extends StatelessWidget {
  final List<Map<String, dynamic>> yearlyBreakdown;

  const YearlyTrendChart({super.key, required this.yearlyBreakdown});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
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
      elevation: 0,
      color: theme.colorScheme.surfaceContainer,
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            Text("Yearly Trends", style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold)),
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
                          if (value % 2 != 0) return const SizedBox.shrink();
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
                    _lineChartBarData(expenseSpots, theme.colorScheme.secondary),
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
}
