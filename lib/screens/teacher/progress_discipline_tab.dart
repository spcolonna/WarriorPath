import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:collection/collection.dart';
import 'package:confetti/confetti.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:warrior_path/screens/teacher/techniques/assign_techniques_screen.dart';

import '../../l10n/app_localizations.dart';
import '../../models/discipline_model.dart';
import '../../models/level_model.dart';
import '../../models/technique_model.dart';

class ProgressDisciplineTab extends StatefulWidget {
  final String schoolId;
  final String studentId;
  final DisciplineModel discipline;
  final Map<String, dynamic> studentProgress;
  final ConfettiController confettiController;
  final bool isOwnerViewing;

  const ProgressDisciplineTab({
    super.key,
    required this.schoolId,
    required this.studentId,
    required this.discipline,
    required this.studentProgress,
    required this.confettiController,
    required this.isOwnerViewing,
  });

  @override
  State<ProgressDisciplineTab> createState() => _ProgressDisciplineTabState();
}

class _ProgressDisciplineTabState extends State<ProgressDisciplineTab> {
  late AppLocalizations l10n;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    l10n = AppLocalizations.of(context);
  }

  Future<List<QueryDocumentSnapshot>> _fetchLevelsForDiscipline() async {
    final snapshot = await FirebaseFirestore.instance
        .collection('schools').doc(widget.schoolId)
        .collection('disciplines').doc(widget.discipline.id)
        .collection('levels').orderBy('order').get();
    return snapshot.docs;
  }

  Future<void> _showPromotionDialog(String currentLevelId,
      int currentLevelOrder, List<QueryDocumentSnapshot> allLevels) async {
    DocumentSnapshot? selectedNextLevel;
    final notesController = TextEditingController();

    showDialog(context: context, builder: (context) =>
        StatefulBuilder(builder: (context, setDialogState) {
          return AlertDialog(
            title: Text(l10n.promotionOrChangeLevel),
            content: Column(mainAxisSize: MainAxisSize.min, children: [
              DropdownButtonFormField<DocumentSnapshot>(
                hint: Text(l10n.choseNewLevel), value: selectedNextLevel,
                items: allLevels
                    .map((levelDoc) =>
                    DropdownMenuItem<DocumentSnapshot>(
                        value: levelDoc, child: Text(levelDoc['name'])))
                    .toList(),
                onChanged: (value) =>
                    setDialogState(() => selectedNextLevel = value),
              ),
              const SizedBox(height: 16),
              TextField(controller: notesController,
                  decoration: InputDecoration(
                      labelText: ('${l10n.notesLabel} (${l10n.optional})'))),
            ]),
            actions: [
              TextButton(onPressed: () => Navigator.of(context).pop(),
                  child: Text(l10n.cancel)),
              ElevatedButton(
                onPressed: selectedNextLevel == null ? null : () {
                  _promoteStudent(currentLevelId: currentLevelId,
                      newLevelSnapshot: selectedNextLevel!,
                      notes: notesController.text);
                  Navigator.of(context).pop();
                },
                child: Text(l10n.confirm),
              ),
            ],
          );
        }));
  }

  Future<void> _promoteStudent(
      {required String currentLevelId, required DocumentSnapshot newLevelSnapshot, required String notes}) async {
    try {
      final firestore = FirebaseFirestore.instance;
      final memberRef = firestore
          .collection('schools')
          .doc(widget.schoolId)
          .collection('members')
          .doc(widget.studentId);
      final newLevelId = newLevelSnapshot.id;
      final batch = firestore.batch();

      batch.update(memberRef, {
        'progress.${widget.discipline.id}.currentLevelId': newLevelId,
        'hasUnseenPromotion': true // La bandera general se puede mantener
      });

      final historyRef = memberRef.collection('progressionHistory').doc();
      batch.set(historyRef, {
        'date': Timestamp.now(),
        'previousLevelId': currentLevelId,
        'newLevelId': newLevelId,
        'disciplineId': widget.discipline.id,
        'disciplineName': widget.discipline.name,
        // Guardamos contexto de la disciplina
        'type': 'level_promotion',
        'notes': notes.trim(),
        'promotedBy': FirebaseAuth.instance.currentUser?.uid
      });

      await batch.commit();
      widget.confettiController.play();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(l10n.studentSuccessPromotion)));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(l10n.promotionError(e.toString()))));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final currentLevelId = widget.studentProgress['currentLevelId'] as String?;
    final assignedTechniqueIds = List<String>.from(
        widget.studentProgress['assignedTechniqueIds'] ?? []);
    final roleInDiscipline = widget.studentProgress['role'] as String? ?? l10n.student;
    final primaryColor = Color(
        int.parse('FF${widget.discipline.theme['primaryColor']}', radix: 16));

    return ListView(
      padding: const EdgeInsets.all(16.0),
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Text(l10n.yourPath, style: Theme.of(context).textTheme.titleLarge),
            Chip(
              label: Text(
                roleInDiscipline[0].toUpperCase() + roleInDiscipline.substring(1),
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
              backgroundColor: primaryColor.withOpacity(0.1),
              side: BorderSide(color: primaryColor),
            )
          ],
        ),
        const SizedBox(height: 8),
        FutureBuilder<List<QueryDocumentSnapshot>>(
          future: _fetchLevelsForDiscipline(),
          builder: (context, levelsSnapshot) {
            if (!levelsSnapshot.hasData) {
              return const Center(child: CircularProgressIndicator());
            }
            if (levelsSnapshot.data!.isEmpty) {
              return Center(child: Text(l10n.noProgressSystemForDiscipline));
            }

            final allLevels = levelsSnapshot.data!;
            if (currentLevelId == null)
              return Center(child: Text(l10n.noLevelAssignedYet));

            final QueryDocumentSnapshot levelToUse;
            final foundLevel = allLevels.firstWhereOrNull((doc) =>
            doc.id == currentLevelId);

            if (foundLevel != null) {
              levelToUse = foundLevel;
            } else if (allLevels.isNotEmpty) {
              levelToUse = allLevels.first;
            } else {
              return Center(child: Text(l10n.noProgressSystemForDiscipline));
            }

            final currentLevelOrder = (levelToUse.data() as Map<String,
                dynamic>)['order'];

            return Column(
              children: [
                ListView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: allLevels.length,
                  itemBuilder: (context, index) {
                    final level = LevelModel.fromFirestore(allLevels[index]);
                    final isCompleted = level.order < currentLevelOrder;
                    final isCurrent = level.order == currentLevelOrder;
                    return ListTile(
                      leading: Icon(
                        isCompleted ? Icons.check_circle : (isCurrent ? Icons
                            .star : Icons.radio_button_unchecked),
                        color: isCurrent ? primaryColor : (isCompleted ? Colors
                            .green : Colors.grey),
                      ),
                      title: Text(level.name),
                    );
                  },
                ),
                const SizedBox(height: 16),
                if (widget.isOwnerViewing)
                  ElevatedButton.icon(
                    onPressed: () =>
                        _showPromotionDialog(
                            currentLevelId, currentLevelOrder, allLevels),
                    icon: const Icon(Icons.arrow_upward),
                    label: Text(l10n.levelPromotion),
                  )
              ],
            );
          },
        ),
        const Divider(height: 32),
        Text(l10n.assignedTechniques, style: Theme
            .of(context)
            .textTheme
            .titleLarge),
        const SizedBox(height: 8),

        if (assignedTechniqueIds.isNotEmpty)
          StreamBuilder<QuerySnapshot>(
            stream: FirebaseFirestore.instance
                .collection('schools')
                .doc(widget.schoolId)
                .collection('disciplines')
                .doc(widget.discipline.id)
                .collection('techniques')
                .where(FieldPath.documentId, whereIn: assignedTechniqueIds)
                .snapshots(),
            builder: (context, techSnapshot) {
              if (!techSnapshot.hasData) {
                return const Center(child: CircularProgressIndicator());
              }
              return Column(
                children: techSnapshot.data!.docs.map((doc) {
                  final tech = TechniqueModel.fromFirestore(doc);
                  return ListTile(
                      title: Text(tech.name), subtitle: Text(tech.category));
                }).toList(),
              );
            },
          )
        else
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 16.0),
            child: Center(child: Text(l10n.noTechniquesForDiscipline)),
          ),

        const SizedBox(height: 16),
        if (widget.isOwnerViewing)
          Center(
            child: ElevatedButton.icon(
              onPressed: () {
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (context) =>
                        AssignTechniquesScreen(
                          schoolId: widget.schoolId,
                          studentId: widget.studentId,
                          disciplineId: widget.discipline.id!,
                          disciplineName: widget.discipline.name,
                          alreadyAssignedIds: assignedTechniqueIds,
                        ),
                  ),
                );
              },
              icon: const Icon(Icons.add_task),
              label: Text(l10n.assignTechnic),
            ),
          ),
      ],
    );
  }
}
