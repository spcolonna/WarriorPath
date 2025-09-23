import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:warrior_path/providers/session_provider.dart';
import 'package:warrior_path/screens/role_selector_screen.dart';
import 'package:warrior_path/models/event_model.dart';
import '../../../l10n/app_localizations.dart';
import '../student_event_detail_screen.dart';

class SchoolInfoTabScreen extends StatelessWidget {
  final String schoolId;
  const SchoolInfoTabScreen({super.key, required this.schoolId});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.mySchool),
      ),
      body: FutureBuilder<DocumentSnapshot>(
        future: FirebaseFirestore.instance.collection('schools').doc(schoolId).get(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(child: Text(l10n.loading));
          }
          if (!snapshot.hasData || !snapshot.data!.exists) {
            return Center(child: Text(l10n.couldNotLoadSchoolInfo));
          }

          final schoolData = snapshot.data!.data() as Map<String, dynamic>;
          final logoUrl = schoolData['logoUrl'] as String?;
          final primaryDiscipline = schoolData['primaryDisciplineName'] ?? l10n.martialArt;

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
                      Text(schoolData['name'] ?? l10n.schoolNameLabel, style: Theme.of(context).textTheme.headlineMedium, textAlign: TextAlign.center),
                      Text(primaryDiscipline, style: Theme.of(context).textTheme.titleLarge?.copyWith(color: Colors.grey.shade600), textAlign: TextAlign.center),
                    ],
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Card(
                    elevation: 2,
                    child: ListTile(
                      leading: Icon(Icons.swap_horiz, color: Theme.of(context).primaryColor),
                      title: Text(l10n.switchProfileSchool),
                      trailing: const Icon(Icons.arrow_forward_ios),
                      onTap: () {
                        Provider.of<SessionProvider>(context, listen: false).setActiveProfileId(null);
                        Navigator.of(context).push(
                          MaterialPageRoute(builder: (context) => const RoleSelectorScreen()),
                        );
                      },
                    ),
                  ),
                ),
                _buildUpcomingEvents(context, schoolId),
                _buildInfoCard(context: context, title: l10n.contactData, children: [
                  ListTile(leading: const Icon(Icons.location_on), title: Text(l10n.address), subtitle: Text('${schoolData['address'] ?? ''}, ${schoolData['city'] ?? ''}')),
                  ListTile(leading: const Icon(Icons.phone), title: Text(l10n.phone), subtitle: Text(schoolData['phone'] ?? l10n.noSpecify)),
                ]),
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
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
      child: Card(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(padding: const EdgeInsets.all(16.0), child: Text(title, style: Theme.of(context).textTheme.titleLarge)),
            const Divider(height: 1),
            ...children,
          ],
        ),
      ),
    );
  }

  Widget _buildUpcomingEvents(BuildContext context, String schoolId) {
    final l10n = AppLocalizations.of(context);
    final studentId = Provider.of<SessionProvider>(context, listen: false).activeProfileId;
    if (studentId == null) return const SizedBox.shrink();

    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance.collection('schools').doc(schoolId).collection('events')
          .where('invitedStudentIds', arrayContains: studentId)
          .where('date', isGreaterThanOrEqualTo: Timestamp.now())
          .orderBy('date').limit(3).snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) return const SizedBox.shrink();

        return Padding(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(l10n.upcomingEvents, style: Theme.of(context).textTheme.titleLarge),
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
              }),
              const Divider(height: 32),
            ],
          ),
        );
      },
    );
  }

  Widget _buildScheduleCard(BuildContext context, String schoolId) {
    return _ScheduleView(schoolId: schoolId);
  }
}

class _ScheduleView extends StatefulWidget {
  final String schoolId;
  const _ScheduleView({required this.schoolId});

  @override
  State<_ScheduleView> createState() => _ScheduleViewState();
}

class _ScheduleViewState extends State<_ScheduleView> {
  late Future<Map<String, String>> _disciplinesMapFuture;

  @override
  void initState() {
    super.initState();
    _disciplinesMapFuture = _fetchDisciplinesAsMap();
  }

  Future<Map<String, String>> _fetchDisciplinesAsMap() async {
    final disciplinesSnapshot = await FirebaseFirestore.instance
        .collection('schools').doc(widget.schoolId)
        .collection('disciplines').get();
    final Map<String, String> disciplinesMap = {};
    for (var doc in disciplinesSnapshot.docs) {
      disciplinesMap[doc.id] = (doc.data()['name'] as String?) ?? '...';
    }
    return disciplinesMap;
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final List<String> dayLabels = [l10n.monday, l10n.tuesday, l10n.wednesday, l10n.thursday, l10n.friday, l10n.saturday, l10n.sunday];

    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Card(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(padding: const EdgeInsets.all(16.0), child: Text(l10n.classSchedule, style: Theme.of(context).textTheme.titleLarge)),
            const Divider(height: 1),
            FutureBuilder<Map<String, String>>(
              future: _disciplinesMapFuture,
              builder: (context, disciplinesSnapshot) {
                if (!disciplinesSnapshot.hasData) return const Center(child: CircularProgressIndicator());
                final disciplinesMap = disciplinesSnapshot.data ?? {};

                return StreamBuilder<QuerySnapshot>(
                  stream: FirebaseFirestore.instance.collection('schools').doc(widget.schoolId).collection('classSchedules').orderBy('dayOfWeek').orderBy('startTime').snapshots(),
                  builder: (context, scheduleSnapshot) {
                    if (scheduleSnapshot.connectionState == ConnectionState.waiting) return const Padding(padding: EdgeInsets.all(16), child: Center(child: CircularProgressIndicator()));
                    if (!scheduleSnapshot.hasData || scheduleSnapshot.data!.docs.isEmpty) return ListTile(title: Text(l10n.scheduleNotDefinedYet));

                    final Map<int, List<QueryDocumentSnapshot>> groupedSchedules = {};
                    for (var doc in scheduleSnapshot.data!.docs) {
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
                            final disciplineName = disciplinesMap[data['disciplineId']] ?? l10n.general;
                            return ListTile(
                              title: Text(data['title']),
                              subtitle: Text(disciplineName),
                              trailing: Text('${data['startTime']} - ${data['endTime']}'),
                            );
                          }).toList(),
                        );
                      }),
                    );
                  },
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}
