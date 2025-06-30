import 'package:flutter/material.dart';
import 'package:flynse/core/providers/savings_provider.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

class YearlySavingsSheet extends StatelessWidget {
  const YearlySavingsSheet({super.key});

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<SavingsProvider>();
    final yearlySavings = provider.yearlySavings;
    final theme = Theme.of(context);

    return Container(
      padding: const EdgeInsets.fromLTRB(24.0, 24.0, 24.0, 0),
      decoration: BoxDecoration(
        color: theme.cardColor,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(25.0)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(
            child: Text(
              'Yearly Savings Breakdown',
              style:
                  theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
            ),
          ),
          const SizedBox(height: 24),
          provider.isLoading
              ? const Center(child: CircularProgressIndicator())
              : yearlySavings.isEmpty
                  ? const Center(
                      child: Padding(
                        padding: EdgeInsets.symmetric(vertical: 32.0),
                        child: Text(
                          'No savings data found.',
                          style: TextStyle(fontSize: 16, color: Colors.grey),
                        ),
                      ),
                    )
                  : ConstrainedBox(
                      constraints: BoxConstraints(
                        maxHeight: MediaQuery.of(context).size.height * 0.4,
                      ),
                      child: ListView.builder(
                        shrinkWrap: true,
                        itemCount: yearlySavings.length,
                        itemBuilder: (context, index) {
                          final item = yearlySavings[index];
                          final year = item['year'];
                          final totalSavings =
                              (item['total_savings'] as num?)?.toDouble() ??
                                  0.0;

                          return Card(
                            margin: const EdgeInsets.symmetric(vertical: 8.0),
                            child: ListTile(
                              contentPadding: const EdgeInsets.symmetric(
                                  vertical: 12.0, horizontal: 16.0),
                              leading: CircleAvatar(
                                backgroundColor:
                                    Colors.lightGreen.withAlpha(51),
                                child: Text(
                                  year.toString(),
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    color: Colors.lightGreen.shade600,
                                  ),
                                ),
                              ),
                              title: Text(
                                'Total Savings in $year',
                                style:
                                    const TextStyle(fontWeight: FontWeight.bold),
                              ),
                              trailing: Text(
                                '₹${NumberFormat.decimalPattern('en_IN').format(totalSavings.round())}',
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 16,
                                  color: Colors.lightGreen.shade500,
                                ),
                              ),
                            ),
                          );
                        },
                      ),
                    ),
          const SizedBox(height: 24),
          Center(
            child: TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Close'),
            ),
          ),
          SizedBox(height: MediaQuery.of(context).padding.bottom + 16),
        ],
      ),
    );
  }
}