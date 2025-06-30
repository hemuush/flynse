// A new class to track the state change caused by a prepayment.
class PrepaymentEvent {
  final DateTime date;
  final double amount;
  final double previousEmi;
  final int previousTenure;
  final double newEmi;
  final int newTenure;
  final String effect; // "EMI Reduced" or "Tenure Reduced"

  PrepaymentEvent({
    required this.date,
    required this.amount,
    required this.previousEmi,
    required this.previousTenure,
    required this.newEmi,
    required this.newTenure,
    required this.effect,
  });
}


class AmortizationSchedule {
  final List<YearlyBreakdown> years;
  final double originalEmi;
  final double finalEmi;
  final int originalTermInMonths;
  final int finalTermInMonths;
  final double totalInterestPaid;
  final double totalPrincipalPaid;
  // --- NEW: A list to hold the history of all prepayment events. ---
  final List<PrepaymentEvent> prepaymentEvents;

  AmortizationSchedule({
    required this.years,
    required this.originalEmi,
    required this.finalEmi,
    required this.originalTermInMonths,
    required this.finalTermInMonths,
    required this.totalInterestPaid,
    required this.totalPrincipalPaid,
    required this.prepaymentEvents,
  });

  double get totalPayment => totalPrincipalPaid + totalInterestPaid;
}

class YearlyBreakdown {
  final int year;
  final double totalInterest;
  final double totalPrincipal;
  final double balance;
  final List<MonthlyBreakdown> months;

  YearlyBreakdown({
    required this.year,
    required this.totalInterest,
    required this.totalPrincipal,
    required this.balance,
    required this.months,
  });
}

class MonthlyBreakdown {
  final int month;
  final DateTime date;
  final double interest;
  final double principal;
  final double balance;
  final double paymentMade;
  final String? note;
  final bool isPaid;

  MonthlyBreakdown({
    required this.month,
    required this.date,
    required this.interest,
    required this.principal,
    required this.balance,
    required this.paymentMade,
    this.note,
    this.isPaid = false,
  });
}
