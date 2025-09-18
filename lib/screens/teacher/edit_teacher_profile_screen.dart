import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';

import '../../l10n/app_localizations.dart';

class EditTeacherProfileScreen extends StatefulWidget {
  const EditTeacherProfileScreen({super.key});

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

  File? _newImageFile;
  String? _currentPhotoUrl;
  bool _isSaving = false;

  String? _selectedGender;
  DateTime? _selectedDateOfBirth;

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

      // --- Usamos 'gender' consistentemente ---
      _selectedGender = data['gender'];
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

  Future<void> _pickImage() async {
    final pickedFile = await ImagePicker().pickImage(source: ImageSource.gallery, imageQuality: 80);
    if (pickedFile != null) setState(() => _newImageFile = File(pickedFile.path));
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
        'gender': _selectedGender,
        'dateOfBirth': _selectedDateOfBirth,
      };

      await FirebaseFirestore.instance.collection('users').doc(user.uid).update(dataToUpdate);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(l10n.updateProfileSuccess), backgroundColor: Colors.green));
        Navigator.of(context).pop();
      }
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(l10n.profileUpdateError(e.toString()))));
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
            return Center(child: Text(l10n.profileLoadedError));
          }

          final Map<String, String> genderOptions = {
            'masculino': l10n.maleGender,
            'femenino': l10n.femaleGender,
            'otro': l10n.otherGender,
            'prefiero_no_decirlo': l10n.noSpecifyGender,
          };
          final bool isValueValid = _selectedGender != null && genderOptions.containsKey(_selectedGender);

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
                          backgroundImage: _newImageFile != null ? FileImage(_newImageFile!) as ImageProvider : (_currentPhotoUrl != null && _currentPhotoUrl!.isNotEmpty) ? NetworkImage(_currentPhotoUrl!) : null,
                          child: _newImageFile == null && (_currentPhotoUrl == null || _currentPhotoUrl!.isEmpty) ? Icon(Icons.person, size: 60, color: Colors.grey.shade400) : null,
                        ),
                        Positioned(bottom: 0, right: 0, child: CircleAvatar(
                          child: IconButton(icon: const Icon(Icons.camera_alt, color: Colors.white), onPressed: _pickImage),
                        )),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),
                  TextFormField(controller: _nameController, decoration: InputDecoration(labelText: l10n.fullName, border: const OutlineInputBorder())),
                  const SizedBox(height: 16),
                  TextFormField(controller: _phoneController, decoration: InputDecoration(labelText: l10n.phone, border: const OutlineInputBorder()), keyboardType: TextInputType.phone),
                  const SizedBox(height: 16),

                  DropdownButtonFormField<String>(
                    value: isValueValid ? _selectedGender : null,
                    decoration: InputDecoration(labelText: l10n.gender, border: const OutlineInputBorder()),
                    items: genderOptions.entries.map((entry) {
                      return DropdownMenuItem(value: entry.key, child: Text(entry.value));
                    }).toList(),
                    onChanged: (value) => setState(() => _selectedGender = value),
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _dobController,
                    decoration: InputDecoration(labelText: l10n.birdthDate, border: const OutlineInputBorder(), suffixIcon: const Icon(Icons.calendar_today)),
                    readOnly: true,
                    onTap: () => _selectDateOfBirth(context),
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
          );
        },
      ),
    );
  }
}
