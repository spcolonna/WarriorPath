import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

class CommunityTabScreen extends StatefulWidget {
  final String schoolId;
  const CommunityTabScreen({Key? key, required this.schoolId}) : super(key: key);

  @override
  State<CommunityTabScreen> createState() => _CommunityTabScreenState();
}

class _CommunityTabScreenState extends State<CommunityTabScreen> {
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
        title: const Text('Comunidad de la Escuela'),
      ),
      body: FutureBuilder<Map<String, dynamic>>(
        future: _levelsMapFuture,
        builder: (context, levelsSnapshot) {
          if (levelsSnapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (levelsSnapshot.hasError) {
            return const Center(child: Text('Error al cargar los niveles de la escuela.'));
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
                return const Center(child: Text('Error al cargar los miembros.'));
              }
              if (!membersSnapshot.hasData || membersSnapshot.data!.docs.isEmpty) {
                return const Center(child: Text('Aún no hay miembros activos en la escuela.'));
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

                  // --- CAMBIO PRINCIPAL AQUÍ ---
                  // Lógica mejorada para pluralizar y poner en mayúscula el rol en ESPAÑOL
                  String roleHeader;
                  switch (memberRole) {
                    case 'alumno':
                      roleHeader = 'Alumnos';
                      break;
                    case 'instructor':
                      roleHeader = 'Instructores';
                      break;
                    case 'maestro':
                      roleHeader = 'Maestros';
                      break;
                    default:
                    // Un caso por si hay un rol inesperado
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

                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
                        child: Row(
                          children: [
                            FutureBuilder<DocumentSnapshot>(
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
                            const SizedBox(width: 16),

                            Text(memberData['displayName'] ?? 'Sin Nombre', style: const TextStyle(fontSize: 16)),

                            const SizedBox(width: 8),

                            if (levelData != null)
                              Chip(
                                label: Text(levelData['name'], style: const TextStyle(color: Colors.white, fontSize: 12)),
                                backgroundColor: Color(levelData['colorValue']),
                                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 0),
                                visualDensity: VisualDensity.compact,
                              ),
                          ],
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
