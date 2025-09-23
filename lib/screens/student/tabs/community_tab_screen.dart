import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import '../../../l10n/app_localizations.dart';
import '../../teacher/student_detail_screen.dart';

class CommunityTabScreen extends StatefulWidget {
  final String schoolId;
  const CommunityTabScreen({super.key, required this.schoolId});

  @override
  State<CommunityTabScreen> createState() => _CommunityTabScreenState();
}

class _CommunityTabScreenState extends State<CommunityTabScreen> {
  late AppLocalizations l10n;
  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    l10n = AppLocalizations.of(context);
  }

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
      disciplinesMap[doc.id] = doc.data()['name'] as String;
    }
    return disciplinesMap;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.schoolCommunity),
      ),
      body: FutureBuilder<Map<String, String>>(
        future: _disciplinesMapFuture,
        builder: (context, disciplinesSnapshot) {
          if (disciplinesSnapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (disciplinesSnapshot.hasError) {
            return Center(child: Text(l10n.errorLoadingDisciplines));
          }
          final disciplinesMap = disciplinesSnapshot.data ?? {};

          return StreamBuilder<QuerySnapshot>(
            stream: FirebaseFirestore.instance
                .collection('schools').doc(widget.schoolId)
                .collection('members').where('status', isEqualTo: 'active')
                .orderBy('role').orderBy('displayName').snapshots(),
            builder: (context, membersSnapshot) {
              if (membersSnapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }
              if (membersSnapshot.hasError) {
                return Center(child: Text(l10n.errorLoadingMembers));
              }
              if (!membersSnapshot.hasData || membersSnapshot.data!.docs.isEmpty) {
                return Center(child: Text(l10n.noActiveMembersYet));
              }

              final members = membersSnapshot.data!.docs;
              String currentRole = "";

              return ListView.builder(
                itemCount: members.length,
                itemBuilder: (context, index) {
                  final memberDoc = members[index];
                  final memberData = memberDoc.data() as Map<String, dynamic>;
                  final memberRole = memberData['role'] ?? 'alumno';
                  final bool showHeader = memberRole != currentRole;
                  currentRole = memberRole;

                  final progressMap = memberData['progress'] as Map<String, dynamic>? ?? {};
                  final enrolledDisciplineNames = progressMap.keys
                      .map((disciplineId) => disciplinesMap[disciplineId] ?? '?')
                      .join(', ');

                  String roleHeader;
                  switch (memberRole) {
                    case 'alumno': roleHeader = l10n.students; break;
                    case 'instructor': roleHeader = l10n.instructor; break;
                    case 'maestro': roleHeader = l10n.teacher; break;
                    default: roleHeader = memberRole;
                  }

                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (showHeader)
                        Padding(
                          padding: const EdgeInsets.only(left: 16.0, top: 20.0, bottom: 8.0),
                          child: Text(roleHeader, style: Theme.of(context).textTheme.headlineSmall),
                        ),

                      Card(
                        margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        child: ListTile(
                          onTap: () {
                            Navigator.of(context).push(
                              MaterialPageRoute(
                                builder: (context) => StudentDetailScreen(
                                  schoolId: widget.schoolId,
                                  studentId: memberDoc.id,
                                ),
                              ),
                            );
                          },
                          leading: FutureBuilder<DocumentSnapshot>(
                            future: FirebaseFirestore.instance.collection('users').doc(memberDoc.id).get(),
                            builder: (context, userSnapshot) {
                              if (!userSnapshot.hasData) return const CircleAvatar(radius: 20);
                              final photoUrl = (userSnapshot.data?.data() as Map<String, dynamic>?)?['photoUrl'] as String?;
                              return CircleAvatar(
                                radius: 20,
                                backgroundImage: (photoUrl != null && photoUrl.isNotEmpty) ? NetworkImage(photoUrl) : null,
                                child: (photoUrl == null || photoUrl.isEmpty) ? const Icon(Icons.person) : null,
                              );
                            },
                          ),
                          title: Text(memberData['displayName'] ?? l10n.noName, style: const TextStyle(fontWeight: FontWeight.bold)),
                          subtitle: Text(enrolledDisciplineNames.isNotEmpty ? enrolledDisciplineNames : 'Sin disciplinas'),
                          trailing: const Icon(Icons.arrow_forward_ios, size: 16, color: Colors.grey),
                        ),
                      ),
                    ],
                  );
                },
              );
            },
          );
        },
      ),
    );
  }
}
