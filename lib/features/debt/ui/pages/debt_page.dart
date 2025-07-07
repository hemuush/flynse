import 'package:flutter/material.dart';
import 'package:flynse/features/debt/ui/widgets/debt_list_view.dart';

class DebtPage extends StatelessWidget {
  const DebtPage({super.key});

  @override
  Widget build(BuildContext context) {
    // The segmented button is removed, and this page now only shows user debts.
    return const DebtListView(isUserDebtor: true);
  }
}
