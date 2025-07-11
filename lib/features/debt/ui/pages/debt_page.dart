import 'package:flutter/material.dart';
import 'package:flynse/features/debt/ui/widgets/debt_list_view.dart';

class DebtPage extends StatelessWidget {
  const DebtPage({super.key});

  @override
  Widget build(BuildContext context) {
    // This page now exclusively shows the user's personal debts.
    return const DebtListView();
  }
}
