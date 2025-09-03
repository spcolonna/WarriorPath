import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:warrior_path/providers/session_provider.dart';
import 'package:warrior_path/screens/teacher/student_detail_screen.dart';

class StudentsTabScreen extends StatefulWidget {
  final int initialTabIndex;

  const StudentsTabScreen({
    Key? key,
    this.initialTabIndex = 0,
  }) : super(key: key);

  @override
  State<StudentsTabScreen> createState() => _StudentsTabScreenState();
}

class _StudentsTabScreenState extends State<StudentsTabScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(
      length: 3,
      vsync: this,
      initialIndex: widget.initialTabIndex,
    );
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // 2. OBTENEMOS EL schoolId DESDE EL PROVIDER
    final schoolId = Provider.of<SessionProvider>(context).activeSchoolId;

    if (schoolId == null) {
      return const Center(child: Text('Error: No hay una escuela activa en la sesión.'));
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Alumnos'),
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: 'Activos'),
            Tab(text: 'Pendientes'),
            Tab(text: 'Inactivos'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          // 3. PASAMOS EL schoolId COMO PARÁMETRO A LOS MÉTODOS QUE LO NECESITAN
          _buildStudentsList('active', schoolId),
          _buildStudentsList('pending', schoolId),
          _buildStudentsList('inactive', schoolId),
        ],
      ),
    );
  }

  Widget _buildStudentsList(String status, String schoolId) {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('schools')
          .doc(schoolId) // Usa el schoolId del provider
          .collection('members')
          .where('status', isEqualTo: status)
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
          return Center(child: Text('No hay alumnos en estado "$status".'));
        }

        return ListView.builder(
          itemCount: snapshot.data!.docs.length,
          itemBuilder: (context, index) {
            final doc = snapshot.data!.docs[index];

            if (status == 'pending') {
              return _buildPendingStudentCard(doc, schoolId);
            }

            final data = doc.data() as Map<String, dynamic>;
            return Card(
              margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
              child: ListTile(
                leading: const CircleAvatar(child: Icon(Icons.person)),
                title: Text(data['displayName'] ?? 'Sin Nombre'),
                trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                onTap: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (context) => StudentDetailScreen(
                        schoolId: schoolId,
                        studentId: doc.id,
                      ),
                    ),
                  );
                },
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildPendingStudentCard(QueryDocumentSnapshot doc, String schoolId) {
    final data = doc.data() as Map<String, dynamic>;
    final userId = doc.id;

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      child: Padding(
        padding: const EdgeInsets.all(8.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(data['displayName'] ?? 'Usuario sin nombre', style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 4),
            Text('Fecha de solicitud: ${ (data['applicationDate'] as Timestamp?)?.toDate().toLocal().toString().substring(0, 10) ?? 'N/A' }'),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton(
                  onPressed: () => _handleApplication(userId, false, schoolId),
                  child: const Text('Rechazar', style: TextStyle(color: Colors.red)),
                ),
                const SizedBox(width: 8),
                ElevatedButton(
                  onPressed: () => _handleApplication(userId, true, schoolId),
                  child: const Text('Aceptar'),
                ),
              ],
            )
          ],
        ),
      ),
    );
  }

  Future<void> _handleApplication(String userId, bool accept, String schoolId) async {
    final firestore = FirebaseFirestore.instance;
    final schoolMembersRef = firestore.collection('schools').doc(schoolId).collection('members').doc(userId);
    final userRef = firestore.collection('users').doc(userId);

    try {
      if (accept) {
        final levelsQuery = await firestore.collection('schools').doc(schoolId).collection('levels').orderBy('order').limit(1).get();
        if (levelsQuery.docs.isEmpty) {
          throw Exception('Tu escuela no tiene niveles configurados. Ve a Gestión -> Niveles para añadirlos.');
        }
        final initialLevelId = levelsQuery.docs.first.id;

        final batch = firestore.batch();

        batch.update(schoolMembersRef, {
          'status': 'active',
          'currentLevelId': initialLevelId,
          'joinDate': FieldValue.serverTimestamp(),
          'role': 'alumno',
        });

        batch.set(userRef, {
          'activeMemberships': {
            schoolId: 'alumno',
          },
          'pendingApplication': FieldValue.delete(),
        }, SetOptions(merge: true));

        await batch.commit();
        if(mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Alumno aceptado con éxito.')));

      } else {
        final batch = firestore.batch();
        batch.delete(schoolMembersRef);
        batch.update(userRef, {'pendingApplication': FieldValue.delete()});
        await batch.commit();
        if(mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Solicitud rechazada.')));
      }
    } catch (e) {
      if(mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: ${e.toString()}')));
    }
  }
}
