import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_colorpicker/flutter_colorpicker.dart';
import 'package:warrior_path/models/level_model.dart'; // Asegúrate que la ruta a tu modelo sea correcta

class LevelManagementScreen extends StatefulWidget {
  final String schoolId;
  const LevelManagementScreen({Key? key, required this.schoolId}) : super(key: key);

  @override
  State<LevelManagementScreen> createState() => _LevelManagementScreenState();
}

class _LevelManagementScreenState extends State<LevelManagementScreen> {
  bool _isLoading = true;
  List<LevelModel> _levels = [];
  List<LevelModel> _initialLevels = []; // Para comparar y saber qué se borró

  @override
  void initState() {
    super.initState();
    _fetchLevels();
  }

  Future<void> _fetchLevels() async {
    setState(() => _isLoading = true);
    final snapshot = await FirebaseFirestore.instance
        .collection('schools').doc(widget.schoolId).collection('levels').orderBy('order').get();

    _levels = snapshot.docs.map((doc) => LevelModel.fromFirestore(doc)).toList();

    _initialLevels = _levels.map((level) => LevelModel.fromModel(level)).toList();

    setState(() => _isLoading = false);
  }

  void _addLevel() {
    setState(() {
      _levels.add(LevelModel(id: null, name: 'Nuevo Nivel', color: Colors.grey, order: _levels.length));
    });
  }

  void _pickColor(int index) {
    Color pickerColor = _levels[index].color;
    showDialog(context: context, builder: (context) => AlertDialog(
      title: const Text('Elige un color'),
      content: SingleChildScrollView(child: ColorPicker(pickerColor: pickerColor, onColorChanged: (color) => pickerColor = color)),
      actions: [ElevatedButton(child: const Text('Seleccionar'), onPressed: () {
        setState(() => _levels[index].color = pickerColor);
        Navigator.of(context).pop();
      })],
    ));
  }

  Future<void> _saveChanges() async {
    setState(() => _isLoading = true);
    try {
      final firestore = FirebaseFirestore.instance;
      final schoolRef = firestore.collection('schools').doc(widget.schoolId);
      final batch = firestore.batch();

      // 1. Manejar borrados
      final initialIds = _initialLevels.map((l) => l.id).toSet();
      final currentIds = _levels.map((l) => l.id).toSet();
      final deletedIds = initialIds.difference(currentIds);
      for (final id in deletedIds) {
        if (id != null) batch.delete(schoolRef.collection('levels').doc(id));
      }

      // 2. Manejar creaciones y actualizaciones
      for (int i = 0; i < _levels.length; i++) {
        final level = _levels[i];
        level.order = i; // Actualizar el orden
        if (level.id == null) { // Es un nivel nuevo
          final newDocRef = schoolRef.collection('levels').doc();
          batch.set(newDocRef, level.toJson());
        } else { // Es un nivel existente
          final docRef = schoolRef.collection('levels').doc(level.id);
          batch.update(docRef, level.toJson());
        }
      }

      await batch.commit();

      if(mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Niveles actualizados con éxito.'), backgroundColor: Colors.green));
        Navigator.of(context).pop();
      }

    } catch(e) {
      if(mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error al guardar: ${e.toString()}')));
    } finally {
      if(mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Gestionar Niveles')),
      body: _isLoading ? const Center(child: CircularProgressIndicator()) : Column(
        children: [
          Expanded(
            child: ReorderableListView.builder(
              padding: const EdgeInsets.all(8),
              itemCount: _levels.length,
              itemBuilder: (context, index) {
                final level = _levels[index];
                return Card(
                  key: ValueKey(level.hashCode),
                  margin: const EdgeInsets.symmetric(vertical: 6, horizontal: 8),
                  child: ListTile(
                    leading: InkWell(onTap: () => _pickColor(index), child: CircleAvatar(backgroundColor: level.color)),
                    title: TextFormField(initialValue: level.name, onChanged: (value) => level.name = value, decoration: const InputDecoration(border: InputBorder.none)),
                    trailing: Row(mainAxisSize: MainAxisSize.min, children: [
                      IconButton(icon: const Icon(Icons.delete_outline, color: Colors.red), onPressed: () => setState(() => _levels.removeAt(index))),
                      const Icon(Icons.drag_handle),
                    ]),
                  ),
                );
              },
              onReorder: (oldIndex, newIndex) {
                setState(() {
                  if (newIndex > oldIndex) newIndex -= 1;
                  final item = _levels.removeAt(oldIndex);
                  _levels.insert(newIndex, item);
                });
              },
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: ElevatedButton.icon(icon: const Icon(Icons.add), label: const Text('Añadir Nivel'), onPressed: _addLevel),
          )
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _saveChanges,
        label: const Text('Guardar Cambios'),
        icon: const Icon(Icons.save),
      ),
    );
  }
}

// NECESITARÁS AÑADIR ESTOS MÉTODOS A TU ARCHIVO models/level_model.dart
/*
class LevelModel {
  String? id; // <-- Añade el ID
  // ... (el resto de campos no cambia)

  LevelModel({this.id, required this.name, ...});

  // Nuevo constructor de copia
  factory LevelModel.fromModel(LevelModel another) {
    return LevelModel(id: another.id, name: another.name, color: another.color, order: another.order);
  }

  // Nuevo factory para leer desde Firestore
  factory LevelModel.fromFirestore(String id, Map<String, dynamic> data) {
    return LevelModel(
      id: id,
      name: data['name'],
      color: Color(data['colorValue']),
      order: data['order'],
    );
  }
}
*/
