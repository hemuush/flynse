import 'dart:developer' as developer;
import 'dart:math';
import 'package:flynse/features/debt/data/models/amortization_schedule.dart';

class AmortizationCalculator {
  static AmortizationSchedule? calculate({
    required double? principal,
    // MODIFICATION: Accepting interest rate as a double.
    required double? rate,
    required int? termInMonths,
    required DateTime? startDate,
    required List<Map<String, dynamic>> repayments,
  }) {
    if (principal == null ||
        rate == null ||
        termInMonths == null ||
        startDate == null ||
        principal <= 0 ||
        rate < 0 ||
        termInMonths <= 0) {
      return null;
    }

    final monthlyRate = rate / 12 / 100;

    // MODIFICATION: Accepting interest rate as a double and rounding result.
    double calculateEmi(double p, double r, int term) {
      if (term <= 0) return p;
      final localMonthlyRate = r / 12 / 100;
      if (localMonthlyRate == 0) return term > 0 ? (p / term).roundToDouble() : p;
      final emi = (p * localMonthlyRate * pow(1 + localMonthlyRate, term)) /
          (pow(1 + localMonthlyRate, term) - 1);
      return emi.roundToDouble();
    }

    final originalEmi = calculateEmi(principal, rate, termInMonths);
    double currentEmi = originalEmi;
    int currentTermInMonths = termInMonths;

    final Map<String, List<Map<String, dynamic>>> paymentsByDate = {};
    for (var p in repayments) {
      try {
        final pDate = DateTime.parse(p['transaction_date']);
        final key = "${pDate.year}-${pDate.month}";
        paymentsByDate.putIfAbsent(key, () => []).add(p);
      } catch (e) {
        /* Ignore invalid date */
      }
    }

    double runningBalance = principal;
    double totalInterestPaid = 0;
    double totalPrincipalPaid = 0;
    final List<MonthlyBreakdown> allMonths = [];
    int monthCounter = 0;

    final List<PrepaymentEvent> prepaymentEvents = [];

    while (runningBalance > 0.01 && monthCounter < 600) { // Safety break at 50 years
      final installmentDate =
          DateTime(startDate.year, startDate.month + monthCounter, startDate.day);
      // MODIFICATION: Rounding calculated interest.
      final interestForMonth = (runningBalance * monthlyRate).roundToDouble();

      final paymentKey = "${installmentDate.year}-${installmentDate.month}";
      final paymentsThisMonth = paymentsByDate[paymentKey] ?? [];
      final wasActuallyPaid = paymentsThisMonth.isNotEmpty;

      // Separate regular and prepayments
      final regularPaymentAmount = paymentsThisMonth
          .where((p) => p['prepayment_option'] == null)
          .fold(0.0, (sum, p) => sum + (p['amount'] as double));
      final prepaymentsInMonth = paymentsThisMonth
          .where((p) => p['prepayment_option'] != null)
          .toList();

      double principalFromRegularPayment = 0;
      double interestPaidThisMonth = 0;
      double paymentToProcess = regularPaymentAmount;

      // If no actual payment was made, assume scheduled EMI was paid for projection
      if (regularPaymentAmount == 0 && !wasActuallyPaid && currentEmi > 0) {
        paymentToProcess = min(currentEmi, runningBalance + interestForMonth);
      }
      
      // Process regular payment part
      if (paymentToProcess > 0) {
        interestPaidThisMonth = min(paymentToProcess, interestForMonth);
        principalFromRegularPayment = paymentToProcess - interestPaidThisMonth;

        runningBalance -= principalFromRegularPayment;
        totalInterestPaid += interestPaidThisMonth;
        totalPrincipalPaid += principalFromRegularPayment;
      }
      
      String? monthNote;
      // *** MODIFICATION START: Process prepayments sequentially ***
      if (prepaymentsInMonth.isNotEmpty) {
        final List<String> notes = [];
        for (final prepayment in prepaymentsInMonth) {
          final double prepaymentAmount = prepayment['amount'] as double;
          if (runningBalance < 0.01) continue;

          // Capture state BEFORE this specific prepayment
          final double previousEmiForEvent = currentEmi;
          final int previousTenureForEvent = currentTermInMonths;

          // Apply prepayment (100% to principal)
          runningBalance -= prepaymentAmount;
          totalPrincipalPaid += prepaymentAmount;

          double newCalculatedEmi = currentEmi;
          int newCalculatedTenure = currentTermInMonths;
          String effect = "";

          if (runningBalance > 0.01) {
            if (prepayment['prepayment_option'] == 'reduce_emi') {
              final monthsLeft = currentTermInMonths - (monthCounter + 1);
              if (monthsLeft > 0) {
                newCalculatedEmi = calculateEmi(runningBalance, rate, monthsLeft);
              } else {
                newCalculatedEmi = runningBalance;
              }
              newCalculatedTenure = currentTermInMonths; // Tenure doesn't change
              effect = "EMI Reduced";
            } else { // reduce_tenure
              newCalculatedEmi = currentEmi; // EMI doesn't change
              if (currentEmi > 0 && monthlyRate > 0) {
                try {
                  final interestComponent = (runningBalance * monthlyRate).roundToDouble();
                  if (currentEmi > interestComponent) {
                    // FIX: Use log explicitly from the dart:math library
                    final logNumerator = log(currentEmi / (currentEmi - interestComponent));
                    final newMonthsRemaining = logNumerator / log(1 + monthlyRate);
                    newCalculatedTenure = monthCounter + 1 + newMonthsRemaining.ceil();
                  } else {
                    newCalculatedTenure = currentTermInMonths;
                  }
                } catch (e, s) {
                  // FIX: Use the developer log with the alias.
                  developer.log('Error calculating loan tenure', error: e, stackTrace: s);
                  newCalculatedTenure = currentTermInMonths;
                }
              }
              effect = "Tenure Reduced";
            }
          } else {
            newCalculatedEmi = 0;
            newCalculatedTenure = monthCounter + 1;
          }

          prepaymentEvents.add(PrepaymentEvent(
            date: installmentDate,
            amount: prepaymentAmount,
            previousEmi: previousEmiForEvent,
            previousTenure: previousTenureForEvent,
            newEmi: newCalculatedEmi,
            newTenure: newCalculatedTenure,
            effect: effect,
          ));

          // Update the main loan state for the next step
          currentEmi = newCalculatedEmi;
          currentTermInMonths = newCalculatedTenure;
          notes.add("Prepayment: ₹${prepaymentAmount.toStringAsFixed(0)} ($effect)");
        }
        monthNote = notes.join('\n');
      }
      // *** MODIFICATION END ***

      final totalPaymentThisMonth = regularPaymentAmount +
          prepaymentsInMonth.fold(
              0.0, (sum, p) => sum + (p['amount'] as double));

      final totalPrincipalPaidThisMonth = principalFromRegularPayment +
          prepaymentsInMonth.fold(
              0.0, (sum, p) => sum + (p['amount'] as double));

      if (runningBalance < 0.01) {
        totalPrincipalPaid += runningBalance;
        runningBalance = 0;
      }

      allMonths.add(MonthlyBreakdown(
        month: monthCounter + 1,
        date: installmentDate,
        interest: interestForMonth,
        principal: totalPrincipalPaidThisMonth,
        balance: runningBalance,
        paymentMade: totalPaymentThisMonth,
        note: monthNote,
        isPaid: wasActuallyPaid,
      ));

      monthCounter++;
      if (runningBalance <= 0) break;
    }

    final Map<int, List<MonthlyBreakdown>> groupedByYear = {};
    for (final monthData in allMonths) {
      groupedByYear.putIfAbsent(monthData.date.year, () => []).add(monthData);
    }

    final List<YearlyBreakdown> yearlyBreakdowns =
        groupedByYear.entries.map((entry) {
      final year = entry.key;
      final monthsInYear = entry.value;
      return YearlyBreakdown(
        year: year,
        totalInterest:
            monthsInYear.fold(0, (prev, e) => prev + e.interest),
        totalPrincipal:
            monthsInYear.fold(0, (prev, e) => prev + e.principal),
        balance: monthsInYear.last.balance,
        months: monthsInYear,
      );
    }).toList();

    yearlyBreakdowns.sort((a, b) => a.year.compareTo(b.year));

    return AmortizationSchedule(
      years: yearlyBreakdowns,
      originalEmi: originalEmi,
      finalEmi: currentEmi > 0 ? currentEmi : 0,
      originalTermInMonths: termInMonths,
      finalTermInMonths: allMonths.length,
      totalInterestPaid: totalInterestPaid,
      totalPrincipalPaid: totalPrincipalPaid,
      prepaymentEvents: prepaymentEvents,
    );
  }
}
