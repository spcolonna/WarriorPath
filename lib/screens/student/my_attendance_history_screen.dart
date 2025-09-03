import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class MyAttendanceHistoryScreen extends StatelessWidget {
  final String schoolId;
  final String studentId;

  const MyAttendanceHistoryScreen({
    Key? key,
    required this.schoolId,
    required this.studentId,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Mi Asistencia'),
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
