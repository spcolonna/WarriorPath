import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class FinanceManagementScreen extends StatefulWidget {
  final String schoolId;
  const FinanceManagementScreen({Key? key, required this.schoolId}) : super(key: key);

  @override
  State<FinanceManagementScreen> createState() => _FinanceManagementScreenState();
}

class _FinanceManagementScreenState extends State<FinanceManagementScreen> {
  final _inscriptionFeeController = TextEditingController();
  final _monthlyFeeController = TextEditingController();
  final _examFeeController = TextEditingController();

  String _selectedCurrency = 'USD'; // Moneda por defecto
  final List<String> _currencies = ['USD', 'UYU', 'ARS', 'EUR', 'MXN'];

  bool _isLoading = true;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _fetchFinancials();
  }

  Future<void> _fetchFinancials() async {
    setState(() { _isLoading = true; });
    try {
      final schoolDoc = await FirebaseFirestore.instance.collection('schools').doc(widget.schoolId).get();
      if (schoolDoc.exists && mounted) {
        final financials = schoolDoc.data()?['financials'] as Map<String, dynamic>? ?? {};
        _inscriptionFeeController.text = financials['inscriptionFee']?.toString() ?? '0';
        _monthlyFeeController.text = financials['monthlyFee']?.toString() ?? '0';
        _examFeeController.text = financials['examFee']?.toString() ?? '0';
        _selectedCurrency = financials['currency'] ?? 'USD';
      }
    } catch (e) {
      if(mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error al cargar los datos: ${e.toString()}')));
    } finally {
      if(mounted) setState(() { _isLoading = false; });
    }
  }

  @override
  void dispose() {
    _inscriptionFeeController.dispose();
    _monthlyFeeController.dispose();
    _examFeeController.dispose();
    super.dispose();
  }

  Future<void> _saveChanges() async {
    setState(() { _isSaving = true; });
    try {
      final financialData = {
        'inscriptionFee': double.tryParse(_inscriptionFeeController.text) ?? 0.0,
        'monthlyFee': double.tryParse(_monthlyFeeController.text) ?? 0.0,
        'examFee': double.tryParse(_examFeeController.text) ?? 0.0,
        'currency': _selectedCurrency,
      };

      await FirebaseFirestore.instance
          .collection('schools')
          .doc(widget.schoolId)
          .update({'financials': financialData});

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Datos financieros actualizados.'), backgroundColor: Colors.green),
        );
        Navigator.of(context).pop();
      }
    } catch (e) {
      if(mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error al guardar: ${e.toString()}')));
    } finally {
      if(mounted) setState(() { _isSaving = false; });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Gestionar Finanzas'),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : AbsorbPointer(
        absorbing: _isSaving,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text('Define los costos principales de tu academia', style: Theme.of(context).textTheme.titleLarge, textAlign: TextAlign.center),
              const SizedBox(height: 24),

              DropdownButtonFormField<String>(
                value: _selectedCurrency,
                decoration: const InputDecoration(labelText: 'Moneda', border: OutlineInputBorder()),
                items: _currencies.map((c) => DropdownMenuItem(value: c, child: Text(c))).toList(),
                onChanged: (v) { if (v != null) setState(() => _selectedCurrency = v); },
              ),
              const SizedBox(height: 24),

              TextFormField(
                controller: _inscriptionFeeController,
                decoration: InputDecoration(labelText: 'Precio de Inscripción', prefixText: '$_selectedCurrency ', border: const OutlineInputBorder()),
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'^\d+\.?\d{0,2}'))],
              ),
              const SizedBox(height: 24),

              TextFormField(
                controller: _monthlyFeeController,
                decoration: InputDecoration(labelText: 'Cuota Recurrente (Ej. Mensual)', prefixText: '$_selectedCurrency ', border: const OutlineInputBorder()),
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'^\d+\.?\d{0,2}'))],
              ),
              const SizedBox(height: 24),

              TextFormField(
                controller: _examFeeController,
                decoration: InputDecoration(labelText: 'Precio por Examen', prefixText: '$_selectedCurrency ', border: const OutlineInputBorder()),
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'^\d+\.?\d{0,2}'))],
              ),
              const SizedBox(height: 32),

              if (_isSaving)
                const Center(child: CircularProgressIndicator())
              else
                ElevatedButton.icon(
                  icon: const Icon(Icons.save),
                  label: const Text('Guardar Cambios'),
                  style: ElevatedButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 16)),
                  onPressed: _saveChanges,
                ),
            ],
          ),
        ),
      ),
    );
  }
}
