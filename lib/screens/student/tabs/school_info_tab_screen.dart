import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:warrior_path/screens/role_selector_screen.dart';

import '../../../l10n/app_localizations.dart';
import '../../../models/event_model.dart';
import '../student_event_detail_screen.dart';

class SchoolInfoTabScreen extends StatelessWidget {
  final String schoolId;
  const SchoolInfoTabScreen({Key? key, required this.schoolId}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
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
          final logoUrl = schoolData['logoUrl'] as String?;

          return SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Container(
                  padding: const EdgeInsets.all(24.0),
                  color: Theme.of(context).primaryColor.withOpacity(0.1),
                  child: Column(
                    children: [
                      CircleAvatar(
                        radius: 50,
                        backgroundColor: Colors.white,
                        backgroundImage: (logoUrl != null && logoUrl.isNotEmpty) ? NetworkImage(logoUrl) : null,
                        child: (logoUrl == null || logoUrl.isEmpty) ? const Icon(Icons.school, size: 50) : null,
                      ),
                      const SizedBox(height: 16),
                      Text(schoolData['name'] ?? 'Nombre de la Escuela', style: Theme.of(context).textTheme.headlineMedium, textAlign: TextAlign.center),
                      Text(schoolData['martialArt'] ?? 'Arte Marcial', style: Theme.of(context).textTheme.titleLarge?.copyWith(color: Colors.grey.shade600), textAlign: TextAlign.center),
                    ],
                  ),
                ),

                Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Card(
                    elevation: 2,
                    child: ListTile(
                      leading: Icon(Icons.swap_horiz, color: Theme.of(context).primaryColor),
                      title: const Text('Cambiar de Perfil/Escuela'),
                      trailing: const Icon(Icons.arrow_forward_ios),
                      onTap: () {
                        Navigator.of(context).push(
                          MaterialPageRoute(builder: (context) => const RoleSelectorScreen()),
                        );
                      },
                    ),
                  ),
                ),

                _buildUpcomingEvents(context, schoolId),

                _buildInfoCard(
                    context: context,
                    title: l10n.contactData,
                    children: [
                      ListTile(leading: const Icon(Icons.location_on), title: const Text('Dirección'), subtitle: Text('${schoolData['address'] ?? ''}, ${schoolData['city'] ?? ''}')),
                      ListTile(leading: const Icon(Icons.phone), title: Text(l10n.phone), subtitle: Text(schoolData['phone'] ?? l10n.noSpecify)),
                    ]
                ),

                _buildScheduleCard(context, schoolId),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildInfoCard({required BuildContext context, required String title, required List<Widget> children}) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0),
      child: Card(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Text(title, style: Theme.of(context).textTheme.titleLarge),
            ),
            const Divider(height: 1),
            ...children,
          ],
        ),
      ),
    );
  }

  Widget _buildUpcomingEvents(BuildContext context, String schoolId) {
    final studentId = FirebaseAuth.instance.currentUser?.uid;
    if (studentId == null) return const SizedBox.shrink();

    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance.collection('schools').doc(schoolId).collection('events')
          .where('invitedStudentIds', arrayContains: studentId)
          .where('eventDate', isGreaterThanOrEqualTo: Timestamp.now())
          .orderBy('eventDate').limit(3).snapshots(),
      builder: (context, snapshot) {
        if (snapshot.hasError) print("### ERROR AL BUSCAR EVENTOS: ${snapshot.error}");
        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) return const SizedBox.shrink();

        return Padding(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Próximos Eventos', style: Theme.of(context).textTheme.titleLarge),
              const SizedBox(height: 8),
              ...snapshot.data!.docs.map((doc) {
                final event = EventModel.fromFirestore(doc);
                return Card(
                  child: ListTile(
                    leading: const Icon(Icons.event_available),
                    title: Text(event.title, style: const TextStyle(fontWeight: FontWeight.bold)),
                    subtitle: Text(DateFormat('dd MMMM, yyyy', 'es_ES').format(event.date)),
                    trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                    onTap: () {
                      Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (context) => StudentEventDetailScreen(
                            schoolId: schoolId,
                            eventId: doc.id,
                          ),
                        ),
                      );
                    },
                  ),
                );
              }).toList(),
              const Divider(height: 32),
            ],
          ),
        );
      },
    );
  }

  Widget _buildScheduleCard(BuildContext context, String schoolId) {
    final List<String> dayLabels = ['Lunes', 'Martes', 'Miércoles', 'Jueves', 'Viernes', 'Sábado', 'Domingo'];

    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Card(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Text('Horario de Clases', style: Theme.of(context).textTheme.titleLarge),
            ),
            const Divider(height: 1),
            StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance.collection('schools').doc(schoolId).collection('classSchedules').orderBy('dayOfWeek').orderBy('startTime').snapshots(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) return const Padding(padding: EdgeInsets.all(16), child: Center(child: CircularProgressIndicator()));
                if (!snapshot.hasData || snapshot.data!.docs.isEmpty) return const ListTile(title: Text('El horario aún no ha sido definido.'));

                final Map<int, List<QueryDocumentSnapshot>> groupedSchedules = {};
                for (var doc in snapshot.data!.docs) {
                  final day = doc['dayOfWeek'] as int;
                  if (groupedSchedules[day] == null) groupedSchedules[day] = [];
                  groupedSchedules[day]!.add(doc);
                }

                return Column(
                  children: List.generate(7, (index) {
                    final dayIndex = index + 1;
                    final schedulesForDay = groupedSchedules[dayIndex] ?? [];
                    if (schedulesForDay.isEmpty) return const SizedBox.shrink();

                    return ExpansionTile(
                      title: Text(dayLabels[index], style: const TextStyle(fontWeight: FontWeight.bold)),
                      children: schedulesForDay.map((doc) {
                        final data = doc.data() as Map<String, dynamic>;
                        return ListTile(
                          title: Text(data['title']),
                          trailing: Text('${data['startTime']} - ${data['endTime']}'),
                        );
                      }).toList(),
                    );
                  }),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}
