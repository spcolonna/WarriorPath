import 'package:flutter/material.dart';

import '../enums/payment_type.dart';
import '../l10n/app_localizations.dart';
import '../models/payment_plan_model.dart';

class RegisterPaymentDialog extends StatefulWidget {
  final List<PaymentPlanModel> allPlans;
  final String? assignedPlanId;
  final String currency;
  final Function(String, double, String?) onSave;

  const RegisterPaymentDialog({
    required this.allPlans, this.assignedPlanId, required this.currency, required this.onSave,
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

  @override
  void initState() {
    super.initState();
    _paymentType = PaymentType.plan;
    if (widget.assignedPlanId != null && widget.allPlans.any((p) => p.id == widget.assignedPlanId)) {
      _selectedPlan = widget.allPlans.firstWhere((p) => p.id == widget.assignedPlanId);
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
      _amountController.text = _selectedPlan!.amount.toString();
    } else {
      _conceptController.text = '';
      _amountController.text = '';
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Registrar Pago'),
      content: SingleChildScrollView(
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          ToggleButtons(
            isSelected: [_paymentType == PaymentType.plan, _paymentType == PaymentType.special],
            onPressed: (index) {
              setState(() {
                _paymentType = index == 0 ? PaymentType.plan : PaymentType.special;
                if (_paymentType == PaymentType.plan) {
                  _updateFieldsFromPlan();
                } else {
                  _conceptController.text = ''; _amountController.text = '';
                }
              });
            },
            borderRadius: BorderRadius.circular(8),
            children: const [Padding(padding: EdgeInsets.symmetric(horizontal: 16), child: Text('Pago de Plan')), Padding(padding: EdgeInsets.symmetric(horizontal: 16), child: Text('Pago Especial'))],
          ),
          const SizedBox(height: 24),
          if (_paymentType == PaymentType.plan)
            DropdownButtonFormField<PaymentPlanModel>(
              value: _selectedPlan,
              hint: const Text('Selecciona un plan'),
              items: widget.allPlans.map((plan) => DropdownMenuItem(value: plan, child: Text(plan.title))).toList(),
              onChanged: (plan) { setState(() { _selectedPlan = plan; _updateFieldsFromPlan(); }); },
            ),
          const SizedBox(height: 16),
          TextField(controller: _conceptController, decoration: const InputDecoration(labelText: 'Concepto'), enabled: _paymentType == PaymentType.special),
          const SizedBox(height: 16),
          TextField(controller: _amountController, decoration: InputDecoration(labelText: 'Monto', prefixText: '${widget.currency} '), keyboardType: const TextInputType.numberWithOptions(decimal: true), enabled: _paymentType == PaymentType.special),
        ]),
      ),
      actions: [
        TextButton(onPressed: () => Navigator.of(context).pop(), child: const Text('Cancelar')),
        ElevatedButton(
          onPressed: () {
            widget.onSave(_conceptController.text, double.tryParse(_amountController.text) ?? 0.0, _paymentType == PaymentType.plan ? _selectedPlan?.id : null);
            Navigator.of(context).pop();
          },
          child: Text(l10n.savePayment),
        ),
      ],
    );
  }
}
