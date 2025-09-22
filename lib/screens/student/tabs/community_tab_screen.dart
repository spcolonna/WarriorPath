import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import '../../../l10n/app_localizations.dart';
import '../../teacher/student_detail_screen.dart';

class CommunityTabScreen extends StatefulWidget {
  final String schoolId;
  const CommunityTabScreen({Key? key, required this.schoolId}) : super(key: key);

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
  late Stream<QuerySnapshot> _membersStream;
  late Future<Map<String, dynamic>> _levelsMapFuture;

  @override
  void initState() {
    super.initState();
    _membersStream = FirebaseFirestore.instance
        .collection('schools')
        .doc(widget.schoolId)
        .collection('members')
        .where('status', isEqualTo: 'active')
        .orderBy('role')
        .orderBy('displayName')
        .snapshots();

    _levelsMapFuture = _fetchLevelsAsMap();
  }

  Future<Map<String, dynamic>> _fetchLevelsAsMap() async {
    final levelsSnapshot = await FirebaseFirestore.instance
        .collection('schools')
        .doc(widget.schoolId)
        .collection('levels')
        .get();

    final Map<String, dynamic> levelsMap = {};
    for (var doc in levelsSnapshot.docs) {
      levelsMap[doc.id] = doc.data();
    }
    return levelsMap;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.schoolCommunity),
      ),
      body: FutureBuilder<Map<String, dynamic>>(
        future: _levelsMapFuture,
        builder: (context, levelsSnapshot) {
          if (levelsSnapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (levelsSnapshot.hasError) {
            return Center(child: Text(l10n.errorLoadingLevels));
          }

          final levelsMap = levelsSnapshot.data ?? {};

          return StreamBuilder<QuerySnapshot>(
            stream: _membersStream,
            builder: (context, membersSnapshot) {
              if (membersSnapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }
              if (membersSnapshot.hasError) {
                print('ERROR DEL STREAM DE COMUNIDAD: ${membersSnapshot.error}');
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

                  String roleHeader;
                  switch (memberRole) {
                    case 'alumno':
                      roleHeader = l10n.students;
                      break;
                    case 'instructor':
                      roleHeader = l10n.instructor;
                      break;
                    case 'maestro':
                      roleHeader = l10n.teacher;
                      break;
                    default:
                      roleHeader = '${memberRole[0].toUpperCase()}${memberRole.substring(1)}s';
                  }

                  final levelId = memberData['currentLevelId'];
                  final levelData = levelId != null ? levelsMap[levelId] : null;

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
                          // 1. Hacemos el ListTile entero "clicable"
                          onTap: () {
                            Navigator.of(context).push(
                              MaterialPageRoute(
                                // 2. Navegamos a la pantalla de detalle del miembro
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
                              if (!userSnapshot.hasData) {
                                return const CircleAvatar(radius: 20);
                              }
                              final photoUrl = (userSnapshot.data?.data() as Map<String, dynamic>?)?['photoUrl'] as String?;
                              return CircleAvatar(
                                radius: 20,
                                backgroundImage: (photoUrl != null && photoUrl.isNotEmpty) ? NetworkImage(photoUrl) : null,
                                child: (photoUrl == null || photoUrl.isEmpty) ? const Icon(Icons.person) : null,
                              );
                            },
                          ),
                          title: Text(memberData['displayName'] ?? l10n.noName, style: const TextStyle(fontWeight: FontWeight.bold)),
                          // 3. Mostramos el rol como subtítulo para diferenciar
                          subtitle: Text(memberRole[0].toUpperCase() + memberRole.substring(1)),
                          trailing: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              if (levelData != null)
                                Chip(
                                  label: Text(levelData['name'], style: const TextStyle(color: Colors.white, fontSize: 12)),
                                  backgroundColor: Color(levelData['colorValue']),
                                  padding: EdgeInsets.zero,
                                  visualDensity: VisualDensity.compact,
                                ),
                              const SizedBox(width: 8),
                              const Icon(Icons.arrow_forward_ios, size: 16, color: Colors.grey),
                            ],
                          ),
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
