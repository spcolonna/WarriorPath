import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import '../l10n/app_localizations.dart';
import '../models/technique_model.dart';

class WizardConfigureTechniquesScreen extends StatefulWidget {
  final String schoolId;
  final DocumentSnapshot disciplineDoc;

  const WizardConfigureTechniquesScreen({
    Key? key,
    required this.schoolId,
    required this.disciplineDoc,
  }) : super(key: key);

  @override
  _WizardConfigureTechniquesScreenState createState() => _WizardConfigureTechniquesScreenState();
}

class _WizardConfigureTechniquesScreenState extends State<WizardConfigureTechniquesScreen> {
  late AppLocalizations l10n;
  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    l10n = AppLocalizations.of(context);
  }

  final _categoryController = TextEditingController();

  List<String> _categories = [];
  List<TechniqueModel> _techniques = [];
  bool _isLoading = false;
  int _nextTechniqueId = 0;
  Color _primaryColor = Colors.blue;
  String _disciplineName = '';

  @override
  void initState() {
    super.initState();
    _loadInitialData();
  }

  void _loadInitialData() {
    final data = widget.disciplineDoc.data() as Map<String, dynamic>? ?? {};
    _disciplineName = data['name'] ?? '';
    final themeData = data['theme'] as Map<String, dynamic>? ?? {};
    _primaryColor = themeData.containsKey('primaryColor')
        ? Color(int.parse('FF${themeData['primaryColor']}', radix: 16))
        : Colors.blue;

    _categories = List<String>.from(data['techniqueCategories'] ?? []);

    if (_categories.isEmpty) {
      _categories.add('General');
    }
  }

  @override
  void dispose() {
    _categoryController.dispose();
    super.dispose();
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

  void _removeCategory(String category) {
    setState(() {
      _categories.remove(category);
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
    if (_categories.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(l10n.atLeastOneCategoryError)));
      return;
    }
    if (_techniques.any((tech) => tech.name.trim().isEmpty || tech.category.isEmpty)) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(l10n.allTechniquesNeedNameCategoryError)));
      return;
    }

    setState(() { _isLoading = true; });

    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) throw Exception(l10n.notAuthenticatedUser);

      final firestore = FirebaseFirestore.instance;
      final disciplineRef = firestore.collection('schools').doc(widget.schoolId).collection('disciplines').doc(widget.disciplineDoc.id);

      final batch = firestore.batch();

      batch.update(disciplineRef, {'techniqueCategories': _categories});

      // Borramos las técnicas viejas para sobreescribir
      final oldTechniques = await disciplineRef.collection('techniques').get();
      for (final doc in oldTechniques.docs) {
        batch.delete(doc.reference);
      }

      // Añadimos las nuevas técnicas
      for (final technique in _techniques) {
        final techniqueRef = disciplineRef.collection('techniques').doc();
        batch.set(techniqueRef, technique.toJson());
      }

      await batch.commit();
      if (!mounted) return;

      Navigator.of(context).pop();

    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(l10n.saveError(e.toString()))));
    } finally {
      if (mounted) setState(() { _isLoading = false; });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.techniquesFor(_disciplineName)),
        backgroundColor: _primaryColor,
      ),
      body: AbsorbPointer(
        absorbing: _isLoading,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(l10n.defineYourCategories, style: Theme.of(context).textTheme.titleLarge),
              const SizedBox(height: 8),
              Row(children: [
                Expanded(child: TextField(controller: _categoryController, decoration: InputDecoration(labelText: l10n.categoryName, hintText: l10n.categoryNameHint))),
                IconButton(icon: const Icon(Icons.add_circle), onPressed: _addCategory, color: _primaryColor),
              ]),
              const SizedBox(height: 16),
              if (_categories.isEmpty) Text(l10n.categoriesAppearHere, style: const TextStyle(color: Colors.grey)) else Wrap(spacing: 8.0, runSpacing: 4.0, children: _categories.map((category) => Chip(label: Text(category), onDeleted: () => _removeCategory(category))).toList()),
              const SizedBox(height: 24),
              const Divider(),
              const SizedBox(height: 16),
              Text(l10n.addYourTechniques, style: Theme.of(context).textTheme.titleLarge),
              const SizedBox(height: 16),
              if (_techniques.isEmpty) Text(l10n.createCategoriesFirst, textAlign: TextAlign.center, style: const TextStyle(color: Colors.grey)),
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
                      child: Column(children: [
                        Row(children: [
                          Expanded(child: Text(l10n.techniqueNumber((index + 1).toString()), style: Theme.of(context).textTheme.titleMedium)),
                          IconButton(icon: const Icon(Icons.delete_outline, color: Colors.red), onPressed: () => _removeTechnique(technique.localId!)),
                        ],
                        ),
                        TextFormField(initialValue: technique.name, onChanged: (value) => technique.name = value, decoration: InputDecoration(labelText: l10n.techniqueName)),
                        const SizedBox(height: 12),
                        DropdownButtonFormField<String>(
                          value: technique.category.isNotEmpty && _categories.contains(technique.category) ? technique.category : null,
                          hint: Text(l10n.selectCategory),
                          items: _categories.map((cat) => DropdownMenuItem(value: cat, child: Text(cat))).toList(),
                          onChanged: (value) { if (value != null) setState(() => technique.category = value); },
                          decoration: InputDecoration(labelText: l10n.categoryLabel),
                        ),
                        const SizedBox(height: 12),
                        TextFormField(initialValue: technique.description, onChanged: (value) => technique.description = value, decoration: InputDecoration(labelText: l10n.descriptionOptional), maxLines: 2),
                        const SizedBox(height: 12),
                        TextFormField(initialValue: technique.videoUrl, onChanged: (value) => technique.videoUrl = value, decoration: InputDecoration(labelText: l10n.videoLinkOptional, hintText: l10n.videoLinkHint), keyboardType: TextInputType.url),
                      ],
                      ),
                    ),
                  );
                },
              ),
              const SizedBox(height: 16),
              ElevatedButton.icon(
                icon: const Icon(Icons.add),
                label: Text(l10n.addTechnique),
                onPressed: _categories.isEmpty ? null : _addTechnique,
              ),
              const SizedBox(height: 24),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(color: Colors.blue.shade50, borderRadius: BorderRadius.circular(8)),
                child: Text(l10n.dontWorryAddEverythingNow, textAlign: TextAlign.center, style: const TextStyle(fontStyle: FontStyle.italic)),
              ),
              const SizedBox(height: 32),
              if (_isLoading)
                const Center(child: CircularProgressIndicator())
              else
                ElevatedButton(
                  style: ElevatedButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 16), backgroundColor: _primaryColor),
                  onPressed: _saveAndContinue,
                  child: const Text('Guardar y Volver al Panel', style: TextStyle(color: Colors.white)),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
