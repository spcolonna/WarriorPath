import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:warrior_path/providers/session_provider.dart';
import 'package:warrior_path/screens/role_selector_screen.dart';
import 'package:warrior_path/screens/teacher/attendance_checklist_screen.dart';

class HomeTabScreen extends StatefulWidget {
  // 1. EL CONSTRUCTOR YA NO RECIBE PARÁMETROS
  const HomeTabScreen({Key? key}) : super(key: key);

  @override
  State<HomeTabScreen> createState() => _HomeTabScreenState();
}

class _HomeTabScreenState extends State<HomeTabScreen> {

  // 2. LA FUNCIÓN AHORA RECIBE EL schoolId COMO ARGUMENTO
  Stream<Map<String, dynamic>> _getDashboardStreams(String schoolId) {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) throw Exception('Usuario no autenticado');

    final schoolRef = FirebaseFirestore.instance.collection('schools').doc(schoolId);
    final userStream = FirebaseFirestore.instance.collection('users').doc(user.uid).snapshots();
    final activeStudentsStream = schoolRef.collection('members').where('status', isEqualTo: 'active').snapshots();
    final pendingRequestsStream = schoolRef.collection('members').where('status', isEqualTo: 'pending').snapshots();
    final today = DateTime.now().weekday;
    final todaySchedulesStream = schoolRef.collection('classSchedules').where('dayOfWeek', isEqualTo: today).orderBy('startTime').snapshots();

    return userStream.asyncMap((userDoc) async {
      final schoolSnap = await schoolRef.get(); // Usamos .get() aquí para eficiencia
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
    // 3. OBTENEMOS EL ID DE LA ESCUELA ACTIVA DESDE EL PROVIDER
    final session = Provider.of<SessionProvider>(context);
    final schoolId = session.activeSchoolId;

    if (schoolId == null) {
      return const Scaffold(body: Center(child: Text('Error: No hay una escuela activa en la sesión.')));
    }

    return StreamBuilder<Map<String, dynamic>>(
      stream: _getDashboardStreams(schoolId),
      builder: (context, snapshot) {
        // --- 4. EL APPBAR AHORA ES DINÁMICO ---
        // Construimos el título del AppBar usando el nombre de la escuela del snapshot
        // o un FutureBuilder si preferimos que sea independiente del stream principal.
        final schoolName = snapshot.data?['schoolName'] ?? 'Cargando...';

        return Scaffold(
          appBar: AppBar(
            title: InkWell(
              onTap: () {
                Navigator.of(context).push(
                  MaterialPageRoute(builder: (context) => const RoleSelectorScreen()),
                );
              },
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Flexible(child: Text(schoolName, overflow: TextOverflow.ellipsis)),
                  const Icon(Icons.arrow_drop_down),
                ],
              ),
            ),
          ),
          body: snapshot.connectionState == ConnectionState.waiting && !snapshot.hasData
              ? const Center(child: CircularProgressIndicator())
              : snapshot.hasError
              ? Center(child: Text('Error: ${snapshot.error}'))
              : _buildDashboardContent(context, snapshot.data!, schoolId), // Pasamos el schoolId

          floatingActionButton: snapshot.hasData
              ? FloatingActionButton.extended(
            onPressed: () {
              final todaySchedules = snapshot.data!['todaySchedules'] as List<QueryDocumentSnapshot>? ?? [];
              _showSelectClassDialog(todaySchedules, schoolId); // Pasamos el schoolId
            },
            label: const Text('Tomar Asistencia'),
            icon: const Icon(Icons.check_circle_outline),
          )
              : null,
        );
      },
    );
  }

  // Extraje el contenido a un widget separado para mayor limpieza
  Widget _buildDashboardContent(BuildContext context, Map<String, dynamic> data, String schoolId) {
    final int activeStudents = data['activeStudents'] ?? 0;
    final int pendingRequests = data['pendingRequests'] ?? 0;
    final String userName = data['userName'];
    final List<QueryDocumentSnapshot> todaySchedules = data['todaySchedules'] ?? [];

    return RefreshIndicator(
      onRefresh: () async => setState(() {}),
      child: ListView(
        padding: const EdgeInsets.all(16.0),
        children: [
          Text('¡Bienvenido, $userName!', style: Theme.of(context).textTheme.headlineSmall),
          const SizedBox(height: 24),
          GridView.count(
            crossAxisCount: 2,
            crossAxisSpacing: 16,
            mainAxisSpacing: 16,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            children: [
              _buildStatCard(title: 'Alumnos Activos', value: activeStudents.toString(), icon: Icons.groups, color: Colors.blue),
              _buildStatCard(
                title: 'Solicitudes Pendientes',
                value: pendingRequests.toString(),
                icon: Icons.person_add,
                color: pendingRequests > 0 ? Colors.orange : Colors.green,
                onTap: () {
                  // Esta navegación ya no se maneja con callback, sino directamente
                  // Aquí iría la lógica si quisiéramos usar un TabController global
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
    );
  }

  // 5. ACTUALIZAMOS EL DIÁLOGO PARA QUE USE EL schoolId
  void _showSelectClassDialog(List<QueryDocumentSnapshot> schedules, String schoolId) {
    if (schedules.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('No hay clases programadas para hoy.')));
      return;
    }
    showDialog(context: context, builder: (context) => AlertDialog(
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
                Navigator.of(context).pop();
                Navigator.of(context).push(MaterialPageRoute(
                  builder: (context) => AttendanceChecklistScreen(
                    schoolId: schoolId, // Usamos el schoolId de la sesión
                    scheduleTitle: scheduleTitle,
                  ),
                ));
              },
            );
          },
        ),
      ),
    ));
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
