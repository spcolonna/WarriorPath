import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';

import '../../l10n/app_localizations.dart'; // --- CAMBIO: Importamos intl

class EditTeacherProfileScreen extends StatefulWidget {
  const EditTeacherProfileScreen({Key? key}) : super(key: key);

  @override
  State<EditTeacherProfileScreen> createState() => _EditTeacherProfileScreenState();
}

class _EditTeacherProfileScreenState extends State<EditTeacherProfileScreen> {
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

  String? _selectedSex;
  DateTime? _selectedDateOfBirth;
  File? _newImageFile;
  String? _currentPhotoUrl;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _userDataFuture = _fetchUserData();
  }

  Future<DocumentSnapshot> _fetchUserData() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) throw Exception('No hay usuario autenticado');

    final userDoc = await FirebaseFirestore.instance.collection('users').doc(user.uid).get();

    if (userDoc.exists && mounted) {
      final data = userDoc.data() as Map<String, dynamic>;
      _nameController.text = data['displayName'] ?? '';
      _phoneController.text = data['phoneNumber'] ?? '';
      _currentPhotoUrl = data['photoUrl'];

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

  Future<void> _pickImage() async {
    final pickedFile = await ImagePicker().pickImage(source: ImageSource.gallery, imageQuality: 80);
    if (pickedFile != null) {
      setState(() {
        _newImageFile = File(pickedFile.path);
      });
    }
  }

  Future<void> _saveChanges() async {
    setState(() { _isSaving = true; });
    try {
      final user = FirebaseAuth.instance.currentUser!;
      String? newPhotoUrl;

      if (_newImageFile != null) {
        final ref = FirebaseStorage.instance.ref().child('profile_pics').child('${user.uid}.jpg');
        await ref.putFile(_newImageFile!);
        newPhotoUrl = await ref.getDownloadURL();
      }

      final dataToUpdate = {
        'displayName': _nameController.text.trim(),
        'phoneNumber': _phoneController.text.trim(),
        if (newPhotoUrl != null) 'photoUrl': newPhotoUrl,
        'gender': _selectedSex,
        'dateOfBirth': _selectedDateOfBirth,
      };

      await FirebaseFirestore.instance.collection('users').doc(user.uid).update(dataToUpdate);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Perfil actualizado con éxito.'), backgroundColor: Colors.green));
        Navigator.of(context).pop();
      }
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(l10n.saveError(e.toString()))));
    } finally {
      if (mounted) setState(() { _isSaving = false; });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(l10n.editMyProfile)),
      body: FutureBuilder<DocumentSnapshot>(
        future: _userDataFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError || !snapshot.data!.exists) {
            return const Center(child: Text('No se pudo cargar el perfil.'));
          }

          return AbsorbPointer(
            absorbing: _isSaving,
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
                          backgroundImage: _newImageFile != null
                              ? FileImage(_newImageFile!) as ImageProvider
                              : (_currentPhotoUrl != null && _currentPhotoUrl!.isNotEmpty)
                              ? NetworkImage(_currentPhotoUrl!)
                              : null,
                          child: _newImageFile == null && (_currentPhotoUrl == null || _currentPhotoUrl!.isEmpty)
                              ? Icon(Icons.person, size: 60, color: Colors.grey.shade400)
                              : null,
                        ),
                        Positioned(bottom: 0, right: 0, child: CircleAvatar(
                          child: IconButton(icon: const Icon(Icons.camera_alt, color: Colors.white), onPressed: _pickImage),
                        )),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),
                  TextFormField(controller: _nameController, decoration: const InputDecoration(labelText: 'Nombre y Apellido', border: OutlineInputBorder())),
                  const SizedBox(height: 16),
                  TextFormField(controller: _phoneController, decoration: InputDecoration(labelText: l10n.phone, border: OutlineInputBorder()), keyboardType: TextInputType.phone),

                  const SizedBox(height: 16),
                  DropdownButtonFormField<String>(
                    value: _selectedSex,
                    decoration:  InputDecoration(labelText: l10n.gender, border: OutlineInputBorder()),
                    items: [l10n.maleGender, l10n.femaleGender, l10n.otherGender, l10n.noSpecifyGender]
                        .map((label) => DropdownMenuItem(
                      value: label.toLowerCase().replaceAll(' ', '_'),
                      child: Text(label),
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
                  if (_isSaving)
                    const Center(child: CircularProgressIndicator())
                  else
                    ElevatedButton.icon(
                      icon: const Icon(Icons.save),
                      label: Text('Guardar Cambios'),
                      style: ElevatedButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 16)),
                      onPressed: _saveChanges,
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
