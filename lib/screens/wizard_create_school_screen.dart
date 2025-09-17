import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:warrior_path/models/school_model.dart';
import 'package:warrior_path/screens/wizard_configure_levels_screen.dart';
import 'package:warrior_path/theme/AppColors.dart';
import 'package:warrior_path/theme/martial_art_themes.dart';

import '../l10n/app_localizations.dart';

class WizardCreateSchoolScreen extends StatefulWidget {
  const WizardCreateSchoolScreen({Key? key}) : super(key: key);

  @override
  _WizardCreateSchoolScreenState createState() => _WizardCreateSchoolScreenState();
}

class _WizardCreateSchoolScreenState extends State<WizardCreateSchoolScreen> {
  late AppLocalizations l10n;
  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    l10n = AppLocalizations.of(context);
  }
  final _schoolNameController = TextEditingController();
  final _addressController = TextEditingController();
  final _cityController = TextEditingController();
  final _phoneController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _searchController = TextEditingController();

  MartialArtTheme? _selectedMartialArtTheme;
  File? _logoImageFile;
  bool _isSubSchool = false;
  bool _isLoading = false;
  bool _isSearching = false;

  List<Map<String, dynamic>> _searchResults = [];
  Map<String, dynamic>? _selectedParentSchool;

  @override
  void initState() {
    super.initState();
    _searchController.addListener(() {
      if (_searchController.text.length > 2) {
        _searchSchools(_searchController.text);
      } else if (_searchController.text.isEmpty) {
        setState(() {
          _searchResults = [];
        });
      }
    });
  }

  @override
  void dispose() {
    _schoolNameController.dispose();
    _addressController.dispose();
    _cityController.dispose();
    _phoneController.dispose();
    _descriptionController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _pickLogoImage() async {
    final pickedFile = await ImagePicker().pickImage(source: ImageSource.gallery, imageQuality: 80);
    if (pickedFile != null) {
      setState(() {
        _logoImageFile = File(pickedFile.path);
      });
    }
  }

  Future<void> _searchSchools(String query) async {
    if (!mounted) return;
    setState(() { _isSearching = true; });
    try {
      final result = await FirebaseFirestore.instance
          .collection('schools')
          .where('name_lowercase', isGreaterThanOrEqualTo: query.toLowerCase())
          .where('name_lowercase', isLessThanOrEqualTo: '${query.toLowerCase()}\uf8ff')
          .limit(5)
          .get();
      if (mounted) {
        setState(() {
          _searchResults = result.docs
              .map((doc) => {'id': doc.id, 'name': doc.data()['name'] as String})
              .toList();
          _isSearching = false;
        });
      }
    } catch (e) {
      print("Error al buscar escuelas: $e");
      if (mounted) {
        setState(() { _isSearching = false; });
      }
    }
  }

  void _onParentSchoolSelected(Map<String, dynamic> school) {
    setState(() {
      _selectedParentSchool = school;
      _searchResults = [];
      _searchController.clear();
      FocusScope.of(context).unfocus();
    });
  }

  Future<void> _continueToNextStep() async {
    if (_schoolNameController.text.trim().isEmpty || _selectedMartialArtTheme == null) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(l10n.nameAndMartialArtRequired)));
      return;
    }
    if (_isSubSchool && _selectedParentSchool == null) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(l10n.needSelectSubSchool)));
      return;
    }

    setState(() { _isLoading = true; });

    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) throw Exception(l10n.notAuthenticatedUser);

      String? logoUrl;
      if (_logoImageFile != null) {
        final ref = FirebaseStorage.instance.ref().child('school_logos').child('${user.uid}_${DateTime.now().toIso8601String()}.jpg');
        await ref.putFile(_logoImageFile!);
        logoUrl = await ref.getDownloadURL();
      }

      final schoolName = _schoolNameController.text.trim();

      final newSchool = SchoolModel(
        name: schoolName,
        logoUrl: logoUrl,
        martialArt: _selectedMartialArtTheme!.name,
        ownerId: user.uid,
        address: _addressController.text.trim(),
        city: _cityController.text.trim(),
        phone: _phoneController.text.trim(),
        description: _descriptionController.text.trim(),
        isSubSchool: _isSubSchool,
        parentSchoolId: _selectedParentSchool?['id'],
        parentSchoolName: _selectedParentSchool?['name'],
        theme: {
          'primaryColor': _selectedMartialArtTheme!.primaryColor.value.toRadixString(16),
          'accentColor': _selectedMartialArtTheme!.accentColor.value.toRadixString(16),
        },
      );

      final firestore = FirebaseFirestore.instance;
      final schoolData = newSchool.toJson();
      schoolData['name_lowercase'] = schoolName.toLowerCase();

      // --- INICIO DE LA MODIFICACIÓN (Tarea 1: Prueba Gratis) ---
      // Calculamos la fecha de vencimiento para 30 días a partir de ahora.
      final trialExpiryDate = DateTime.now().add(const Duration(days: 30));

      // Añadimos el mapa de suscripción al documento de la escuela.
      schoolData['subscription'] = {
        'status': 'trial', // Un estado para saber que está en período de prueba
        'expiryDate': Timestamp.fromDate(trialExpiryDate),
      };

      final schoolDocRef = await firestore.collection('schools').add(schoolData);

      final userRef = firestore.collection('users').doc(user.uid);
      await userRef.set({'activeMemberships': { schoolDocRef.id: 'maestro' }}, SetOptions(merge: true));
      await userRef.update({'wizardStep': 2});

      if (!mounted) return;

      Navigator.of(context).push(
        MaterialPageRoute(
          builder: (context) => WizardConfigureLevelsScreen(
            schoolId: schoolDocRef.id,
            martialArtTheme: _selectedMartialArtTheme!,
          ),
        ),
      );

    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(l10n.createSchoolError(e.toString()))));
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
        title: Text(l10n.crateSchoolStep2),
        backgroundColor: _selectedMartialArtTheme?.primaryColor ?? AppColors.primaryColor,
      ),
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
                      backgroundColor: Colors.grey.shade200,
                      backgroundImage: _logoImageFile != null ? FileImage(_logoImageFile!) : null,
                      child: _logoImageFile == null ? Icon(Icons.school, size: 60, color: Colors.grey.shade400) : null,
                    ),
                    Positioned(
                      bottom: 0,
                      right: 0,
                      child: CircleAvatar(
                        backgroundColor: _selectedMartialArtTheme?.primaryColor ?? Theme.of(context).primaryColor,
                        child: IconButton(
                          icon: const Icon(Icons.camera_alt, color: Colors.white),
                          onPressed: _pickLogoImage,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),
              TextField(controller: _schoolNameController, decoration: const InputDecoration(labelText: 'Nombre de tu Escuela *')),
              const SizedBox(height: 24),
              Text('Selecciona el Arte Marcial principal *', style: Theme.of(context).textTheme.titleMedium),
              const SizedBox(height: 16),
              GridView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: 2, crossAxisSpacing: 16, mainAxisSpacing: 16, childAspectRatio: 1.5),
                itemCount: MartialArtTheme.allThemes.length,
                itemBuilder: (context, index) {
                  final theme = MartialArtTheme.allThemes[index];
                  final isSelected = _selectedMartialArtTheme?.name == theme.name;
                  return GestureDetector(
                    onTap: () => setState(() { _selectedMartialArtTheme = theme; }),
                    child: Card(
                      color: isSelected ? theme.primaryColor.withOpacity(0.8) : Colors.grey.shade100,
                      elevation: isSelected ? 8 : 2,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12), side: isSelected ? BorderSide(color: theme.accentColor, width: 3) : BorderSide.none),
                      child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                        Icon(Icons.sports_martial_arts, size: 40, color: isSelected ? Colors.white : theme.primaryColor),
                        const SizedBox(height: 8),
                        Text(theme.name, style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: isSelected ? Colors.white : AppColors.textDark)),
                      ]),
                    ),
                  );
                },
              ),
              const SizedBox(height: 16),
              SwitchListTile(
                title: const Text('¿Es una Sub-Escuela?'),
                value: _isSubSchool,
                onChanged: (bool value) {
                  setState(() {
                    _isSubSchool = value;
                    if (!value) _selectedParentSchool = null;
                  });
                },
              ),
              if (_isSubSchool)
                Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  const SizedBox(height: 8),
                  if (_selectedParentSchool != null)
                    Chip(label: Text('Asociada a: ${_selectedParentSchool!['name']}'), onDeleted: () => setState(() { _selectedParentSchool = null; }))
                  else
                    Column(children: [
                      TextField(controller: _searchController, decoration: InputDecoration(labelText: 'Buscar escuela principal', suffixIcon: _isSearching ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2)) : const Icon(Icons.search))),
                      if (_searchResults.isNotEmpty)
                        SizedBox(height: 150, child: ListView.builder(shrinkWrap: true, itemCount: _searchResults.length, itemBuilder: (context, index) {
                          final school = _searchResults[index];
                          return ListTile(title: Text(school['name']), onTap: () => _onParentSchoolSelected(school));
                        })),
                    ]),
                  const SizedBox(height: 8),
                  const Text('Si no encuentras la escuela, puedes asociarla más tarde desde el panel de gestión.', style: TextStyle(fontSize: 12, color: Colors.grey)),
                ]),
              const SizedBox(height: 24),
              const Divider(),
              const SizedBox(height: 16),
              Text('Datos Institucionales', style: Theme.of(context).textTheme.titleMedium),
              const SizedBox(height: 16),
              TextField(controller: _addressController, decoration: const InputDecoration(labelText: 'Dirección')),
              const SizedBox(height: 16),
              TextField(controller: _cityController, decoration: const InputDecoration(labelText: 'Ciudad')),
              const SizedBox(height: 16),
              TextField(controller: _phoneController, decoration: const InputDecoration(labelText: 'Teléfono de Contacto'), keyboardType: TextInputType.phone),
              const SizedBox(height: 16),
              TextField(controller: _descriptionController, decoration: const InputDecoration(labelText: 'Descripción breve'), maxLines: 3),
              const SizedBox(height: 32),
              if (_isLoading)
                const Center(child: CircularProgressIndicator())
              else
                ElevatedButton(
                  style: ElevatedButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 16), backgroundColor: _selectedMartialArtTheme?.primaryColor ?? AppColors.primaryColor),
                  onPressed: _continueToNextStep,
                  child: Text(l10n.saveAndContinue, style: TextStyle(color: Colors.white)),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
