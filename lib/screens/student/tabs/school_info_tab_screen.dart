import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

class SchoolInfoTabScreen extends StatelessWidget {
  final String schoolId;
  const SchoolInfoTabScreen({Key? key, required this.schoolId}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Mi Escuela'),
      ),
      body: FutureBuilder<DocumentSnapshot>(
        future: FirebaseFirestore.instance.collection('schools').doc(schoolId).get(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (!snapshot.hasData || !snapshot.data!.exists) {
            return const Center(child: Text('No se pudo cargar la información de la escuela.'));
          }

          final schoolData = snapshot.data!.data() as Map<String, dynamic>;

          return SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Header con el nombre de la escuela
                Container(
                  padding: const EdgeInsets.all(24.0),
                  color: Theme.of(context).primaryColor.withOpacity(0.1),
                  child: Column(
                    children: [
                      const CircleAvatar(
                        radius: 50,
                        // Aquí podrías mostrar el logo de la escuela si lo guardas en la DB
                        child: Icon(Icons.school, size: 50),
                      ),
                      const SizedBox(height: 16),
                      Text(
                        schoolData['name'] ?? 'Nombre de la Escuela',
                        style: Theme.of(context).textTheme.headlineMedium,
                        textAlign: TextAlign.center,
                      ),
                      Text(
                        schoolData['martialArt'] ?? 'Arte Marcial',
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(color: Colors.grey.shade600),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                ),

                // Información de contacto
                Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    children: [
                      _buildInfoTile(
                        icon: Icons.location_on,
                        title: 'Dirección',
                        subtitle: '${schoolData['address'] ?? ''}, ${schoolData['city'] ?? ''}',
                      ),
                      const Divider(),
                      _buildInfoTile(
                        icon: Icons.phone,
                        title: 'Teléfono',
                        subtitle: schoolData['phone'] ?? 'No especificado',
                      ),
                    ],
                  ),
                ),

                // Horario de Clases
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16.0),
                  child: Text('Horario de Clases', style: Theme.of(context).textTheme.headlineSmall),
                ),
                _buildScheduleView(schoolId),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildInfoTile({required IconData icon, required String title, required String subtitle}) {
    return ListTile(
      leading: Icon(icon),
      title: Text(title),
      subtitle: Text(subtitle),
    );
  }

  // Widget para mostrar el horario semanal
  Widget _buildScheduleView(String schoolId) {
    final List<String> dayLabels = ['Lunes', 'Martes', 'Miércoles', 'Jueves', 'Viernes', 'Sábado', 'Domingo'];

    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('schools')
          .doc(schoolId)
          .collection('classSchedules')
          .orderBy('dayOfWeek')
          .orderBy('startTime')
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: Padding(padding: EdgeInsets.all(8.0), child: CircularProgressIndicator()));
        }
        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
          return const Padding(
            padding: EdgeInsets.all(16.0),
            child: Text('El horario aún no ha sido definido por la escuela.'),
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
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: 7, // Lunes a Domingo
          itemBuilder: (context, index) {
            final dayIndex = index + 1;
            final schedulesForDay = groupedSchedules[dayIndex] ?? [];
            if (schedulesForDay.isEmpty) return const SizedBox.shrink();

            return Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(dayLabels[index], style: Theme.of(context).textTheme.titleLarge),
                  ...schedulesForDay.map((doc) {
                    final data = doc.data() as Map<String, dynamic>;
                    return ListTile(
                      dense: true,
                      title: Text(data['title']),
                      trailing: Text('${data['startTime']} - ${data['endTime']}'),
                    );
                  }).toList(),
                ],
              ),
            );
          },
        );
      },
    );
  }
}
