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
  late final List<String> _dayLabels;
  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    l10n = AppLocalizations.of(context);
    _dayLabels = [
      l10n.monday,
      l10n.tuesday,
      l10n.wednesday,
      l10n.thursday,
      l10n.friday,
      l10n.saturday,
      l10n.sunday,
    ];
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
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('schools')
            .doc(widget.schoolId)
            .collection('classSchedules')
            .orderBy('dayOfWeek')
            .orderBy('startTime')
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return Center(
              child: Text(l10n.noSchedulesDefined, textAlign: TextAlign.center),
            );
          }

          final Map<int, List<QueryDocumentSnapshot>> groupedSchedules = {};
          for (var doc in snapshot.data!.docs) {
            final day = doc['dayOfWeek'] as int;
            if (groupedSchedules[day] == null) {
              groupedSchedules[day] = [];
            }
            groupedSchedules[day]!.add(doc);
          }

          return ListView.builder(
            itemCount: 7, // Lunes a Domingo
            itemBuilder: (context, index) {
              final dayIndex = index + 1;
              final schedulesForDay = groupedSchedules[dayIndex] ?? [];

              if (schedulesForDay.isEmpty) {
                return const SizedBox.shrink(); // No mostrar nada si no hay clases ese día
              }

              return Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(_dayLabels[index], style: Theme.of(context).textTheme.titleLarge),
                    const Divider(),
                    ...schedulesForDay.map((doc) {
                      final data = doc.data() as Map<String, dynamic>;
                      return Card(
                        child: ListTile(
                          title: Text(data['title']),
                          subtitle: Text('${data['startTime']} - ${data['endTime']}'),
                          trailing: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              // IconButton(icon: const Icon(Icons.edit, color: Colors.blue), onPressed: () { /* TODO: Implementar edición */ }),
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
