import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:warrior_path/screens/teacher/student_detail_screen.dart';
import '../../l10n/app_localizations.dart';

/// Permite al profesor crear un alumno "sin app": un perfil proxy sin cuenta de
/// Firebase Auth (sin mail ni contraseña). Replica el patrón de cuentas proxy
/// usado para hijos en add_child_screen.dart. Como toda la app indexa al alumno
/// por el id del documento en members/{id}, este perfil funciona en asistencia,
/// pagos y progreso sin cambios adicionales.
class AddOfflineStudentScreen extends StatefulWidget {
  final String schoolId;
  const AddOfflineStudentScreen({super.key, required this.schoolId});

  @override
  State<AddOfflineStudentScreen> createState() =>
      _AddOfflineStudentScreenState();
}

class _AddOfflineStudentScreenState extends State<AddOfflineStudentScreen> {
  late AppLocalizations l10n;
  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    l10n = AppLocalizations.of(context);
  }

  final _formKey = GlobalKey<FormState>();
  bool _isLoading = false;

  final _nameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _dobController = TextEditingController();
  String? _selectedSex;
  DateTime? _selectedDateOfBirth;

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    _dobController.dispose();
    super.dispose();
  }

  Future<void> _selectDateOfBirth() async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate:
          _selectedDateOfBirth ??
          DateTime.now().subtract(const Duration(days: 365 * 12)),
      firstDate: DateTime(1920),
      lastDate: DateTime.now(),
    );
    if (picked != null) {
      setState(() {
        _selectedDateOfBirth = picked;
        _dobController.text = DateFormat('dd/MM/yyyy').format(picked);
      });
    }
  }

  Future<void> _saveOfflineStudent() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      final firestore = FirebaseFirestore.instance;
      final studentUserRef = firestore.collection('users').doc();
      final studentId = studentUserRef.id;
      final displayName = _nameController.text.trim();

      final batch = firestore.batch();

      // Perfil proxy en users (sin cuenta de Auth)
      batch.set(studentUserRef, {
        'uid': studentId,
        'email': 'offline.$studentId@proxy.warriorpath.app',
        'displayName': displayName,
        'phoneNumber': _phoneController.text.trim(),
        'gender': _selectedSex,
        'dateOfBirth': _selectedDateOfBirth,
        'isProxyAccount': true,
        'isOfflineStudent': true,
        'managedBySchoolId': widget.schoolId,
        'createdAt': FieldValue.serverTimestamp(),
      });

      // Miembro activo de la escuela. El progreso se inicializa vacío; el
      // profesor inscribe en disciplinas desde el detalle del alumno.
      final memberRef = firestore
          .collection('schools')
          .doc(widget.schoolId)
          .collection('members')
          .doc(studentId);
      batch.set(memberRef, {
        'userId': studentId,
        'displayName': displayName,
        'status': 'active',
        'isOfflineStudent': true,
        'gender': _selectedSex,
        'powerLevel': 0,
        'joinDate': FieldValue.serverTimestamp(),
        'progress': {},
      });

      await batch.commit();

      if (!mounted) return;
      // Reemplazamos esta pantalla por el detalle del alumno recién creado,
      // donde el profesor puede inscribirlo en disciplinas.
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(
          builder: (_) => StudentDetailScreen(
            schoolId: widget.schoolId,
            studentId: studentId,
          ),
        ),
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(l10n.genericErrorContent(e.toString()))),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(l10n.addOfflineStudentTitle)),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(l10n.addOfflineStudentDescription),
              const SizedBox(height: 24),
              TextFormField(
                controller: _nameController,
                textCapitalization: TextCapitalization.words,
                decoration: InputDecoration(
                  labelText: l10n.studentNameLabel,
                  border: const OutlineInputBorder(),
                  prefixIcon: const Icon(Icons.person_outline),
                ),
                validator: (value) => (value == null || value.trim().isEmpty)
                    ? l10n.requiredField
                    : null,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _dobController,
                readOnly: true,
                onTap: _selectDateOfBirth,
                decoration: InputDecoration(
                  labelText: l10n.birdthDate,
                  border: const OutlineInputBorder(),
                  suffixIcon: const Icon(Icons.calendar_today),
                ),
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<String>(
                initialValue: _selectedSex,
                decoration: InputDecoration(
                  labelText: l10n.gender,
                  border: const OutlineInputBorder(),
                ),
                items: [
                  DropdownMenuItem(
                    value: 'masculino',
                    child: Text(l10n.maleGender),
                  ),
                  DropdownMenuItem(
                    value: 'femenino',
                    child: Text(l10n.femaleGender),
                  ),
                  DropdownMenuItem(value: 'otro', child: Text(l10n.otherGender)),
                  DropdownMenuItem(
                    value: 'prefiero_no_decirlo',
                    child: Text(l10n.noSpecifyGender),
                  ),
                ],
                onChanged: (value) => setState(() => _selectedSex = value),
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _phoneController,
                keyboardType: TextInputType.phone,
                decoration: InputDecoration(
                  labelText: l10n.phone,
                  border: const OutlineInputBorder(),
                  prefixIcon: const Icon(Icons.phone_outlined),
                ),
              ),
              const SizedBox(height: 32),
              ElevatedButton.icon(
                icon: const Icon(Icons.save),
                label: Text(l10n.save),
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
                onPressed: _isLoading ? null : _saveOfflineStudent,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
