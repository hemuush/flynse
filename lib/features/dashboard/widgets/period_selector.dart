import 'package:flutter/material.dart';
import 'package:flynse/core/providers/analytics_provider.dart';
import 'package:flynse/core/providers/app_provider.dart';
import 'package:flynse/core/routing/app_router.dart';
import 'package:flynse/features/analytics/analytics_page.dart';
import 'package:provider/provider.dart';

/// A widget for selecting the year and month to display on the dashboard.
///
/// This provides a cleaner and more intuitive way for users to navigate
/// through different time periods.
class PeriodSelector extends StatelessWidget {
  const PeriodSelector({super.key});

  final List<String> _monthNames = const [
    'January', 'February', 'March', 'April', 'May', 'June', 'July',
    'August', 'September', 'October', 'November', 'December'
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
                          // If the new year doesn't have the current month, reset it
                          if (!appProvider.getAvailableMonthsForYear(value).contains(selectedMonth)) {
                            selectedMonth = appProvider.getAvailableMonthsForYear(value).first;
                          }
                        });
                      }
                    },
                    decoration: const InputDecoration(labelText: 'Year'),
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
                    decoration: const InputDecoration(labelText: 'Month'),
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

    return Center(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 4.0),
        decoration: BoxDecoration(
          color: theme.colorScheme.surface.withAlpha(204),
          borderRadius: BorderRadius.circular(24.0),
          border: Border.all(color: theme.dividerColor.withAlpha(100))
        ),
        child: IntrinsicHeight(
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              InkWell(
                onTap: () => _showPeriodDialog(context),
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(24),
                  bottomLeft: Radius.circular(24),
                ),
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
                  child: Row(
                    children: [
                      Icon(Icons.edit_calendar_outlined,
                          size: 20, color: theme.colorScheme.primary),
                      const SizedBox(width: 8),
                      Text(
                        periodText,
                        style: theme.textTheme.titleMedium
                            ?.copyWith(fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
                ),
              ),
              VerticalDivider(
                color: theme.dividerColor.withAlpha(150),
                width: 1,
                thickness: 1,
                indent: 10,
                endIndent: 10,
              ),
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
        ),
      ),
    );
  }
}
