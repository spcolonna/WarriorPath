import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:warrior_path/models/technique_model.dart';
import 'package:warrior_path/services/student_progress_service.dart';

import '../../l10n/app_localizations.dart';

/// Permite al alumno marcar las técnicas que ya sabe.
///
/// Es el equivalente del lado del alumno de `AssignTechniquesScreen`, pero con
/// una diferencia importante: lo que marca acá va a `selfReportedTechniqueIds`,
/// una lista aparte de la del maestro. Las que el maestro ya le confirmó
/// aparecen marcadas y bloqueadas — el alumno no puede desmarcarse algo que el
/// maestro le dio por sabido.
class SelfReportTechniquesScreen extends StatefulWidget {
  final String schoolId;
  final String studentId;
  final String disciplineId;

  /// Técnicas que ya confirmó el maestro (se muestran fijas).
  final List<String> assignedByTeacher;

  /// Técnicas que el alumno ya había declarado antes.
  final List<String> initiallySelfReported;

  const SelfReportTechniquesScreen({
    super.key,
    required this.schoolId,
    required this.studentId,
    required this.disciplineId,
    required this.assignedByTeacher,
    required this.initiallySelfReported,
  });

  @override
  State<SelfReportTechniquesScreen> createState() =>
      _SelfReportTechniquesScreenState();
}

class _SelfReportTechniquesScreenState
    extends State<SelfReportTechniquesScreen> {
  late AppLocalizations l10n;
  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    l10n = AppLocalizations.of(context);
  }

  late Future<Map<String, List<TechniqueModel>>> _techniquesFuture;
  late Set<String> _selected;
  late Set<String> _teacherAssigned;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _teacherAssigned = widget.assignedByTeacher.toSet();
    _selected = widget.initiallySelfReported.toSet();
    _techniquesFuture = _fetchAndGroup();
  }

  Future<Map<String, List<TechniqueModel>>> _fetchAndGroup() async {
    final snapshot = await FirebaseFirestore.instance
        .collection('schools')
        .doc(widget.schoolId)
        .collection('disciplines')
        .doc(widget.disciplineId)
        .collection('techniques')
        .get();

    final grouped = <String, List<TechniqueModel>>{};
    for (final doc in snapshot.docs) {
      final tech = TechniqueModel.fromFirestore(doc);
      grouped.putIfAbsent(tech.category, () => []).add(tech);
    }
    return grouped;
  }

  Future<void> _save() async {
    setState(() => _saving = true);
    try {
      final original = widget.initiallySelfReported.toSet();
      final added = _selected.difference(original);
      final removed = original.difference(_selected);

      // Se guarda de a una con arrayUnion/arrayRemove para no pisar lo que el
      // maestro pueda haber cambiado mientras esta pantalla estaba abierta.
      for (final id in added) {
        await StudentProgressService.setSelfReportedTechnique(
          schoolId: widget.schoolId,
          studentId: widget.studentId,
          disciplineId: widget.disciplineId,
          techniqueId: id,
          reported: true,
        );
      }
      for (final id in removed) {
        await StudentProgressService.setSelfReportedTechnique(
          schoolId: widget.schoolId,
          studentId: widget.studentId,
          disciplineId: widget.disciplineId,
          techniqueId: id,
          reported: false,
        );
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(l10n.techniquesReportedSuccess),
            backgroundColor: Colors.green,
          ),
        );
        Navigator.of(context).pop(true);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(l10n.saveError(e.toString()))),
        );
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(l10n.myTechniquesTitle)),
      body: Column(
        children: [
          Container(
            width: double.infinity,
            color: Colors.blue.withValues(alpha: 0.07),
            padding: const EdgeInsets.all(16),
            child: Text(
              l10n.myTechniquesHelp,
              style: TextStyle(fontSize: 13.5, color: Colors.grey.shade800),
            ),
          ),
          Expanded(
            child: FutureBuilder<Map<String, List<TechniqueModel>>>(
              future: _techniquesFuture,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                final grouped = snapshot.data ?? {};
                if (grouped.isEmpty) {
                  return Center(
                    child: Padding(
                      padding: const EdgeInsets.all(24),
                      child: Text(
                        l10n.noTechniquesDefined,
                        textAlign: TextAlign.center,
                      ),
                    ),
                  );
                }

                final categories = grouped.keys.toList()..sort();
                return ListView.builder(
                  itemCount: categories.length,
                  itemBuilder: (context, i) {
                    final category = categories[i];
                    final techs = grouped[category]!;
                    return ExpansionTile(
                      title: Text(
                        category,
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                      initiallyExpanded: true,
                      children: techs.map((t) {
                        final confirmed = _teacherAssigned.contains(t.id);
                        return CheckboxListTile(
                          title: Text(t.name),
                          subtitle: confirmed
                              ? Text(
                                  l10n.confirmedByTeacher,
                                  style: const TextStyle(
                                    fontSize: 12,
                                    color: Colors.green,
                                  ),
                                )
                              : null,
                          value: confirmed || _selected.contains(t.id),
                          // Lo que el maestro ya confirmó no se puede desmarcar.
                          onChanged: confirmed
                              ? null
                              : (v) => setState(() {
                                    if (v == true) {
                                      _selected.add(t.id!);
                                    } else {
                                      _selected.remove(t.id);
                                    }
                                  }),
                        );
                      }).toList(),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _saving ? null : _save,
        icon: _saving
            ? const SizedBox(
                width: 18,
                height: 18,
                child: CircularProgressIndicator(
                    strokeWidth: 2, color: Colors.white),
              )
            : const Icon(Icons.save),
        label: Text(l10n.save),
      ),
    );
  }
}
