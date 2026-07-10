import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_colorpicker/flutter_colorpicker.dart';
import 'package:warrior_path/data/martial_art_defaults.dart';
import 'package:warrior_path/models/level_model.dart';
import 'package:warrior_path/models/technique_model.dart';

import '../../../l10n/app_localizations.dart';

class DisciplineDetailScreen extends StatefulWidget {
  final String schoolId;
  final DocumentSnapshot disciplineDoc;

  const DisciplineDetailScreen({
    super.key,
    required this.schoolId,
    required this.disciplineDoc,
  });

  @override
  State<DisciplineDetailScreen> createState() => _DisciplineDetailScreenState();
}

class _DisciplineDetailScreenState extends State<DisciplineDetailScreen> with SingleTickerProviderStateMixin {
  late AppLocalizations l10n;
  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    l10n = AppLocalizations.of(context);
  }

  late TabController _tabController;
  bool _isLoading = true;
  bool _isSaving = false;

  // Estado para Niveles
  final _systemNameController = TextEditingController();
  List<LevelModel> _levels = [];
  List<LevelModel> _initialLevels = [];

  // Estado para Técnicas
  final _categoryController = TextEditingController();
  List<String> _categories = [];
  List<String> _initialCategories = [];
  List<TechniqueModel> _techniques = [];
  List<TechniqueModel> _initialTechniques = [];

  // Datos de la Disciplina
  Color _primaryColor = Colors.blue;
  String _disciplineName = '';

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _loadInitialData();
  }

  Future<void> _loadInitialData() async {
    final data = widget.disciplineDoc.data() as Map<String, dynamic>? ?? {};
    _disciplineName = data['name'] ?? '';
    final themeData = data['theme'] as Map<String, dynamic>? ?? {};
    _primaryColor = themeData.containsKey('primaryColor')
        ? Color(int.parse('FF${themeData['primaryColor']}', radix: 16))
        : Colors.blue;
    _systemNameController.text = data['progressionSystemName'] ?? '';
    _categories = List<String>.from(data['techniqueCategories'] ?? []);
    _initialCategories = List.from(_categories);

    final levelsSnap = await widget.disciplineDoc.reference.collection('levels').orderBy('order').get();
    _levels = levelsSnap.docs.map((doc) => LevelModel.fromFirestore(doc)).toList();
    _initialLevels = _levels.map((level) => LevelModel.fromModel(level)).toList();

    final techSnap = await widget.disciplineDoc.reference.collection('techniques').get();
    _techniques = techSnap.docs.map((doc) => TechniqueModel.fromFirestore(doc)).toList();
    _initialTechniques = _techniques.map((tech) => TechniqueModel.fromModel(tech)).toList();

    if (mounted) setState(() => _isLoading = false);
  }

  @override
  void dispose() {
    _tabController.dispose();
    _systemNameController.dispose();
    _categoryController.dispose();
    super.dispose();
  }

  /// Agrega (sin borrar ni reordenar) los niveles, categorías y técnicas de la
  /// plantilla del arte que todavía no estén presentes. Es aditivo a propósito:
  /// los niveles existentes conservan su `id`, así que ningún alumno con
  /// `currentLevelId` asignado queda colgado. El profe revisa y confirma con
  /// "Guardar todos los cambios" (que ya es diff-based por id).
  Future<void> _applyTemplate() async {
    final template = MartialArtDefaults.templateFor(_disciplineName);
    if (template == null) return;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(l10n.applyTemplateTitle(_disciplineName)),
        content: Text(l10n.applyTemplateBody(_disciplineName)),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: Text(l10n.cancel),
          ),
          FilledButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            child: Text(l10n.applyTemplate),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;

    final existingLevelNames =
        _levels.map((l) => l.name.trim().toLowerCase()).toSet();
    final existingTechNames =
        _techniques.map((t) => t.name.trim().toLowerCase()).toSet();

    setState(() {
      // Niveles nuevos (id == null → se crearán al guardar, sin tocar los que ya hay).
      for (final level in template.toLevels()) {
        if (!existingLevelNames.contains(level.name.trim().toLowerCase())) {
          _levels.add(level);
        }
      }
      // Categorías: unión sin duplicar.
      for (final cat in template.categories) {
        if (!_categories.contains(cat)) _categories.add(cat);
      }
      // Técnicas nuevas.
      for (final tech in template.toTechniques(0)) {
        if (!existingTechNames.contains(tech.name.trim().toLowerCase())) {
          _techniques.add(TechniqueModel(
            name: tech.name,
            category: tech.category,
            complexity: tech.complexity,
          ));
        }
      }
      // Si el sistema de progresión estaba vacío, tomamos el de la plantilla.
      if (_systemNameController.text.trim().isEmpty) {
        _systemNameController.text = template.progressionSystemName;
      }
    });

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l10n.templateApplied)),
      );
    }
  }

  Future<void> _saveAllChanges() async {
    setState(() => _isSaving = true);

    try {
      final firestore = FirebaseFirestore.instance;
      final disciplineRef = widget.disciplineDoc.reference;
      final batch = firestore.batch();

      // --- Lógica de guardado para Niveles ---
      batch.update(disciplineRef, {'progressionSystemName': _systemNameController.text.trim()});
      final initialLevelIds = _initialLevels.map((l) => l.id).toSet();
      final currentLevelIds = _levels.map((l) => l.id).toSet();
      final deletedLevelIds = initialLevelIds.difference(currentLevelIds);

      for (final id in deletedLevelIds) {
        if (id != null) batch.delete(disciplineRef.collection('levels').doc(id));
      }

      for (int i = 0; i < _levels.length; i++) {
        _levels[i].order = i;
        if (_levels[i].id == null) {
          batch.set(disciplineRef.collection('levels').doc(), _levels[i].toJson());
        } else {
          batch.update(disciplineRef.collection('levels').doc(_levels[i].id), _levels[i].toJson());
        }
      }

      // --- Lógica de guardado para Técnicas ---
      batch.update(disciplineRef, {'techniqueCategories': _categories});
      final initialTechIds = _initialTechniques.map((t) => t.id).toSet();
      final currentTechIds = _techniques.map((t) => t.id).toSet();
      final deletedTechIds = initialTechIds.difference(currentTechIds);

      for (final id in deletedTechIds) {
        if (id != null) batch.delete(disciplineRef.collection('techniques').doc(id));
      }

      for (final technique in _techniques) {
        if (technique.id == null) {
          batch.set(disciplineRef.collection('techniques').doc(), technique.toJson());
        } else {
          batch.update(disciplineRef.collection('techniques').doc(technique.id), technique.toJson());
        }
      }

      await batch.commit();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(l10n.curriculumSaveSuccess), backgroundColor: Colors.green));
      Navigator.of(context).pop();

    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(l10n.saveError(e.toString()))));
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  void _addLevel() => setState(() => _levels.add(LevelModel(name: '', color: Colors.grey)));
  void _removeLevel(int index) => setState(() => _levels.removeAt(index));


  void _pickColor(int index) {
    Color pickerColor = _levels[index].color;
    showDialog(context: context, builder: (context) => AlertDialog(
      title: Text(l10n.pickAColor),
      content: SingleChildScrollView(child: ColorPicker(pickerColor: pickerColor, onColorChanged: (color) => pickerColor = color)),
      actions: [ElevatedButton(child: Text(l10n.select), onPressed: () {
        setState(() => _levels[index].color = pickerColor);
        Navigator.of(context).pop();
      })],
    ));
  }

  void _addCategory() {
    final name = _categoryController.text.trim();
    if(name.isNotEmpty && !_categories.contains(name)) {
      setState(() {
      _categories.add(name);
      _categoryController.clear();
    });
    }
  }
  void _removeCategory(String cat) => setState(() => _categories.remove(cat));
  void _addTechnique() {
    final newTech = TechniqueModel(name: '', category: _categories.isNotEmpty ? _categories.first : '');
    setState(() => _techniques.add(newTech));
    _editTechnique(newTech);
  }

  void _removeTechnique(TechniqueModel tech) => setState(() => _techniques.remove(tech));

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
        builder: (ctx, setSheet) => DraggableScrollableSheet(
          expand: false,
          initialChildSize: 0.85,
          minChildSize: 0.5,
          maxChildSize: 0.95,
          builder: (_, scrollCtrl) => Padding(
            padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
            child: Column(
              children: [
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 10),
                  child: Container(width: 40, height: 4,
                    decoration: BoxDecoration(color: Colors.grey.shade300, borderRadius: BorderRadius.circular(2))),
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: Align(
                    alignment: Alignment.centerLeft,
                    child: Text(
                      technique.name.trim().isEmpty ? l10n.addTechnique : technique.name,
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
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
                        decoration: InputDecoration(labelText: l10n.techniqueName, border: const OutlineInputBorder()),
                      ),
                      const SizedBox(height: 14),
                      if (_categories.isNotEmpty)
                        DropdownButtonFormField<String>(
                          initialValue: _categories.contains(technique.category) ? technique.category : _categories.first,
                          decoration: InputDecoration(labelText: l10n.categoryLabel, border: const OutlineInputBorder()),
                          items: _categories.map((c) => DropdownMenuItem(value: c, child: Text(c))).toList(),
                          onChanged: (v) { if (v != null) technique.category = v; },
                        ),
                      const SizedBox(height: 14),
                      TextFormField(
                        controller: descCtrl,
                        onChanged: (v) => technique.description = v,
                        decoration: InputDecoration(labelText: l10n.descriptionOptional, border: const OutlineInputBorder()),
                        maxLines: 2,
                      ),
                      const SizedBox(height: 14),
                      TextFormField(
                        controller: videoCtrl,
                        onChanged: (v) => technique.videoUrl = v.trim().isEmpty ? null : v.trim(),
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
                        onPressed: () { setState(() {}); Navigator.of(ctx).pop(); },
                        style: FilledButton.styleFrom(minimumSize: const Size.fromHeight(48)),
                        child: Text(l10n.ok),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.curriculumFor(_disciplineName)),
        backgroundColor: _primaryColor,
        actions: [
          if (MartialArtDefaults.hasTemplate(_disciplineName))
            IconButton(
              icon: const Icon(Icons.auto_awesome),
              tooltip: l10n.applyTemplate,
              onPressed: _isSaving ? null : _applyTemplate,
            ),
        ],
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: Colors.white,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white70,
          tabs: [
            Tab(text: l10n.manageLevels),
            Tab(text: l10n.manageTechniques),
          ],
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : AbsorbPointer(
        absorbing: _isSaving,
        child: TabBarView(
          controller: _tabController,
          children: [
            _buildLevelsTab(l10n),
            _buildTechniquesTab(l10n),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _isSaving ? null : _saveAllChanges,
        label: _isSaving ? const CircularProgressIndicator(color: Colors.white) : Text(l10n.saveAllChanges),
        icon: _isSaving ? null : const Icon(Icons.save),
      ),
    );
  }

  Widget _buildLevelsTab(AppLocalizations l10n) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          TextField(controller: _systemNameController, decoration: InputDecoration(labelText: l10n.progressionSystemName, hintText: l10n.progressionSystemHint)),
          const SizedBox(height: 24),
          Text(l10n.levelsOrderHint, style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 8),
          if (_levels.isEmpty) Text(l10n.addYourFirstLevel, textAlign: TextAlign.center, style: const TextStyle(color: Colors.grey)),
          ReorderableListView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: _levels.length,
            itemBuilder: (context, index) {
              return Card(
                key: ValueKey(_levels[index]),
                margin: const EdgeInsets.symmetric(vertical: 6),
                child: ListTile(
                  leading: InkWell(onTap: () => _pickColor(index), child: CircleAvatar(backgroundColor: _levels[index].color)),
                  title: TextFormField(initialValue: _levels[index].name, onChanged: (value) => _levels[index].name = value, decoration: InputDecoration(hintText: l10n.levelNameHint)),
                  trailing: Row(mainAxisSize: MainAxisSize.min, children: [
                    IconButton(icon: const Icon(Icons.delete_outline), onPressed: () => _removeLevel(index)),
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
          const SizedBox(height: 16),
          ElevatedButton.icon(icon: const Icon(Icons.add), label: Text(l10n.addLevel), onPressed: _addLevel),
          const SizedBox(height: 80),
        ],
      ),
    );
  }

  Widget _buildTechniquesTab(AppLocalizations l10n) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(l10n.defineYourCategories, style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: 8),
          Row(children: [ Expanded(child: TextField(controller: _categoryController, decoration: InputDecoration(labelText: l10n.categoryName, hintText: l10n.categoryNameHint))), IconButton(icon: const Icon(Icons.add_circle), onPressed: _addCategory, color: _primaryColor)]),
          const SizedBox(height: 16),
          if (_categories.isEmpty) Text(l10n.categoriesAppearHere, style: const TextStyle(color: Colors.grey)) else Wrap(spacing: 8.0, children: _categories.map((c) => Chip(label: Text(c), onDeleted: () => _removeCategory(c))).toList()),
          const SizedBox(height: 24),
          const Divider(),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(child: Text(l10n.addYourTechniques, style: Theme.of(context).textTheme.titleLarge)),
              TextButton.icon(
                icon: const Icon(Icons.add),
                label: Text(l10n.addTechnique),
                onPressed: _categories.isEmpty ? null : _addTechnique,
              ),
            ],
          ),
          const SizedBox(height: 8),
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
                      key: ValueKey(_techniques[i].id ?? i),
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
                              child: Text('${i + 1}',
                                style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: _primaryColor)),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    _techniques[i].name.trim().isEmpty ? l10n.techniqueName : _techniques[i].name,
                                    style: TextStyle(
                                      fontWeight: FontWeight.w600, fontSize: 14,
                                      color: _techniques[i].name.trim().isEmpty ? Colors.grey : null,
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                  if (_techniques[i].category.isNotEmpty)
                                    Text(_techniques[i].category,
                                      style: TextStyle(fontSize: 11, color: Colors.grey.shade500),
                                      maxLines: 1, overflow: TextOverflow.ellipsis),
                                ],
                              ),
                            ),
                            Icon(Icons.edit_outlined, size: 16, color: Colors.grey.shade400),
                            const SizedBox(width: 8),
                            GestureDetector(
                              onTap: () => _removeTechnique(_techniques[i]),
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
          ElevatedButton.icon(icon: const Icon(Icons.add), label: Text(l10n.addTechnique), onPressed: _categories.isEmpty ? null : _addTechnique),
          const SizedBox(height: 80),
        ],
      ),
    );
  }
}
