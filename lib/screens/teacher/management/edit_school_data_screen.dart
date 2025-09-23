import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:warrior_path/models/discipline_model.dart';
import 'package:warrior_path/theme/martial_art_themes.dart';

import '../../../l10n/app_localizations.dart';

class EditSchoolDataScreen extends StatefulWidget {
  final String schoolId;
  const EditSchoolDataScreen({super.key, required this.schoolId});

  @override
  State<EditSchoolDataScreen> createState() => _EditSchoolDataScreenState();
}

class _EditSchoolDataScreenState extends State<EditSchoolDataScreen> {
  late AppLocalizations l10n;
  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    l10n = AppLocalizations.of(context);
  }

  final _nameController = TextEditingController();
  final _addressController = TextEditingController();
  final _cityController = TextEditingController();
  final _phoneController = TextEditingController();
  final _descriptionController = TextEditingController();

  String? _currentLogoUrl;
  File? _newLogoImageFile;
  bool _isLoading = true;
  bool _isSaving = false;

  List<DisciplineModel> _disciplines = [];

  @override
  void initState() {
    super.initState();
    _fetchSchoolData();
  }

  Future<void> _fetchSchoolData() async {
    setState(() => _isLoading = true);
    try {
      final schoolDocFuture = FirebaseFirestore.instance.collection('schools').doc(widget.schoolId).get();
      final disciplinesFuture = FirebaseFirestore.instance.collection('schools').doc(widget.schoolId).collection('disciplines').get();

      final results = await Future.wait([schoolDocFuture, disciplinesFuture]);

      final schoolDoc = results[0] as DocumentSnapshot<Map<String, dynamic>>;
      if (schoolDoc.exists) {
        final data = schoolDoc.data()!;
        _nameController.text = data['name'] ?? '';
        _addressController.text = data['address'] ?? '';
        _cityController.text = data['city'] ?? '';
        _phoneController.text = data['phone'] ?? '';
        _descriptionController.text = data['description'] ?? '';
        _currentLogoUrl = data['logoUrl'];
      }

      final disciplinesSnapshot = results[1] as QuerySnapshot;
      _disciplines = disciplinesSnapshot.docs.map((doc) => DisciplineModel.fromFirestore(doc)).toList();

    } catch (e) {
      if(mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error al cargar datos: ${e.toString()}')));
    } finally {
      if(mounted) setState(() => _isLoading = false);
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _addressController.dispose();
    _cityController.dispose();
    _phoneController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  Future<void> _pickLogoImage() async {
    final pickedFile = await ImagePicker().pickImage(source: ImageSource.gallery, imageQuality: 80);
    if (pickedFile != null) setState(() => _newLogoImageFile = File(pickedFile.path));
  }

  void _showAddDisciplineDialog() {
    final disciplineNameController = TextEditingController();
    MartialArtTheme? selectedTheme;

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(l10n.newDiscipline),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(controller: disciplineNameController, decoration: InputDecoration(labelText: l10n.disciplineName)),
            const SizedBox(height: 16),
            DropdownButtonFormField<MartialArtTheme>(
              value: selectedTheme,
              hint: Text(l10n.baseStyle),
              decoration: const InputDecoration(border: OutlineInputBorder()),
              items: MartialArtTheme.allThemes.map((theme) => DropdownMenuItem(value: theme, child: Text(theme.name))).toList(),
              onChanged: (theme) => selectedTheme = theme,
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.of(ctx).pop(), child: Text(l10n.cancel)),
          ElevatedButton(
            onPressed: () {
              if (disciplineNameController.text.trim().isNotEmpty && selectedTheme != null) {
                setState(() {
                  _disciplines.add(DisciplineModel(
                    name: disciplineNameController.text.trim(),
                    theme: {
                      'primaryColor': selectedTheme!.primaryColor.value.toRadixString(16),
                      'accentColor': selectedTheme!.accentColor.value.toRadixString(16),
                    },
                    isActive: true,
                  ));
                });
                Navigator.of(ctx).pop();
              }
            },
            child: Text(l10n.addDiscipline),
          ),
        ],
      ),
    );
  }

  Future<void> _saveChanges() async {
    setState(() { _isSaving = true; });
    try {
      String? newLogoUrl;
      if (_newLogoImageFile != null) {
        final ref = FirebaseStorage.instance.ref().child('school_logos').child('${widget.schoolId}_${DateTime.now().toIso8601String()}.jpg');
        await ref.putFile(_newLogoImageFile!);
        newLogoUrl = await ref.getDownloadURL();
      }

      final schoolName = _nameController.text.trim();
      final Map<String, dynamic> dataToUpdate = {
        'name': schoolName, 'name_lowercase': schoolName.toLowerCase(), 'address': _addressController.text.trim(),
        'city': _cityController.text.trim(), 'phone': _phoneController.text.trim(), 'description': _descriptionController.text.trim(),
      };

      if (newLogoUrl != null) {
        dataToUpdate['logoUrl'] = newLogoUrl;
      }

      final firestore = FirebaseFirestore.instance;
      final schoolRef = firestore.collection('schools').doc(widget.schoolId);
      final batch = firestore.batch();

      // 1. Actualizamos los datos de la escuela
      batch.update(schoolRef, dataToUpdate);

      // 2. Actualizamos/Creamos las disciplinas
      for (final discipline in _disciplines) {
        if (discipline.id == null) { // Nueva disciplina
          batch.set(schoolRef.collection('disciplines').doc(), discipline.toJson());
        } else { // Disciplina existente
          batch.update(schoolRef.collection('disciplines').doc(discipline.id), discipline.toJson());
        }
      }

      await batch.commit();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(l10n.schoolDataUpdated), backgroundColor: Colors.green));
        Navigator.of(context).pop();
      }
    } catch (e) {
      if(mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(l10n.saveError(e.toString()))));
    } finally {
      if(mounted) setState(() { _isSaving = false; });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(l10n.editSchoolData)),
      body: _isLoading ? const Center(child: CircularProgressIndicator()) : AbsorbPointer(
        absorbing: _isSaving,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Center(child: Stack(children: [
                CircleAvatar(
                  radius: 60, backgroundColor: Colors.grey.shade200,
                  backgroundImage: _newLogoImageFile != null ? FileImage(_newLogoImageFile!) as ImageProvider : (_currentLogoUrl != null && _currentLogoUrl!.isNotEmpty) ? NetworkImage(_currentLogoUrl!) : null,
                  child: _newLogoImageFile == null && (_currentLogoUrl == null || _currentLogoUrl!.isEmpty) ? Icon(Icons.school, size: 60, color: Colors.grey.shade400) : null,
                ),
                Positioned(bottom: 0, right: 0, child: CircleAvatar(child: IconButton(icon: const Icon(Icons.camera_alt, color: Colors.white), onPressed: _pickLogoImage))),
              ])),
              const SizedBox(height: 24),
              TextFormField(controller: _nameController, decoration: InputDecoration(labelText: l10n.schoolNameLabel, border: const OutlineInputBorder())),
              const SizedBox(height: 16),
              TextFormField(controller: _addressController, decoration: InputDecoration(labelText: l10n.address, border: const OutlineInputBorder())),
              const SizedBox(height: 16),
              TextFormField(controller: _cityController, decoration: InputDecoration(labelText: l10n.city, border: const OutlineInputBorder())),
              const SizedBox(height: 16),
              TextFormField(controller: _phoneController, decoration: InputDecoration(labelText: l10n.phone, border: const OutlineInputBorder()), keyboardType: TextInputType.phone),
              const SizedBox(height: 16),
              TextFormField(controller: _descriptionController, decoration: InputDecoration(labelText: l10n.description, border: const OutlineInputBorder()), maxLines: 4),

              const Divider(height: 40),

              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(l10n.manageDisciplines, style: Theme.of(context).textTheme.titleLarge),
                  IconButton(
                    icon: const Icon(Icons.add_circle_outline),
                    onPressed: _showAddDisciplineDialog,
                    tooltip: l10n.addDiscipline,
                  ),
                ],
              ),
              const SizedBox(height: 8),
              if (_disciplines.isEmpty)
                Center(child: Text(l10n.noDisciplinesAdded))
              else
                ListView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: _disciplines.length,
                  itemBuilder: (context, index) {
                    final discipline = _disciplines[index];
                    return Card(
                      child: SwitchListTile(
                        title: Text(discipline.name),
                        value: discipline.isActive,
                        onChanged: (bool value) {
                          setState(() {
                            _disciplines[index].isActive = value;
                          });
                        },
                        subtitle: Text(discipline.isActive ? l10n.active : l10n.inactive, style: TextStyle(color: discipline.isActive ? Colors.green : Colors.red)),
                      ),
                    );
                  },
                ),

              const SizedBox(height: 32),
              if (_isSaving)
                const Center(child: CircularProgressIndicator())
              else
                ElevatedButton.icon(
                  icon: const Icon(Icons.save),
                  label: Text(l10n.saveChanges),
                  style: ElevatedButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 16)),
                  onPressed: _saveChanges,
                ),
            ],
          ),
        ),
      ),
    );
  }
}
