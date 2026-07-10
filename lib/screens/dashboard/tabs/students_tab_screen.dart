import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:warrior_path/providers/session_provider.dart';
import 'package:warrior_path/screens/teacher/add_offline_student_screen.dart';
import 'package:warrior_path/screens/teacher/student_detail_screen.dart';
import 'package:warrior_path/services/student_application_service.dart';

import '../../../l10n/app_localizations.dart';

class StudentsTabScreen extends StatefulWidget {
  final int initialTabIndex;
  const StudentsTabScreen({super.key, this.initialTabIndex = 0});

  @override
  State<StudentsTabScreen> createState() => _StudentsTabScreenState();
}

class _StudentsTabScreenState extends State<StudentsTabScreen> with SingleTickerProviderStateMixin {
  late AppLocalizations l10n;
  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    l10n = AppLocalizations.of(context);
  }

  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this, initialIndex: widget.initialTabIndex);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final schoolId = Provider.of<SessionProvider>(context).activeSchoolId;
    if (schoolId == null) {
      return Center(child: Text(l10n.noActiveSchoolError));
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.students),
        bottom: TabBar(
          controller: _tabController,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white.withValues(alpha: 0.55),
          indicatorColor: Colors.white,
          indicatorWeight: 3,
          tabs: [
            Tab(text: l10n.actives),
            Tab(text: l10n.pending),
            Tab(text: l10n.inactives),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildStudentsList('active', schoolId),
          _buildStudentsList('pending', schoolId),
          _buildStudentsList('inactive', schoolId),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        heroTag: 'fab_students_add',
        onPressed: () {
          Navigator.of(context).push(
            MaterialPageRoute(
              builder: (_) => AddOfflineStudentScreen(schoolId: schoolId),
            ),
          );
        },
        icon: const Icon(Icons.person_add_alt_1),
        label: Text(l10n.addStudent),
      ),
    );
  }

  Widget _buildStudentsList(String status, String schoolId) {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance.collection('schools').doc(schoolId).collection('members').where('status', isEqualTo: status).snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
          return Center(child: Text(l10n.noStudentsWithStatus(status)));
        }

        return ListView.builder(
          itemCount: snapshot.data!.docs.length,
          itemBuilder: (context, index) {
            final doc = snapshot.data!.docs[index];
            if (status == 'pending') {
              return _buildPendingStudentCard(doc, schoolId);
            }
            final data = doc.data() as Map<String, dynamic>;
            final isOffline = data['isOfflineStudent'] == true;
            return Card(
              margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
              child: ListTile(
                leading: const CircleAvatar(child: Icon(Icons.person)),
                title: Text(data['displayName'] ?? l10n.noName),
                subtitle: isOffline ? _OfflineBadge(label: l10n.offlineStudentBadge) : null,
                trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                onTap: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(builder: (context) => StudentDetailScreen(schoolId: schoolId, studentId: doc.id)),
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
            Text(data['displayName'] ?? l10n.noName, style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 4),
            Text(l10n.applicationDate((data['applicationDate'] as Timestamp?)?.toDate().toLocal().toString().substring(0, 10) ?? 'N/A')),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton(
                  onPressed: () => _handleApplication(userId, false, schoolId),
                  child: Text(l10n.reject, style: const TextStyle(color: Colors.red)),
                ),
                const SizedBox(width: 8),
                ElevatedButton(
                  onPressed: () => _handleApplication(userId, true, schoolId),
                  child: Text(l10n.accept),
                ),
              ],
            )
          ],
        ),
      ),
    );
  }

  Future<void> _handleApplication(String userId, bool accept, String schoolId) async {
    if (accept) {
      await StudentApplicationService.accept(context,
          schoolId: schoolId, userId: userId);
    } else {
      await StudentApplicationService.reject(context,
          schoolId: schoolId, userId: userId);
    }
  }
}

class _OfflineBadge extends StatelessWidget {
  final String label;
  const _OfflineBadge({required this.label});

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.only(top: 4),
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
        decoration: BoxDecoration(
          color: Colors.orange.withValues(alpha: 0.15),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: Colors.orange.shade400),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.cloud_off, size: 12, color: Colors.orange.shade700),
            const SizedBox(width: 4),
            Text(
              label,
              style: TextStyle(
                fontSize: 11,
                color: Colors.orange.shade800,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
