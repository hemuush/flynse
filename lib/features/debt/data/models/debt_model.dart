class Debt {
  final int id;
  final String name;
  final String? description;
  final double principalAmount;
  final double totalAmount;
  final double amountPaid;
  final DateTime creationDate;
  final bool isClosed;
  // MODIFICATION: Changed interest rate to a double.
  final double? interestRate;
  final int? loanTermYears;
  final int interestUpdatesApplied;
  final bool isUserDebtor;
  final int? friendId;
  final bool isEmiPurchase;
  final String? purchaseDescription;
  final double? currentEmi;
  final int? currentTermMonths;

  Debt({
    required this.id,
    required this.name,
    this.description,
    required this.principalAmount,
    required this.totalAmount,
    required this.amountPaid,
    required this.creationDate,
    required this.isClosed,
    this.interestRate,
    this.loanTermYears,
    required this.interestUpdatesApplied,
    required this.isUserDebtor,
    this.friendId,
    required this.isEmiPurchase,
    this.purchaseDescription,
    this.currentEmi,
    this.currentTermMonths,
  });

  factory Debt.fromMap(Map<String, dynamic> map) {
    return Debt(
      id: map['id'],
      name: map['name'],
      description: map['description'],
      principalAmount: map['principal_amount'],
      totalAmount: map['total_amount'],
      amountPaid: map['amount_paid'],
      creationDate: DateTime.parse(map['creation_date']),
      isClosed: map['is_closed'] == 1,
      // MODIFICATION: Casting interest rate to a double.
      interestRate: (map['interest_rate'] as num?)?.toDouble(),
      loanTermYears: map['loan_term_years'],
      interestUpdatesApplied: map['interest_updates_applied'],
      isUserDebtor: map['is_user_debtor'] == 1,
      friendId: map['friend_id'],
      isEmiPurchase: map['is_emi_purchase'] == 1,
      purchaseDescription: map['purchase_description'],
      currentEmi: map['current_emi'],
      currentTermMonths: map['current_term_months'],
    );
  }
}
