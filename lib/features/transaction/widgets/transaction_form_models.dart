import 'package:flutter/material.dart';

// A helper class to pass arguments to the AddEditTransactionPage.
class AddEditTransactionPageArgs {
  final Map<String, dynamic>? transaction;
  final bool isSaving;
  final bool isLoanToFriend;

  AddEditTransactionPageArgs(
      {this.transaction, this.isSaving = false, this.isLoanToFriend = false});
}

// Model for a single split entry in the UI
class SplitEntry {
  final int id = DateTime.now().microsecondsSinceEpoch;
  String? subCategory;
  final TextEditingController amountController = TextEditingController();
}

// A model to hold the state for a single transaction form
class TransactionFormState {
  final int id;
  String type;
  Map<String, dynamic>? category;
  List<String> subCategories;
  DateTime date;

  final TextEditingController amountController;
  final TextEditingController descriptionController = TextEditingController(); // New field

  // New field for friends
  Map<String, dynamic>? selectedFriend;

  // New field for friend repayments
  Map<String, dynamic>? selectedDebtForRepayment;
  bool get isFriendRepayment =>
      type == 'Income' && category?['name'] == 'Friend Repayment';

  // New field for user debt repayments
  Map<String, dynamic>? selectedDebtForUserRepayment;
  bool get isDebtRepayment =>
      type == 'Expense' && category?['name'] == 'Debt Repayment';

  // New field for savings withdrawal
  String? selectedCategoryForWithdrawal;
  bool get isSavingsWithdrawal =>
      type == 'Saving' && category?['name'] == 'Savings Withdrawal';

  // Debt-specific fields
  final TextEditingController loanNameController = TextEditingController();
  final TextEditingController interestController = TextEditingController();
  final TextEditingController termController = TextEditingController();
  final TextEditingController purchaseDescriptionController =
      TextEditingController();
  bool isEmiPurchase = false;

  // Split-specific fields
  bool isSplit = false;
  List<SplitEntry> splits = [SplitEntry()]; // Start with one split entry

  TransactionFormState({
    required this.type,
    this.category,
    this.subCategories = const [],
    required this.date,
    required this.amountController,
  }) : id = DateTime.now().microsecondsSinceEpoch;
}
