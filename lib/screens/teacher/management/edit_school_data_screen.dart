import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

class EditSchoolDataScreen extends StatefulWidget {
  final String schoolId;
  const EditSchoolDataScreen({Key? key, required this.schoolId}) : super(key: key);

  @override
  State<EditSchoolDataScreen> createState() => _EditSchoolDataScreenState();
}

class _EditSchoolDataScreenState extends State<EditSchoolDataScreen> {
  final _nameController = TextEditingController();
  final _addressController = TextEditingController();
  final _cityController = TextEditingController();
  final _phoneController = TextEditingController();
  final _descriptionController = TextEditingController();

  String? _currentLogoUrl;
  File? _newLogoImageFile;

  bool _isLoading = true;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _fetchSchoolData();
  }

  Future<void> _fetchSchoolData() async {
    setState(() => _isLoading = true);
    try {
      final schoolDoc = await FirebaseFirestore.instance.collection('schools').doc(widget.schoolId).get();
      if (schoolDoc.exists && mounted) {
        final data = schoolDoc.data()!;
        _nameController.text = data['name'] ?? '';
        _addressController.text = data['address'] ?? '';
        _cityController.text = data['city'] ?? '';
        _phoneController.text = data['phone'] ?? '';
        _descriptionController.text = data['description'] ?? '';
        _currentLogoUrl = data['logoUrl'];
      }
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
    if (pickedFile != null) {
      setState(() {
        _newLogoImageFile = File(pickedFile.path);
      });
    }
  }

  Future<void> _saveChanges() async {
    setState(() { _isSaving = true; });
    try {
      String? newLogoUrl;
      // Si se seleccionó una nueva imagen, la subimos
      if (_newLogoImageFile != null) {
        final ref = FirebaseStorage.instance.ref().child('school_logos').child('${widget.schoolId}_${DateTime.now().toIso8601String()}.jpg');
        await ref.putFile(_newLogoImageFile!);
        newLogoUrl = await ref.getDownloadURL();
      }

      final dataToUpdate = {
        'name': _nameController.text.trim(),
        'address': _addressController.text.trim(),
        'city': _cityController.text.trim(),
        'phone': _phoneController.text.trim(),
        'description': _descriptionController.text.trim(),
        if (newLogoUrl != null) 'logoUrl': newLogoUrl, // Solo actualiza la URL si hay una nueva imagen
      };

      await FirebaseFirestore.instance.collection('schools').doc(widget.schoolId).update(dataToUpdate);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Datos de la escuela actualizados.'), backgroundColor: Colors.green));
        Navigator.of(context).pop();
      }
    } catch (e) {
      if(mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error al guardar: ${e.toString()}')));
    } finally {
      if(mounted) setState(() { _isSaving = false; });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Editar Datos de la Escuela'),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : AbsorbPointer(
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
                      backgroundImage: _newLogoImageFile != null
                          ? FileImage(_newLogoImageFile!) as ImageProvider
                          : (_currentLogoUrl != null && _currentLogoUrl!.isNotEmpty)
                          ? NetworkImage(_currentLogoUrl!)
                          : null,
                      child: _newLogoImageFile == null && (_currentLogoUrl == null || _currentLogoUrl!.isEmpty)
                          ? Icon(Icons.school, size: 60, color: Colors.grey.shade400)
                          : null,
                    ),
                    Positioned(bottom: 0, right: 0, child: CircleAvatar(
                      child: IconButton(icon: const Icon(Icons.camera_alt, color: Colors.white), onPressed: _pickLogoImage),
                    )),
                  ],
                ),
              ),
              const SizedBox(height: 24),
              TextFormField(controller: _nameController, decoration: const InputDecoration(labelText: 'Nombre de la Escuela', border: OutlineInputBorder())),
              const SizedBox(height: 16),
              TextFormField(controller: _addressController, decoration: const InputDecoration(labelText: 'Dirección', border: OutlineInputBorder())),
              const SizedBox(height: 16),
              TextFormField(controller: _cityController, decoration: const InputDecoration(labelText: 'Ciudad', border: OutlineInputBorder())),
              const SizedBox(height: 16),
              TextFormField(controller: _phoneController, decoration: const InputDecoration(labelText: 'Teléfono de Contacto', border: OutlineInputBorder()), keyboardType: TextInputType.phone),
              const SizedBox(height: 16),
              TextFormField(controller: _descriptionController, decoration: const InputDecoration(labelText: 'Descripción breve', border: OutlineInputBorder()), maxLines: 4),
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
      ),
    );
  }
}
