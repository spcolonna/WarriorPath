import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:warrior_path/services/attendance_service.dart';

import '../../l10n/app_localizations.dart';

class MyAttendanceHistoryScreen extends StatelessWidget {
  final String schoolId;
  final String studentId;

  const MyAttendanceHistoryScreen({
    super.key,
    required this.schoolId,
    required this.studentId,
  });

  /// Carga una clase pasada a la que el alumno fue pero no quedó registrada.
  ///
  /// Se limita a los últimos 30 días: cubre el olvido real sin permitir cargar
  /// meses enteros de golpe.
  Future<void> _addPastAttendance(BuildContext context) async {
    final l10n = AppLocalizations.of(context);
    final now = DateTime.now();

    final date = await showDatePicker(
      context: context,
      initialDate: now,
      firstDate: AttendanceService.studentEarliestDate(),
      lastDate: now,
      helpText: l10n.registerPausedAssistance,
    );
    if (date == null || !context.mounted) return;

    final schedules = await AttendanceService.schedulesForDate(
      schoolId: schoolId,
      date: date,
    );
    if (!context.mounted) return;

    if (schedules.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l10n.noClassForTHisDay)),
      );
      return;
    }

    final chosen = await showDialog<QueryDocumentSnapshot<Map<String, dynamic>>>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(l10n.classFor(DateFormat('dd/MM/yyyy').format(date))),
        content: SizedBox(
          width: double.maxFinite,
          child: ListView(
            shrinkWrap: true,
            children: schedules.map((s) {
              final d = s.data();
              return ListTile(
                title: Text(d['title'] ?? ''),
                subtitle: Text('${d['startTime']} - ${d['endTime']}'),
                onTap: () => Navigator.of(ctx).pop(s),
              );
            }).toList(),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: Text(l10n.cancel),
          ),
        ],
      ),
    );
    if (chosen == null || !context.mounted) return;

    try {
      await AttendanceService.markPresent(
        schoolId: schoolId,
        studentId: studentId,
        scheduleTitle: chosen.data()['title'] ?? '',
        scheduleId: chosen.id,
        date: date,
      );
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(l10n.successAssistance),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(l10n.saveError(e.toString()))),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Scaffold(
      appBar: AppBar(
        title: const Text('Mi Asistencia'),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _addPastAttendance(context),
        icon: const Icon(Icons.event_available),
        label: Text(l10n.registerPausedAssistance),
      ),
      body: StreamBuilder<QuerySnapshot>(
        // La consulta es la misma que usamos para la vista del profesor
        stream: FirebaseFirestore.instance
            .collection('schools')
            .doc(schoolId)
            .collection('attendanceRecords')
            .where('presentStudentIds', arrayContains: studentId)
            .orderBy('date', descending: true)
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return const Center(child: Text('Error al cargar tu historial.'));
          }
          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return const Center(child: Text('Aún no tienes asistencias registradas.'));
          }

          final records = snapshot.data!.docs;

          return ListView.builder(
            itemCount: records.length,
            itemBuilder: (context, index) {
              final recordData = records[index].data() as Map<String, dynamic>;
              final date = (recordData['date'] as Timestamp).toDate();
              final formattedDate = DateFormat('EEEE dd \'de\' MMMM, yyyy', 'es_ES').format(date);

              return ListTile(
                leading: const Icon(Icons.check_circle, color: Colors.green),
                title: Text(recordData['scheduleTitle'] ?? 'Clase'),
                subtitle: Text(formattedDate),
              );
            },
          );
        },
      ),
    );
  }
}
