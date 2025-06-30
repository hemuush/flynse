import 'package:flutter/material.dart';
import 'package:flynse/core/providers/debt_provider.dart';
import 'package:flynse/features/debt/ui/widgets/debt_list_view.dart';
import 'package:provider/provider.dart';

class DebtPage extends StatelessWidget {
  const DebtPage({super.key});

  @override
  Widget build(BuildContext context) {
    final debtProvider = context.watch<DebtProvider>();
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16.0, 8.0, 16.0, 16.0),
          child: SizedBox(
            width: double.infinity,
            child: SegmentedButton<int>(
              segments: const <ButtonSegment<int>>[
                ButtonSegment<int>(
                    value: 0,
                    label: Text('Your Debts'),
                    icon: Icon(Icons.arrow_circle_up_outlined)),
                ButtonSegment<int>(
                    value: 1,
                    label: Text('Owed to You'),
                    icon: Icon(Icons.arrow_circle_down_outlined)),
              ],
              selected: {debtProvider.debtViewIndex},
              onSelectionChanged: (Set<int> newSelection) {
                context
                    .read<DebtProvider>()
                    .setDebtViewIndex(newSelection.first);
              },
              style: SegmentedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 12),
                textStyle: const TextStyle(fontWeight: FontWeight.w600),
              ),
            ),
          ),
        ),
        Expanded(
          child: IndexedStack(
            index: debtProvider.debtViewIndex,
            children: const [
              DebtListView(isUserDebtor: true),
              DebtListView(isUserDebtor: false),
            ],
          ),
        ),
      ],
    );
  }
}
