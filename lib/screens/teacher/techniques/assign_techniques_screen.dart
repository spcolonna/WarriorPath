import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:warrior_path/models/technique_model.dart';

import '../../../l10n/app_localizations.dart';

class AssignTechniquesScreen extends StatefulWidget {
  final String schoolId;
  final String studentId;
  final String disciplineId;
  final String disciplineName;
  final List<String> alreadyAssignedIds;

  const AssignTechniquesScreen({
    super.key,
    required this.schoolId,
    required this.studentId,
    required this.disciplineId,
    required this.disciplineName,
    required this.alreadyAssignedIds,
  });

  @override
  _AssignTechniquesScreenState createState() => _AssignTechniquesScreenState();
}

class _AssignTechniquesScreenState extends State<AssignTechniquesScreen> {
  late AppLocalizations l10n;
  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    l10n = AppLocalizations.of(context);
  }

  late Future<Map<String, List<TechniqueModel>>> _techniquesFuture;
  late Set<String> _selectedIds;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _selectedIds = Set<String>.from(widget.alreadyAssignedIds);
    _techniquesFuture = _fetchAndGroupTechniques();
  }

  Future<Map<String, List<TechniqueModel>>> _fetchAndGroupTechniques() async {
    final snapshot = await FirebaseFirestore.instance
        .collection('schools').doc(widget.schoolId)
        .collection('disciplines').doc(widget.disciplineId) // <-- Ruta actualizada
        .collection('techniques').get();

    final Map<String, List<TechniqueModel>> grouped = {};
    for (var doc in snapshot.docs) {
      final tech = TechniqueModel.fromFirestore(doc);
      if (grouped[tech.category] == null) grouped[tech.category] = [];
      grouped[tech.category]!.add(tech);
    }
    return grouped;
  }

  Future<void> _saveAssignments() async {
    setState(() => _isLoading = true);
    try {
      final fieldToUpdate = 'progress.${widget.disciplineId}.assignedTechniqueIds';

      await FirebaseFirestore.instance
          .collection('schools').doc(widget.schoolId)
          .collection('members').doc(widget.studentId)
          .update({
        fieldToUpdate: _selectedIds.toList(),
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(l10n.techniquesAssignedSuccess), backgroundColor: Colors.green));
        Navigator.of(context).pop();
      }
    } catch(e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(l10n.saveError(e.toString()))));
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.assignTechniquesFor(widget.disciplineName)),
      ),
      body: FutureBuilder<Map<String, List<TechniqueModel>>>(
        future: _techniquesFuture,
        builder: (context, snapshot) {
          if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
          final groupedTechniques = snapshot.data!;
          if (groupedTechniques.isEmpty) {
            return Center(child: Text(l10n.noTechniquesForDiscipline));
          }
          return ListView(
            children: groupedTechniques.entries.map((entry) {
              return ExpansionTile(
                title: Text(entry.key, style: const TextStyle(fontWeight: FontWeight.bold)),
                initiallyExpanded: true,
                children: entry.value.map((tech) {
                  return CheckboxListTile(
                    title: Text(tech.name),
                    value: _selectedIds.contains(tech.id),
                    onChanged: (value) {
                      setState(() {
                        if (value == true) {
                          _selectedIds.add(tech.id!);
                        } else {
                          _selectedIds.remove(tech.id!);
                        }
                      });
                    },
                  );
                }).toList(),
              );
            }).toList(),
          );
        },
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _isLoading ? null : _saveAssignments,
        label: Text(l10n.saveAssignments),
        icon: const Icon(Icons.save),
      ),
    );
  }
}
