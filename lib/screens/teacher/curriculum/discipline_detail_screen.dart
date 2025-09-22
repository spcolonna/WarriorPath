import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_colorpicker/flutter_colorpicker.dart';
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
  void _addTechnique() => setState(() => _techniques.add(TechniqueModel(name: '', category: _categories.isNotEmpty ? _categories.first : '')));
  void _removeTechnique(TechniqueModel tech) => setState(() => _techniques.remove(tech));

  @override
  Widget build(BuildContext context) {

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.curriculumFor(_disciplineName)),
        backgroundColor: _primaryColor,
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
                key: ValueKey(technique.id ?? index),
                margin: const EdgeInsets.symmetric(vertical: 8),
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(children: [
                    Row(children: [
                      Expanded(child: Text(l10n.techniqueNumber((index + 1).toString()), style: Theme.of(context).textTheme.titleMedium)),
                      IconButton(icon: const Icon(Icons.delete_outline, color: Colors.red), onPressed: () => _removeTechnique(technique)),
                    ]),
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
                  ]),
                ),
              );
            },
          ),
          const SizedBox(height: 16),
          ElevatedButton.icon(icon: const Icon(Icons.add), label: Text(l10n.addTechnique), onPressed: _categories.isEmpty ? null : _addTechnique),
          const SizedBox(height: 80),
        ],
      ),
    );
  }
}
