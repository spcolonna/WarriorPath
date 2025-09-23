import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:warrior_path/providers/session_provider.dart';
import 'package:warrior_path/screens/teacher/student_detail_screen.dart';

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
            return Card(
              margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
              child: ListTile(
                leading: const CircleAvatar(child: Icon(Icons.person)),
                title: Text(data['displayName'] ?? l10n.noName),
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
      await _showDisciplineSelectionDialog(userId, schoolId);
    } else {
      final firestore = FirebaseFirestore.instance;
      final schoolMembersRef = firestore.collection('schools').doc(schoolId).collection('members').doc(userId);
      final userRef = firestore.collection('users').doc(userId);
      final batch = firestore.batch();
      batch.delete(schoolMembersRef);
      batch.update(userRef, {'pendingApplications': FieldValue.delete()});
      await batch.commit();
      if(mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(l10n.applicationRejected)));
    }
  }

  Future<void> _showDisciplineSelectionDialog(String userId, String schoolId) async {
    final disciplines = await FirebaseFirestore.instance.collection('schools').doc(schoolId).collection('disciplines').where('isActive', isEqualTo: true).get();

    if (disciplines.docs.isEmpty && mounted) {
      showDialog(context: context, builder: (ctx) => AlertDialog(
        title: Text(l10n.errorTitle),
        content: Text(l10n.noDisciplinesAvailable),
        actions: [ TextButton(onPressed: () => Navigator.of(ctx).pop(), child: Text(l10n.ok)) ],
      ),
      );
      return;
    }

    final selectedDisciplineId = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(l10n.enrollInDiscipline),
        content: SizedBox(
          width: double.maxFinite,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(l10n.selectDisciplineForStudent),
              const SizedBox(height: 16),
              ...disciplines.docs.map((doc) => ListTile(
                title: Text(doc['name']),
                onTap: () => Navigator.of(ctx).pop(doc.id),
              )),
            ],
          ),
        ),
      ),
    );

    if (selectedDisciplineId != null && mounted) {
      await _confirmAcceptance(userId, schoolId, selectedDisciplineId);
    }
  }

  Future<void> _confirmAcceptance(String userId, String schoolId, String disciplineId) async {
    final firestore = FirebaseFirestore.instance;

    try {
      final disciplineRef = firestore.collection('schools').doc(schoolId).collection('disciplines').doc(disciplineId);
      final levelsQuery = await disciplineRef.collection('levels').orderBy('order').limit(1).get();

      if (levelsQuery.docs.isEmpty) {
        throw Exception('La disciplina seleccionada no tiene niveles configurados.');
      }
      final initialLevelId = levelsQuery.docs.first.id;

      final batch = firestore.batch();
      final memberRef = firestore.collection('schools').doc(schoolId).collection('members').doc(userId);
      final userRef = firestore.collection('users').doc(userId);

      batch.update(memberRef, {
        'status': 'active',
        'progress': {
          disciplineId: {
            'currentLevelId': initialLevelId,
            'enrollmentDate': FieldValue.serverTimestamp(),
            'assignedTechniqueIds': [],
          }
        },
        'joinDate': FieldValue.serverTimestamp(),
      });

      batch.set(userRef, {
        'activeMemberships': { schoolId: 'alumno' },
        'pendingApplications': FieldValue.delete(),
      }, SetOptions(merge: true));

      await batch.commit();
      if(mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(l10n.studentAcceptedSuccess), backgroundColor: Colors.green));
    } catch (e) {
      if(mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: ${e.toString()}')));
    }
  }
}
