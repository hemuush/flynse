import 'dart:math';

import 'package:flynse/core/data/database_helper.dart';
import 'package:flynse/features/debt/data/services/amortization_calculator.dart';
import 'package:sqflite/sqflite.dart';

/// Repository for handling all debt and loan-related database queries.
class DebtRepository {
  final DatabaseHelper _dbHelper = DatabaseHelper();

  Future<Database> get _database async => _dbHelper.database;

  Future<void> applyAnnualInterest() async {
    final db = await _database;
    final activeLoans = await db.query(
      'debts',
      where:
          'is_closed = 0 AND is_user_debtor = 1 AND interest_rate > 0 AND (loan_term_years IS NULL OR loan_term_years = 0)',
    );

    final now = DateTime.now();

    for (var loan in activeLoans) {
      final creationDate = DateTime.parse(loan['creation_date'] as String);
      final principal = loan['principal_amount'] as double;
      final interestRate = (loan['interest_rate'] as double? ?? 0) / 100.0;
      final updatesApplied = loan['interest_updates_applied'] as int;

      if (interestRate <= 0) continue;

      final yearsPassed = now.difference(creationDate).inDays ~/ 365;

      if (yearsPassed > updatesApplied) {
        final updatesToApply = yearsPassed - updatesApplied;
        final interestToAdd = (principal * interestRate * updatesToApply).roundToDouble();

        final newTotalAmount =
            (loan['total_amount'] as double) + interestToAdd;

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

      final debtId = await txn.insert('debts', {
        'name': debtData['name'],
        'principal_amount': principal,
        'total_amount': totalAmount,
        'interest_rate': interestRate,
        'loan_term_years': termInYears,
        'creation_date': loanStartDateStr,
        'is_user_debtor': 1,
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
          'debt_id': debtId
        });
      }

      await txn.insert('transactions', {
        'description': 'Loan received: ${debtData['name']}',
        'amount': principal,
        'type': 'Income',
        'category': 'Loan',
        'transaction_date': transactionDate,
        'debt_id': debtId
      });
      return debtId;
    });
  }

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
        'debt_id': debtId,
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
            rate: updatedDebt['interest_rate'] as double?,
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
          rate: latestDebtState['interest_rate'] as double?,
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

  Future<List<Map<String, dynamic>>> getDebts(
      {required bool isUserDebtor, bool isClosed = false}) async {
    final db = await _database;

    return db.query(
      'debts',
      where: 'is_user_debtor = ? AND is_closed = ?',
      whereArgs: [isUserDebtor ? 1 : 0, isClosed ? 1 : 0],
      orderBy: '(total_amount - amount_paid) DESC',
    );
  }

  /// MODIFICATION: This method now recalculates the EMI when loan details are updated.
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

      // Use new values if provided, otherwise fallback to existing values
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

  Future<void> addRepaymentFromFriend(
      int debtId, String description, double amount, DateTime date) async {
    final db = await _database;
    await db.transaction((txn) async {
      await txn.insert('transactions', {
        'description': description,
        'amount': amount,
        'type': 'Income',
        'category': 'Friend Repayment',
        'transaction_date': date.toIso8601String(),
        'debt_id': debtId
      });

      await txn.rawUpdate('''
        UPDATE debts
        SET amount_paid = amount_paid + ?
        WHERE id = ?
      ''', [amount, debtId]);

      final result =
          await txn.query('debts', where: 'id = ?', whereArgs: [debtId]);
      if (result.isNotEmpty) {
        final debt = result.first;
        if ((debt['amount_paid'] as num) >=
            (debt['total_amount'] as num) - 0.01) {
          await txn.update('debts', {'is_closed': 1},
              where: 'id = ?', whereArgs: [debtId]);
        }
      }
    });
  }

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
        final isUserDebtor = debt['is_user_debtor'] == 1;

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
            'type': isUserDebtor ? 'Expense' : 'Income',
            'category': isUserDebtor ? 'Debt Repayment' : 'Friend Repayment',
            'transaction_date': date.toIso8601String(),
            'debt_id': debtId
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

  Future<void> deleteDebtAndTransactions(int debtId) async {
    final db = await _database;
    await db.transaction((txn) async {
      await txn
          .delete('transactions', where: 'debt_id = ?', whereArgs: [debtId]);
      await txn.delete('debts', where: 'id = ?', whereArgs: [debtId]);
    });
  }

  Future<List<Map<String, dynamic>>> getRepaymentHistory(int debtId,
      {Transaction? txn}) async {
    final db = txn ?? await _database;
    return db.query('transactions',
        where: 'debt_id = ? AND (category = ? OR category = ?)',
        whereArgs: [debtId, 'Debt Repayment', 'Friend Repayment'],
        orderBy: 'transaction_date ASC, id ASC');
  }

  Future<double> getTotalPendingDebt() async {
    final db = await _database;
    final result = await db.rawQuery(
        "SELECT SUM(total_amount - amount_paid) as total FROM debts WHERE is_closed = 0 AND is_user_debtor = 1");
    if (result.isNotEmpty && result.first['total'] != null) {
      return (result.first['total'] as num).toDouble();
    }
    return 0.0;
  }

  Future<int> getActiveDebtCount() async {
    final db = await _database;
    final result = await db.rawQuery(
        "SELECT COUNT(*) as count FROM debts WHERE is_closed = 0 AND is_user_debtor = 1");
    if (result.isNotEmpty && result.first['count'] != null) {
      return (result.first['count'] as num).toInt();
    }
    return 0;
  }
}
