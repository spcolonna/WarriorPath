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
    final newTech = TechniqueModel(
      name: '',
      category: _categories.isNotEmpty ? _categories.first : '',
      localId: _nextTechniqueId++,
    );
    setState(() => _techniques.add(newTech));
    _editTechnique(newTech);
  }

  void _editTechnique(TechniqueModel technique) {
    final nameCtrl = TextEditingController(text: technique.name);
    final descCtrl = TextEditingController(text: technique.description);
    final videoCtrl = TextEditingController(text: technique.videoUrl ?? '');

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setSheet) {
          String? selectedCategory = _categories.contains(technique.category)
              ? technique.category
              : (_categories.isNotEmpty ? _categories.first : null);

          return DraggableScrollableSheet(
            expand: false,
            initialChildSize: 0.85,
            minChildSize: 0.5,
            maxChildSize: 0.95,
            builder: (ctx2, scrollCtrl) => Padding(
              padding: EdgeInsets.only(
                  bottom: MediaQuery.of(context).viewInsets.bottom),
              child: Column(
                children: [
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 10),
                    child: Container(
                      width: 40, height: 4,
                      decoration: BoxDecoration(
                        color: Colors.grey.shade300,
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: Row(
                      children: [
                        Text(
                          technique.name.trim().isEmpty
                              ? 'Nueva técnica'
                              : technique.name,
                          style: Theme.of(context).textTheme.titleLarge,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 8),
                  const Divider(height: 1),
                  Expanded(
                    child: ListView(
                      controller: scrollCtrl,
                      padding: const EdgeInsets.fromLTRB(20, 16, 20, 16),
                      children: [
                        TextFormField(
                          controller: nameCtrl,
                          autofocus: true,
                          onChanged: (v) {
                            technique.name = v;
                            setSheet(() {});
                          },
                          decoration: InputDecoration(
                            labelText: l10n.techniqueName,
                            border: const OutlineInputBorder(),
                          ),
                        ),
                        const SizedBox(height: 14),
                        if (_categories.isNotEmpty)
                          DropdownButtonFormField<String>(
                            initialValue: selectedCategory,
                            decoration: InputDecoration(
                              labelText: l10n.categoryLabel,
                              border: const OutlineInputBorder(),
                            ),
                            items: _categories.map((c) =>
                                DropdownMenuItem(value: c, child: Text(c))).toList(),
                            onChanged: (v) {
                              if (v != null) technique.category = v;
                            },
                          ),
                        const SizedBox(height: 16),
                        TextFormField(
                          controller: descCtrl,
                          onChanged: (v) => technique.description = v,
                          decoration: InputDecoration(
                            labelText: l10n.descriptionOptional,
                            border: const OutlineInputBorder(),
                          ),
                          maxLines: 2,
                        ),
                        const SizedBox(height: 14),
                        TextFormField(
                          controller: videoCtrl,
                          onChanged: (v) =>
                              technique.videoUrl = v.trim().isEmpty ? null : v.trim(),
                          decoration: InputDecoration(
                            labelText: l10n.videoLinkOptional,
                            hintText: l10n.videoLinkHint,
                            border: const OutlineInputBorder(),
                            prefixIcon: const Icon(Icons.play_circle_outline),
                          ),
                          keyboardType: TextInputType.url,
                        ),
                        const SizedBox(height: 24),
                        FilledButton(
                          onPressed: () {
                            setState(() {});
                            Navigator.of(ctx).pop();
                          },
                          style: FilledButton.styleFrom(
                            minimumSize: const Size.fromHeight(48),
                          ),
                          child: const Text('Listo'),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
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
              if (_techniques.isEmpty)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  child: Text(l10n.createCategoriesFirst, textAlign: TextAlign.center, style: const TextStyle(color: Colors.grey)),
                )
              else
                Card(
                  margin: EdgeInsets.zero,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  child: Column(
                    children: [
                      for (int i = 0; i < _techniques.length; i++) ...[
                        if (i > 0) const Divider(height: 1, indent: 16, endIndent: 16),
                        InkWell(
                          key: ValueKey(_techniques[i].localId),
                          onTap: () => _editTechnique(_techniques[i]),
                          borderRadius: i == 0
                              ? const BorderRadius.vertical(top: Radius.circular(12))
                              : i == _techniques.length - 1
                                  ? const BorderRadius.vertical(bottom: Radius.circular(12))
                                  : BorderRadius.zero,
                          child: Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                            child: Row(
                              children: [
                                Container(
                                  width: 28, height: 28,
                                  decoration: BoxDecoration(
                                    color: _primaryColor.withValues(alpha: 0.12),
                                    shape: BoxShape.circle,
                                  ),
                                  alignment: Alignment.center,
                                  child: Text(
                                    '${i + 1}',
                                    style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: _primaryColor),
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        _techniques[i].name.trim().isEmpty
                                            ? 'Sin nombre'
                                            : _techniques[i].name,
                                        style: TextStyle(
                                          fontWeight: FontWeight.w600,
                                          fontSize: 14,
                                          color: _techniques[i].name.trim().isEmpty
                                              ? Colors.grey
                                              : null,
                                        ),
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                      if (_techniques[i].category.isNotEmpty)
                                        Text(
                                          _techniques[i].category,
                                          style: TextStyle(fontSize: 11, color: Colors.grey.shade500),
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                    ],
                                  ),
                                ),
                                Icon(Icons.edit_outlined, size: 16, color: Colors.grey.shade400),
                                const SizedBox(width: 4),
                                GestureDetector(
                                  onTap: () => _removeTechnique(_techniques[i].localId!),
                                  child: Icon(Icons.delete_outline, size: 18, color: Colors.red.shade300),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
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
