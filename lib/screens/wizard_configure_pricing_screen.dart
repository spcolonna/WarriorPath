import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:warrior_path/models/payment_plan_model.dart';
import 'package:warrior_path/screens/wizard_review_screen.dart';
import 'package:warrior_path/theme/martial_art_themes.dart';

class WizardConfigurePricingScreen extends StatefulWidget {
  final String schoolId;
  final MartialArtTheme martialArtTheme;

  const WizardConfigurePricingScreen({
    Key? key,
    required this.schoolId,
    required this.martialArtTheme,
  }) : super(key: key);

  @override
  State<WizardConfigurePricingScreen> createState() => _WizardConfigurePricingScreenState();
}

class _WizardConfigurePricingScreenState extends State<WizardConfigurePricingScreen> {
  final _inscriptionFeeController = TextEditingController();
  final _examFeeController = TextEditingController();

  String _selectedCurrency = 'UYU';
  final List<String> _currencies = ['UYU', 'USD', 'ARS', 'EUR', 'MXN'];

  List<PaymentPlanModel> _plans = [];

  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _addPlan();
  }

  @override
  void dispose() {
    _inscriptionFeeController.dispose();
    _examFeeController.dispose();
    super.dispose();
  }

  void _addPlan() {
    setState(() {
      _plans.add(PaymentPlanModel(
          title: '',
          amount: 0.0,
          currency: _selectedCurrency,
          description: ''
      ));
    });
  }

  void _removePlan(int index) {
    setState(() {
      _plans.removeAt(index);
    });
  }

  Future<void> _saveAndContinue() async {
    // Validación de datos
    if (_plans.any((p) => p.title.trim().isEmpty || p.amount <= 0)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Todos los planes deben tener un título y un monto mayor a cero.')),
      );
      return;
    }

    setState(() { _isLoading = true; });

    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) throw Exception("Usuario no autenticado.");

      final firestore = FirebaseFirestore.instance;
      final schoolRef = firestore.collection('schools').doc(widget.schoolId);
      final batch = firestore.batch();

      // 1. Guardar los costos únicos en el documento principal de la escuela
      final financialData = {
        'inscriptionFee': double.tryParse(_inscriptionFeeController.text) ?? 0.0,
        'examFee': double.tryParse(_examFeeController.text) ?? 0.0,
        'currency': _selectedCurrency,
      };
      batch.update(schoolRef, {'financials': financialData});

      // 2. Guardar cada plan como un documento separado en la sub-colección 'paymentPlans'
      for (final plan in _plans) {
        plan.currency = _selectedCurrency; // Aseguramos que todos los planes tengan la moneda seleccionada
        final planRef = schoolRef.collection('paymentPlans').doc();
        batch.set(planRef, plan.toJson());
      }

      // 3. Actualizar el progreso del wizard
      batch.update(firestore.collection('users').doc(user.uid), {'wizardStep': 5});

      await batch.commit();

      if (!mounted) return;
      Navigator.of(context).push(
        MaterialPageRoute(
          builder: (context) => WizardReviewScreen(
            schoolId: widget.schoolId,
            martialArtTheme: widget.martialArtTheme,
          ),
        ),
      );

    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error al guardar: ${e.toString()}')));
    } finally {
      if (mounted) setState(() { _isLoading = false; });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Configurar Precios (Paso 5)'),
        backgroundColor: widget.martialArtTheme.primaryColor,
      ),
      body: AbsorbPointer(
        absorbing: _isLoading,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text('Costos Únicos y Moneda', style: Theme.of(context).textTheme.titleLarge, textAlign: TextAlign.center),
              const SizedBox(height: 24),
              DropdownButtonFormField<String>(
                value: _selectedCurrency,
                decoration: const InputDecoration(labelText: 'Moneda', border: OutlineInputBorder()),
                items: _currencies.map((c) => DropdownMenuItem<String>(value: c, child: Text(c))).toList(),
                onChanged: (v) => setState(() => _selectedCurrency = v!),
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
                controller: _examFeeController,
                decoration: InputDecoration(labelText: 'Precio por Examen', prefixText: '$_selectedCurrency ', border: const OutlineInputBorder()),
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'^\d+\.?\d{0,2}'))],
              ),
              const Divider(height: 40, thickness: 1),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('Planes de Cuotas Mensuales', style: Theme.of(context).textTheme.titleLarge),
                  IconButton(
                    icon: Icon(Icons.add_circle, color: widget.martialArtTheme.primaryColor),
                    tooltip: 'Añadir nuevo plan',
                    onPressed: _addPlan,
                  ),
                ],
              ),
              const SizedBox(height: 8),
              if (_plans.isEmpty) const Center(child: Text('Añade al menos un plan de pago mensual.')),
              ListView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: _plans.length,
                itemBuilder: (context, index) {
                  return Card(
                    margin: const EdgeInsets.symmetric(vertical: 8),
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        children: [
                          TextFormField(
                            initialValue: _plans[index].title,
                            onChanged: (value) => _plans[index].title = value,
                            decoration: const InputDecoration(labelText: 'Título del Plan', hintText: 'Ej: Plan Familiar'),
                          ),
                          const SizedBox(height: 12),
                          TextFormField(
                            initialValue: _plans[index].amount > 0 ? _plans[index].amount.toString() : '',
                            onChanged: (value) => _plans[index].amount = double.tryParse(value) ?? 0.0,
                            decoration: InputDecoration(labelText: 'Monto Mensual', prefixText: '$_selectedCurrency ', hintText: '0.0'),
                            keyboardType: const TextInputType.numberWithOptions(decimal: true),
                          ),
                          const SizedBox(height: 12),
                          TextFormField(
                            initialValue: _plans[index].description,
                            onChanged: (value) => _plans[index].description = value,
                            decoration: const InputDecoration(labelText: 'Descripción (opcional)', hintText: 'Ej: Para 2 o más hermanos'),
                          ),
                          if (_plans.length > 1)
                            Align(
                              alignment: Alignment.centerRight,
                              child: IconButton(
                                icon: Icon(Icons.delete_outline, color: Colors.red.shade300),
                                onPressed: () => _removePlan(index),
                              ),
                            ),
                        ],
                      ),
                    ),
                  );
                },
              ),
              const SizedBox(height: 32),
              if (_isLoading)
                const Center(child: CircularProgressIndicator())
              else
                ElevatedButton(
                  style: ElevatedButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 16), backgroundColor: widget.martialArtTheme.primaryColor),
                  onPressed: _saveAndContinue,
                  child: const Text('Guardar y Continuar', style: TextStyle(color: Colors.white)),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
