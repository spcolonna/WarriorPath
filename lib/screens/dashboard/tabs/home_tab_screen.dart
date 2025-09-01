import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

class HomeTabScreen extends StatefulWidget {
  const HomeTabScreen({Key? key}) : super(key: key);

  @override
  State<HomeTabScreen> createState() => _HomeTabScreenState();
}

class _HomeTabScreenState extends State<HomeTabScreen> {
  late Future<Map<String, dynamic>> _dashboardDataFuture;
  String? _schoolId;

  @override
  void initState() {
    super.initState();
    _dashboardDataFuture = _fetchDashboardData();
  }

  Future<Map<String, dynamic>> _fetchDashboardData() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) throw Exception('Usuario no autenticado');

    // 1. Obtener el perfil del usuario para encontrar su escuela
    final userDoc = await FirebaseFirestore.instance.collection('users').doc(user.uid).get();
    final memberships = userDoc.data()?['activeMemberships'] as Map<String, dynamic>? ?? {};

    // Asumimos que el maestro solo gestiona una escuela por ahora
    _schoolId = memberships.keys.firstWhere((k) => memberships[k] == 'maestro', orElse: () => '');

    if (_schoolId == null || _schoolId!.isEmpty) {
      return {'error': 'No se encontró una escuela para gestionar.'};
    }

    final schoolRef = FirebaseFirestore.instance.collection('schools').doc(_schoolId);

    // 2. Ejecutar todas las consultas en paralelo
    final results = await Future.wait([
      schoolRef.collection('members').where('status', isEqualTo: 'active').count().get(),
      schoolRef.collection('members').where('status', isEqualTo: 'pending').count().get(),
      schoolRef.get(),
    ]);

    final activeStudents = results[0] as AggregateQuerySnapshot;
    final pendingRequests = results[1] as AggregateQuerySnapshot;
    final schoolData = results[2] as DocumentSnapshot<Map<String, dynamic>>;

    return {
      'activeStudents': activeStudents.count,
      'pendingRequests': pendingRequests.count,
      'schoolName': schoolData.data()?['name'] ?? 'Mi Escuela',
      'userName': userDoc.data()?['displayName'] ?? 'Maestro',
    };
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Inicio'),
      ),
      body: FutureBuilder<Map<String, dynamic>>(
        future: _dashboardDataFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError || snapshot.data?['error'] != null) {
            return Center(child: Text('Error: ${snapshot.error ?? snapshot.data?['error']}'));
          }

          final data = snapshot.data!;
          final int activeStudents = data['activeStudents'] ?? 0;
          final int pendingRequests = data['pendingRequests'] ?? 0;
          final String schoolName = data['schoolName'];
          final String userName = data['userName'];

          return RefreshIndicator(
            onRefresh: () async {
              setState(() {
                _dashboardDataFuture = _fetchDashboardData();
              });
            },
            child: ListView(
              padding: const EdgeInsets.all(16.0),
              children: [
                Text('¡Bienvenido, $userName!', style: Theme.of(context).textTheme.headlineSmall),
                Text(schoolName, style: Theme.of(context).textTheme.titleMedium?.copyWith(color: Colors.grey)),
                const SizedBox(height: 24),

                // Grid de Estadísticas
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
                        // TODO: Navegar a la pestaña de Alumnos, filtrando por pendientes
                        print('Navegando a solicitudes pendientes...');
                      },
                    ),
                  ],
                ),
                const SizedBox(height: 24),

                // Próximas Clases (Placeholder por ahora, ya que requiere la lógica de horarios)
                Text('Próximas Clases', style: Theme.of(context).textTheme.headlineSmall),
                const SizedBox(height: 8),
                const Card(
                  child: ListTile(
                    leading: Icon(Icons.info_outline),
                    title: Text('Funcionalidad de Horarios Próximamente'),
                    subtitle: Text('Aquí verás las clases del día.'),
                  ),
                ),
              ],
            ),
          );
        },
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          // TODO: Implementar la lógica para tomar asistencia
        },
        label: const Text('Tomar Asistencia'),
        icon: const Icon(Icons.check_circle_outline),
      ),
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
}
