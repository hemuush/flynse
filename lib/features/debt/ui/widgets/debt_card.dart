import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flynse/core/data/repositories/debt_repository.dart';
import 'package:flynse/core/providers/app_provider.dart';
import 'package:flynse/core/providers/dashboard_provider.dart';
import 'package:flynse/core/providers/debt_provider.dart';
import 'package:flynse/features/debt/ui/pages/debt_schedule_page.dart';
import 'package:flynse/features/debt/ui/pages/repayment_history_page.dart';
import 'package:flynse/features/settings/friend_history_page.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

class DebtCard extends StatefulWidget {
  final Map<String, dynamic> debt;

  const DebtCard({super.key, required this.debt});

  @override
  State<DebtCard> createState() => _DebtCardState();
}

class _DebtCardState extends State<DebtCard> {
  bool _isExpanded = false;
  final DebtRepository _debtRepo = DebtRepository();

  @override
  Widget build(BuildContext context) {
    final isCompleted = widget.debt['is_closed'] == 1;

    final cardContent = _buildCardContent(context);

    return isCompleted
        ? cardContent
        : Dismissible(
            key: Key(widget.debt['id'].toString()),
            direction: DismissDirection.endToStart,
            confirmDismiss: (direction) async {
              return await showDialog(
                context: context,
                builder: (BuildContext context) {
                  return AlertDialog(
                    title: const Text("Confirm Deletion"),
                    content: Text(
                        "Are you sure you want to delete the debt named \"${widget.debt['name']}\"? This action will also delete all associated transactions and cannot be undone."),
                    actions: <Widget>[
                      TextButton(
                        onPressed: () => Navigator.of(context).pop(false),
                        child: const Text("Cancel"),
                      ),
                      TextButton(
                        onPressed: () => Navigator.of(context).pop(true),
                        style: TextButton.styleFrom(
                          foregroundColor: Theme.of(context).colorScheme.error,
                        ),
                        child: const Text("Delete"),
                      ),
                    ],
                  );
                },
              );
            },
            onDismissed: (direction) async {
              final debtProvider = context.read<DebtProvider>();
              final appProvider = context.read<AppProvider>();
              await debtProvider.deleteDebt(widget.debt['id']);
              if (mounted) {
                await appProvider.refreshAllData();
              }
            },
            background: Container(
              decoration: BoxDecoration(
                color: Colors.redAccent,
                borderRadius: BorderRadius.circular(12),
              ),
              margin: const EdgeInsets.symmetric(vertical: 6),
              alignment: Alignment.centerRight,
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: const Icon(Icons.delete, color: Colors.white),
            ),
            child: cardContent,
          );
  }

  Widget _buildCardContent(BuildContext context) {
    final theme = Theme.of(context);
    final isDarkMode = theme.brightness == Brightness.dark;
    final isUserDebtor = widget.debt['is_user_debtor'] == 1;
    final isCompleted = widget.debt['is_closed'] == 1;

    final double totalAmount = widget.debt['total_amount'] as double;
    final double amountPaid = widget.debt['amount_paid'] as double;
    final double progress =
        totalAmount > 0 ? (amountPaid / totalAmount).clamp(0.0, 1.0) : 0.0;

    final nf =
        NumberFormat.currency(locale: 'en_IN', symbol: '₹', decimalDigits: 0);
    final formattedAmountPaid = nf.format(amountPaid);
    final formattedTotalAmount = nf.format(totalAmount);

    return Card(
      elevation: 0,
      color: theme.colorScheme.surfaceContainer,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16.0),
        side: BorderSide(
          color: isDarkMode ? Colors.grey.shade800 : Colors.grey.shade200,
          width: 1,
        ),
      ),
      margin: const EdgeInsets.symmetric(vertical: 6),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: () {
          if (!isCompleted) {
            setState(() {
              _isExpanded = !_isExpanded;
            });
          }
        },
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                      child: Text(widget.debt['name'],
                          style: theme.textTheme.titleMedium
                              ?.copyWith(fontWeight: FontWeight.bold))),
                  if (isCompleted)
                    Icon(Icons.check_circle, color: Colors.green.shade400)
                  else
                    AnimatedRotation(
                      turns: _isExpanded ? 0.5 : 0.0,
                      duration: const Duration(milliseconds: 300),
                      child: Icon(
                        Icons.expand_more,
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 12),
              ClipRRect(
                borderRadius: BorderRadius.circular(10),
                child: LinearProgressIndicator(
                  value: progress,
                  minHeight: 8,
                  backgroundColor: theme.colorScheme.surfaceContainerHighest,
                  valueColor: AlwaysStoppedAnimation<Color>(isCompleted
                      ? theme.colorScheme.tertiary
                      : (isUserDebtor
                          ? theme.colorScheme.secondary
                          : theme.colorScheme.tertiary)),
                ),
              ),
              const SizedBox(height: 8),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                      isUserDebtor
                          ? 'Paid: $formattedAmountPaid'
                          : 'Received: $formattedAmountPaid',
                      style: theme.textTheme.bodySmall),
                  Text('Total: $formattedTotalAmount',
                      style: theme.textTheme.bodySmall
                          ?.copyWith(fontWeight: FontWeight.bold)),
                ],
              ),
              AnimatedSize(
                duration: const Duration(milliseconds: 300),
                curve: Curves.easeInOut,
                child: _isExpanded
                    ? _buildExpandedDetails(context)
                    : const SizedBox(width: double.infinity),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDetailRow(ThemeData theme, String title, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(title, style: theme.textTheme.bodyMedium),
          Text(value,
              style: theme.textTheme.bodyMedium
                  ?.copyWith(fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }

  Widget _buildExpandedDetails(BuildContext context) {
    final theme = Theme.of(context);
    final isUserDebtor = widget.debt['is_user_debtor'] == 1;
    final nf =
        NumberFormat.currency(locale: 'en_IN', symbol: '₹', decimalDigits: 2);

    final friendId = widget.debt['friend_id'] as int?;
    VoidCallback onViewHistoryPressed;

    if (friendId != null) {
      onViewHistoryPressed = () {
        Navigator.of(context).push(MaterialPageRoute(
          builder: (context) => FriendHistoryPage(
            friendId: friendId,
            friendName: widget.debt['name'],
          ),
        ));
      };
    } else {
      onViewHistoryPressed = () {
        Navigator.of(context).push(MaterialPageRoute(
          builder: (context) => RepaymentHistoryPage(debt: widget.debt),
        ));
      };
    }

    if (isUserDebtor) {
      final principal = widget.debt['principal_amount'] as double;
      final totalAmount = widget.debt['total_amount'] as double;
      final interestAdded = totalAmount - principal;
      final remainingAmount =
          totalAmount - (widget.debt['amount_paid'] as double);

      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Divider(height: 24),
          _buildDetailRow(theme, "Principal Amount", nf.format(principal)),
          if (interestAdded > 0)
            _buildDetailRow(
                theme, "Interest Added to Date", nf.format(interestAdded)),
          _buildDetailRow(
              theme, "Remaining Amount", nf.format(remainingAmount)),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              TextButton.icon(
                icon: const Icon(Icons.history_rounded, size: 18),
                label: const Text('View History'),
                onPressed: onViewHistoryPressed,
              ),
              Row(
                children: [
                  _buildPopupMenu(context),
                  const SizedBox(width: 8),
                  FilledButton.tonalIcon(
                    icon: const Icon(Icons.payment, size: 18),
                    label: const Text('Pay'),
                    onPressed: () => _showPaymentDialog(context, widget.debt),
                  ),
                ],
              ),
            ],
          ),
        ],
      );
    } else {
      final totalAmount = widget.debt['total_amount'] as double;
      final amountReceived = widget.debt['amount_paid'] as double;
      final remainingAmount = totalAmount - amountReceived;

      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Divider(height: 24),
          _buildDetailRow(
              theme, "Remaining Amount", nf.format(remainingAmount)),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              TextButton.icon(
                icon: const Icon(Icons.history_rounded, size: 18),
                label: const Text('View History'),
                onPressed: onViewHistoryPressed,
              ),
              FilledButton.tonalIcon(
                icon: const Icon(Icons.add_card_rounded, size: 18),
                label: const Text('Receive Payment'),
                onPressed: () =>
                    _showReceivePaymentDialog(context, widget.debt),
              ),
            ],
          ),
        ],
      );
    }
  }

  Widget _buildPopupMenu(BuildContext context) {
    return PopupMenuButton<String>(
      onSelected: (value) {
        if (value == 'foreclose') {
          _showForeclosureDialog(context);
        } else if (value == 'edit') {
          _showEditLoanDialog(context, widget.debt);
        } else if (value == 'schedule') {
          Navigator.of(context).push(MaterialPageRoute(
            builder: (_) => DebtSchedulePage(debt: widget.debt),
          ));
        }
      },
      itemBuilder: (BuildContext context) {
        final hasScheduleInfo =
            (widget.debt['interest_rate'] as num? ?? 0) > 0 &&
                (widget.debt['loan_term_years'] as num? ?? 0) > 0;
        return <PopupMenuEntry<String>>[
          const PopupMenuItem<String>(
            value: 'edit',
            child: Text('Edit Loan'),
          ),
          if (hasScheduleInfo)
            const PopupMenuItem<String>(
              value: 'schedule',
              child: Text('View Schedule'),
            ),
          const PopupMenuItem<String>(
            value: 'foreclose',
            child: Text('Foreclose Loan'),
          ),
        ];
      },
      icon: const Icon(Icons.more_horiz),
    );
  }

  void _showEditLoanDialog(BuildContext context, Map<String, dynamic> debt) {
    final formKey = GlobalKey<FormState>();
    final interestController =
        TextEditingController(text: debt['interest_rate']?.toString() ?? '');
    final termController =
        TextEditingController(text: debt['loan_term_years']?.toString() ?? '');
    final debtProvider = context.read<DebtProvider>();
    final appProvider = context.read<AppProvider>();

    showDialog(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: Text('Edit Loan: ${debt['name']}'),
          content: Form(
            key: formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextFormField(
                  controller: interestController,
                  decoration: const InputDecoration(
                      labelText: 'Interest Rate % (Optional)'),
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  validator: (v) {
                    if (v != null && v.isNotEmpty && double.tryParse(v) == null) {
                      return 'Please enter a valid number.';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: termController,
                  decoration: const InputDecoration(
                      labelText: 'Loan Term in Years (Optional)'),
                  keyboardType: TextInputType.number,
                  inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                  validator: (v) {
                     if (v != null && v.isNotEmpty && int.tryParse(v) == null) {
                      return 'Please enter a valid whole number.';
                    }
                    return null;
                  },
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () async {
                if (formKey.currentState!.validate()) {
                  final newInterestRate =
                      double.tryParse(interestController.text);
                  final newTermYears = int.tryParse(termController.text);

                  Navigator.of(dialogContext).pop();

                  await debtProvider.updateDebtDetails(
                    debt['id'],
                    newInterestRate,
                    newTermYears,
                  );
                  await appProvider.refreshAllData();
                }
              },
              child: const Text('Save'),
            ),
          ],
        );
      },
    );
  }

  void _showForeclosureDialog(BuildContext context) {
    final debtProvider = context.read<DebtProvider>();
    final appProvider = context.read<AppProvider>();
    final dashboardProvider = context.read<DashboardProvider>();

    final penaltyController = TextEditingController();

    final totalAmount = widget.debt['total_amount'] as double;
    final amountPaid = widget.debt['amount_paid'] as double;
    final remainingAmount = totalAmount - amountPaid;

    final cumulativeTotals = dashboardProvider.cumulativeTotals;
    final currentBalance = (cumulativeTotals['Income'] ?? 0.0) -
        (cumulativeTotals['Expense'] ?? 0.0) -
        (cumulativeTotals['Saving'] ?? 0.0);

    final now = DateTime.now();
    final selectedYear = appProvider.selectedYear;
    final selectedMonth = appProvider.selectedMonth;
    late DateTime transactionDate;

    if (selectedYear == now.year && selectedMonth == now.month) {
      transactionDate = now;
    } else {
      transactionDate = DateTime(selectedYear, selectedMonth + 1, 0);
    }

    showDialog(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: Text('Foreclose Loan: ${widget.debt['name']}?'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Remaining Balance: ${NumberFormat.simpleCurrency(locale: 'en_IN').format(remainingAmount)}',
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              const Text(
                'This will create a final expense for the remaining balance and mark the loan as completed.',
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: penaltyController,
                decoration: const InputDecoration(
                  labelText: 'Foreclosure Penalty % (Optional)',
                  hintText: 'e.g., 2 for 2%',
                ),
                keyboardType:
                    const TextInputType.numberWithOptions(decimal: true),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () async {
                final penaltyPercentage =
                    double.tryParse(penaltyController.text);
                
                final finalPayment = remainingAmount + (remainingAmount * (penaltyPercentage ?? 0) / 100);

                if (finalPayment > currentBalance) {
                  final confirmed = await showDialog<bool>(
                    context: dialogContext,
                    builder: (warningContext) => AlertDialog(
                      title: const Text('Insufficient Balance'),
                      content: Text(
                          'Your current balance is ${NumberFormat.simpleCurrency(locale: 'en_IN').format(currentBalance)}, but the foreclosure amount is ${NumberFormat.simpleCurrency(locale: 'en_IN').format(finalPayment)}. This will result in a negative balance. Do you want to continue?'),
                      actions: [
                        TextButton(
                          onPressed: () => Navigator.of(warningContext).pop(false),
                          child: const Text('No'),
                        ),
                        TextButton(
                          onPressed: () => Navigator.of(warningContext).pop(true),
                          style: TextButton.styleFrom(
                              foregroundColor: Theme.of(context).colorScheme.error),
                          child: const Text('Yes, Continue'),
                        ),
                      ],
                    ),
                  );
                  if (confirmed != true) {
                    return; 
                  }
                }

                Navigator.of(dialogContext).pop();
                
                await debtProvider.forecloseDebt(widget.debt['id'],
                    widget.debt['name'], transactionDate,
                    foreclosurePenaltyPercentage: penaltyPercentage);
                await appProvider.refreshAllData();
              },
              style: TextButton.styleFrom(
                  foregroundColor: Theme.of(context).colorScheme.error),
              child: const Text('Foreclose'),
            ),
          ],
        );
      },
    );
  }

  void _showPaymentDialog(BuildContext context, Map<String, dynamic> debt) async {
    final formKey = GlobalKey<FormState>();
    final amountController = TextEditingController();
    final debtProvider = context.read<DebtProvider>();
    final appProvider = context.read<AppProvider>();
    final scaffoldMessenger = ScaffoldMessenger.of(context);

    final latestDebt = debtProvider.userDebts.firstWhere((d) => d['id'] == debt['id'], orElse: () => debt);

    final bool hasInterestOrTerm = (latestDebt['interest_rate'] as num? ?? 0) > 0 || (latestDebt['loan_term_years'] as num? ?? 0) > 0;

    if (!hasInterestOrTerm) {
      if (!mounted) return;
      _showSimplePaymentDialog(context, latestDebt);
      return;
    }

    final loanStartDate = DateTime.parse(latestDebt['creation_date']);
    final selectedPeriodDate = DateTime(appProvider.selectedYear, appProvider.selectedMonth);
    final loanStartPeriod = DateTime(loanStartDate.year, loanStartDate.month);
    final isLoanActiveInSelectedPeriod = !selectedPeriodDate.isBefore(loanStartPeriod);

    // FIX: The EMI value is now trusted to be correct in the database.
    // If it's null, it defaults to 0.0.
    final double currentEmi = (latestDebt['current_emi'] as double?) ?? 0.0;
    final totalAmount = latestDebt['total_amount'] as double;
    final amountPaid = latestDebt['amount_paid'] as double;
    final remainingAmount = totalAmount - amountPaid;

    final List<Map<String, dynamic>> repayments = await _debtRepo.getRepaymentHistory(latestDebt['id']);
    
    if (!mounted) return;

    final isEmiPaidForCurrentMonth = repayments.any((r) {
        final repaymentDate = DateTime.parse(r['transaction_date']);
        return r['prepayment_option'] == null &&
               repaymentDate.year == appProvider.selectedYear &&
               repaymentDate.month == appProvider.selectedMonth;
    });

    bool payEmi = !isEmiPaidForCurrentMonth;

    showDialog(
      context: context,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            String emiTitle = 'Pay Scheduled EMI';
            if (isEmiPaidForCurrentMonth) {
              emiTitle = 'EMI Paid for this month';
            } else if (!isLoanActiveInSelectedPeriod) {
              emiTitle = 'Loan not yet active';
            }

            return AlertDialog(
              title: Text('Make Payment for ${latestDebt['name']}'),
              content: Form(
                key: formKey,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (currentEmi > 0)
                      CheckboxListTile(
                        title: Text(emiTitle),
                        subtitle: Text(NumberFormat.simpleCurrency(locale: 'en_IN').format(currentEmi)),
                        value: payEmi,
                        onChanged: isEmiPaidForCurrentMonth || !isLoanActiveInSelectedPeriod
                          ? null
                          : (value) {
                              setDialogState(() {
                                payEmi = value ?? false;
                              });
                            },
                        controlAffinity: ListTileControlAffinity.leading,
                        contentPadding: EdgeInsets.zero,
                      ),
                    TextFormField(
                      controller: amountController,
                      keyboardType: const TextInputType.numberWithOptions(decimal: true),
                      decoration: const InputDecoration(
                        labelText: 'Additional Prepayment (Optional)',
                        hintText: 'Lump-sum amount'
                      ),
                      validator: (v) {
                        if (v == null || v.isEmpty) return null;

                        final prepaymentAmount = double.tryParse(v);
                        if (prepaymentAmount == null) return 'Invalid number';
                        if (prepaymentAmount <= 0) return 'Amount must be positive';

                        double totalPayment = prepaymentAmount;
                        if (payEmi) {
                          totalPayment += currentEmi;
                        }

                        if (totalPayment > remainingAmount + 0.01) {
                          return 'Total payment cannot exceed remaining balance of ${NumberFormat.simpleCurrency(locale: 'en_IN').format(remainingAmount)}';
                        }
                        return null;
                      },
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(dialogContext).pop(),
                  child: const Text('Cancel'),
                ),
                ElevatedButton(
                  onPressed: () async {
                    if (formKey.currentState!.validate()) {
                      Navigator.of(dialogContext).pop();

                      final now = DateTime.now();
                      final transactionDate = (appProvider.selectedYear == now.year && appProvider.selectedMonth == now.month)
                          ? now
                          : DateTime(appProvider.selectedYear, appProvider.selectedMonth, 1);

                      final double prepaymentAmount = double.tryParse(amountController.text) ?? 0.0;
                      
                      bool paymentMade = false;
                      
                      double currentRemaining = remainingAmount;

                      if (payEmi && currentEmi > 0 && isLoanActiveInSelectedPeriod) {
                         double emiToPay = currentEmi;
                         if (emiToPay > currentRemaining && currentRemaining > 0) {
                             emiToPay = currentRemaining;
                         }

                         if(emiToPay > 0) {
                            await debtProvider.addRepayment(latestDebt['id'], 'EMI for ${latestDebt['name']}', emiToPay, transactionDate);
                            currentRemaining -= emiToPay;
                            paymentMade = true;
                         }
                      }

                      if (!mounted) return;

                      if (prepaymentAmount > 0) {
                        final prepaymentOption = await _showPrepaymentChoiceDialog(context);
                        if (prepaymentOption != null) {
                           await debtProvider.addRepayment(
                                latestDebt['id'],
                                'Prepayment for ${latestDebt['name']}',
                                prepaymentAmount,
                                transactionDate,
                                prepaymentOption: prepaymentOption
                           );
                           paymentMade = true;
                        }
                      }
                      
                      if(paymentMade) {
                         await appProvider.refreshAllData();
                         if(mounted) {
                            scaffoldMessenger.showSnackBar(const SnackBar(content: Text('Payment recorded successfully!')));
                         }
                      }
                    }
                  },
                  child: const Text('Submit Payment'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  void _showSimplePaymentDialog(BuildContext context, Map<String, dynamic> debt) {
    final formKey = GlobalKey<FormState>();
    final amountController = TextEditingController();
    final debtProvider = context.read<DebtProvider>();
    final appProvider = context.read<AppProvider>();

    final totalAmount = debt['total_amount'] as double;
    final amountPaid = debt['amount_paid'] as double;
    final remainingAmount = totalAmount - amountPaid;

    final now = DateTime.now();
    final transactionDate =
        (appProvider.selectedYear == now.year && appProvider.selectedMonth == now.month)
            ? now
            : DateTime(appProvider.selectedYear, appProvider.selectedMonth, 1);

    showDialog(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: Text('Pay ${debt['name']}'),
          content: Form(
            key: formKey,
            child: TextFormField(
              controller: amountController,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              decoration: const InputDecoration(labelText: 'Amount'),
              validator: (v) {
                if (v == null || v.isEmpty) return 'Enter amount';
                final amount = double.tryParse(v);
                if (amount == null) return 'Invalid number';
                if (amount <= 0) return 'Amount must be positive';
                if (amount > remainingAmount + 0.01) {
                  return 'Amount cannot exceed remaining balance of ${NumberFormat.simpleCurrency(locale: 'en_IN').format(remainingAmount)}';
                }
                return null;
              },
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () async {
                if (formKey.currentState!.validate()) {
                  Navigator.of(dialogContext).pop();
                  final amount = double.parse(amountController.text);
                  await debtProvider.addRepayment(
                      debt['id'], 'Payment for ${debt['name']}', amount, transactionDate);
                  await appProvider.refreshAllData();
                }
              },
              child: const Text('Submit Payment'),
            ),
          ],
        );
      },
    );
  }

  void _showReceivePaymentDialog(
      BuildContext context, Map<String, dynamic> debt) {
    // This dialog is for when a friend pays you back
    final amountController = TextEditingController();
    final formKey = GlobalKey<FormState>();
    final debtProvider = context.read<DebtProvider>();
    final appProvider = context.read<AppProvider>();

    final totalAmount = debt['total_amount'] as double;
    final amountPaid = debt['amount_paid'] as double;
    final remainingAmount = totalAmount - amountPaid;

    final now = DateTime.now();
    final transactionDate =
        (appProvider.selectedYear == now.year && appProvider.selectedMonth == now.month)
            ? now
            : DateTime(appProvider.selectedYear, appProvider.selectedMonth, 1);

    showDialog(
        context: context,
        builder: (dialogContext) {
          return AlertDialog(
            title: Text('Receive Payment from ${debt['name']}'),
            content: Form(
              key: formKey,
              child: TextFormField(
                controller: amountController,
                keyboardType:
                    const TextInputType.numberWithOptions(decimal: true),
                decoration:
                    const InputDecoration(labelText: 'Amount Received'),
                validator: (v) {
                  if (v == null || v.isEmpty) return 'Enter amount';
                  final amount = double.tryParse(v);
                  if (amount == null) return 'Invalid number';
                  if (amount <= 0) return 'Amount must be positive';
                  if (amount > remainingAmount + 0.01) { // Add tolerance
                     return 'Amount cannot exceed what is owed (${NumberFormat.simpleCurrency(locale: 'en_IN').format(remainingAmount)})';
                  }
                  return null;
                },
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(dialogContext).pop(),
                child: const Text('Cancel'),
              ),
              ElevatedButton(
                onPressed: () async {
                  if (formKey.currentState!.validate()) {
                    Navigator.of(dialogContext).pop();
                    final amount = double.parse(amountController.text);
                    await debtProvider.addRepaymentFromFriend(
                        debt['id'],
                        'Payment from ${debt['name']}',
                        amount,
                        transactionDate);
                    await appProvider.refreshAllData();
                  }
                },
                child: const Text('Receive'),
              ),
            ],
          );
        });
  }

  Future<String?> _showPrepaymentChoiceDialog(BuildContext context) async {
    return await showDialog<String>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Apply Prepayment'),
        content: const Text('How would you like to apply this extra payment?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop('reduce_emi'),
            child: const Text('Reduce EMI'),
          ),
          ElevatedButton(
            onPressed: () =>
                Navigator.of(dialogContext).pop('reduce_tenure'),
            child: const Text('Reduce Tenure'),
          ),
        ],
      ),
    );
  }
}
