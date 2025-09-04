import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_colorpicker/flutter_colorpicker.dart';
import 'package:warrior_path/models/level_model.dart';
import 'package:warrior_path/screens/wizard_configure_techniques_screen.dart';
import 'package:warrior_path/theme/martial_art_themes.dart';

class WizardConfigureLevelsScreen extends StatefulWidget {
  final String schoolId;
  final MartialArtTheme martialArtTheme;

  const WizardConfigureLevelsScreen({
    Key? key,
    required this.schoolId,
    required this.martialArtTheme,
  }) : super(key: key);

  @override
  _WizardConfigureLevelsScreenState createState() => _WizardConfigureLevelsScreenState();
}

class _WizardConfigureLevelsScreenState extends State<WizardConfigureLevelsScreen> {
  final _systemNameController = TextEditingController();
  final List<LevelModel> _levels = [];
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    // Añadimos un nivel inicial para que el usuario no empiece desde cero
    _addLevel();
  }

  void _addLevel() {
    setState(() {
      _levels.add(LevelModel(name: '', color: Colors.grey));
    });
  }

  void _removeLevel(int index) {
    setState(() {
      _levels.removeAt(index);
    });
  }

  void _pickColor(int index) {
    Color pickerColor = _levels[index].color;
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Elige un color'),
        content: SingleChildScrollView(
          child: ColorPicker(
            pickerColor: pickerColor,
            onColorChanged: (color) => pickerColor = color,
          ),
        ),
        actions: <Widget>[
          ElevatedButton(
            child: const Text('Seleccionar'),
            onPressed: () {
              setState(() => _levels[index].color = pickerColor);
              Navigator.of(context).pop();
            },
          )
        ],
      ),
    );
  }

  Future<void> _saveAndContinue() async {
    // Validación
    if (_systemNameController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Por favor, dale un nombre a tu sistema de progresión.')));
      return;
    }
    if (_levels.isEmpty || _levels.any((level) => level.name.trim().isEmpty)) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Asegúrate de que todos los niveles tengan un nombre.')));
      return;
    }

    setState(() { _isLoading = true; });

    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) throw Exception("Usuario no autenticado.");

      final firestore = FirebaseFirestore.instance;
      final schoolRef = firestore.collection('schools').doc(widget.schoolId);

      // Usamos un 'batch write' para realizar todas las operaciones de una vez
      final batch = firestore.batch();

      // 1. Actualizamos el nombre del sistema en el documento de la escuela
      batch.update(schoolRef, {'progressionSystemName': _systemNameController.text.trim()});

      // 2. Añadimos cada nivel a la sub-colección 'levels'
      for (int i = 0; i < _levels.length; i++) {
        _levels[i].order = i; // Asignamos el orden según la posición en la lista
        final levelRef = schoolRef.collection('levels').doc(); // Firestore genera el ID
        batch.set(levelRef, _levels[i].toJson());
      }

      // 3. Ejecutamos todas las operaciones en el batch
      await batch.commit();

      // 4. Actualizamos el progreso del wizard del usuario
      await firestore.collection('users').doc(user.uid).update({'wizardStep': 3});

      if (!mounted) return;

      Navigator.of(context).push(
        MaterialPageRoute(
          builder: (context) => WizardConfigureTechniquesScreen(
            schoolId: widget.schoolId,
            martialArtTheme: widget.martialArtTheme,
          ),
        ),
      );

    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error al guardar: ${e.toString()}')));
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
        title: const Text('Configurar Niveles (Paso 3)'),
        backgroundColor: widget.martialArtTheme.primaryColor,
      ),
      body: AbsorbPointer(
        absorbing: _isLoading,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              TextField(
                controller: _systemNameController,
                decoration: const InputDecoration(
                  labelText: 'Nombre del Sistema de Progresión *',
                  hintText: 'Ej: Fajas, Cinturones, Grados',
                ),
              ),
              const SizedBox(height: 24),
              Text(
                'Niveles (ordena del más bajo al más alto)',
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(height: 8),
              if (_levels.isEmpty)
                const Text('Añade tu primer nivel abajo.', textAlign: TextAlign.center, style: TextStyle(color: Colors.grey)),
              ReorderableListView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: _levels.length,
                itemBuilder: (context, index) {
                  return Card(
                    key: ValueKey(_levels[index]), // Clave única para la reordenación
                    margin: const EdgeInsets.symmetric(vertical: 6),
                    child: ListTile(
                      leading: InkWell(
                        onTap: () => _pickColor(index),
                        child: CircleAvatar(backgroundColor: _levels[index].color),
                      ),
                      title: TextField(
                        controller: TextEditingController(text: _levels[index].name),
                        onChanged: (value) {
                          _levels[index].name = value;
                        },
                        decoration: const InputDecoration(hintText: 'Nombre del Nivel'),
                      ),
                      trailing: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          IconButton(
                            icon: const Icon(Icons.delete_outline),
                            onPressed: () => _removeLevel(index),
                          ),
                          const Icon(Icons.drag_handle),
                        ],
                      ),
                    ),
                  );
                },
                onReorder: (oldIndex, newIndex) {
                  setState(() {
                    if (newIndex > oldIndex) {
                      newIndex -= 1;
                    }
                    final item = _levels.removeAt(oldIndex);
                    _levels.insert(newIndex, item);
                  });
                },
              ),
              const SizedBox(height: 16),
              ElevatedButton.icon(
                icon: const Icon(Icons.add),
                label: const Text('Añadir Nivel'),
                onPressed: _addLevel,
              ),
              const SizedBox(height: 32),
              if (_isLoading)
                const Center(child: CircularProgressIndicator())
              else
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    backgroundColor: widget.martialArtTheme.primaryColor,
                  ),
                  onPressed: _saveAndContinue,
                  child: const Text('Guardar y Continuar', style: TextStyle(color: Colors.white)),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
