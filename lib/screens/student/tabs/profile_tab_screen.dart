import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:warrior_path/screens/WelcomeScreen.dart';
import 'package:warrior_path/screens/student/school_search_screen.dart';
import 'package:warrior_path/screens/wizard_create_school_screen.dart';

import '../../../l10n/app_localizations.dart';

class StudentProfileTabScreen extends StatefulWidget {
  final String memberId;
  const StudentProfileTabScreen({Key? key, required this.memberId}) : super(key: key);

  @override
  State<StudentProfileTabScreen> createState() => _StudentProfileTabScreenState();
}

class _StudentProfileTabScreenState extends State<StudentProfileTabScreen> {
  late AppLocalizations l10n;
  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    l10n = AppLocalizations.of(context);
  }

  late Future<DocumentSnapshot> _userDataFuture;

  // --- CAMBIO: Añadimos controllers y variables para los nuevos datos ---
  final _nameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _dobController = TextEditingController();
  final _emergencyContactNameController = TextEditingController();
  final _emergencyContactPhoneController = TextEditingController();
  final _medicalEmergencyServiceController = TextEditingController();
  final _medicalInfoController = TextEditingController();

  String? _selectedSex;
  DateTime? _selectedDateOfBirth;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _userDataFuture = _fetchUserData();
  }

  Future<DocumentSnapshot> _fetchUserData() async {
    final userDoc = await FirebaseFirestore.instance.collection('users').doc(widget.memberId).get();

    if (userDoc.exists && mounted) {
      final data = userDoc.data() as Map<String, dynamic>;
      _nameController.text = data['displayName'] ?? '';
      _phoneController.text = data['phoneNumber'] ?? '';
      _emergencyContactNameController.text = data['emergencyContactName'] ?? '';
      _emergencyContactPhoneController.text = data['emergencyContactPhone'] ?? '';
      _medicalEmergencyServiceController.text = data['medicalEmergencyService'] ?? '';
      _medicalInfoController.text = data['medicalInfo'] ?? '';

      // --- CAMBIO: Cargamos los nuevos datos del perfil ---
      _selectedSex = data['gender'];
      _selectedDateOfBirth = (data['dateOfBirth'] as Timestamp?)?.toDate();
      if (_selectedDateOfBirth != null) {
        _dobController.text = DateFormat('dd/MM/yyyy', 'es_ES').format(_selectedDateOfBirth!);
      }
    }
    return userDoc;
  }

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    _emergencyContactNameController.dispose();
    _emergencyContactPhoneController.dispose();
    _medicalEmergencyServiceController.dispose();
    _medicalInfoController.dispose();
    _dobController.dispose();
    super.dispose();
  }

  Future<void> _selectDateOfBirth(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedDateOfBirth ?? DateTime(2000),
      firstDate: DateTime(1920),
      lastDate: DateTime.now(),
      locale: const Locale('es', 'ES'),
    );
    if (picked != null && picked != _selectedDateOfBirth) {
      setState(() {
        _selectedDateOfBirth = picked;
        _dobController.text = DateFormat('dd/MM/yyyy', 'es_ES').format(picked);
      });
    }
  }

  Future<void> _saveProfileChanges() async {
    setState(() { _isLoading = true; });
    try {
      // --- CAMBIO: Añadimos los nuevos campos a los datos a guardar ---
      final dataToUpdate = {
        'displayName': _nameController.text.trim(),
        'phoneNumber': _phoneController.text.trim(),
        'gender': _selectedSex,
        'dateOfBirth': _selectedDateOfBirth,
        'emergencyContactName': _emergencyContactNameController.text.trim(),
        'emergencyContactPhone': _emergencyContactPhoneController.text.trim(),
        'medicalEmergencyService': _medicalEmergencyServiceController.text.trim(),
        'medicalInfo': _medicalInfoController.text.trim(),
      };
      await FirebaseFirestore.instance.collection('users').doc(widget.memberId).update(dataToUpdate);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Perfil actualizado con éxito.'), backgroundColor: Colors.green),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error al actualizar el perfil: ${e.toString()}')),
        );
      }
    } finally {
      if (mounted) {
        setState(() { _isLoading = false; });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Mi Perfil'),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            tooltip: 'Cerrar Sesión',
            onPressed: () async {
              await FirebaseAuth.instance.signOut();
              if (context.mounted) {
                Navigator.of(context).pushAndRemoveUntil(
                  MaterialPageRoute(builder: (context) => const WelcomeScreen()),
                      (route) => false,
                );
              }
            },
          )
        ],
      ),
      body: FutureBuilder<DocumentSnapshot>(
        future: _userDataFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError || !snapshot.data!.exists) {
            return const Center(child: Text('No se pudo cargar tu perfil.'));
          }

          return AbsorbPointer(
            absorbing: _isLoading,
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text('Mis Datos', style: Theme.of(context).textTheme.titleLarge),
                  const SizedBox(height: 16),
                  TextFormField(controller: _nameController, decoration: const InputDecoration(labelText: 'Nombre y Apellido', border: OutlineInputBorder())),
                  const SizedBox(height: 16),
                  TextFormField(controller: _phoneController, decoration: const InputDecoration(labelText: 'Mi Teléfono', border: OutlineInputBorder()), keyboardType: TextInputType.phone),

                  // --- CAMBIO: Añadimos los nuevos widgets de formulario ---
                  const SizedBox(height: 16),
                  DropdownButtonFormField<String>(
                    value: _selectedSex,
                    decoration: const InputDecoration(labelText: 'Género', border: OutlineInputBorder()),
                    items: ['Masculino', 'Femenino', 'Otro', 'Prefiero no decirlo']
                        .map((label) => DropdownMenuItem(
                      child: Text(label),
                      value: label.toLowerCase().replaceAll(' ', '_'),
                    ))
                        .toList(),
                    onChanged: (value) {
                      setState(() {
                        _selectedSex = value;
                      });
                    },
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _dobController,
                    decoration: InputDecoration(
                      labelText: l10n.birdthDate,
                      border: OutlineInputBorder(),
                      suffixIcon: Icon(Icons.calendar_today),
                    ),
                    readOnly: true,
                    onTap: () => _selectDateOfBirth(context),
                  ),

                  const SizedBox(height: 32),
                  Text(l10n.emergencyInfo, style: Theme.of(context).textTheme.titleLarge),
                  const SizedBox(height: 8),
                  const Text('Esta información solo será visible para los maestros de tu escuela en caso de ser necesario.', style: TextStyle(color: Colors.grey)),
                  const SizedBox(height: 16),
                  TextFormField(controller: _emergencyContactNameController, decoration: const InputDecoration(labelText: 'Nombre del Contacto de Emergencia', border: OutlineInputBorder())),
                  const SizedBox(height: 16),
                  TextFormField(controller: _emergencyContactPhoneController, decoration: const InputDecoration(labelText: 'Teléfono del Contacto de Emergencia', border: OutlineInputBorder()), keyboardType: TextInputType.phone),
                  const SizedBox(height: 16),
                  TextFormField(controller: _medicalEmergencyServiceController, decoration: const InputDecoration(labelText: 'Servicio de Emergencia Médica', hintText: 'Ej: SEMM, Emergencia Uno, UCM', border: OutlineInputBorder())),
                  const SizedBox(height: 16),
                  TextFormField(controller: _medicalInfoController, decoration: const InputDecoration(labelText: 'Información Médica Relevante', hintText: 'Ej: Alergias, asma, medicación, etc.', border: OutlineInputBorder()), maxLines: 4),
                  const SizedBox(height: 32),
                  if (_isLoading)
                    const Center(child: CircularProgressIndicator())
                  else
                    ElevatedButton.icon(
                      icon: const Icon(Icons.save),
                      label: Text('Guardar Cambios'),
                      style: ElevatedButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 16)),
                      onPressed: _saveProfileChanges,
                    ),
                  const SizedBox(height: 32),
                  const Divider(),
                  const SizedBox(height: 16),
                  Text('Acciones de Cuenta', style: Theme.of(context).textTheme.titleLarge),
                  const SizedBox(height: 16),
                  Card(
                    elevation: 2,
                    child: ListTile(
                      leading: Icon(Icons.search, color: Theme.of(context).primaryColor),
                      title: Text(l10n.enrollInAnotherSchool),
                      subtitle: Text(l10n.joinAnotherCommunity),
                      trailing: const Icon(Icons.arrow_forward_ios),
                      onTap: () { Navigator.of(context).push(MaterialPageRoute(builder: (context) => const SchoolSearchScreen())); },
                    ),
                  ),
                  const SizedBox(height: 16),
                  Card(
                    elevation: 2,
                    child: ListTile(
                      leading: Icon(Icons.add_business, color: Theme.of(context).primaryColor),
                      title: Text(l10n.createNewSchool),
                      subtitle: const Text('Conviértete en maestro e inicia tu camino.'),
                      trailing: const Icon(Icons.arrow_forward_ios),
                      onTap: () { Navigator.of(context).push(MaterialPageRoute(builder: (context) => const WizardCreateSchoolScreen())); },
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}
