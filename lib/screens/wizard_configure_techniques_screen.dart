import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:warrior_path/models/technique_model.dart';
import 'package:warrior_path/screens/wizard_configure_pricing_screen.dart';
import 'package:warrior_path/theme/martial_art_themes.dart';

class WizardConfigureTechniquesScreen extends StatefulWidget {
  final String schoolId;
  final MartialArtTheme martialArtTheme;

  const WizardConfigureTechniquesScreen({
    Key? key,
    required this.schoolId,
    required this.martialArtTheme,
  }) : super(key: key);

  @override
  _WizardConfigureTechniquesScreenState createState() => _WizardConfigureTechniquesScreenState();
}

class _WizardConfigureTechniquesScreenState extends State<WizardConfigureTechniquesScreen> {
  final _categoryController = TextEditingController();

  // Listas para manejar el estado de la UI
  List<String> _categories = ['Formas', 'Técnicas Básicas', 'Armas']; // Ejemplos iniciales
  List<TechniqueModel> _techniques = [];

  bool _isLoading = false;
  int _nextTechniqueId = 0; // Para dar una clave única a cada widget de técnica

  void _addCategory() {
    final categoryName = _categoryController.text.trim();
    if (categoryName.isNotEmpty && !_categories.contains(categoryName)) {
      setState(() {
        _categories.add(categoryName);
        _categoryController.clear();
      });
    }
  }

  void _removeCategory(String category) {
    setState(() {
      _categories.remove(category);
      // Opcional: eliminar técnicas de esa categoría o reasignarlas
      _techniques.removeWhere((tech) => tech.category == category);
    });
  }

  void _addTechnique() {
    setState(() {
      _techniques.add(TechniqueModel(
        name: '',
        category: _categories.isNotEmpty ? _categories.first : '',
        localId: _nextTechniqueId++,
      ));
    });
  }

  void _removeTechnique(int localId) {
    setState(() {
      _techniques.removeWhere((tech) => tech.localId == localId);
    });
  }

  Future<void> _saveAndContinue() async {
    // Validación
    if (_categories.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Debes tener al menos una categoría.')));
      return;
    }
    if (_techniques.any((tech) => tech.name.trim().isEmpty || tech.category.isEmpty)) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Todas las técnicas deben tener un nombre y una categoría asignada.')));
      return;
    }

    setState(() { _isLoading = true; });

    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) throw Exception("Usuario no autenticado.");

      final firestore = FirebaseFirestore.instance;
      final schoolRef = firestore.collection('schools').doc(widget.schoolId);
      final batch = firestore.batch();

      // 1. Guardar la lista de categorías en el documento de la escuela
      batch.update(schoolRef, {'techniqueCategories': _categories});

      // 2. Guardar cada técnica en la sub-colección 'techniques'
      for (final technique in _techniques) {
        final techniqueRef = schoolRef.collection('techniques').doc();
        batch.set(techniqueRef, technique.toJson());
      }

      await batch.commit();

      // 3. Actualizar el progreso del wizard del usuario
      await firestore.collection('users').doc(user.uid).update({'wizardStep': 4});

      if (!mounted) return;

      Navigator.of(context).pushReplacement(
        MaterialPageRoute(
          builder: (context) => WizardConfigurePricingScreen(
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
        title: const Text('Añadir Técnicas (Paso 4)'),
        backgroundColor: widget.martialArtTheme.primaryColor,
      ),
      body: AbsorbPointer(
        absorbing: _isLoading,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // --- SECCIÓN DE CATEGORÍAS ---
              Text('1. Define tus Categorías', style: Theme.of(context).textTheme.titleLarge),
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _categoryController,
                      decoration: const InputDecoration(labelText: 'Nombre de la Categoría'),
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.add_circle),
                    onPressed: _addCategory,
                    color: widget.martialArtTheme.primaryColor,
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Wrap(
                spacing: 8.0,
                runSpacing: 4.0,
                children: _categories.map((category) => Chip(
                  label: Text(category),
                  onDeleted: () => _removeCategory(category),
                )).toList(),
              ),
              const SizedBox(height: 24),
              const Divider(),
              const SizedBox(height: 16),

              // --- SECCIÓN DE TÉCNICAS ---
              Text('2. Añade tus Técnicas', style: Theme.of(context).textTheme.titleLarge),
              const SizedBox(height: 16),
              if (_techniques.isEmpty)
                const Text('Añade tu primera técnica abajo.', textAlign: TextAlign.center, style: TextStyle(color: Colors.grey)),
              ListView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: _techniques.length,
                itemBuilder: (context, index) {
                  final technique = _techniques[index];
                  return Card(
                    key: ValueKey(technique.localId),
                    margin: const EdgeInsets.symmetric(vertical: 8),
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        children: [
                          Row(
                            children: [
                              Expanded(
                                child: Text('Técnica #${index + 1}', style: Theme.of(context).textTheme.titleMedium),
                              ),
                              IconButton(
                                icon: const Icon(Icons.delete_outline, color: Colors.red),
                                onPressed: () => _removeTechnique(technique.localId),
                              ),
                            ],
                          ),
                          TextFormField(
                            initialValue: technique.name,
                            onChanged: (value) => technique.name = value,
                            decoration: const InputDecoration(labelText: 'Nombre de la Técnica *'),
                          ),
                          const SizedBox(height: 12),
                          DropdownButtonFormField<String>(
                            value: technique.category.isNotEmpty && _categories.contains(technique.category) ? technique.category : null,
                            hint: const Text('Selecciona una categoría'),
                            items: _categories.map((cat) => DropdownMenuItem(value: cat, child: Text(cat))).toList(),
                            onChanged: (value) {
                              if (value != null) {
                                setState(() => technique.category = value);
                              }
                            },
                            decoration: const InputDecoration(labelText: 'Categoría *'),
                          ),
                          const SizedBox(height: 12),
                          TextFormField(
                            initialValue: technique.description,
                            onChanged: (value) => technique.description = value,
                            decoration: const InputDecoration(labelText: 'Descripción (opcional)'),
                            maxLines: 2,
                          ),
                          const SizedBox(height: 12),
                          TextFormField(
                            initialValue: technique.videoUrl,
                            onChanged: (value) => technique.videoUrl = value,
                            decoration: const InputDecoration(labelText: 'Enlace a Video (opcional)', hintText: 'https://youtube.com/...'),
                            keyboardType: TextInputType.url,
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
              const SizedBox(height: 16),
              ElevatedButton.icon(
                icon: const Icon(Icons.add),
                label: const Text('Añadir Técnica'),
                onPressed: _addTechnique,
              ),

              const SizedBox(height: 24),
              // --- MENSAJE INFORMATIVO ---
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.blue.shade50,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Text(
                  'No te preocupes por añadir todo ahora. Siempre podrás gestionar tus técnicas desde el panel de control de tu escuela.',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontStyle: FontStyle.italic),
                ),
              ),
              const SizedBox(height: 32),

              // --- BOTÓN DE CONTINUAR ---
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
