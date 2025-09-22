import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:warrior_path/models/payment_plan_model.dart';
import 'package:warrior_path/screens/wizard_review_screen.dart';

import '../l10n/app_localizations.dart';

class WizardConfigurePricingScreen extends StatefulWidget {
  final String schoolId;
  const WizardConfigurePricingScreen({
    super.key,
    required this.schoolId,
  });

  @override
  State<WizardConfigurePricingScreen> createState() => _WizardConfigurePricingScreenState();
}

class _WizardConfigurePricingScreenState extends State<WizardConfigurePricingScreen> {
  late AppLocalizations l10n;
  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    l10n = AppLocalizations.of(context);
  }

  final _inscriptionFeeController = TextEditingController();
  final _examFeeController = TextEditingController();

  String _selectedCurrency = 'UYU';
  final List<String> _currencies = ['UYU', 'USD', 'ARS', 'EUR', 'MXN'];

  List<PaymentPlanModel> _plans = [];
  bool _isLoading = false;
  Color _primaryColor = Colors.blue;

  @override
  void initState() {
    super.initState();
    _fetchThemeColor();
    _addPlan();
  }

  Future<void> _fetchThemeColor() async {
    try {
      final primaryDiscipline = await FirebaseFirestore.instance
          .collection('schools').doc(widget.schoolId)
          .collection('disciplines').where('isPrimary', isEqualTo: true).limit(1).get();

      if (primaryDiscipline.docs.isNotEmpty && mounted) {
        final themeData = primaryDiscipline.docs.first['theme'] as Map<String, dynamic>;
        setState(() {
          _primaryColor = Color(int.parse('FF${themeData['primaryColor']}', radix: 16));
        });
      }
    } catch (e) {
      // Usar color por defecto en caso de error
      print('Error fetching theme color: $e');
    }
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
          title: '', amount: 0.0, currency: _selectedCurrency, description: ''
      ));
    });
  }

  void _removePlan(int index) {
    setState(() {
      _plans.removeAt(index);
    });
  }

  Future<void> _saveAndContinue() async {
    if (_plans.any((p) => p.title.trim().isEmpty || p.amount <= 0)) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l10n.allPlansNeedTitleAndAmount)),
      );
      return;
    }

    setState(() { _isLoading = true; });

    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) throw Exception(l10n.notAuthenticatedUser);

      final firestore = FirebaseFirestore.instance;
      final schoolRef = firestore.collection('schools').doc(widget.schoolId);
      final batch = firestore.batch();

      final financialData = {
        'inscriptionFee': double.tryParse(_inscriptionFeeController.text) ?? 0.0,
        'examFee': double.tryParse(_examFeeController.text) ?? 0.0,
        'currency': _selectedCurrency,
      };
      batch.update(schoolRef, {'financials': financialData});

      for (final plan in _plans) {
        plan.currency = _selectedCurrency;
        final planRef = schoolRef.collection('paymentPlans').doc();
        batch.set(planRef, plan.toJson());
      }

      batch.update(firestore.collection('users').doc(user.uid), {'wizardStep': 5});
      await batch.commit();

      if (!mounted) return;
      Navigator.of(context).push(
        MaterialPageRoute(
          builder: (context) => WizardReviewScreen(schoolId: widget.schoolId),
        ),
      );

    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(l10n.saveError(e.toString()))));
    } finally {
      if (mounted) setState(() { _isLoading = false; });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.configurePricingStep5),
        backgroundColor: _primaryColor,
      ),
      body: AbsorbPointer(
        absorbing: _isLoading,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(l10n.uniqueCostsAndCurrency, style: Theme.of(context).textTheme.titleLarge, textAlign: TextAlign.center),
              const SizedBox(height: 24),
              DropdownButtonFormField<String>(
                value: _selectedCurrency,
                decoration: InputDecoration(labelText: l10n.currency, border: const OutlineInputBorder()),
                items: _currencies.map((c) => DropdownMenuItem<String>(value: c, child: Text(c))).toList(),
                onChanged: (v) => setState(() => _selectedCurrency = v!),
              ),
              const SizedBox(height: 24),
              TextFormField(
                controller: _inscriptionFeeController,
                decoration: InputDecoration(labelText: l10n.inscriptionFee, prefixText: '$_selectedCurrency ', border: const OutlineInputBorder()),
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'^\d+\.?\d{0,2}'))],
              ),
              const SizedBox(height: 24),
              TextFormField(
                controller: _examFeeController,
                decoration: InputDecoration(labelText: l10n.examFee, prefixText: '$_selectedCurrency ', border: const OutlineInputBorder()),
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'^\d+\.?\d{0,2}'))],
              ),
              const Divider(height: 40, thickness: 1),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(l10n.monthlyFeePlans, style: Theme.of(context).textTheme.titleLarge),
                  IconButton(
                    icon: Icon(Icons.add_circle, color: _primaryColor),
                    tooltip: l10n.addNewPlan,
                    onPressed: _addPlan,
                  ),
                ],
              ),
              const SizedBox(height: 8),
              if (_plans.isEmpty) Center(child: Text(l10n.addAtLeastOnePlan)),
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
                            decoration: InputDecoration(labelText: l10n.planTitle, hintText: l10n.planTitleExample),
                          ),
                          const SizedBox(height: 12),
                          TextFormField(
                            initialValue: _plans[index].amount > 0 ? _plans[index].amount.toString() : '',
                            onChanged: (value) => _plans[index].amount = double.tryParse(value) ?? 0.0,
                            decoration: InputDecoration(labelText: l10n.monthlyAmount, prefixText: '$_selectedCurrency ', hintText: '0.0'),
                            keyboardType: const TextInputType.numberWithOptions(decimal: true),
                          ),
                          const SizedBox(height: 12),
                          TextFormField(
                            initialValue: _plans[index].description,
                            onChanged: (value) => _plans[index].description = value,
                            decoration: InputDecoration(labelText: l10n.planDescriptionOptional, hintText: l10n.planDescriptionExample),
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
                  style: ElevatedButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 16), backgroundColor: _primaryColor),
                  onPressed: _saveAndContinue,
                  child: Text(l10n.saveAndContinue, style: const TextStyle(color: Colors.white)),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
