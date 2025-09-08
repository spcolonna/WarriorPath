import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:warrior_path/models/technique_model.dart';

class AssignTechniquesScreen extends StatefulWidget {
  final String schoolId;
  final String studentId;
  final List<String> alreadyAssignedIds;

  const AssignTechniquesScreen({
    Key? key,
    required this.schoolId,
    required this.studentId,
    required this.alreadyAssignedIds,
  }) : super(key: key);

  @override
  _AssignTechniquesScreenState createState() => _AssignTechniquesScreenState();
}

class _AssignTechniquesScreenState extends State<AssignTechniquesScreen> {
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
    final snapshot = await FirebaseFirestore.instance.collection('schools').doc(widget.schoolId).collection('techniques').get();
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
      await FirebaseFirestore.instance.collection('schools').doc(widget.schoolId).collection('members').doc(widget.studentId).update({
        'assignedTechniqueIds': _selectedIds.toList(),
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Técnicas asignadas con éxito.'), backgroundColor: Colors.green));
        Navigator.of(context).pop();
      }
    } catch(e) {
      // ... (manejo de error)
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Asignar Técnicas')),
      body: FutureBuilder<Map<String, List<TechniqueModel>>>(
        future: _techniquesFuture,
        builder: (context, snapshot) {
          if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
          final groupedTechniques = snapshot.data!;
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
        label: const Text('Guardar Asignaciones'),
        icon: const Icon(Icons.save),
      ),
    );
  }
}
