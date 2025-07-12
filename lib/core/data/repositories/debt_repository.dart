import 'dart:math';
import 'package:flynse/core/data/database_helper.dart';
import 'package:flynse/features/debt/data/services/amortization_calculator.dart';
import 'package:sqflite/sqflite.dart';

/// Repository for handling all PERSONAL debt and loan-related database queries.
/// Friend-related debt logic has been moved to FriendRepository.
class DebtRepository {
  final DatabaseHelper _dbHelper = DatabaseHelper();

  Future<Database> get _database async => _dbHelper.database;

  /// --- NEW: A public method to trigger interest recalculation for all debts. ---
  Future<void> recalculateAllPersonalDebts() async {
    await applyAnnualInterest();
  }

  Future<void> applyAnnualInterest() async {
    final db = await _database;
    // MODIFICATION: This query no longer needs to check for friend_id.
    final activeLoans = await db.query(
      'debts',
      where:
          'is_closed = 0 AND interest_rate > 0 AND (loan_term_years IS NULL OR loan_term_years = 0)',
    );

    final now = DateTime.now();

    for (var loan in activeLoans) {
      final creationDate = DateTime.parse(loan['creation_date'] as String);
      final principal = loan['principal_amount'] as double;
      final annualInterestRate = (loan['interest_rate'] as double? ?? 0) / 100.0;

      if (annualInterestRate <= 0) continue;

      int yearsPassed = now.year - creationDate.year;
      if (now.month < creationDate.month ||
          (now.month == creationDate.month && now.day < creationDate.day)) {
        yearsPassed--;
      }
      yearsPassed = yearsPassed < 0 ? 0 : yearsPassed;

      double newTotalAmount = principal;
      for (int i = 0; i < yearsPassed; i++) {
        newTotalAmount *= (1 + annualInterestRate);
      }
      newTotalAmount = newTotalAmount.roundToDouble();

      if ((newTotalAmount - (loan['total_amount'] as double)).abs() > 0.01) {
        await db.update(
          'debts',
          {
            'total_amount': newTotalAmount,
            'interest_updates_applied': yearsPassed,
          },
          where: 'id = ?',
          whereArgs: [loan['id']],
        );
      }
    }
  }

  double _calculateEmi(double principal, double? rate, int? termInYears) {
    if (rate == null || termInYears == null || rate <= 0 || termInYears <= 0) {
      return 0;
    }
    final monthlyRate = rate / 12 / 100;
    final numberOfMonths = termInYears * 12;
    if (monthlyRate == 0) {
      return numberOfMonths > 0 ? principal / numberOfMonths : principal;
    }
    final emi = (principal * monthlyRate * pow(1 + monthlyRate, numberOfMonths)) /
        (pow(1 + monthlyRate, numberOfMonths) - 1);
    return emi.roundToDouble();
  }

  /// Adds a new PERSONAL debt to the database.
  Future<int> addDebt(Map<String, dynamic> debtData) async {
    final db = await _database;
    return await db.transaction((txn) async {
      double principal = debtData['amount'];
      double? interestRate = debtData['interest_rate'];
      int? termInYears = debtData['loan_term_years'];
      final bool isEmiPurchase = debtData['is_emi_purchase'] ?? false;
      final String? purchaseDescription = debtData['purchase_description'];
      final String loanStartDateStr = debtData['loan_start_date'];
      final String transactionDate = debtData['date'];

      final loanStartDate = DateTime.parse(loanStartDateStr);
      final now = DateTime.now();
      double totalAmount = principal;

      if (interestRate != null && interestRate > 0) {
        int monthsPassed = (now.year - loanStartDate.year) * 12 + now.month - loanStartDate.month;
        if (monthsPassed > 0) {
           final monthlyRate = interestRate / 12 / 100;
           double runningBalance = principal;
           for (int i = 0; i < monthsPassed; i++) {
               final interestForMonth = (runningBalance * monthlyRate).roundToDouble();
               runningBalance += interestForMonth;
           }
           totalAmount = runningBalance.roundToDouble();
        }
      }

      final double initialEmi =
          _calculateEmi(principal, interestRate, termInYears);
      final int? initialTermMonths =
          termInYears != null ? termInYears * 12 : null;

      // MODIFICATION: No longer inserts friend_id or is_user_debtor
      final debtId = await txn.insert('debts', {
        'name': debtData['name'],
        'principal_amount': principal,
        'total_amount': totalAmount,
        'interest_rate': interestRate,
        'loan_term_years': termInYears,
        'creation_date': loanStartDateStr,
        'is_emi_purchase': isEmiPurchase ? 1 : 0,
        'purchase_description': purchaseDescription,
        'current_emi': initialEmi > 0 ? initialEmi : null,
        'current_term_months': initialTermMonths,
      });

      if (isEmiPurchase &&
          purchaseDescription != null &&
          purchaseDescription.isNotEmpty) {
        await txn.insert('transactions', {
          'description': purchaseDescription,
          'amount': principal,
          'type': 'Expense',
          'category': 'Shopping',
          'transaction_date': transactionDate,
          'personal_debt_id': debtId // MODIFICATION: Use new column
        });
      }

      await txn.insert('transactions', {
        'description': 'Loan received: ${debtData['name']}',
        'amount': principal,
        'type': 'Income',
        'category': 'Loan',
        'transaction_date': transactionDate,
        'personal_debt_id': debtId // MODIFICATION: Use new column
      });
      return debtId;
    });
  }

  /// Adds a repayment for a PERSONAL debt.
  Future<void> addRepaymentWithDate(
      int debtId, String description, double amount, DateTime date,
      {String? prepaymentOption}) async {
    final db = await _database;
    await db.transaction((txn) async {
      await txn.insert('transactions', {
        'description': description,
        'amount': amount,
        'type': 'Expense',
        'category': 'Debt Repayment',
        'transaction_date': date.toIso8601String(),
        'personal_debt_id': debtId, // MODIFICATION: Use new column
        'prepayment_option': prepaymentOption,
      });

      await txn.rawUpdate('''
        UPDATE debts
        SET amount_paid = amount_paid + ?
        WHERE id = ?
      ''', [amount, debtId]);

      final debtResult =
          await txn.query('debts', where: 'id = ?', whereArgs: [debtId]);
      if (debtResult.isEmpty) return;
      final updatedDebt = debtResult.first;

      if (prepaymentOption != null) {
        final repayments = await getRepaymentHistory(debtId, txn: txn);
        
        final originalTermInMonths = (updatedDebt['loan_term_years'] as int? ?? 0) * 12;

        final schedule = AmortizationCalculator.calculate(
            principal: updatedDebt['principal_amount'] as double?,
            rate: (updatedDebt['interest_rate'] as num?)?.toDouble(),
            termInMonths: originalTermInMonths > 0 ? originalTermInMonths : null,
            startDate:
                DateTime.tryParse(updatedDebt['creation_date'] as String? ?? ''),
            repayments: repayments);

        if (schedule != null) {
          await txn.update(
              'debts',
              {
                'current_emi': schedule.finalEmi > 0 ? schedule.finalEmi : null,
                'current_term_months': schedule.finalTermInMonths
              },
              where: 'id = ?',
              whereArgs: [debtId]);
        }
      }

      final latestDebtState =
          (await txn.query('debts', where: 'id = ?', whereArgs: [debtId]))
              .first;

      bool shouldClose = false;

      final hasInterest = (latestDebtState['interest_rate'] as num? ?? 0) > 0;
      final termInYears = latestDebtState['loan_term_years'] as int? ?? 0;

      if (!hasInterest || termInYears <= 0) {
        if ((latestDebtState['amount_paid'] as num) >= (latestDebtState['total_amount'] as num)) {
          shouldClose = true;
        }
      } 
      else {
        final schedule = AmortizationCalculator.calculate(
          principal: latestDebtState['principal_amount'] as double?,
          rate: (latestDebtState['interest_rate'] as num?)?.toDouble(),
          termInMonths: termInYears * 12,
          startDate: DateTime.tryParse(latestDebtState['creation_date'] as String? ?? ''),
          repayments: await getRepaymentHistory(debtId, txn: txn),
        );

        if (schedule != null) {
          double actualPrincipalPaid = 0.0;
          for (final yearData in schedule.years) {
            for (final monthData in yearData.months) {
              if (monthData.isPaid) {
                actualPrincipalPaid += monthData.principal;
              }
            }
          }
          
          final originalPrincipal = latestDebtState['principal_amount'] as double;
          
          if (actualPrincipalPaid >= originalPrincipal - 0.01) { 
            shouldClose = true;
          }
        }
      }

      if (shouldClose) {
        await txn.update('debts', {'is_closed': 1},
            where: 'id = ?', whereArgs: [debtId]);
      }
    });
  }

  /// Fetches personal debts.
  Future<List<Map<String, dynamic>>> getDebts({bool isClosed = false}) async {
    final db = await _database;
    // MODIFICATION: Simplified query, no longer needs to check for friend_id or is_user_debtor
    return db.query(
      'debts',
      where: 'is_closed = ?',
      whereArgs: [isClosed ? 1 : 0],
      orderBy: '(total_amount - amount_paid) DESC',
    );
  }

  /// Updates the details of a personal loan.
  Future<void> updateDebtInfo({
    required int debtId,
    double? newInterestRate,
    int? newTermYears,
  }) async {
    final db = await _database;
    await db.transaction((txn) async {
      final existingDebtList = await txn.query('debts', where: 'id = ?', whereArgs: [debtId]);
      if (existingDebtList.isEmpty) {
        return;
      }
      final existingDebt = existingDebtList.first;
      final principal = existingDebt['principal_amount'] as double;

      final interestRate = newInterestRate ?? existingDebt['interest_rate'] as double?;
      final termYears = newTermYears ?? existingDebt['loan_term_years'] as int?;

      final newEmi = _calculateEmi(principal, interestRate, termYears);
      final newTermMonths = termYears != null ? termYears * 12 : null;

      await txn.update(
        'debts',
        {
          'interest_rate': interestRate,
          'loan_term_years': termYears,
          'current_emi': newEmi > 0 ? newEmi : null,
          'current_term_months': newTermMonths,
        },
        where: 'id = ?',
        whereArgs: [debtId],
      );
    });
  }

  /// Forecloses a personal debt.
  Future<void> forecloseDebt(int debtId, String debtName, DateTime date,
      {double? foreclosurePenaltyPercentage}) async {
    final db = await _database;
    await db.transaction((txn) async {
      final result =
          await txn.query('debts', where: 'id = ?', whereArgs: [debtId]);
      if (result.isNotEmpty) {
        final debt = result.first;
        final totalAmount = debt['total_amount'] as double;
        final amountPaid = debt['amount_paid'] as double;
        final remainingAmount = totalAmount - amountPaid;

        double finalPayment = remainingAmount;
        String description = 'Foreclosure for: $debtName';

        if (foreclosurePenaltyPercentage != null &&
            foreclosurePenaltyPercentage > 0) {
          final penaltyAmount =
              remainingAmount * (foreclosurePenaltyPercentage / 100);
          finalPayment += penaltyAmount;
          description += ' (with $foreclosurePenaltyPercentage% penalty)';
        }

        if (finalPayment > 0) {
          await txn.insert('transactions', {
            'description': description,
            'amount': finalPayment.roundToDouble(),
            'type': 'Expense',
            'category': 'Debt Repayment',
            'transaction_date': date.toIso8601String(),
            'personal_debt_id': debtId // MODIFICATION: Use new column
          });
        }

        await txn.update(
            'debts',
            {
              'is_closed': 1,
              'amount_paid': totalAmount + (finalPayment - remainingAmount)
            },
            where: 'id = ?',
            whereArgs: [debtId]);
      }
    });
  }

  /// Deletes a personal debt and its associated transactions.
  Future<void> deleteDebtAndTransactions(int debtId) async {
    final db = await _database;
    await db.transaction((txn) async {
      // MODIFICATION: Use new column
      await txn.delete('transactions', where: 'personal_debt_id = ?', whereArgs: [debtId]);
      await txn.delete('debts', where: 'id = ?', whereArgs: [debtId]);
    });
  }

  /// Fetches repayment history for a PERSONAL debt.
  Future<List<Map<String, dynamic>>> getRepaymentHistory(int debtId,
      {Transaction? txn}) async {
    final db = txn ?? await _database;
    // MODIFICATION: Use new column
    return db.query('transactions',
        where: 'personal_debt_id = ? AND category = ?',
        whereArgs: [debtId, 'Debt Repayment'],
        orderBy: 'transaction_date ASC, id ASC');
  }

  /// Calculates total pending PERSONAL debt.
  Future<double> getTotalPendingDebt() async {
    final db = await _database;
    // MODIFICATION: Simplified query
    final result = await db.rawQuery(
        "SELECT SUM(total_amount - amount_paid) as total FROM debts WHERE is_closed = 0");
    if (result.isNotEmpty && result.first['total'] != null) {
      return (result.first['total'] as num).toDouble();
    }
    return 0.0;
  }
}
