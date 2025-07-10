import 'package:flutter/material.dart';
import 'package:flynse/core/providers/analytics_provider.dart';
import 'package:flynse/core/providers/app_provider.dart';
import 'package:flynse/core/routing/app_router.dart';
import 'package:flynse/features/analytics/analytics_page.dart';
import 'package:provider/provider.dart';

/// A widget for selecting the year and month to display on the dashboard.
///
/// This provides a cleaner and more intuitive way for users to navigate
/// through different time periods, with quick navigation buttons.
class PeriodSelector extends StatelessWidget {
  const PeriodSelector({super.key});

  final List<String> _monthNames = const [
    'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul',
    'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
  ];

  Future<void> _showPeriodDialog(BuildContext context) async {
    final appProvider = context.read<AppProvider>();
    int selectedYear = appProvider.selectedYear;
    int selectedMonth = appProvider.selectedMonth;

    final newPeriod = await showDialog<Map<String, int>>(
      context: context,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              title: const Text('Select Period'),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  DropdownButtonFormField<int>(
                    value: selectedYear,
                    items: appProvider.availableYears.map((year) => DropdownMenuItem(value: year, child: Text(year.toString()))).toList(),
                    onChanged: (value) {
                      if (value != null) {
                        setDialogState(() {
                          selectedYear = value;
                          if (!appProvider.getAvailableMonthsForYear(value).contains(selectedMonth)) {
                            selectedMonth = appProvider.getAvailableMonthsForYear(value).first;
                          }
                        });
                      }
                    },
                    decoration: const InputDecoration(labelText: 'Year', border: OutlineInputBorder()),
                  ),
                  const SizedBox(height: 16),
                  DropdownButtonFormField<int>(
                    value: selectedMonth,
                    items: appProvider.getAvailableMonthsForYear(selectedYear).map((month) => DropdownMenuItem(value: month, child: Text(_monthNames[month-1]))).toList(),
                    onChanged: (value) {
                       if (value != null) {
                         setDialogState(() {
                           selectedMonth = value;
                         });
                       }
                    },
                    decoration: const InputDecoration(labelText: 'Month', border: OutlineInputBorder()),
                  ),
                ],
              ),
              actions: [
                TextButton(onPressed: () => Navigator.of(dialogContext).pop(), child: const Text('Cancel')),
                ElevatedButton(
                  onPressed: () {
                    Navigator.of(dialogContext).pop({'year': selectedYear, 'month': selectedMonth});
                  },
                  child: const Text('Select'),
                ),
              ],
            );
          },
        );
      },
    );

    if (newPeriod != null) {
      await appProvider.setPeriod(newPeriod['year']!, newPeriod['month']!);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final provider = context.watch<AppProvider>();
    final periodText =
        '${_monthNames[provider.selectedMonth - 1]} ${provider.selectedYear}';

    // --- NEW: Logic to handle month navigation ---
    void goToPreviousMonth() {
      int newMonth = provider.selectedMonth - 1;
      int newYear = provider.selectedYear;
      if (newMonth == 0) {
        newMonth = 12;
        newYear--;
      }
      // Only change if the target year is available
      if (provider.availableYears.contains(newYear)) {
        provider.setPeriod(newYear, newMonth);
      }
    }

    void goToNextMonth() {
      int newMonth = provider.selectedMonth + 1;
      int newYear = provider.selectedYear;
      if (newMonth == 13) {
        newMonth = 1;
        newYear++;
      }
      // Do not go into a future month beyond the current date
      final now = DateTime.now();
      if (newYear > now.year || (newYear == now.year && newMonth > now.month)) {
        return;
      }
      provider.setPeriod(newYear, newYear);
    }
    
    final now = DateTime.now();
    final isLastMonth = provider.selectedYear == now.year && provider.selectedMonth == now.month;

    return Container(
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(24.0),
        border: Border.all(color: theme.dividerColor.withAlpha(128))
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          // --- Previous Month Button ---
          IconButton(
            icon: const Icon(Icons.chevron_left_rounded),
            onPressed: goToPreviousMonth,
            tooltip: 'Previous Month',
          ),
          // --- Date Display and Dialog Trigger ---
          GestureDetector(
            onTap: () => _showPeriodDialog(context),
            child: Text(
              periodText,
              style: theme.textTheme.titleSmall
                  ?.copyWith(fontWeight: FontWeight.bold),
            ),
          ),
          // --- Next Month Button ---
          IconButton(
            icon: const Icon(Icons.chevron_right_rounded),
            onPressed: isLastMonth ? null : goToNextMonth,
            tooltip: 'Next Month',
          ),
          // --- Analytics Button ---
          IconButton(
            icon: const Icon(Icons.bar_chart_rounded),
            color: theme.colorScheme.primary,
            tooltip: 'View Analytics',
            onPressed: () async {
              await context
                  .read<AnalyticsProvider>()
                  .fetchAnalyticsData(provider.selectedYear);
              if (context.mounted) {
                Navigator.of(context).pushNamed(
                  AppRouter.analyticsPage,
                  arguments: AnalyticsPageArgs(
                    selectedYear: provider.selectedYear,
                    selectedMonth: provider.selectedMonth,
                  ),
                );
              }
            },
          )
        ],
      ),
    );
  }
}