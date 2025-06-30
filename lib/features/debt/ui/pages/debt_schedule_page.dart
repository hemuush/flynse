import 'package:flutter/material.dart';
import 'package:flynse/core/data/database_helper.dart';
import 'package:flynse/core/data/repositories/debt_repository.dart';
import 'package:flynse/features/debt/data/models/amortization_schedule.dart';
import 'package:flynse/features/debt/data/services/amortization_calculator.dart';
import 'package:intl/intl.dart';

// Helper class to bundle the results from the schedule generation.
class ScheduleResult {
  final AmortizationSchedule schedule;
  final Map<String, dynamic> latestDebt;
  final List<Map<String, dynamic>> repayments;

  ScheduleResult(this.schedule, this.latestDebt, this.repayments);
}


/// A page to display the detailed amortization schedule for a specific debt.
class DebtSchedulePage extends StatefulWidget {
  final Map<String, dynamic> debt;

  const DebtSchedulePage({
    super.key,
    required this.debt,
  });

  @override
  State<DebtSchedulePage> createState() => _DebtSchedulePageState();
}

class _DebtSchedulePageState extends State<DebtSchedulePage> {
  final Set<int> _expandedYears = {};
  late Future<ScheduleResult?> _scheduleFuture;
  final DebtRepository _debtRepo = DebtRepository();

  // --- MODIFICATION: State for collapsible sections ---
  bool _isLoanSummaryExpanded = true;
  bool _isLoanPlanExpanded = true;

  @override
  void initState() {
    super.initState();
    _scheduleFuture = _generateSchedule();
  }

  /// Generates the amortization schedule.
  /// It now fetches the latest debt details and returns a bundled result.
  Future<ScheduleResult?> _generateSchedule() async {
    final db = await DatabaseHelper().database;
    final latestDebtList = await db.query('debts', where: 'id = ?', whereArgs: [widget.debt['id']], limit: 1);
    
    if (latestDebtList.isEmpty) return null;
    
    final latestDebt = latestDebtList.first;
    final repayments = await _debtRepo.getRepaymentHistory(widget.debt['id']);
    
    final termInMonths = (latestDebt['loan_term_years'] as int? ?? 0) * 12;

    final schedule = AmortizationCalculator.calculate(
      principal: latestDebt['principal_amount'] as double?,
      // MODIFICATION: Cast interest rate to a double.
      rate: (latestDebt['interest_rate'] as num?)?.toDouble(),
      termInMonths: termInMonths > 0 ? termInMonths : null,
      startDate: DateTime.tryParse(latestDebt['creation_date'] as String? ?? ''),
      repayments: repayments,
    );
    
    if (schedule == null) return null;
    
    return ScheduleResult(schedule, latestDebt, repayments);
  }

  @override
  Widget build(BuildContext context) {
    final nf =
        NumberFormat.currency(locale: 'en_IN', symbol: '₹', decimalDigits: 0);
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: Text('Schedule for ${widget.debt['name']}'),
      ),
      body: FutureBuilder<ScheduleResult?>(
        future: _scheduleFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError || !snapshot.hasData || snapshot.data == null) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Text('Could not generate schedule for this loan. Error: ${snapshot.error}'),
              ),
            );
          }

          final result = snapshot.data!;
          final schedule = result.schedule;
          
          return SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(16.0, 16.0, 16.0, 100.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildSummaryCard(nf, theme, result),
                const SizedBox(height: 24),
                _buildAmortizationTable(theme, nf, schedule),
              ],
            ),
          );
        },
      ),
    );
  }

  /// Redesigned summary card to be more informative and collapsible.
  Widget _buildSummaryCard(NumberFormat nf, ThemeData theme, ScheduleResult result) {
    final schedule = result.schedule;
    final debtData = result.latestDebt;
    final repayments = result.repayments;
    
    final prepayments = repayments.where((p) => p['prepayment_option'] != null).toList();
    final totalPrepayment = prepayments.fold(0.0, (sum, p) => sum + (p['amount'] as double));
    final totalPaid = debtData['amount_paid'] as double? ?? 0.0;

    return Card(
      elevation: 0,
      color: theme.colorScheme.surfaceContainer,
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // --- MODIFICATION: Loan Summary Header ---
            InkWell(
              onTap: () => setState(() => _isLoanSummaryExpanded = !_isLoanSummaryExpanded),
              child: Row(
                children: [
                  Expanded(child: Text("Loan Summary", style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold))),
                  AnimatedRotation(
                    turns: _isLoanSummaryExpanded ? 0.0 : -0.5,
                    duration: const Duration(milliseconds: 300),
                    child: const Icon(Icons.expand_more),
                  ),
                ],
              ),
            ),
            // --- MODIFICATION: Collapsible Loan Summary Content ---
            AnimatedSize(
              duration: const Duration(milliseconds: 300),
              curve: Curves.easeInOut,
              child: _isLoanSummaryExpanded
                  ? Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const SizedBox(height: 16),
                        _buildSummaryRow(theme, "Principal Amount", nf.format(debtData['principal_amount'])),
                        const Divider(height: 16),
                        _buildSummaryRow(theme, "Total Paid to Date", nf.format(totalPaid)),
                        if (totalPrepayment > 0) ...[
                          const SizedBox(height: 4),
                          Padding(
                            padding: const EdgeInsets.only(left: 8.0),
                            child: _buildSummaryRow(theme, "└ Prepayments Made", nf.format(totalPrepayment), color: theme.colorScheme.primary),
                          ),
                          Padding(
                            padding: const EdgeInsets.only(left: 24.0, top: 4.0),
                            child: Column(
                              children: prepayments.map((p) {
                                final amount = p['amount'] as double;
                                final option = p['prepayment_option'] as String;
                                final optionText = option == 'reduce_emi' ? 'Reduce EMI' : 'Reduce Tenure';
                                return _buildSummaryRow(
                                  theme, 
                                  "• ${nf.format(amount)}", 
                                  optionText, 
                                  color: theme.colorScheme.onSurfaceVariant.withAlpha(200)
                                );
                              }).toList(),
                            ),
                          )
                        ],
                        const Divider(height: 16),
                        _buildSummaryRow(theme, "Total Interest Paid", nf.format(schedule.totalInterestPaid), color: theme.colorScheme.secondary),
                      ],
                    )
                  : const SizedBox.shrink(),
            ),
            
            const Divider(height: 24),
            
            // --- MODIFICATION: Loan Plan Header ---
            InkWell(
              onTap: () => setState(() => _isLoanPlanExpanded = !_isLoanPlanExpanded),
              child: Row(
                children: [
                  Expanded(child: Text("Loan Plan", style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold))),
                   AnimatedRotation(
                    turns: _isLoanPlanExpanded ? 0.0 : -0.5,
                    duration: const Duration(milliseconds: 300),
                    child: const Icon(Icons.expand_more),
                  ),
                ],
              ),
            ),
             // --- MODIFICATION: Collapsible Loan Plan Content ---
            AnimatedSize(
              duration: const Duration(milliseconds: 300),
              curve: Curves.easeInOut,
              child: _isLoanPlanExpanded 
                ? Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: 16),
                    _buildSummaryRow(theme, "Original Plan", "${nf.format(schedule.originalEmi)} / ${schedule.originalTermInMonths} Mo"),
                    if (schedule.prepaymentEvents.isNotEmpty) ...[
                      const Divider(height: 24),
                      Text("Prepayment History", style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
                      const SizedBox(height: 12),
                      // MODIFICATION: Removed unnecessary .toList()
                      ...schedule.prepaymentEvents.map((event) {
                        return Padding(
                          padding: const EdgeInsets.only(bottom: 12.0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                               Text(
                                "On ${DateFormat.yMMMd().format(event.date)}, you prepaid ${nf.format(event.amount)}.",
                                style: theme.textTheme.bodyLarge,
                              ),
                              const SizedBox(height: 4),
                              Padding(
                                padding: const EdgeInsets.only(left: 16.0),
                                child: Column(
                                  children: [
                                    _buildSummaryRow(theme, "Previous Plan", "${nf.format(event.previousEmi)} / ${event.previousTenure} Mo", color: theme.colorScheme.onSurfaceVariant),
                                    _buildSummaryRow(theme, "New Plan", "${nf.format(event.newEmi)} / ${event.newTenure} Mo", color: Colors.green.shade400, isBold: true),
                                  ],
                                )
                              ),
                            ],
                          ),
                        );
                      }),
                    ],
                    const Divider(height: 24),
                    _buildSummaryRow(
                          theme, "Current Plan", "${nf.format(schedule.finalEmi)} / ${schedule.finalTermInMonths} Mo",
                          isBold: true, color: theme.colorScheme.tertiary),
                  ],
                ) 
              : const SizedBox.shrink(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSummaryRow(ThemeData theme, String title, String value, {bool isBold = false, Color? color}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(title, style: theme.textTheme.bodyLarge?.copyWith(color: color)),
          Text(
            value,
            style: theme.textTheme.bodyLarge?.copyWith(
              fontWeight: isBold ? FontWeight.bold : FontWeight.w600,
              color: color
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAmortizationTable(
      ThemeData theme, NumberFormat nf, AmortizationSchedule schedule) {
    const tableColumnWidths = <int, TableColumnWidth>{
      0: FlexColumnWidth(3),
      1: FlexColumnWidth(2.5),
      2: FlexColumnWidth(2.5),
      3: FlexColumnWidth(3),
    };

    return Card(
      elevation: 0,
      color: theme.colorScheme.surfaceContainer,
      clipBehavior: Clip.antiAlias,
      child: Table(
        columnWidths: tableColumnWidths,
        children: [
          TableRow(
            decoration: BoxDecoration(
              color: theme.colorScheme.surfaceContainerHighest,
            ),
            children: [
              _tableCell(theme, 'Date', isHeader: true),
              _tableCell(theme, 'Principal',
                  isHeader: true, align: TextAlign.right),
              _tableCell(theme, 'Interest',
                  isHeader: true, align: TextAlign.right),
              _tableCell(theme, 'Rem. Balance',
                  isHeader: true, align: TextAlign.right),
            ],
          ),
          ...schedule.years.expand((yearData) {
            bool isExpanded = _expandedYears.contains(yearData.year);
            return [
              TableRow(
                children: [
                  TableCell(
                    verticalAlignment: TableCellVerticalAlignment.fill,
                    child: InkWell(
                      onTap: () {
                        setState(() {
                          if (isExpanded) {
                            _expandedYears.remove(yearData.year);
                          } else {
                            _expandedYears.add(yearData.year);
                          }
                        });
                      },
                      child: Row(
                        children: [
                          Expanded(
                            child: _tableCell(theme, yearData.year.toString(),
                                isYearHeader: true),
                          ),
                          Padding(
                            padding: const EdgeInsets.only(right: 8.0),
                            child: AnimatedRotation(
                              turns: isExpanded ? 0.5 : 0.0,
                              duration: const Duration(milliseconds: 200),
                              child: const Icon(Icons.expand_more, size: 20),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  _tableCell(theme, nf.format(yearData.totalPrincipal),
                      isYearHeader: true, align: TextAlign.right),
                  _tableCell(theme, nf.format(yearData.totalInterest),
                      isYearHeader: true,
                      align: TextAlign.right,
                      color: theme.colorScheme.secondary),
                  _tableCell(theme, nf.format(yearData.balance),
                      isYearHeader: true, align: TextAlign.right),
                ],
              ),
              if (isExpanded)
                ...yearData.months.map((monthData) {
                  final monthYearString =
                      DateFormat('MMM, yy').format(monthData.date);
                  final bool isActuallyPaid = monthData.isPaid;

                  final paidColor =
                      isActuallyPaid ? Colors.green.shade700 : null;
                  
                  String cellText = monthYearString;
                  if (monthData.note != null && monthData.note!.isNotEmpty) {
                    final formattedNote = monthData.note!.replaceAll(" (", "\n(");
                    cellText = '$monthYearString\n$formattedNote';
                  }

                  return TableRow(
                    decoration: BoxDecoration(
                      color: isActuallyPaid
                          ? Colors.lightGreen.withAlpha(26)
                          : theme.colorScheme.surface,
                    ),
                    children: [
                      _tableCell(
                          theme,
                          cellText,
                          isMonthly: true,
                          color: paidColor),
                      _tableCell(theme, nf.format(monthData.principal),
                          isMonthly: true,
                          align: TextAlign.right,
                          color: paidColor),
                      _tableCell(theme, nf.format(monthData.interest),
                          isMonthly: true,
                          align: TextAlign.right,
                          color: paidColor),
                      _tableCell(theme, nf.format(monthData.balance),
                          isMonthly: true,
                          align: TextAlign.right,
                          color: paidColor),
                    ],
                  );
                })
            ];
          })
        ],
      ),
    );
  }

  Widget _tableCell(
    ThemeData theme,
    String text, {
    TextAlign align = TextAlign.left,
    bool isHeader = false,
    bool isYearHeader = false,
    bool isMonthly = false,
    Color? color,
  }) {
    TextStyle style;
    EdgeInsets padding =
        const EdgeInsets.symmetric(horizontal: 16, vertical: 12);

    if (isHeader) {
      style = theme.textTheme.bodySmall!;
    } else if (isYearHeader) {
      style = theme.textTheme.bodyLarge!.copyWith(fontWeight: FontWeight.bold);
    } else {
      style = theme.textTheme.bodySmall!;
      padding = const EdgeInsets.fromLTRB(24, 10, 16, 10);
    }

    return Padding(
      padding: padding,
      child: Text(
        text,
        style: style.copyWith(color: color),
        textAlign: align,
      ),
    );
  }
}
