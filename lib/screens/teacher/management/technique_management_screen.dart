import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:warrior_path/models/technique_model.dart';
import 'package:warrior_path/l10n/app_localizations.dart';

class TechniqueManagementScreen extends StatefulWidget {
  final String schoolId;
  const TechniqueManagementScreen({Key? key, required this.schoolId}) : super(key: key);

  @override
  State<TechniqueManagementScreen> createState() => _TechniqueManagementScreenState();
}

class _TechniqueManagementScreenState extends State<TechniqueManagementScreen> {
  late AppLocalizations l10n;
  bool _isLoading = true;
  List<String> _categories = [];
  List<TechniqueModel> _techniques = [];
  List<TechniqueModel> _initialTechniques = [];
  final _categoryController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _fetchData();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    l10n = AppLocalizations.of(context);
  }

  @override
  void dispose() {
    _categoryController.dispose();
    super.dispose();
  }

  // ... (Todos tus métodos como _fetchData, _addCategory, _saveChanges, _attemptToDeleteTechnique, etc., van aquí. No cambian.)
  Future<void> _fetchData() async {
    setState(() => _isLoading = true);
    final schoolDoc = await FirebaseFirestore.instance.collection('schools').doc(widget.schoolId).get();
    _categories = List<String>.from(schoolDoc.data()?['techniqueCategories'] ?? []);
    final techniquesSnapshot = await FirebaseFirestore.instance.collection('schools').doc(widget.schoolId).collection('techniques').get();
    _techniques = techniquesSnapshot.docs.map((doc) => TechniqueModel.fromFirestore(doc)).toList();
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
    showDialog(context: context, builder: (context) {
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
      batch.update(schoolRef, {'techniqueCategories': _categories});
      final initialIds = _initialTechniques.map((t) => t.id).toSet();
      final currentIds = _techniques.map((t) => t.id).toSet();
      final deletedIds = initialIds.difference(currentIds);
      for (final id in deletedIds) {
        if (id != null) batch.delete(schoolRef.collection('techniques').doc(id));
      }
      for (final tech in _techniques) {
        if (tech.id == null) {
          batch.set(schoolRef.collection('techniques').doc(), tech.toJson());
        } else {
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

  Future<void> _attemptToDeleteTechnique(TechniqueModel technique) async {
    showDialog(context: context, barrierDismissible: false, builder: (ctx) => const Center(child: CircularProgressIndicator()));
    try {
      final querySnapshot = await FirebaseFirestore.instance.collection('schools').doc(widget.schoolId).collection('members').where('assignedTechniqueIds', arrayContains: technique.id).limit(10).get();
      Navigator.of(context).pop();
      if (querySnapshot.docs.isEmpty) {
        final bool? confirmDelete = await showDialog<bool>(context: context, builder: (ctx) => AlertDialog(
          title: const Text('Confirmar Borrado'),
          content: Text('¿Estás seguro de que quieres eliminar la técnica "${technique.name}" de forma permanente?'),
          actions: [
            TextButton(onPressed: () => Navigator.of(ctx).pop(false), child: Text(l10n.cancel)),
            ElevatedButton(style: ElevatedButton.styleFrom(backgroundColor: Colors.red), onPressed: () => Navigator.of(ctx).pop(true), child: Text(l10n.eliminate)),
          ],
        ),
        );
        if (confirmDelete ?? false) {
          setState(() {
            _techniques.removeWhere((t) => t.id == technique.id);
          });
        }
      } else {
        final studentNames = querySnapshot.docs.map((doc) => doc.data()['displayName'] as String? ?? 'Alumno sin nombre').toList();
        if (mounted) {
          _showUsersWithTechniqueDialog(technique, studentNames);
        }
      }
    } catch (e) {
      Navigator.of(context).pop();
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Ocurrió un error: ${e.toString()}')));
    }
  }

  void _showUsersWithTechniqueDialog(TechniqueModel technique, List<String> studentNames) {
    showDialog(context: context, builder: (ctx) => AlertDialog(
      title: Text('No se puede eliminar "${technique.name}"'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Esta técnica está asignada a los siguientes alumnos:'),
            const SizedBox(height: 16),
            for (final name in studentNames) Padding(padding: const EdgeInsets.symmetric(vertical: 4.0), child: Text('• $name')),
            const SizedBox(height: 16),
            const Text('Por favor, quita la asignación de estos alumnos para poder eliminar la técnica.'),
          ],
        ),
      ),
      actions: [
        TextButton(onPressed: () => Navigator.of(ctx).pop(), child: Text(l10n.ok)),
      ],
    ),
    );
  }


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Gestionar Técnicas')),

      // --- CAMBIO ESTRUCTURAL: El body ahora es una Column ---
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Column(
        children: [
          // --- CAMBIO: La lista ahora está dentro de un Expanded ---
          // Esto hace que ocupe todo el espacio vertical disponible y sea deslizable.
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(16.0, 16.0, 16.0, 0), // Quitamos padding inferior
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
                  if (_techniques.isEmpty) const Padding(
                    padding: EdgeInsets.symmetric(vertical: 16.0),
                    child: Text('Añade tu primera técnica con el botón (+).'),
                  ),
                  ListView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: _techniques.length,
                    itemBuilder: (context, index) {
                      final tech = _techniques[index];
                      return ListTile(
                        title: Text(tech.name),
                        subtitle: Text(tech.category),
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            IconButton(icon: const Icon(Icons.edit), tooltip: 'Editar', onPressed: () => _showTechniqueDialog(technique: tech)),
                            IconButton(icon: Icon(Icons.delete_outline, color: Colors.red.shade400), tooltip: 'Eliminar', onPressed: () => _attemptToDeleteTechnique(tech)),
                          ],
                        ),
                      );
                    },
                  ),
                  // Añadimos un espacio al final de la lista para que el último elemento no quede pegado abajo
                  const SizedBox(height: 24),
                ],
              ),
            ),
          ),

          // --- CAMBIO: La barra de botones fijos en la parte inferior ---
          // Está fuera del SingleChildScrollView, por lo que no se desliza.
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                FloatingActionButton(
                  heroTag: 'add_technique',
                  onPressed: _showTechniqueDialog,
                  tooltip: 'Añadir Técnica',
                  child: const Icon(Icons.add),
                ),
                const SizedBox(width: 16),
                FloatingActionButton.extended(
                  heroTag: 'save_changes',
                  onPressed: _saveChanges,
                  label: const Text('Guardar Cambios'),
                  icon: const Icon(Icons.save),
                ),
              ],
            ),
          ),
        ],
      ),
      // --- CAMBIO: Eliminamos la propiedad floatingActionButton ---
      // floatingActionButton: ...,
    );
  }
}

// ... (El widget de ayuda _TechniqueForm no necesita cambios)
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
    final String? currentCategory = widget.categories.contains(widget.model.category)
        ? widget.model.category
        : (widget.categories.isNotEmpty ? widget.categories.first : null);

    if (currentCategory != null) {
      widget.model.category = currentCategory;
    }

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        TextFormField(initialValue: widget.model.name, onChanged: (v) => widget.model.name = v, decoration: const InputDecoration(labelText: 'Nombre *')),
        const SizedBox(height: 12),
        if(widget.categories.isNotEmpty && currentCategory != null)
          DropdownButtonFormField<String>(
            value: currentCategory,
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
