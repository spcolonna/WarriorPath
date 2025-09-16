import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:warrior_path/providers/session_provider.dart';
import 'package:warrior_path/screens/role_selector_screen.dart';
import 'package:warrior_path/screens/teacher/attendance_checklist_screen.dart';

import '../../../l10n/app_localizations.dart';

class HomeTabScreen extends StatefulWidget {
  const HomeTabScreen({super.key});

  @override
  State<HomeTabScreen> createState() => _HomeTabScreenState();
}

class _HomeTabScreenState extends State<HomeTabScreen> {
  late AppLocalizations l10n;
  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    l10n = AppLocalizations.of(context);
  }

  void _showSelectClassDialog(List<QueryDocumentSnapshot> schedules, String schoolId) {
    if (schedules.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l10n.noSchedulerClass)),
      );
      return;
    }

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text(l10n.choseClass),
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
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (context) => AttendanceChecklistScreen(
                          schoolId: schoolId,
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

  @override
  Widget build(BuildContext context) {
    final session = Provider.of<SessionProvider>(context);
    final schoolId = session.activeSchoolId;
    final user = FirebaseAuth.instance.currentUser;

    if (schoolId == null || user == null) {
      return Scaffold(body: Center(child: Text(l10n.sessionError)));
    }

    return Scaffold(
      appBar: AppBar(
        title: _buildSchoolSelector(schoolId),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16.0),
        children: [
          StreamBuilder<DocumentSnapshot>(
            stream: FirebaseFirestore.instance.collection('users').doc(user.uid).snapshots(),
            builder: (context, snapshot) {
              final userName = snapshot.data?['displayName'] ?? l10n.teacher;
              return Text(
                l10n.welcomeTitle(userName),
                style: Theme.of(context).textTheme.headlineSmall,
              );
            },
          ),
          const SizedBox(height: 24),

          _buildStatsGrid(schoolId),

          const SizedBox(height: 24),
          Text(l10n.todayClass, style: Theme.of(context).textTheme.headlineSmall),
          const SizedBox(height: 8),

          _buildTodaySchedules(schoolId),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () async {
          final today = DateTime.now().weekday;
          final snapshot = await FirebaseFirestore.instance
              .collection('schools').doc(schoolId)
              .collection('classSchedules').where('dayOfWeek', isEqualTo: today).get();
          _showSelectClassDialog(snapshot.docs, schoolId);
        },
        label: Text(l10n.takeAssistance),
        icon: const Icon(Icons.check_circle_outline),
      ),
    );
  }

  Widget _buildSchoolSelector(String schoolId) {
    return InkWell(
      onTap: () {
        Navigator.of(context).push(MaterialPageRoute(builder: (context) => const RoleSelectorScreen()));
      },
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          StreamBuilder<DocumentSnapshot>(
            stream: FirebaseFirestore.instance.collection('schools').doc(schoolId).snapshots(),
            builder: (context, snapshot) {
              final schoolName = snapshot.data?['name'] ?? l10n.loading;
              final martialArt = snapshot.data?['martialArt'] ?? '';
              return Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(schoolName),
                  if (martialArt.isNotEmpty)
                    Text(
                      martialArt,
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w400,
                        color: Colors.white70,
                      ),
                    ),
                ],
              );
            },
          ),
          const Icon(Icons.arrow_drop_down),
        ],
      ),
    );
  }

  Widget _buildStatsGrid(String schoolId) {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance.collection('schools').doc(schoolId).collection('members').snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());

        final allMembers = snapshot.data!.docs;
        final activeStudents = allMembers.where((doc) => doc['status'] == 'active').length;
        final pendingRequests = allMembers.where((doc) => doc['status'] == 'pending').length;

        return GridView.count(
          crossAxisCount: 2,
          crossAxisSpacing: 16, mainAxisSpacing: 16,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          children: [
            _buildStatCard(title: l10n.activeStudents, value: activeStudents.toString(), icon: Icons.groups, color: Colors.blue),
            _buildStatCard(
              title: l10n.pendingApplication, value: pendingRequests.toString(),
              icon: Icons.person_add,
              color: pendingRequests > 0 ? Colors.orange : Colors.green,
              onTap: () {
                // TODO: Navegar directamente a la pestaña de pendientes. Por ahora, esto es un placeholder.
              },
            ),
          ],
        );
      },
    );
  }

  Widget _buildTodaySchedules(String schoolId) {
    final today = DateTime.now().weekday;
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance.collection('schools').doc(schoolId).collection('classSchedules').where('dayOfWeek', isEqualTo: today).orderBy('startTime').snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
        if (snapshot.data!.docs.isEmpty) {
          return Card(child: ListTile(leading: const Icon(Icons.info_outline), title: Text(l10n.noSchedulerClass)));
        }
        return ListView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: snapshot.data!.docs.length,
          itemBuilder: (context, index) {
            final schedule = snapshot.data!.docs[index].data() as Map<String, dynamic>;
            return Card(child: ListTile(
              leading: const Icon(Icons.schedule),
              title: Text(schedule['title']),
              trailing: Text('${schedule['startTime']} - ${schedule['endTime']}'),
            ));
          },
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
}
