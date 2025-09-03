import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:warrior_path/models/technique_model.dart';

class TechniqueManagementScreen extends StatefulWidget {
  final String schoolId;
  const TechniqueManagementScreen({Key? key, required this.schoolId}) : super(key: key);

  @override
  State<TechniqueManagementScreen> createState() => _TechniqueManagementScreenState();
}

class _TechniqueManagementScreenState extends State<TechniqueManagementScreen> {
  bool _isLoading = true;
  List<String> _categories = [];
  List<TechniqueModel> _techniques = [];

  // Guardamos el estado inicial para comparar al guardar
  List<String> _initialCategories = [];
  List<TechniqueModel> _initialTechniques = [];

  final _categoryController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _fetchData();
  }

  Future<void> _fetchData() async {
    setState(() => _isLoading = true);
    final schoolDoc = await FirebaseFirestore.instance.collection('schools').doc(widget.schoolId).get();
    _categories = List<String>.from(schoolDoc.data()?['techniqueCategories'] ?? []);
    _initialCategories = List<String>.from(_categories);

    final techniquesSnapshot = await FirebaseFirestore.instance.collection('schools').doc(widget.schoolId).collection('techniques').get();
    _techniques = techniquesSnapshot.docs.map((doc) => TechniqueModel.fromFirestore(doc.id, doc.data())).toList();
    _initialTechniques = _techniques.map((tech) => TechniqueModel.fromModel(tech)).toList();

    setState(() => _isLoading = false);
  }

  void _addCategory() {
    final categoryName = _categoryController.text.trim();
    if (categoryName.isNotEmpty && !_categories.contains(categoryName)) {
      setState(() {
        _categories.add(categoryName);
        _categoryController.clear();
      });
    }
  }

  void _showTechniqueDialog({TechniqueModel? technique}) {
    final bool isEditing = technique != null;
    final model = isEditing ? TechniqueModel.fromModel(technique) : TechniqueModel(name: '', category: _categories.isNotEmpty ? _categories.first : '');

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text(isEditing ? 'Editar Técnica' : 'Añadir Técnica'),
          content: SingleChildScrollView(child: _TechniqueForm(model: model, categories: _categories)),
          actions: [
            TextButton(onPressed: () => Navigator.of(context).pop(), child: const Text('Cancelar')),
            ElevatedButton(
              onPressed: () {
                setState(() {
                  if (isEditing) {
                    final index = _techniques.indexWhere((t) => t.id == model.id);
                    if (index != -1) _techniques[index] = model;
                  } else {
                    _techniques.add(model);
                  }
                });
                Navigator.of(context).pop();
              },
              child: const Text('Guardar'),
            ),
          ],
        );
      },
    );
  }

  Future<void> _saveChanges() async {
    setState(() => _isLoading = true);
    try {
      final firestore = FirebaseFirestore.instance;
      final schoolRef = firestore.collection('schools').doc(widget.schoolId);
      final batch = firestore.batch();

      // 1. Actualizar categorías en el documento principal
      batch.update(schoolRef, {'techniqueCategories': _categories});

      // 2. Manejar técnicas borradas
      final initialIds = _initialTechniques.map((t) => t.id).toSet();
      final currentIds = _techniques.map((t) => t.id).toSet();
      final deletedIds = initialIds.difference(currentIds);
      for (final id in deletedIds) {
        if (id != null) batch.delete(schoolRef.collection('techniques').doc(id));
      }

      // 3. Manejar técnicas creadas y actualizadas
      for (final tech in _techniques) {
        if (tech.id == null) { // Técnica nueva
          batch.set(schoolRef.collection('techniques').doc(), tech.toJson());
        } else { // Técnica existente
          batch.update(schoolRef.collection('techniques').doc(tech.id), tech.toJson());
        }
      }

      await batch.commit();
      if(mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Currículo actualizado.'), backgroundColor: Colors.green));
        Navigator.of(context).pop();
      }
    } catch (e) {
      if(mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error al guardar: ${e.toString()}')));
    } finally {
      if(mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Gestionar Técnicas')),
      body: _isLoading ? const Center(child: CircularProgressIndicator()) : SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Categorías', style: Theme.of(context).textTheme.titleLarge),
            Row(children: [
              Expanded(child: TextField(controller: _categoryController, decoration: const InputDecoration(labelText: 'Nueva Categoría'))),
              IconButton(icon: const Icon(Icons.add_circle), onPressed: _addCategory),
            ]),
            const SizedBox(height: 8),
            Wrap(spacing: 8, children: _categories.map((cat) => Chip(label: Text(cat), onDeleted: () => setState(() => _categories.remove(cat)))).toList()),
            const Divider(height: 32),
            Text('Técnicas', style: Theme.of(context).textTheme.titleLarge),
            if (_techniques.isEmpty) const Text('Añade tu primera técnica con el botón (+).'),
            ListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: _techniques.length,
              itemBuilder: (context, index) {
                final tech = _techniques[index];
                return ListTile(
                  title: Text(tech.name),
                  subtitle: Text(tech.category),
                  trailing: IconButton(icon: const Icon(Icons.edit), onPressed: () => _showTechniqueDialog(technique: tech)),
                );
              },
            ),
          ],
        ),
      ),
      floatingActionButton: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          FloatingActionButton(heroTag: 'add_technique', onPressed: _showTechniqueDialog, child: const Icon(Icons.add)),
          const SizedBox(height: 16),
          FloatingActionButton.extended(heroTag: 'save_changes', onPressed: _saveChanges, label: const Text('Guardar Cambios'), icon: const Icon(Icons.save)),
        ],
      ),
    );
  }
}

// Widget de ayuda para el formulario de añadir/editar técnica
class _TechniqueForm extends StatefulWidget {
  final TechniqueModel model;
  final List<String> categories;
  const _TechniqueForm({Key? key, required this.model, required this.categories}) : super(key: key);

  @override
  State<_TechniqueForm> createState() => __TechniqueFormState();
}

class __TechniqueFormState extends State<_TechniqueForm> {
  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        TextFormField(initialValue: widget.model.name, onChanged: (v) => widget.model.name = v, decoration: const InputDecoration(labelText: 'Nombre *')),
        const SizedBox(height: 12),
        if(widget.categories.isNotEmpty)
          DropdownButtonFormField<String>(
            value: widget.model.category,
            items: widget.categories.map((cat) => DropdownMenuItem(value: cat, child: Text(cat))).toList(),
            onChanged: (v) { if(v != null) setState(() => widget.model.category = v); },
            decoration: const InputDecoration(labelText: 'Categoría *'),
          ),
        const SizedBox(height: 12),
        TextFormField(initialValue: widget.model.description, onChanged: (v) => widget.model.description = v, decoration: const InputDecoration(labelText: 'Descripción'), maxLines: 2),
        const SizedBox(height: 12),
        TextFormField(initialValue: widget.model.videoUrl, onChanged: (v) => widget.model.videoUrl = v, decoration: const InputDecoration(labelText: 'Enlace a Video'), keyboardType: TextInputType.url),
      ],
    );
  }
}
