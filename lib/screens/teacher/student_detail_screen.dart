import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

class StudentDetailScreen extends StatefulWidget {
  final String schoolId;
  final String studentId;

  const StudentDetailScreen({
    Key? key,
    required this.schoolId,
    required this.studentId,
  }) : super(key: key);

  @override
  _StudentDetailScreenState createState() => _StudentDetailScreenState();
}

class _StudentDetailScreenState extends State<StudentDetailScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  late Stream<DocumentSnapshot> _memberStream;
  late Stream<QuerySnapshot> _attendanceStream; // Declarado aquí

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);

    final firestore = FirebaseFirestore.instance;

    // Se define el stream del miembro una sola vez
    _memberStream = firestore
        .collection('schools')
        .doc(widget.schoolId)
        .collection('members')
        .doc(widget.studentId)
        .snapshots();

    // Se define el stream de asistencia una sola vez
    _attendanceStream = firestore
        .collection('schools')
        .doc(widget.schoolId)
        .collection('attendanceRecords')
        .where('presentStudentIds', arrayContains: widget.studentId)
        .orderBy('date', descending: true)
        .snapshots();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<Map<String, dynamic>?> _fetchLevelDetails(String? levelId) async {
    if (levelId == null) return null;
    final levelDoc = await FirebaseFirestore.instance
        .collection('schools')
        .doc(widget.schoolId)
        .collection('levels')
        .doc(levelId)
        .get();
    return levelDoc.data();
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<DocumentSnapshot>(
      stream: _memberStream,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Scaffold(appBar: AppBar(), body: const Center(child: CircularProgressIndicator()));
        }
        if (!snapshot.hasData || !snapshot.data!.exists) {
          return Scaffold(appBar: AppBar(), body: const Center(child: Text('No se encontró al alumno.')));
        }

        final memberData = snapshot.data!.data() as Map<String, dynamic>;
        final studentName = memberData['displayName'] ?? 'Alumno';
        final levelId = memberData['initialLevelId']; // Asumimos que aquí está el ID del nivel

        return Scaffold(
          appBar: AppBar(
            title: Text(studentName),
          ),
          body: Column(
            children: [
              // --- CABECERA CON DATOS PRINCIPALES ---
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: FutureBuilder<Map<String, dynamic>?>(
                  future: _fetchLevelDetails(levelId),
                  builder: (context, levelSnapshot) {
                    if (levelSnapshot.connectionState == ConnectionState.waiting) {
                      // Muestra un placeholder mientras carga el nivel
                      return Row(children: [const CircleAvatar(radius: 40), const SizedBox(width: 16), Expanded(child: Text(studentName, style: Theme.of(context).textTheme.headlineSmall))]);
                    }

                    final levelData = levelSnapshot.data;
                    final levelName = levelData?['name'] ?? 'Sin Nivel';
                    final levelColor = levelData != null ? Color(levelData['colorValue']) : Colors.grey;

                    return Row(
                      children: [
                        FutureBuilder<DocumentSnapshot>(
                          future: FirebaseFirestore.instance.collection('users').doc(widget.studentId).get(),
                          builder: (context, userSnapshot) {
                            if (!userSnapshot.hasData) {
                              return const CircleAvatar(radius: 40);
                            }
                            final photoUrl = (userSnapshot.data!.data() as Map<String, dynamic>)['photoUrl'] as String?;
                            return CircleAvatar(
                              radius: 40,
                              backgroundImage: (photoUrl != null && photoUrl.isNotEmpty)
                                  ? NetworkImage(photoUrl)
                                  : null,
                              child: (photoUrl == null || photoUrl.isEmpty)
                                  ? const Icon(Icons.person, size: 40)
                                  : null,
                            );
                          },
                        ),
                        const SizedBox(width: 16),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(studentName, style: Theme.of(context).textTheme.headlineSmall),
                            Chip(
                              label: Text(levelName, style: const TextStyle(color: Colors.white)),
                              backgroundColor: levelColor,
                            ),
                          ],
                        ),
                      ],
                    );
                  },
                ),
              ),

              // --- PESTAÑAS DE INFORMACIÓN ---
              TabBar(
                controller: _tabController,
                isScrollable: true,
                tabs: const [
                  Tab(text: 'General'),
                  Tab(text: 'Asistencia'),
                  Tab(text: 'Pagos'),
                  Tab(text: 'Progreso'),
                ],
              ),
              Expanded(
                child: TabBarView(
                  controller: _tabController,
                  children: [
                    const Center(child: Text('Información de Contacto y Emergencia')),
                    _buildAttendanceHistoryTab(_attendanceStream), // Se pasa el stream
                    const Center(child: Text('Historial de Pagos')),
                    const Center(child: Text('Historial de Exámenes y Promociones')),
                  ],
                ),
              ),
            ],
          ),
          // --- BOTONES DE ACCIÓN ---
          floatingActionButton: FloatingActionButton.extended(
            onPressed: () {
              // TODO: Lógica para promover de nivel
            },
            label: const Text('Promover Nivel'),
            icon: const Icon(Icons.arrow_upward),
          ),
        );
      },
    );
  }

  // Este widget ahora RECIBE el stream en lugar de crearlo
  Widget _buildAttendanceHistoryTab(Stream<QuerySnapshot> stream) {
    return StreamBuilder<QuerySnapshot>(
      stream: stream,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        if (snapshot.hasError) {
          print('ERROR DEL STREAM DE ASISTENCIA: ${snapshot.error}');
          return const Center(child: Text('Error al cargar el historial.'));
        }
        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
          return const Center(child: Text('No hay registros de asistencia para este alumno.'));
        }

        return ListView.builder(
          itemCount: snapshot.data!.docs.length,
          itemBuilder: (context, index) {
            final record = snapshot.data!.docs[index].data() as Map<String, dynamic>;
            final date = (record['date'] as Timestamp).toDate();
            final formattedDate = '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year}';


            return ListTile(
              leading: const Icon(Icons.check_circle, color: Colors.green),
              title: Text(record['scheduleTitle'] ?? 'Clase'),
              trailing: Text(formattedDate),
            );
          },
        );
      },
    );
  }
}
