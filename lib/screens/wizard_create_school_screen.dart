import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:warrior_path/models/school_model.dart';
import 'package:warrior_path/screens/wizard_discipline_hub_screen.dart';
import 'package:warrior_path/theme/martial_art_themes.dart';
import '../l10n/app_localizations.dart';

class WizardCreateSchoolScreen extends StatefulWidget {
  const WizardCreateSchoolScreen({super.key});

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
  final _disciplineNameController = TextEditingController();
  final _addressController = TextEditingController();
  final _cityController = TextEditingController();
  final _phoneController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _searchController = TextEditingController();

  File? _logoImageFile;
  bool _isLoading = false;

  // Lógica de Disciplinas
  MartialArtTheme? _selectedThemeForNewDiscipline;
  List<MartialArtTheme> _selectedDisciplines = [];

  // Lógica de Sub-Escuela
  bool _isSubSchool = false;
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
        setState(() => _searchResults = []);
      }
    });
  }

  @override
  void dispose() {
    _schoolNameController.dispose();
    _disciplineNameController.dispose();
    _addressController.dispose();
    _cityController.dispose();
    _phoneController.dispose();
    _descriptionController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _continueToNextStep() async {
    if (_schoolNameController.text.trim().isEmpty || _selectedDisciplines.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(l10n.addAtLeastOneDiscipline)));
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
        ownerId: user.uid,
        logoUrl: logoUrl,
        address: _addressController.text.trim(),
        city: _cityController.text.trim(),
        phone: _phoneController.text.trim(),
        description: _descriptionController.text.trim(),
        isSubSchool: _isSubSchool,
        parentSchoolId: _selectedParentSchool?['id'],
        parentSchoolName: _selectedParentSchool?['name'],
      );

      final firestore = FirebaseFirestore.instance;
      final schoolData = newSchool.toJson();
      schoolData['name_lowercase'] = schoolName.toLowerCase();

      // Añadimos el período de prueba gratis
      final trialExpiryDate = DateTime.now().add(const Duration(days: 30));
      schoolData['subscription'] = {
        'status': 'trial',
        'expiryDate': Timestamp.fromDate(trialExpiryDate),
      };

      final batch = firestore.batch();
      final schoolDocRef = firestore.collection('schools').doc();
      batch.set(schoolDocRef, schoolData);

      for (int i = 0; i < _selectedDisciplines.length; i++) {
        final theme = _selectedDisciplines[i];
        final disciplineRef = schoolDocRef.collection('disciplines').doc();
        batch.set(disciplineRef, {
          'name': theme.name,
          'isPrimary': i == 0,
          'theme': {
            'primaryColor': theme.primaryColor.value.toRadixString(16),
            'accentColor': theme.accentColor.value.toRadixString(16),
          },
          'createdAt': FieldValue.serverTimestamp(),
        });
      }

      final userRef = firestore.collection('users').doc(user.uid);
      batch.set(userRef, {'activeMemberships': { schoolDocRef.id: 'maestro' }}, SetOptions(merge: true));
      batch.update(userRef, {'wizardStep': 2});

      await batch.commit();

      if (!mounted) return;

      Navigator.of(context).push(
        MaterialPageRoute(
          builder: (context) => WizardDisciplineHubScreen(
            schoolId: schoolDocRef.id,
          ),
        ),
      );

    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(l10n.createSchoolError(e.toString()))));
    } finally {
      if (mounted) setState(() { _isLoading = false; });
    }
  }

  Future<void> _pickLogoImage() async {
    final pickedFile = await ImagePicker().pickImage(source: ImageSource.gallery, imageQuality: 80);
    if (pickedFile != null) setState(() => _logoImageFile = File(pickedFile.path));
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
          _searchResults = result.docs.map((doc) => {'id': doc.id, 'name': doc.data()['name'] as String}).toList();
        });
      }
    } finally {
      if (mounted) setState(() => _isSearching = false);
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


  @override
  Widget build(BuildContext context) {
    final primaryColor = _selectedDisciplines.isNotEmpty
        ? _selectedDisciplines.first.primaryColor
        : Theme.of(context).primaryColor;

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.crateSchoolStep2),
        backgroundColor: primaryColor,
      ),
      body: AbsorbPointer(
        absorbing: _isLoading,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Center(child: Stack(children: [ CircleAvatar(radius: 60, backgroundColor: Colors.grey.shade200, backgroundImage: _logoImageFile != null ? FileImage(_logoImageFile!) : null, child: _logoImageFile == null ? Icon(Icons.school, size: 60, color: Colors.grey.shade400) : null), Positioned(bottom: 0, right: 0, child: CircleAvatar(backgroundColor: primaryColor, child: IconButton(icon: const Icon(Icons.camera_alt, color: Colors.white), onPressed: _pickLogoImage)))])),
              const SizedBox(height: 24),
              TextField(controller: _schoolNameController, decoration: InputDecoration(labelText: l10n.schoolNameLabel)),
              const SizedBox(height: 24),
              const Divider(),

              Text(l10n.disciplines, style: Theme.of(context).textTheme.titleLarge),
              const SizedBox(height: 8),
              Text(l10n.selectDisciplinesPrompt),
              const SizedBox(height: 16),
              GridView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2, crossAxisSpacing: 16, mainAxisSpacing: 16, childAspectRatio: 1.5,
                ),
                itemCount: MartialArtTheme.allThemes.length,
                itemBuilder: (context, index) {
                  final theme = MartialArtTheme.allThemes[index];
                  final isSelected = _selectedDisciplines.contains(theme);

                  return GestureDetector(
                    onTap: () {
                      setState(() {
                        if (isSelected) {
                          _selectedDisciplines.remove(theme);
                        } else {
                          _selectedDisciplines.add(theme);
                        }
                      });
                    },
                    child: Card(
                      color: isSelected ? theme.primaryColor.withOpacity(0.9) : Colors.white,
                      elevation: isSelected ? 8 : 2,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                        side: isSelected ? BorderSide(color: theme.accentColor, width: 3) : const BorderSide(color: Colors.black12),
                      ),
                      child: Stack(
                        alignment: Alignment.center,
                        children: [
                          Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                            Icon(Icons.sports_martial_arts, size: 40, color: isSelected ? Colors.white : theme.primaryColor),
                            const SizedBox(height: 8),
                            Text(theme.name, style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: isSelected ? Colors.white : null)),
                          ]),
                          if(isSelected)
                            const Positioned(
                              top: 8,
                              right: 8,
                              child: Icon(Icons.check_circle, color: Colors.white, size: 20),
                            )
                        ],
                      ),
                    ),
                  );
                },
              ),

              const SizedBox(height: 24),
              SwitchListTile(
                title: Text(l10n.isSubSchool),
                value: _isSubSchool,
                onChanged: (bool value) => setState(() { _isSubSchool = value; if (!value) _selectedParentSchool = null; }),
              ),
              if (_isSubSchool) Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                const SizedBox(height: 8),
                if (_selectedParentSchool != null) Chip(label: Text(l10n.associatedWith(_selectedParentSchool!['name'])), onDeleted: () => setState(() => _selectedParentSchool = null))
                else Column(children: [
                  TextField(controller: _searchController, decoration: InputDecoration(labelText: l10n.searchParentSchool, suffixIcon: _isSearching ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2)) : const Icon(Icons.search))),
                  if (_searchResults.isNotEmpty) SizedBox(height: 150, child: ListView.builder(shrinkWrap: true, itemCount: _searchResults.length, itemBuilder: (context, index) {
                    final school = _searchResults[index];
                    return ListTile(title: Text(school['name']), onTap: () => _onParentSchoolSelected(school));
                  })),
                ]),
                const SizedBox(height: 8),
                Text(l10n.associateLaterMessage, style: const TextStyle(fontSize: 12, color: Colors.grey)),
              ]),
              const SizedBox(height: 24),
              const Divider(),
              const SizedBox(height: 16),
              Text(l10n.institutionalDataOptional, style: Theme.of(context).textTheme.titleMedium), // <-- TEXTO CORREGIDO
              const SizedBox(height: 16),
              TextField(controller: _addressController, decoration: InputDecoration(labelText: l10n.address)),
              const SizedBox(height: 16),
              TextField(controller: _cityController, decoration: InputDecoration(labelText: l10n.city)),
              const SizedBox(height: 16),
              TextField(controller: _phoneController, decoration: InputDecoration(labelText: l10n.phone), keyboardType: TextInputType.phone),
              const SizedBox(height: 16),
              TextField(controller: _descriptionController, decoration: InputDecoration(labelText: l10n.description), maxLines: 3),
              const SizedBox(height: 32),
              if (_isLoading)
                const Center(child: CircularProgressIndicator())
              else
                ElevatedButton(
                  style: ElevatedButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 16), backgroundColor: primaryColor),
                  onPressed: _continueToNextStep,
                  child: Text(l10n.saveAndContinue, style: const TextStyle(color: Colors.white)),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
