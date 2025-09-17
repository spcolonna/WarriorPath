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
          SnackBar(content: Text(l10n.updateProfileSuccess), backgroundColor: Colors.green),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(l10n.profileUpdateError(e.toString()))),
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
        title: Text(l10n.myProfile),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            tooltip: l10n.logOut,
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
            return Center(child: Text(l10n.profileLoadedError)); // Corregido para usar la clave correcta
          }

          // --- INICIO DE LA CORRECCIÓN PARA EL DROPDOWN ---
          // 1. Definimos las opciones con claves estables y valores localizados.
          final Map<String, String> sexOptions = {
            'male': l10n.maleGender,
            'female': l10n.femaleGender,
            'other': l10n.otherGender,
            'prefers_not_to_say': l10n.noSpecifyGender,
          };

          // 2. Validamos el valor actual (_selectedSex) contra las CLAVES estables.
          final bool isValueValid = _selectedSex != null && sexOptions.containsKey(_selectedSex);
          // --- FIN DE LA CORRECCIÓN ---

          return AbsorbPointer(
            absorbing: _isLoading,
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(l10n.myData, style: Theme.of(context).textTheme.titleLarge),
                  const SizedBox(height: 16),
                  TextFormField(controller: _nameController, decoration: InputDecoration(labelText: l10n.fullName, border: const OutlineInputBorder())),
                  const SizedBox(height: 16),
                  TextFormField(controller: _phoneController, decoration: InputDecoration(labelText: l10n.phone, border: const OutlineInputBorder()), keyboardType: TextInputType.phone),
                  const SizedBox(height: 16),

                  // --- DROPDOWN COMPLETAMENTE CORREGIDO ---
                  DropdownButtonFormField<String>(
                    value: isValueValid ? _selectedSex : null,
                    decoration: InputDecoration(labelText: l10n.gender, border: const OutlineInputBorder()),
                    // 3. Construimos los items a partir del mapa.
                    items: sexOptions.entries.map((entry) {
                      return DropdownMenuItem(
                        value: entry.key, // La clave estable (e.g., 'female')
                        child: Text(entry.value), // El texto traducido (e.g., 'Femenino')
                      );
                    }).toList(),
                    onChanged: (value) {
                      setState(() {
                        _selectedSex = value; // Guardamos la clave estable en el estado
                      });
                    },
                  ),
                  // --- FIN DEL DROPDOWN CORREGIDO ---

                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _dobController,
                    decoration: InputDecoration(
                      labelText: l10n.birdthDate,
                      border: const OutlineInputBorder(),
                      suffixIcon: const Icon(Icons.calendar_today),
                    ),
                    readOnly: true,
                    onTap: () => _selectDateOfBirth(context),
                  ),
                  const SizedBox(height: 32),
                  Text(l10n.emergencyInfo, style: Theme.of(context).textTheme.titleLarge),
                  const SizedBox(height: 8),
                  Text(l10n.emergencyInfoNotice, style: const TextStyle(color: Colors.grey)),
                  const SizedBox(height: 16),
                  TextFormField(controller: _emergencyContactNameController, decoration: InputDecoration(labelText: l10n.emergencyContactName, border: const OutlineInputBorder())),
                  const SizedBox(height: 16),
                  TextFormField(controller: _emergencyContactPhoneController, decoration: InputDecoration(labelText: l10n.emergencyContactPhone, border: const OutlineInputBorder()), keyboardType: TextInputType.phone),
                  const SizedBox(height: 16),
                  TextFormField(controller: _medicalEmergencyServiceController, decoration: InputDecoration(labelText: l10n.medicalEmergencyService, hintText: l10n.medicalServiceExample, border: const OutlineInputBorder())),
                  const SizedBox(height: 16),
                  TextFormField(controller: _medicalInfoController, decoration: InputDecoration(labelText: l10n.relevantMedicalInfo, hintText: l10n.medicalInfoExample, border: const OutlineInputBorder()), maxLines: 4),
                  const SizedBox(height: 32),
                  if (_isLoading)
                    const Center(child: CircularProgressIndicator())
                  else
                    ElevatedButton.icon(
                      icon: const Icon(Icons.save),
                      label: Text(l10n.saveChanges),
                      style: ElevatedButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 16)),
                      onPressed: _saveProfileChanges,
                    ),
                  const SizedBox(height: 32),
                  const Divider(),
                  const SizedBox(height: 16),
                  Text(l10n.accountActions, style: Theme.of(context).textTheme.titleLarge),
                  const SizedBox(height: 16),
                  Card(
                    elevation: 2,
                    child: ListTile(
                      leading: Icon(Icons.escalator_warning, color: Theme.of(context).primaryColor),
                      title: Text(l10n.manageChildren),
                      subtitle: Text(l10n.manageChildrenSubtitle),
                      trailing: const Icon(Icons.arrow_forward_ios),
                      onTap: () {
                        // TODO: Navegar a la pantalla de gestión de hijos.
                        ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('Próximo paso: construir esta pantalla.'))
                        );
                      },
                    ),
                  ),
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
                      subtitle: Text(l10n.becomeATeacher),
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
