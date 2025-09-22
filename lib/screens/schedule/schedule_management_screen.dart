import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:warrior_path/screens/schedule/add_edit_schedule_screen.dart';

import '../../l10n/app_localizations.dart';

class ScheduleManagementScreen extends StatefulWidget {
  final String schoolId;
  const ScheduleManagementScreen({Key? key, required this.schoolId}) : super(key: key);

  @override
  State<ScheduleManagementScreen> createState() => _ScheduleManagementScreenState();
}

class _ScheduleManagementScreenState extends State<ScheduleManagementScreen> {
  late AppLocalizations l10n;
  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    l10n = AppLocalizations.of(context);
    super.didChangeDependencies();
    _dayLabels = [
      l10n.monday, l10n.tuesday, l10n.wednesday, l10n.thursday,
      l10n.friday, l10n.saturday, l10n.sunday,
    ];
  }

  late Future<Map<String, String>> _disciplinesMapFuture;
  late final List<String> _dayLabels;

  @override
  void initState() {
    super.initState();
    _disciplinesMapFuture = _fetchDisciplinesAsMap();
  }

  Future<Map<String, String>> _fetchDisciplinesAsMap() async {
    final disciplinesSnapshot = await FirebaseFirestore.instance
        .collection('schools')
        .doc(widget.schoolId)
        .collection('disciplines')
        .get();

    final Map<String, String> disciplinesMap = {};
    for (var doc in disciplinesSnapshot.docs) {
      disciplinesMap[doc.id] = (doc.data()['name'] as String?) ?? 'Disciplina sin nombre';
    }
    return disciplinesMap;
  }

  void _deleteSchedule(String scheduleId) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(l10n.confirmDeletion),
        content: Text(l10n.confirmDeleteSchedule),
        actions: [
          TextButton(onPressed: () => Navigator.of(ctx).pop(), child: Text(l10n.cancel)),
          TextButton(
            onPressed: () {
              FirebaseFirestore.instance
                  .collection('schools')
                  .doc(widget.schoolId)
                  .collection('classSchedules')
                  .doc(scheduleId)
                  .delete();
              Navigator.of(ctx).pop();
            },
            child: Text(l10n.eliminate, style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.manageSchedules),
      ),
      body: FutureBuilder<Map<String, String>>(
        future: _disciplinesMapFuture,
        builder: (context, disciplinesSnapshot) {
          if (disciplinesSnapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (disciplinesSnapshot.hasError) {
            return const Center(child: Text('Error al cargar disciplinas.'));
          }

          final disciplinesMap = disciplinesSnapshot.data ?? {};

          return StreamBuilder<QuerySnapshot>(
            stream: FirebaseFirestore.instance
                .collection('schools')
                .doc(widget.schoolId)
                .collection('classSchedules')
                .orderBy('dayOfWeek')
                .orderBy('startTime')
                .snapshots(),
            builder: (context, scheduleSnapshot) {
              if (scheduleSnapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }
              if (!scheduleSnapshot.hasData || scheduleSnapshot.data!.docs.isEmpty) {
                return Center(
                  child: Text(l10n.noSchedulesDefined, textAlign: TextAlign.center),
                );
              }

              final Map<int, List<QueryDocumentSnapshot>> groupedSchedules = {};
              for (var doc in scheduleSnapshot.data!.docs) {
                final day = doc['dayOfWeek'] as int;
                if (groupedSchedules[day] == null) groupedSchedules[day] = [];
                groupedSchedules[day]!.add(doc);
              }

              return ListView.builder(
                itemCount: 7,
                itemBuilder: (context, index) {
                  final dayIndex = index + 1;
                  final schedulesForDay = groupedSchedules[dayIndex] ?? [];
                  if (schedulesForDay.isEmpty) return const SizedBox.shrink();

                  return Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(_dayLabels[index], style: Theme.of(context).textTheme.titleLarge),
                        const Divider(),
                        ...schedulesForDay.map((doc) {
                          final data = doc.data() as Map<String, dynamic>;
                          // --- CAMBIO: Obtenemos el nombre de la disciplina del mapa ---
                          final disciplineId = data['disciplineId'] as String?;
                          final disciplineName = disciplinesMap[disciplineId] ?? l10n.noDiscipline;

                          return Card(
                            child: ListTile(
                              title: Text(data['title']),
                              // --- CAMBIO: Mostramos la disciplina en el subtítulo ---
                              subtitle: Text('$disciplineName | ${data['startTime']} - ${data['endTime']}'),
                              trailing: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  IconButton(
                                    icon: const Icon(Icons.delete, color: Colors.red),
                                    onPressed: () => _deleteSchedule(doc.id),
                                  ),
                                ],
                              ),
                            ),
                          );
                        }),
                      ],
                    ),
                  );
                },
              );
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Navigator.of(context).push(
            MaterialPageRoute(
              builder: (context) => AddEditScheduleScreen(schoolId: widget.schoolId),
            ),
          );
        },
        child: const Icon(Icons.add),
      ),
    );
  }
}
