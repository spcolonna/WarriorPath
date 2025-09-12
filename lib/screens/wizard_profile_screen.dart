import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import 'package:warrior_path/screens/student/school_search_screen.dart';
import 'package:warrior_path/screens/wizard_create_school_screen.dart';

enum UserRole { student, teacher, both }

class WizardProfileScreen extends StatefulWidget {
  final bool isExistingUser;

  const WizardProfileScreen({Key? key, this.isExistingUser = false}) : super(key: key);

  @override
  _WizardProfileScreenState createState() => _WizardProfileScreenState();
}

class _WizardProfileScreenState extends State<WizardProfileScreen> {
  final _nameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _dobController = TextEditingController();

  UserRole? _selectedRole;
  File? _imageFile;
  bool _isLoading = false;
  String? _uid;

  // --- CAMBIO: Variables de estado para los nuevos campos ---
  String? _selectedSex;
  DateTime? _selectedDateOfBirth;

  @override
  void initState() {
    super.initState();
    _uid = FirebaseAuth.instance.currentUser?.uid;
    if (widget.isExistingUser && _uid != null) {
      _loadExistingUserData();
    }
  }

  @override
  void dispose() {
    // --- CAMBIO: Hacemos dispose del nuevo controller ---
    _nameController.dispose();
    _phoneController.dispose();
    _dobController.dispose();
    super.dispose();
  }

  Future<void> _loadExistingUserData() async {
    final userDoc = await FirebaseFirestore.instance.collection('users').doc(_uid).get();
    if (userDoc.exists && mounted) {
      final data = userDoc.data()!;
      setState(() {
        _nameController.text = data['displayName'] ?? '';
        _phoneController.text = data['phoneNumber'] ?? '';

        // --- CAMBIO: Cargamos los datos nuevos si existen ---
        _selectedSex = data['gender'];
        _selectedDateOfBirth = (data['dateOfBirth'] as Timestamp?)?.toDate();
        if (_selectedDateOfBirth != null) {
          _dobController.text = DateFormat('dd/MM/yyyy', 'es_ES').format(_selectedDateOfBirth!);
        }
      });
    }
  }

  void _updateRole(UserRole role) {
    setState(() {
      _selectedRole = role;
    });
  }

  Future<void> _pickImage() async {
    final pickedFile = await ImagePicker().pickImage(source: ImageSource.gallery, imageQuality: 50);
    if (pickedFile != null) {
      setState(() {
        _imageFile = File(pickedFile.path);
      });
    }
  }

  // --- CAMBIO: Nueva función para mostrar el selector de fecha ---
  Future<void> _selectDateOfBirth(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedDateOfBirth ?? DateTime(2000), // Fecha inicial por defecto
      firstDate: DateTime(1920), // Año mínimo
      lastDate: DateTime.now(),   // No se puede nacer en el futuro
      locale: const Locale('es', 'ES'),
    );
    if (picked != null && picked != _selectedDateOfBirth) {
      setState(() {
        _selectedDateOfBirth = picked;
        _dobController.text = DateFormat('dd/MM/yyyy', 'es_ES').format(picked);
      });
    }
  }

  Future<void> _saveAndContinue() async {
    if (_nameController.text.trim().isEmpty || _selectedRole == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Nombre y rol son requeridos.')),
      );
      return;
    }
    if (_uid == null) return;

    setState(() { _isLoading = true; });

    try {
      String? photoUrl;
      if (_imageFile != null) {
        final ref = FirebaseStorage.instance.ref().child('profile_pics').child('$_uid.jpg');
        await ref.putFile(_imageFile!);
        photoUrl = await ref.getDownloadURL();
      }

      // --- CAMBIO: Añadimos los nuevos campos al mapa que se guarda ---
      final dataToUpdate = <String, dynamic>{
        'displayName': _nameController.text.trim(),
        'phoneNumber': _phoneController.text.trim(),
        'role': _selectedRole.toString().split('.').last,
        'wizardStep': 1,
        'gender': _selectedSex,
        'dateOfBirth': _selectedDateOfBirth, // El modelo se encargará de convertirlo a Timestamp
      };
      if (photoUrl != null) {
        dataToUpdate['photoUrl'] = photoUrl;
      }

      final userRef = FirebaseFirestore.instance.collection('users').doc(_uid);
      await userRef.set(dataToUpdate, SetOptions(merge: true));

      if (!mounted) return;

      if (_selectedRole == UserRole.student) {
        Navigator.of(context).push(
            MaterialPageRoute(builder: (context) => const SchoolSearchScreen(isFromWizard: true)));
      } else {
        Navigator.of(context).push(
            MaterialPageRoute(builder: (context) => const WizardCreateSchoolScreen()));
      }

    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error al guardar: ${e.toString()}')),
      );
    } finally {
      if (mounted) {
        setState(() { _isLoading = false; });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(widget.isExistingUser ? 'Elige tu Rol' : 'Completa tu Perfil (Paso 1)')),
      body: AbsorbPointer(
        absorbing: _isLoading,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Center(
                child: Stack(
                  children: [
                    CircleAvatar(
                      radius: 60,
                      backgroundColor: Colors.grey.shade300,
                      backgroundImage: _imageFile != null ? FileImage(_imageFile!) : null,
                      child: _imageFile == null ? const Icon(Icons.person, size: 60, color: Colors.white) : null,
                    ),
                    Positioned(
                      bottom: 0,
                      right: 0,
                      child: IconButton(
                        icon: const Icon(Icons.camera_alt),
                        onPressed: _pickImage,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),
              TextFormField(
                controller: _nameController,
                decoration: const InputDecoration(labelText: 'Nombre y Apellido *'),
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _phoneController,
                decoration: const InputDecoration(labelText: 'Teléfono de Contacto'),
                keyboardType: TextInputType.phone,
              ),

              // --- CAMBIO: Widgets para los nuevos campos ---
              const SizedBox(height: 16),
              DropdownButtonFormField<String>(
                value: _selectedSex,
                decoration: const InputDecoration(labelText: 'Género'),
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
                decoration: const InputDecoration(
                  labelText: 'Fecha de Nacimiento',
                  suffixIcon: Icon(Icons.calendar_today),
                ),
                readOnly: true, // Para que no se pueda escribir, solo seleccionar
                onTap: () {
                  // Llamamos a nuestra nueva función al tocar el campo
                  _selectDateOfBirth(context);
                },
              ),
              // --- FIN DEL CAMBIO ---

              const SizedBox(height: 24),
              Text('¿Cómo quieres empezar? *', style: Theme.of(context).textTheme.titleMedium),
              const SizedBox(height: 8),

              SegmentedButton<UserRole>(
                segments: const <ButtonSegment<UserRole>>[
                  ButtonSegment<UserRole>(
                      value: UserRole.student,
                      label: Flexible(child: Text('Estudiante')),
                      icon: Icon(Icons.school)
                  ),
                  ButtonSegment<UserRole>(
                      value: UserRole.teacher,
                      label: Flexible(child: Text('Profesor')),
                      icon: Icon(Icons.sports_kabaddi)
                  ),
                  ButtonSegment<UserRole>(
                      value: UserRole.both,
                      label: Flexible(child: Text('Ambos')),
                      icon: Icon(Icons.group)
                  ),
                ],
                selected: _selectedRole != null ? <UserRole>{_selectedRole!} : <UserRole>{},
                onSelectionChanged: (Set<UserRole> newSelection) {
                  if (newSelection.isNotEmpty) {
                    _updateRole(newSelection.first);
                  }
                },
                emptySelectionAllowed: true,
                showSelectedIcon: false,
              ),

              const SizedBox(height: 16),
              if (_selectedRole == UserRole.teacher || _selectedRole == UserRole.both)
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.blue.shade50,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Text(
                    'Al elegir "Profesor" o "Ambos", el siguiente paso será crear tu propia escuela.',
                    textAlign: TextAlign.center,
                  ),
                ),
              const SizedBox(height: 32),
              if (_isLoading)
                const Center(child: CircularProgressIndicator())
              else
                ElevatedButton(
                  style: ElevatedButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 16)),
                  onPressed: _saveAndContinue,
                  child: const Text('Guardar y Continuar'),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
