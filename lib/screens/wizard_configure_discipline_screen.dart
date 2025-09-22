import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_colorpicker/flutter_colorpicker.dart';
import 'package:warrior_path/models/level_model.dart';
import 'package:warrior_path/models/technique_model.dart';

import '../l10n/app_localizations.dart';

class WizardConfigureDisciplineScreen extends StatefulWidget {
  final String schoolId;
  final DocumentSnapshot disciplineDoc;

  const WizardConfigureDisciplineScreen({
    Key? key,
    required this.schoolId,
    required this.disciplineDoc,
  }) : super(key: key);

  @override
  State<WizardConfigureDisciplineScreen> createState() => _WizardConfigureDisciplineScreenState();
}

class _WizardConfigureDisciplineScreenState extends State<WizardConfigureDisciplineScreen> {
  late AppLocalizations l10n;
  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    l10n = AppLocalizations.of(context);
  }

  int _currentStep = 0;
  bool _isLoading = true;

  // Estado para Niveles
  final _systemNameController = TextEditingController();
  final List<LevelModel> _levels = [];

  // Estado para Técnicas
  final _categoryController = TextEditingController();
  List<String> _categories = [];
  List<TechniqueModel> _techniques = [];
  int _nextTechniqueId = 0;

  // Datos de la Disciplina
  Color _primaryColor = Colors.blue;
  String _disciplineName = '';

  @override
  void initState() {
    super.initState();
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

    // Cargar niveles y técnicas existentes
    final levelsSnap = await widget.disciplineDoc.reference.collection('levels').orderBy('order').get();
    if (levelsSnap.docs.isNotEmpty) {
      _levels.addAll(levelsSnap.docs.map((doc) => LevelModel.fromFirestore(doc)));
    } else {
      _addLevel(); // Añadir uno por defecto si no hay
    }

    final techSnap = await widget.disciplineDoc.reference.collection('techniques').get();
    if (techSnap.docs.isNotEmpty) {
      _techniques.addAll(techSnap.docs.map((doc) => TechniqueModel.fromFirestore(doc)));
    }

    if (mounted) setState(() => _isLoading = false);
  }

  @override
  void dispose() {
    _systemNameController.dispose();
    _categoryController.dispose();
    super.dispose();
  }

  Future<bool> _onWillPop() async {
    // Lógica para advertir si hay cambios sin guardar
    return (await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(l10n.confirm),
        content: Text(l10n.unsavedChangesWarning),
        actions: <Widget>[
          TextButton(onPressed: () => Navigator.of(context).pop(false), child: Text(l10n.noStay)),
          TextButton(onPressed: () => Navigator.of(context).pop(true), child: Text(l10n.yesExit)),
        ],
      ),
    )) ?? false;
  }

  void _onStepContinue() {
    if (_currentStep < 1) {
      setState(() => _currentStep += 1);
    } else {
      _saveAndFinish();
    }
  }

  void _onStepCancel() {
    if (_currentStep > 0) {
      setState(() => _currentStep -= 1);
    }
  }

  Future<void> _saveAndFinish() async {
    setState(() => _isLoading = true);

    try {
      final firestore = FirebaseFirestore.instance;
      final disciplineRef = firestore.collection('schools').doc(widget.schoolId).collection('disciplines').doc(widget.disciplineDoc.id);
      final batch = firestore.batch();

      // Guardar datos de Niveles
      batch.update(disciplineRef, {'progressionSystemName': _systemNameController.text.trim()});
      final oldLevels = await disciplineRef.collection('levels').get();
      for (final doc in oldLevels.docs) batch.delete(doc.reference);
      for (int i = 0; i < _levels.length; i++) {
        _levels[i].order = i;
        final levelRef = disciplineRef.collection('levels').doc();
        batch.set(levelRef, _levels[i].toJson());
      }

      // Guardar datos de Técnicas
      batch.update(disciplineRef, {'techniqueCategories': _categories});
      final oldTechniques = await disciplineRef.collection('techniques').get();
      for (final doc in oldTechniques.docs) batch.delete(doc.reference);
      for (final technique in _techniques) {
        final techniqueRef = disciplineRef.collection('techniques').doc();
        batch.set(techniqueRef, technique.toJson());
      }

      await batch.commit();
      if (!mounted) return;
      Navigator.of(context).pop(); // Volver al panel de disciplinas

    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(l10n.saveError(e.toString()))));
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  // --- MÉTODOS DE AYUDA PARA LOS FORMULARIOS (Niveles y Técnicas) ---
  void _addLevel() => setState(() => _levels.add(LevelModel(name: '', color: Colors.grey)));
  void _removeLevel(int index) => setState(() => _levels.removeAt(index));
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
  void _addTechnique() => setState(() => _techniques.add(TechniqueModel(name: '', category: _categories.isNotEmpty ? _categories.first : '', localId: _nextTechniqueId++)));
  void _removeTechnique(int id) => setState(() => _techniques.removeWhere((t) => t.localId == id));


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

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(appBar: AppBar(title: Text(l10n.loading)), body: const Center(child: CircularProgressIndicator()));
    }

    return PopScope(
      canPop: false,
      onPopInvoked: (didPop) async {
        if (didPop) return;
        final bool shouldPop = await _onWillPop();
        if (shouldPop && context.mounted) Navigator.pop(context);
      },
      child: Scaffold(
        appBar: AppBar(title: Text('${l10n.configureDiscipline}: $_disciplineName'), backgroundColor: _primaryColor),
        body: Stepper(
          currentStep: _currentStep,
          onStepContinue: _onStepContinue,
          onStepCancel: _onStepCancel,
          onStepTapped: (step) => setState(() => _currentStep = step),
          controlsBuilder: (context, details) {
            return Padding(
              padding: const EdgeInsets.only(top: 16.0),
              child: Wrap(
                alignment: WrapAlignment.end, // Alinea los botones a la derecha
                spacing: 12.0, // Espacio horizontal entre botones
                runSpacing: 8.0, // Espacio vertical si se van a una segunda línea
                children: [
                  TextButton(
                    onPressed: () {
                      if (details.stepIndex == 0) { // Si está en el paso de Niveles
                        details.onStepContinue?.call(); // Simplemente avanza al siguiente paso
                      } else { // Si está en el paso de Técnicas
                        _saveAndFinish(); // Guarda lo que haya y vuelve al panel
                      }
                    },
                    child: Text(l10n.skipStep, style: const TextStyle(color: Colors.grey)),
                  ),

                  if (details.stepIndex > 0)
                    TextButton(
                      onPressed: details.onStepCancel,
                      child: Text(l10n.cancel),
                    ),

                  ElevatedButton(
                    onPressed: details.onStepContinue,
                    child: Text(_currentStep == 1 ? l10n.finish : l10n.continueStep),
                  ),
                ],
              ),
            );
          },
          steps: [
            Step(
              title: Text(l10n.step1Levels),
              isActive: _currentStep >= 0,
              state: _currentStep > 0 ? StepState.complete : StepState.indexed,
              content: _buildLevelsStep(),
            ),
            Step(
              title: Text(l10n.step2Techniques),
              isActive: _currentStep >= 1,
              content: _buildTechniquesStep(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLevelsStep() {
    return Column(
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
                leading: InkWell(
                  onTap: () => _pickColor(index),
                  child: CircleAvatar(backgroundColor: _levels[index].color),
                ),
                title: TextFormField(
                  initialValue: _levels[index].name,
                  onChanged: (value) {
                    _levels[index].name = value;
                  },
                  decoration: InputDecoration(hintText: l10n.levelNameHint),
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
        ElevatedButton.icon(icon: const Icon(Icons.add), label: Text(l10n.addLevel), onPressed: _addLevel),
      ],
    );
  }

  Widget _buildTechniquesStep() {
    return Column(
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
              key: ValueKey(technique.localId),
              margin: const EdgeInsets.symmetric(vertical: 8),
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            l10n.techniqueNumber((index + 1).toString()),
                            style: Theme.of(context).textTheme.titleMedium,
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.delete_outline, color: Colors.red),
                          onPressed: () => _removeTechnique(technique.localId!),
                        ),
                      ],
                    ),
                    TextFormField(
                      initialValue: technique.name,
                      onChanged: (value) => technique.name = value,
                      decoration: InputDecoration(labelText: l10n.techniqueName),
                    ),
                    const SizedBox(height: 12),
                    DropdownButtonFormField<String>(
                      value: technique.category.isNotEmpty && _categories.contains(technique.category)
                          ? technique.category
                          : null,
                      hint: Text(l10n.selectCategory),
                      items: _categories.map((cat) => DropdownMenuItem(value: cat, child: Text(cat))).toList(),
                      onChanged: (value) {
                        if (value != null) {
                          setState(() => technique.category = value);
                        }
                      },
                      decoration: InputDecoration(labelText: l10n.categoryLabel),
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      initialValue: technique.description,
                      onChanged: (value) => technique.description = value,
                      decoration: InputDecoration(labelText: l10n.descriptionOptional),
                      maxLines: 2,
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      initialValue: technique.videoUrl,
                      onChanged: (value) => technique.videoUrl = value,
                      decoration: InputDecoration(
                        labelText: l10n.videoLinkOptional,
                        hintText: l10n.videoLinkHint,
                      ),
                      keyboardType: TextInputType.url,
                    ),
                  ],
                ),
              ),
            );
          },
        ),
        const SizedBox(height: 16),
        ElevatedButton.icon(icon: const Icon(Icons.add), label: Text(l10n.addTechnique), onPressed: _categories.isEmpty ? null : _addTechnique),
      ],
    );
  }
}
