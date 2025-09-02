import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../../teacher/attendance_checklist_screen.dart';

class HomeTabScreen extends StatefulWidget {
  final String schoolId;
  final Function(int, {int? subTabIndex}) onNavigateToTab;
  const HomeTabScreen({
    Key? key,
    required this.schoolId,
    required this.onNavigateToTab,
  }) : super(key: key);

  @override
  State<HomeTabScreen> createState() => _HomeTabScreenState();
}

class _HomeTabScreenState extends State<HomeTabScreen> {
  Stream<Map<String, dynamic>> _getDashboardStreams() {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) throw Exception('Usuario no autenticado');

    final schoolRef = FirebaseFirestore.instance.collection('schools').doc(widget.schoolId);

    // Los streams que queremos combinar
    final schoolStream = schoolRef.snapshots();
    final userStream = FirebaseFirestore.instance.collection('users').doc(user.uid).snapshots();
    final activeStudentsStream = schoolRef.collection('members').where('status', isEqualTo: 'active').snapshots();
    final pendingRequestsStream = schoolRef.collection('members').where('status', isEqualTo: 'pending').snapshots();

    final today = DateTime.now().weekday;
    final todaySchedulesStream = schoolRef.collection('classSchedules').where('dayOfWeek', isEqualTo: today).orderBy('startTime').snapshots();

    // Combinamos todos los streams en uno solo
    // Nota: para combinaciones más complejas, se suele usar el paquete rxdart, pero esto es suficiente para empezar.
    return userStream.asyncMap((userDoc) async {
      final schoolSnap = await schoolStream.first;
      final activeStudentsSnap = await activeStudentsStream.first;
      final pendingRequestsSnap = await pendingRequestsStream.first;
      final todaySchedulesSnap = await todaySchedulesStream.first;

      return {
        'activeStudents': activeStudentsSnap.docs.length,
        'pendingRequests': pendingRequestsSnap.docs.length,
        'schoolName': schoolSnap.data()?['name'] ?? 'Mi Escuela',
        'userName': userDoc.data()?['displayName'] ?? 'Maestro',
        'todaySchedules': todaySchedulesSnap.docs,
      };
    });
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<Map<String, dynamic>>(
      stream: _getDashboardStreams(),
      builder: (context, snapshot) {
        // Mientras carga, mostramos un Scaffold simple
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Scaffold(appBar: AppBar(title: const Text('Inicio')), body: const Center(child: CircularProgressIndicator()));
        }
        if (snapshot.hasError) {
          return Scaffold(appBar: AppBar(title: const Text('Inicio')), body: Center(child: Text('Error: ${snapshot.error}')));
        }
        if (!snapshot.hasData || snapshot.data!.isEmpty) {
          return Scaffold(appBar: AppBar(title: const Text('Inicio')), body: const Center(child: Text('No se encontraron datos.')));
        }

        // Una vez que tenemos datos, construimos el Scaffold completo
        final data = snapshot.data!;
        final int activeStudents = data['activeStudents'] ?? 0;
        final int pendingRequests = data['pendingRequests'] ?? 0;
        final String schoolName = data['schoolName'];
        final String userName = data['userName'];
        final List<QueryDocumentSnapshot> todaySchedules = data['todaySchedules'] ?? [];

        return Scaffold(
          appBar: AppBar(
            title: const Text('Inicio'),
          ),
          body: RefreshIndicator(
            onRefresh: () async {
              // El RefreshIndicator sigue funcionando igual
              setState(() {});
            },
            child: ListView(
              padding: const EdgeInsets.all(16.0),
              children: [
                Text('¡Bienvenido, $userName!', style: Theme.of(context).textTheme.headlineSmall),
                Text(schoolName, style: Theme.of(context).textTheme.titleMedium?.copyWith(color: Colors.grey)),
                const SizedBox(height: 24),

                GridView.count(
                  crossAxisCount: 2,
                  crossAxisSpacing: 16,
                  mainAxisSpacing: 16,
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  children: [
                    _buildStatCard(
                      title: 'Alumnos Activos',
                      value: activeStudents.toString(),
                      icon: Icons.groups,
                      color: Colors.blue,
                    ),
                    _buildStatCard(
                      title: 'Solicitudes Pendientes',
                      value: pendingRequests.toString(),
                      icon: Icons.person_add,
                      color: pendingRequests > 0 ? Colors.orange : Colors.green,
                      onTap: () {
                        widget.onNavigateToTab(1, subTabIndex: 1);
                      },
                    ),
                  ],
                ),
                const SizedBox(height: 24),

                Text('Clases de Hoy', style: Theme.of(context).textTheme.headlineSmall),
                const SizedBox(height: 8),

                _buildTodaySchedules(todaySchedules),
              ],
            ),
          ),
          // El FloatingActionButton ahora está DENTRO del StreamBuilder
          // por lo que SÍ tiene acceso a la variable 'data' y a 'todaySchedules'
          floatingActionButton: FloatingActionButton.extended(
            onPressed: () {
              // Esta lógica ahora funciona sin errores
              _showSelectClassDialog(todaySchedules);
            },
            label: const Text('Tomar Asistencia'),
            icon: const Icon(Icons.check_circle_outline),
          ),
        );
      },
    );
  }

  // Dentro de la clase _HomeTabScreenState

  void _showSelectClassDialog(List<QueryDocumentSnapshot> schedules) {
    if (schedules.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No hay clases programadas para hoy.')),
      );
      return;
    }

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Seleccionar Clase'),
          content: SizedBox(
            width: double.maxFinite,
            child: ListView.builder(
              shrinkWrap: true,
              itemCount: schedules.length,
              itemBuilder: (context, index) {
                final schedule = schedules[index].data() as Map<String, dynamic>;
                final scheduleTitle = schedule['title'];
                final scheduleTime = '${schedule['startTime']} - ${schedule['endTime']}';

                return ListTile(
                  title: Text(scheduleTitle),
                  subtitle: Text(scheduleTime),
                  onTap: () {
                    Navigator.of(context).pop(); // Cierra el diálogo
                    Navigator.of(context).push( // Abre la pantalla de asistencia
                      MaterialPageRoute(
                        builder: (context) => AttendanceChecklistScreen(
                          schoolId: widget.schoolId,
                          scheduleTitle: scheduleTitle,
                        ),
                      ),
                    );
                  },
                );
              },
            ),
          ),
        );
      },
    );
  }

  Widget _buildStatCard({required String title, required String value, required IconData icon, required Color color, VoidCallback? onTap}) {
    return InkWell(
      onTap: onTap,
      child: Card(
        elevation: 4,
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(icon, size: 32, color: color),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(value, style: Theme.of(context).textTheme.headlineMedium?.copyWith(fontWeight: FontWeight.bold)),
                  Text(title, style: Theme.of(context).textTheme.bodyMedium),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTodaySchedules(List<QueryDocumentSnapshot> schedules) {
    if (schedules.isEmpty) {
      return const Card(
        child: ListTile(
          leading: Icon(Icons.info_outline),
          title: Text('No hay clases programadas para hoy'),
        ),
      );
    }

    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: schedules.length,
      itemBuilder: (context, index) {
        final schedule = schedules[index].data() as Map<String, dynamic>;
        return Card(
          child: ListTile(
            leading: const Icon(Icons.schedule),
            title: Text(schedule['title']),
            trailing: Text('${schedule['startTime']} - ${schedule['endTime']}'),
          ),
        );
      },
    );
  }
}
