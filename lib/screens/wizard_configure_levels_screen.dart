import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_colorpicker/flutter_colorpicker.dart';
import 'package:warrior_path/models/level_model.dart';
import '../l10n/app_localizations.dart';

class WizardConfigureLevelsScreen extends StatefulWidget {
  final String schoolId;
  final DocumentSnapshot disciplineDoc;

  const WizardConfigureLevelsScreen({
    Key? key,
    required this.schoolId,
    required this.disciplineDoc,
  }) : super(key: key);

  @override
  _WizardConfigureLevelsScreenState createState() => _WizardConfigureLevelsScreenState();
}

class _WizardConfigureLevelsScreenState extends State<WizardConfigureLevelsScreen> {
  late AppLocalizations l10n;
  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    l10n = AppLocalizations.of(context);
  }

  final _systemNameController = TextEditingController();
  final List<LevelModel> _levels = [];
  bool _isLoading = true;
  Color _primaryColor = Colors.blue;
  String _disciplineName = '';

  @override
  void initState() {
    super.initState();
    _loadInitialData();
  }

  Future<void> _loadInitialData() async {
    final disciplineData = widget.disciplineDoc.data() as Map<String, dynamic>? ?? {};
    _disciplineName = disciplineData['name'] ?? '';
    _systemNameController.text = disciplineData['progressionSystemName'] ?? '';

    final themeData = disciplineData['theme'] as Map<String, dynamic>? ?? {};
    _primaryColor = themeData.containsKey('primaryColor')
        ? Color(int.parse('FF${themeData['primaryColor']}', radix: 16))
        : Colors.blue;

    try {
      final levelsSnapshot = await widget.disciplineDoc.reference
          .collection('levels')
          .orderBy('order')
          .get();

      if (levelsSnapshot.docs.isNotEmpty) {
        _levels.addAll(levelsSnapshot.docs.map((doc) => LevelModel.fromFirestore(doc)));
      }
    } catch (e) {
      print("Error cargando niveles existentes: $e");
    }

    if (_levels.isEmpty) {
      _addLevel();
    }

    if (mounted) {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  void dispose() {
    _systemNameController.dispose();
    super.dispose();
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
    showDialog(context: context, builder: (context) => AlertDialog(
      title: Text(l10n.pickAColor),
      content: SingleChildScrollView(child: ColorPicker(pickerColor: pickerColor, onColorChanged: (color) => pickerColor = color)),
      actions: [ElevatedButton(child: Text(l10n.select), onPressed: () {
        setState(() => _levels[index].color = pickerColor);
        Navigator.of(context).pop();
      })],
    ));
  }

  Future<void> _saveAndContinue() async {
    if (_systemNameController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(l10n.progressionSystemNameRequired)));
      return;
    }
    if (_levels.any((level) => level.name.trim().isEmpty)) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(l10n.allLevelsNeedAName)));
      return;
    }

    setState(() { _isLoading = true; });

    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) throw Exception(l10n.notAuthenticatedUser);

      final firestore = FirebaseFirestore.instance;
      final disciplineRef = firestore.collection('schools').doc(widget.schoolId).collection('disciplines').doc(widget.disciplineDoc.id);
      final batch = firestore.batch();

      batch.update(disciplineRef, {'progressionSystemName': _systemNameController.text.trim()});

      final oldLevels = await disciplineRef.collection('levels').get();
      for (final doc in oldLevels.docs) {
        batch.delete(doc.reference);
      }

      for (int i = 0; i < _levels.length; i++) {
        _levels[i].order = i;
        final levelRef = disciplineRef.collection('levels').doc();
        batch.set(levelRef, _levels[i].toJson());
      }
      await batch.commit();

      if (!mounted) return;

      // Al guardar, volvemos al panel. El usuario decidirá si configurar otra disciplina o continuar.
      Navigator.of(context).pop();

    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(l10n.saveError(e.toString()))));
    } finally {
      if (mounted) setState(() { _isLoading = false; });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
        appBar: AppBar(title: Text(l10n.loading)),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.levelsFor(_disciplineName)),
        backgroundColor: _primaryColor,
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
                decoration: InputDecoration(
                  labelText: l10n.progressionSystemName,
                  hintText: l10n.progressionSystemHint,
                ),
              ),
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
                      title: TextField(
                        controller: TextEditingController(text: _levels[index].name),
                        onChanged: (value) => _levels[index].name = value,
                        decoration: InputDecoration(hintText: l10n.levelNameHint),
                      ),
                      trailing: Row(mainAxisSize: MainAxisSize.min, children: [
                        IconButton(icon: const Icon(Icons.delete_outline), onPressed: () => _removeLevel(index)),
                        const Icon(Icons.drag_handle),
                      ],
                      ),
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
              ElevatedButton.icon(
                icon: const Icon(Icons.add),
                label: Text(l10n.addLevel),
                onPressed: _addLevel,
              ),
              const SizedBox(height: 32),
              if (_isLoading)
                const Center(child: CircularProgressIndicator())
              else
                ElevatedButton(
                  style: ElevatedButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 16), backgroundColor: _primaryColor),
                  onPressed: _saveAndContinue,
                  child: const Text('Guardar y Volver al Panel', style: TextStyle(color: Colors.white)), // TODO: Localizar
                ),
            ],
          ),
        ),
      ),
    );
  }
}
