import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

class AttendanceChecklistScreen extends StatefulWidget {
  final String schoolId;
  final String scheduleTitle;

  const AttendanceChecklistScreen({
    Key? key,
    required this.schoolId,
    required this.scheduleTitle,
  }) : super(key: key);

  @override
  _AttendanceChecklistScreenState createState() => _AttendanceChecklistScreenState();
}

class _AttendanceChecklistScreenState extends State<AttendanceChecklistScreen> {
  late Future<List<QueryDocumentSnapshot>> _studentsFuture;
  final Set<String> _presentStudentIds = {}; // Usamos un Set para eficiencia
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _studentsFuture = _fetchActiveStudents();
  }

  Future<List<QueryDocumentSnapshot>> _fetchActiveStudents() async {
    final snapshot = await FirebaseFirestore.instance
        .collection('schools')
        .doc(widget.schoolId)
        .collection('members')
        .where('status', isEqualTo: 'active')
        .get();
    return snapshot.docs;
  }

  Future<void> _saveAttendance() async {
    setState(() { _isLoading = true; });

    try {
      await FirebaseFirestore.instance
          .collection('schools')
          .doc(widget.schoolId)
          .collection('attendanceRecords')
          .add({
        'date': Timestamp.now(),
        'scheduleTitle': widget.scheduleTitle,
        'presentStudentIds': _presentStudentIds.toList(),
      });

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Asistencia guardada con éxito')),
      );
      Navigator.of(context).pop();

    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error al guardar: ${e.toString()}')),
      );
    } finally {
      if (mounted) {
        setState(() { _isLoading = false; });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Tomar Asistencia'),
            Text(widget.scheduleTitle, style: TextStyle(fontSize: 14, fontWeight: FontWeight.normal)),
          ],
        ),
      ),
      body: AbsorbPointer(
        absorbing: _isLoading,
        child: FutureBuilder<List<QueryDocumentSnapshot>>(
          future: _studentsFuture,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }
            if (!snapshot.hasData || snapshot.data!.isEmpty) {
              return const Center(child: Text('No hay alumnos activos en esta escuela.'));
            }

            final students = snapshot.data!;
            return Column(
              children: [
                Expanded(
                  child: ListView.builder(
                    itemCount: students.length,
                    itemBuilder: (context, index) {
                      final studentDoc = students[index];
                      final studentData = studentDoc.data() as Map<String, dynamic>;
                      final studentId = studentDoc.id;
                      final isPresent = _presentStudentIds.contains(studentId);

                      return CheckboxListTile(
                        title: Text(studentData['displayName'] ?? 'Sin Nombre'),
                        value: isPresent,
                        onChanged: (bool? value) {
                          setState(() {
                            if (value == true) {
                              _presentStudentIds.add(studentId);
                            } else {
                              _presentStudentIds.remove(studentId);
                            }
                          });
                        },
                      );
                    },
                  ),
                ),
                if (_isLoading) const Padding(padding: EdgeInsets.all(16.0), child: CircularProgressIndicator()),
              ],
            );
          },
        ),
      ),
      bottomNavigationBar: Padding(
        padding: const EdgeInsets.all(16.0),
        child: ElevatedButton.icon(
          icon: const Icon(Icons.save),
          label: const Text('Guardar Asistencia'),
          style: ElevatedButton.styleFrom(
            padding: const EdgeInsets.symmetric(vertical: 16),
          ),
          onPressed: _isLoading ? null : _saveAttendance,
        ),
      ),
    );
  }
}
