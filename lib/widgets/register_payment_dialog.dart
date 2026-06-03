import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../enums/payment_type.dart';
import '../l10n/app_localizations.dart';
import '../models/payment_plan_model.dart';

class RegisterPaymentDialog extends StatefulWidget {
  final List<PaymentPlanModel> allPlans;
  final String? assignedPlanId;
  final String currency;
  final Function(String, double, String?, DateTime) onSave;

  const RegisterPaymentDialog({
    super.key,
    required this.allPlans,
    this.assignedPlanId,
    required this.currency,
    required this.onSave,
  });

  @override
  State<RegisterPaymentDialog> createState() => _RegisterPaymentDialogState();
}

class _RegisterPaymentDialogState extends State<RegisterPaymentDialog> {
  late AppLocalizations l10n;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    l10n = AppLocalizations.of(context);
  }

  PaymentType _paymentType = PaymentType.plan;
  PaymentPlanModel? _selectedPlan;
  final _conceptController = TextEditingController();
  final _amountController = TextEditingController();

  // Default: first day of the current month
  late DateTime _paymentDate;

  @override
  void initState() {
    super.initState();
    final now = DateTime.now();
    _paymentDate = DateTime(now.year, now.month, 1);

    if (widget.assignedPlanId != null &&
        widget.allPlans.any((p) => p.id == widget.assignedPlanId)) {
      _selectedPlan = widget.allPlans.firstWhere(
        (p) => p.id == widget.assignedPlanId,
      );
    } else if (widget.allPlans.isNotEmpty) {
      _selectedPlan = widget.allPlans.first;
    }
    _updateFieldsFromPlan();
  }

  @override
  void dispose() {
    _conceptController.dispose();
    _amountController.dispose();
    super.dispose();
  }

  void _updateFieldsFromPlan() {
    if (_selectedPlan != null) {
      _conceptController.text = _selectedPlan!.title;
      _amountController.text = _selectedPlan!.amount.toStringAsFixed(2);
    } else {
      _conceptController.clear();
      _amountController.clear();
    }
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _paymentDate,
      firstDate: DateTime(DateTime.now().year - 5),
      lastDate: DateTime.now(),
      locale: const Locale('es', 'ES'),
    );
    if (picked != null) setState(() => _paymentDate = picked);
  }

  @override
  Widget build(BuildContext context) {
    final dateLabel = DateFormat(
      "d 'de' MMMM yyyy",
      'es_ES',
    ).format(_paymentDate);

    return AlertDialog(
      title: Text(l10n.registerPayment),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            SegmentedButton<PaymentType>(
              segments: <ButtonSegment<PaymentType>>[
                ButtonSegment<PaymentType>(
                  value: PaymentType.plan,
                  label: Text(l10n.planPayment),
                  icon: const Icon(Icons.article_outlined),
                ),
                ButtonSegment<PaymentType>(
                  value: PaymentType.special,
                  label: Text(l10n.specialPayment),
                  icon: const Icon(Icons.star_outline),
                ),
              ],
              selected: <PaymentType>{_paymentType},
              onSelectionChanged: (Set<PaymentType> newSelection) {
                setState(() {
                  _paymentType = newSelection.first;
                  if (_paymentType == PaymentType.plan) {
                    _updateFieldsFromPlan();
                  } else {
                    _selectedPlan = null;
                    _conceptController.clear();
                    _amountController.clear();
                  }
                });
              },
            ),
            const SizedBox(height: 24),
            if (_paymentType == PaymentType.plan)
              DropdownButtonFormField<PaymentPlanModel>(
                initialValue: _selectedPlan,
                hint: Text(l10n.selectPlan),
                items: widget.allPlans
                    .map(
                      (plan) => DropdownMenuItem(
                        value: plan,
                        child: Text(plan.title),
                      ),
                    )
                    .toList(),
                onChanged: (plan) {
                  setState(() {
                    _selectedPlan = plan;
                    _updateFieldsFromPlan();
                  });
                },
                isExpanded: true,
              ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _conceptController,
              decoration: InputDecoration(labelText: l10n.concept),
              readOnly: _paymentType == PaymentType.plan,
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _amountController,
              decoration: InputDecoration(
                labelText: l10n.amount,
                prefixText: '${widget.currency} ',
              ),
              keyboardType: const TextInputType.numberWithOptions(
                decimal: true,
              ),
              readOnly: _paymentType == PaymentType.plan,
            ),
            const SizedBox(height: 16),
            // Date picker row
            InkWell(
              onTap: _pickDate,
              borderRadius: BorderRadius.circular(4),
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 14,
                ),
                decoration: BoxDecoration(
                  border: Border.all(
                    color: Theme.of(context).colorScheme.outline,
                  ),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            'Fecha del pago',
                            style: TextStyle(
                              fontSize: 12,
                              color: Theme.of(
                                context,
                              ).colorScheme.onSurfaceVariant,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(dateLabel, style: const TextStyle(fontSize: 16)),
                        ],
                      ),
                    ),
                    Icon(
                      Icons.edit_calendar_outlined,
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: Text(l10n.cancel),
        ),
        ElevatedButton(
          onPressed: () {
            final amount = double.tryParse(_amountController.text) ?? 0.0;
            if (_conceptController.text.trim().isEmpty || amount <= 0) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('El concepto y el monto son requeridos.'),
                ),
              );
              return;
            }
            widget.onSave(
              _conceptController.text.trim(),
              amount,
              _paymentType == PaymentType.plan ? _selectedPlan?.id : null,
              _paymentDate,
            );
            Navigator.of(context).pop();
          },
          child: Text(l10n.savePayment),
        ),
      ],
    );
  }
}
