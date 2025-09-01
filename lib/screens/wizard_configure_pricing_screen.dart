import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
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
  _WizardConfigurePricingScreenState createState() => _WizardConfigurePricingScreenState();
}

class _WizardConfigurePricingScreenState extends State<WizardConfigurePricingScreen> {
  final _inscriptionFeeController = TextEditingController();
  final _monthlyFeeController = TextEditingController();
  final _examFeeController = TextEditingController();

  String _selectedCurrency = 'UYU'; // Moneda por defecto
  bool _isLoading = false;

  final List<String> _currencies = ['UYU', 'USD', 'ARS', 'EUR'];

  Future<void> _saveAndContinue() async {
    // Validación simple para asegurar que los campos no estén vacíos
    if (_inscriptionFeeController.text.isEmpty ||
        _monthlyFeeController.text.isEmpty ||
        _examFeeController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Por favor, completa todos los campos de precios. Puedes ingresar 0 si no aplica.')),
      );
      return;
    }

    setState(() { _isLoading = true; });

    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) throw Exception("Usuario no autenticado.");

      // Convertir texto a números de forma segura
      final inscriptionFee = double.tryParse(_inscriptionFeeController.text) ?? 0.0;
      final monthlyFee = double.tryParse(_monthlyFeeController.text) ?? 0.0;
      final examFee = double.tryParse(_examFeeController.text) ?? 0.0;

      final financialData = {
        'inscriptionFee': inscriptionFee,
        'monthlyFee': monthlyFee,
        'examFee': examFee,
        'currency': _selectedCurrency,
      };

      final firestore = FirebaseFirestore.instance;

      // 1. Actualizar el documento de la escuela con la información financiera
      await firestore.collection('schools').doc(widget.schoolId).update({
        'financials': financialData,
      });

      // 2. Actualizar el progreso del wizard del usuario
      await firestore.collection('users').doc(user.uid).update({'wizardStep': 5});

      if (!mounted) return;

      Navigator.of(context).pushReplacement(
        MaterialPageRoute(
          builder: (context) => WizardReviewScreen(
            schoolId: widget.schoolId,
            martialArtTheme: widget.martialArtTheme,
          ),
        ),
      );

    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error al guardar los precios: ${e.toString()}')),
      );
    } finally {
      if (mounted) {
        setState(() { _isLoading = false; });
      }
    }
  }

  @override
  void dispose() {
    _inscriptionFeeController.dispose();
    _monthlyFeeController.dispose();
    _examFeeController.dispose();
    super.dispose();
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
              Text(
                'Define los costos principales de tu academia',
                style: Theme.of(context).textTheme.titleLarge,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24),

              // Selector de Moneda
              DropdownButtonFormField<String>(
                value: _selectedCurrency,
                decoration: const InputDecoration(
                  labelText: 'Moneda',
                  border: OutlineInputBorder(),
                ),
                items: _currencies.map((String currency) {
                  return DropdownMenuItem<String>(
                    value: currency,
                    child: Text(currency),
                  );
                }).toList(),
                onChanged: (String? newValue) {
                  setState(() {
                    _selectedCurrency = newValue!;
                  });
                },
              ),
              const SizedBox(height: 24),

              // Campo para Precio de Inscripción
              TextFormField(
                controller: _inscriptionFeeController,
                decoration: InputDecoration(
                  labelText: 'Precio de Inscripción',
                  prefixText: '$_selectedCurrency ',
                  border: const OutlineInputBorder(),
                  helperText: 'Costo único para nuevos miembros.',
                ),
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'^\d+\.?\d{0,2}'))],
              ),
              const SizedBox(height: 24),

              // Campo para Cuota Mensual
              TextFormField(
                controller: _monthlyFeeController,
                decoration: InputDecoration(
                  labelText: 'Cuota Recurrente (Ej. Mensual)',
                  prefixText: '$_selectedCurrency ',
                  border: const OutlineInputBorder(),
                  helperText: 'El costo principal que pagan los alumnos periódicamente.',
                ),
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'^\d+\.?\d{0,2}'))],
              ),
              const SizedBox(height: 24),

              // Campo para Precio de Examen
              TextFormField(
                controller: _examFeeController,
                decoration: InputDecoration(
                  labelText: 'Precio por Examen',
                  prefixText: '$_selectedCurrency ',
                  border: const OutlineInputBorder(),
                  helperText: 'Costo para rendir examen de pasaje de grado.',
                ),
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'^\d+\.?\d{0,2}'))],
              ),
              const SizedBox(height: 24),

              // Mensaje Informativo
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.blue.shade50,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Text(
                  'Podrás configurar planes más complejos (descuentos, becas, etc.) más tarde desde tu panel de gestión.',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontStyle: FontStyle.italic),
                ),
              ),
              const SizedBox(height: 32),

              // Botón de Continuar
              if (_isLoading)
                const Center(child: CircularProgressIndicator())
              else
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    backgroundColor: widget.martialArtTheme.primaryColor,
                  ),
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
