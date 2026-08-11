import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:warrior_path/services/student_payment_service.dart';

import '../../l10n/app_localizations.dart';

/// Permite al alumno declarar un pago que ya hizo.
///
/// A diferencia del diálogo del maestro, lo que se guarda acá queda
/// **pendiente de confirmación**: el maestro lo tiene que validar antes de que
/// cuente como plata cobrada.
///
/// Si el alumno tiene un plan asignado, se precarga con el concepto y el monto
/// del plan (que es el caso habitual: pagó la cuota del mes). Si no lo tiene,
/// carga concepto, monto y método a mano.
class DeclarePaymentDialog extends StatefulWidget {
  final String schoolId;
  final String studentId;
  final String studentName;

  const DeclarePaymentDialog({
    super.key,
    required this.schoolId,
    required this.studentId,
    required this.studentName,
  });

  @override
  State<DeclarePaymentDialog> createState() => _DeclarePaymentDialogState();
}

class _DeclarePaymentDialogState extends State<DeclarePaymentDialog> {
  late AppLocalizations l10n;
  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    l10n = AppLocalizations.of(context);
  }

  final _conceptCtrl = TextEditingController();
  final _amountCtrl = TextEditingController();

  DateTime _date = DateTime.now();
  String _method = PaymentMethod.cash;
  String _currency = 'UYU';

  String? _planId;
  String? _planTitle;
  bool _usePlan = false;
  bool _loading = true;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _loadPlan();
  }

  @override
  void dispose() {
    _conceptCtrl.dispose();
    _amountCtrl.dispose();
    super.dispose();
  }

  Future<void> _loadPlan() async {
    try {
      final fs = FirebaseFirestore.instance;
      final member = await fs
          .collection('schools')
          .doc(widget.schoolId)
          .collection('members')
          .doc(widget.studentId)
          .get();
      final planId = member.data()?['assignedPaymentPlanId'] as String?;

      if (planId != null) {
        final plan = await fs
            .collection('schools')
            .doc(widget.schoolId)
            .collection('paymentPlans')
            .doc(planId)
            .get();
        final d = plan.data();
        if (d != null && mounted) {
          _planId = planId;
          _planTitle = d['title'] as String? ?? '';
          _currency = d['currency'] as String? ?? 'UYU';
          _usePlan = true;
          _conceptCtrl.text = _planTitle!;
          _amountCtrl.text = ((d['amount'] as num?)?.toDouble() ?? 0).toString();
        }
      }
    } catch (_) {
      // Si falla, se sigue con la carga manual: no vale la pena bloquear al
      // alumno por no poder leer el plan.
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _date,
      firstDate: DateTime.now().subtract(const Duration(days: 365)),
      lastDate: DateTime.now(),
    );
    if (picked != null) setState(() => _date = picked);
  }

  Future<void> _save() async {
    final amount = double.tryParse(_amountCtrl.text.replaceAll(',', '.'));
    if (_conceptCtrl.text.trim().isEmpty || amount == null || amount <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l10n.requiredField)),
      );
      return;
    }

    setState(() => _saving = true);
    try {
      await StudentPaymentService.declare(
        schoolId: widget.schoolId,
        studentId: widget.studentId,
        studentName: widget.studentName,
        concept: _conceptCtrl.text.trim(),
        amount: amount,
        currency: _currency,
        paymentDate: _date,
        paymentPlanId: _usePlan ? _planId : null,
        paymentMethod: _method,
      );
      if (mounted) {
        Navigator.of(context).pop(true);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(l10n.paymentDeclaredSuccess),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(l10n.saveError(e.toString()))),
        );
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  String _methodLabel(String m) => switch (m) {
        PaymentMethod.cash => l10n.methodCash,
        PaymentMethod.transfer => l10n.methodTransfer,
        _ => l10n.methodOther,
      };

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const AlertDialog(
        content: SizedBox(
          height: 80,
          child: Center(child: CircularProgressIndicator()),
        ),
      );
    }

    return AlertDialog(
      title: Text(l10n.declarePaymentTitle),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              l10n.declarePaymentHelp,
              style: TextStyle(fontSize: 13, color: Colors.grey.shade700),
            ),
            const SizedBox(height: 16),

            // Con plan asignado, lo habitual es pagar la cuota: se ofrece
            // precargado y se evita que tenga que tipear nada.
            if (_planId != null) ...[
              SwitchListTile(
                contentPadding: EdgeInsets.zero,
                title: Text(l10n.payMyPlan),
                subtitle: Text(_planTitle ?? ''),
                value: _usePlan,
                onChanged: (v) => setState(() => _usePlan = v),
              ),
              const SizedBox(height: 8),
            ],

            TextField(
              controller: _conceptCtrl,
              readOnly: _usePlan,
              decoration: InputDecoration(
                labelText: l10n.concept,
                border: const OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _amountCtrl,
              readOnly: _usePlan,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              decoration: InputDecoration(
                labelText: l10n.amount,
                prefixText: '$_currency ',
                border: const OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 12),
            DropdownButtonFormField<String>(
              initialValue: _method,
              decoration: InputDecoration(
                labelText: l10n.paymentMethod,
                border: const OutlineInputBorder(),
              ),
              items: PaymentMethod.all
                  .map((m) => DropdownMenuItem(
                        value: m,
                        child: Text(_methodLabel(m)),
                      ))
                  .toList(),
              onChanged: (v) => setState(() => _method = v ?? PaymentMethod.cash),
            ),
            const SizedBox(height: 12),
            OutlinedButton.icon(
              icon: const Icon(Icons.calendar_today, size: 18),
              label: Text(DateFormat('dd/MM/yyyy').format(_date)),
              onPressed: _pickDate,
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: _saving ? null : () => Navigator.of(context).pop(),
          child: Text(l10n.cancel),
        ),
        ElevatedButton(
          onPressed: _saving ? null : _save,
          child: _saving
              ? const SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : Text(l10n.save),
        ),
      ],
    );
  }
}
