import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

class EditTeacherProfileScreen extends StatefulWidget {
  const EditTeacherProfileScreen({Key? key}) : super(key: key);

  @override
  State<EditTeacherProfileScreen> createState() => _EditTeacherProfileScreenState();
}

class _EditTeacherProfileScreenState extends State<EditTeacherProfileScreen> {
  late Future<DocumentSnapshot> _userDataFuture;
  final _nameController = TextEditingController();
  final _phoneController = TextEditingController();

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
    }
    return userDoc;
  }

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    super.dispose();
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
      };

      await FirebaseFirestore.instance.collection('users').doc(user.uid).update(dataToUpdate);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Perfil actualizado con éxito.'), backgroundColor: Colors.green));
        Navigator.of(context).pop();
      }
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error al guardar: ${e.toString()}')));
    } finally {
      if (mounted) setState(() { _isSaving = false; });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Editar Mi Perfil')),
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
                  TextFormField(controller: _phoneController, decoration: const InputDecoration(labelText: 'Teléfono', border: OutlineInputBorder()), keyboardType: TextInputType.phone),
                  const SizedBox(height: 32),
                  if (_isSaving)
                    const Center(child: CircularProgressIndicator())
                  else
                    ElevatedButton.icon(
                      icon: const Icon(Icons.save),
                      label: const Text('Guardar Cambios'),
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
