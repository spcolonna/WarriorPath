import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:confetti/confetti.dart';
import 'package:firebase_auth/firebase_auth.dart';
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
  late Stream<QuerySnapshot> _attendanceStream;
  late ConfettiController _confettiController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
    _confettiController = ConfettiController(duration: const Duration(seconds: 3));

    final firestore = FirebaseFirestore.instance;
    _memberStream = firestore.collection('schools').doc(widget.schoolId).collection('members').doc(widget.studentId).snapshots();
    _attendanceStream = firestore.collection('schools').doc(widget.schoolId).collection('attendanceRecords').where('presentStudentIds', arrayContains: widget.studentId).orderBy('date', descending: true).snapshots();
  }

  @override
  void dispose() {
    _tabController.dispose();
    _confettiController.dispose();
    super.dispose();
  }

  Future<Map<String, dynamic>?> _fetchLevelDetails(String? levelId) async {
    if (levelId == null) return null;
    final levelDoc = await FirebaseFirestore.instance.collection('schools').doc(widget.schoolId).collection('levels').doc(levelId).get();
    if (!levelDoc.exists) return {'name': 'Nivel no encontrado', 'colorValue': Colors.red.value, 'order': -1, 'id': levelId};
    return {...levelDoc.data()!, 'id': levelDoc.id};
  }

  Future<void> _showPromotionDialog(String currentLevelId, int currentLevelOrder) async {
    final levelsSnapshot = await FirebaseFirestore.instance
        .collection('schools')
        .doc(widget.schoolId)
        .collection('levels')
        .orderBy('order')
        .get();

    final List<DocumentSnapshot> availableLevels = levelsSnapshot.docs;
    DocumentSnapshot? selectedNextLevel;
    final notesController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              title: const Text('Promover Alumno'),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  DropdownButtonFormField<DocumentSnapshot>(
                    hint: const Text('Selecciona el nuevo nivel'),
                    value: selectedNextLevel,
                    items: availableLevels.map((levelDoc) {
                      return DropdownMenuItem<DocumentSnapshot>(
                        value: levelDoc,
                        child: Text(levelDoc['name']),
                      );
                    }).toList(),
                    onChanged: (value) {
                      setDialogState(() => selectedNextLevel = value);
                    },
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: notesController,
                    decoration: const InputDecoration(labelText: 'Notas (opcional)'),
                    maxLines: 3,
                  ),
                ],
              ),
              actions: [
                TextButton(onPressed: () => Navigator.of(context).pop(), child: const Text('Cancelar')),
                ElevatedButton(
                  onPressed: selectedNextLevel == null ? null : () {
                    _promoteStudent(
                      currentLevelId: currentLevelId,
                      newLevelSnapshot: selectedNextLevel!,
                      notes: notesController.text,
                    );
                    Navigator.of(context).pop();
                  },
                  child: const Text('Confirmar'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  Future<void> _promoteStudent({
    required String currentLevelId,
    required DocumentSnapshot newLevelSnapshot,
    required String notes,
  }) async {
    try {
      final firestore = FirebaseFirestore.instance;
      final memberRef = firestore.collection('schools').doc(widget.schoolId).collection('members').doc(widget.studentId);
      final newLevelId = newLevelSnapshot.id;

      final batch = firestore.batch();
      batch.update(memberRef, {
        'currentLevelId': newLevelId,
        'hasUnseenPromotion': true,
      });
      final historyRef = memberRef.collection('progressionHistory').doc();
      batch.set(historyRef, {
        'date': Timestamp.now(),
        'previousLevelId': currentLevelId,
        'newLevelId': newLevelId,
        'notes': notes.trim(),
        'promotedBy': FirebaseAuth.instance.currentUser?.uid,
      });
      await batch.commit();

      _confettiController.play();
      if(mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('¡Alumno promovido con éxito!')));

    } catch (e) {
      if(mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error al promover: ${e.toString()}')));
    }
  }

  // --- MÉTODO build() COMPLETO ---
  @override
  Widget build(BuildContext context) {
    return Stack(
      alignment: Alignment.topCenter,
      children: [
        StreamBuilder<DocumentSnapshot>(
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
            final currentLevelId = memberData['currentLevelId'] ?? memberData['initialLevelId'];

            return Scaffold(
              appBar: AppBar(
                title: Text(studentName),
              ),
              body: Column(
                children: [
                  Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: FutureBuilder<Map<String, dynamic>?>(
                      future: _fetchLevelDetails(currentLevelId),
                      builder: (context, levelSnapshot) {
                        if (levelSnapshot.connectionState == ConnectionState.waiting) {
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
                                  backgroundImage: (photoUrl != null && photoUrl.isNotEmpty) ? NetworkImage(photoUrl) : null,
                                  child: (photoUrl == null || photoUrl.isEmpty) ? const Icon(Icons.person, size: 40) : null,
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
                        _buildAttendanceHistoryTab(),
                        const Center(child: Text('Historial de Pagos')),
                        const Center(child: Text('Historial de Exámenes y Promociones')),
                      ],
                    ),
                  ),
                ],
              ),
              floatingActionButton: FloatingActionButton.extended(
                onPressed: () {
                  _fetchLevelDetails(currentLevelId).then((levelData) {
                    if (levelData != null) {
                      _showPromotionDialog(levelData['id'], levelData['order']);
                    } else {
                      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('No se pudo cargar el nivel actual del alumno.')));
                    }
                  });
                },
                label: const Text('Promover Nivel'),
                icon: const Icon(Icons.arrow_upward),
              ),
            );
          },
        ),
        ConfettiWidget(
          confettiController: _confettiController,
          blastDirectionality: BlastDirectionality.explosive,
          shouldLoop: false,
          numberOfParticles: 30,
          emissionFrequency: 0.05,
          maxBlastForce: 20,
          minBlastForce: 8,
          gravity: 0.3,
          colors: const [Colors.green, Colors.blue, Colors.pink, Colors.orange, Colors.purple],
        ),
      ],
    );
  }

  Widget _buildAttendanceHistoryTab() {
    return StreamBuilder<QuerySnapshot>(
      stream: _attendanceStream,
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
