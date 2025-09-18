import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../l10n/app_localizations.dart';
import 'guardian_dashboard_screen.dart';

class AddChildScreen extends StatefulWidget {
  const AddChildScreen({super.key});

  @override
  State<AddChildScreen> createState() => _AddChildScreenState();
}

class _AddChildScreenState extends State<AddChildScreen> {
  late AppLocalizations l10n;
  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    l10n = AppLocalizations.of(context);
  }

  final _formKey = GlobalKey<FormState>();
  bool _isLoading = false;

  final _nameController = TextEditingController();
  final _dobController = TextEditingController();
  String? _selectedSex;
  DateTime? _selectedDateOfBirth;
  final _emergencyContactNameController = TextEditingController();
  final _emergencyContactPhoneController = TextEditingController();
  final _medicalEmergencyServiceController = TextEditingController();
  final _medicalInfoController = TextEditingController();

  @override
  void dispose() {
    _nameController.dispose();
    _dobController.dispose();
    _emergencyContactNameController.dispose();
    _emergencyContactPhoneController.dispose();
    _medicalEmergencyServiceController.dispose();
    _medicalInfoController.dispose();
    super.dispose();
  }

  Future<void> _selectDateOfBirth(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedDateOfBirth ?? DateTime.now().subtract(const Duration(days: 365 * 10)),
      firstDate: DateTime(1950),
      lastDate: DateTime.now(),
      locale: const Locale('es', 'ES'),
    );
    if (picked != null && picked != _selectedDateOfBirth) {
      setState(() {
        _selectedDateOfBirth = picked;
        _dobController.text = DateFormat('dd/MM/yyyy').format(picked);
      });
    }
  }


  Future<void> _saveChildProfile() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() { _isLoading = true; });

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => PopScope(
        canPop: false,
        child: AlertDialog(
          content: Row(children: [
            const CircularProgressIndicator(),
            const SizedBox(width: 24),
            Text(l10n.creatingChildProfile),
          ]),
        ),
      ),
    );

    try {
      final guardianUser = FirebaseAuth.instance.currentUser;
      if (guardianUser == null) throw Exception(l10n.notAuthenticatedUser);

      final firestore = FirebaseFirestore.instance;

      final childUserRef = firestore.collection('users').doc();
      final childId = childUserRef.id;

      final guardianshipRef = firestore.collection('guardianships').doc();

      await firestore.runTransaction((transaction) async {
        final childProfileData = {
          'uid': childId,
          'email': 'child.$childId@proxy.warriorpath.app',
          'displayName': _nameController.text.trim(),
          'gender': _selectedSex,
          'dateOfBirth': _selectedDateOfBirth,
          'emergencyContactName': _emergencyContactNameController.text.trim(),
          'emergencyContactPhone': _emergencyContactPhoneController.text.trim(),
          'medicalEmergencyService': _medicalEmergencyServiceController.text.trim(),
          'medicalInfo': _medicalInfoController.text.trim(),
          'isProxyAccount': true,
          'createdAt': FieldValue.serverTimestamp(),
        };

        final guardianshipData = {
          'guardianId': guardianUser.uid,
          'childId': childId,
          'relationship': 'guardian',
        };

        transaction.set(childUserRef, childProfileData);
        transaction.set(guardianshipRef, guardianshipData);
      });

      await firestore.collection('users').doc(guardianUser.uid).update({'wizardStep': 99});

      if (mounted) Navigator.of(context, rootNavigator: true).pop();
      if (mounted) {
        Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(builder: (context) => const GuardianDashboardScreen()),
              (route) => false,
        );
      }

      ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(l10n.childProfileCreatedSuccess), backgroundColor: Colors.green)
      );

    } catch (e) {
      if (mounted) Navigator.of(context, rootNavigator: true).pop();
      ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(l10n.childProfileCreatedError(e.toString())))
      );
    } finally {
      if (mounted) setState(() { _isLoading = false; });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(l10n.addChildTitle)),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(l10n.addChildDescription, textAlign: TextAlign.center),
              const SizedBox(height: 24),
              Text(l10n.childData, style: Theme.of(context).textTheme.titleLarge),
              const SizedBox(height: 16),
              TextFormField(
                controller: _nameController,
                decoration: InputDecoration(labelText: l10n.childFullName, border: const OutlineInputBorder()),
                validator: (value) => value == null || value.isEmpty ? l10n.requiredField : null,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _dobController,
                decoration: InputDecoration(labelText: l10n.birdthDate, border: const OutlineInputBorder(), suffixIcon: const Icon(Icons.calendar_today)),
                readOnly: true,
                onTap: () => _selectDateOfBirth(context),
                validator: (value) => value == null || value.isEmpty ? l10n.requiredField : null,
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<String>(
                value: _selectedSex,
                decoration: InputDecoration(labelText: l10n.gender, border: const OutlineInputBorder()),
                items: [
                  DropdownMenuItem(value: 'masculino', child: Text(l10n.maleGender)),
                  DropdownMenuItem(value: 'femenino', child: Text(l10n.femaleGender)),
                  DropdownMenuItem(value: 'otro', child: Text(l10n.otherGender)),
                  DropdownMenuItem(value: 'prefiero_no_decirlo', child: Text(l10n.noSpecifyGender)),
                ],
                onChanged: (value) => setState(() => _selectedSex = value),
                validator: (value) => value == null ? l10n.requiredField : null,
              ),
              const SizedBox(height: 32),
              Text(l10n.emergencyInfo, style: Theme.of(context).textTheme.titleLarge),
              const SizedBox(height: 16),
              TextFormField(controller: _emergencyContactNameController, decoration: InputDecoration(labelText: l10n.emergencyContactName, border: const OutlineInputBorder())),
              const SizedBox(height: 16),
              TextFormField(controller: _emergencyContactPhoneController, decoration: InputDecoration(labelText: l10n.emergencyContactPhone, border: const OutlineInputBorder()), keyboardType: TextInputType.phone),
              const SizedBox(height: 16),
              TextFormField(controller: _medicalEmergencyServiceController, decoration: InputDecoration(labelText: l10n.medicalEmergencyService, hintText: l10n.medicalServiceExample, border: const OutlineInputBorder())),
              const SizedBox(height: 16),
              TextFormField(controller: _medicalInfoController, decoration: InputDecoration(labelText: l10n.relevantMedicalInfo, hintText: l10n.medicalInfoExample, border: const OutlineInputBorder()), maxLines: 4),
              const SizedBox(height: 32),
              ElevatedButton.icon(
                icon: const Icon(Icons.save),
                label: Text(l10n.saveChild),
                style: ElevatedButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 16)),
                onPressed: _isLoading ? null : _saveChildProfile,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
