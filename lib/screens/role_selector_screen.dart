import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:warrior_path/providers/session_provider.dart';
import 'package:warrior_path/screens/student/school_search_screen.dart';
import 'package:warrior_path/screens/student/student_dashboard_screen.dart';
import 'package:warrior_path/screens/teacher_dashboard_screen.dart';
import '../l10n/app_localizations.dart';

class RoleSelectorScreen extends StatefulWidget {
  const RoleSelectorScreen({super.key});

  @override
  State<RoleSelectorScreen> createState() => _RoleSelectorScreenState();
}

class _RoleSelectorScreenState extends State<RoleSelectorScreen> {
  late AppLocalizations l10n;
  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    l10n = AppLocalizations.of(context);
  }

  Future<List<Map<String, dynamic>>> _fetchUserProfiles(String userId, AppLocalizations l10n) async {
    final userDoc = await FirebaseFirestore.instance.collection('users').doc(userId).get();
    if (!userDoc.exists) return [];

    final memberships = userDoc.data()?['activeMemberships'] as Map<String, dynamic>? ?? {};
    final List<Future<Map<String, dynamic>>> profileFutures = [];

    for (var entry in memberships.entries) {
      final schoolId = entry.key;
      final role = entry.value;
      profileFutures.add(
        FirebaseFirestore.instance.collection('schools').doc(schoolId).get().then((schoolDoc) {
          return {
            'schoolId': schoolId,
            'role': role,
            'schoolName': schoolDoc.data()?['name'] ?? l10n.unknownSchool,
            'logoUrl': schoolDoc.data()?['logoUrl'],
            // --- CAMBIO: Guardamos el ID del perfil para el que se seleccionó el rol ---
            'profileId': userId,
          };
        }),
      );
    }
    return Future.wait(profileFutures);
  }

  void _selectProfile(Map<String, dynamic> profile) {
    final sessionProvider = Provider.of<SessionProvider>(context, listen: false);
    final schoolId = profile['schoolId'];
    final role = profile['role'];
    final profileId = profile['profileId'];

    sessionProvider.setFullActiveSession(schoolId, role, profileId);

    Widget destination;
    if (role == 'maestro') {
      destination = const TeacherDashboardScreen();
    } else {
      destination = const StudentDashboardScreen();
    }

    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (context) => destination),
          (route) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    final sessionProvider = Provider.of<SessionProvider>(context, listen: false);
    final currentUser = FirebaseAuth.instance.currentUser;

    final targetProfileId = sessionProvider.activeProfileId ?? currentUser?.uid;

    return Scaffold(
      appBar: AppBar(title: Text(l10n.selectProfile)),
      body: targetProfileId == null
          ? Center(child: Text(l10n.noActiveProfilesFound))
          : FutureBuilder<List<Map<String, dynamic>>>(
        future: _fetchUserProfiles(targetProfileId, l10n),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(child: Text(l10n.loading));
          }

          if (snapshot.hasError || !snapshot.hasData || snapshot.data!.isEmpty) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(24.0),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    const Icon(Icons.search_off, size: 80, color: Colors.grey),
                    const SizedBox(height: 24),
                    Text(
                      l10n.noActiveProfilesFound,
                      style: Theme.of(context).textTheme.headlineSmall,
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      l10n.noActiveProfilesMessage,
                      style: Theme.of(context).textTheme.bodyMedium,
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 32),
                    ElevatedButton.icon(
                      icon: const Icon(Icons.add),
                      label: Text(l10n.enrollInSchool),
                      onPressed: () {
                        Navigator.of(context).push(
                          MaterialPageRoute(builder: (context) => const SchoolSearchScreen()),
                        );
                      },
                    ),
                  ],
                ),
              ),
            );
          }

          // Si SÍ hay datos, se ejecuta esta parte
          final profiles = snapshot.data!;
          return ListView.builder(
            itemCount: profiles.length,
            itemBuilder: (context, index) {
              final profile = profiles[index];
              final roleText = (profile['role'] as String)[0].toUpperCase() + (profile['role'] as String).substring(1);
              final logoUrl = profile['logoUrl'] as String?;

              return Card(
                margin: const EdgeInsets.all(16.0),
                child: ListTile(
                  leading: CircleAvatar(
                    backgroundImage: (logoUrl != null && logoUrl.isNotEmpty) ? NetworkImage(logoUrl) : null,
                    child: (logoUrl == null || logoUrl.isEmpty) ? const Icon(Icons.school) : null,
                  ),
                  title: Text(l10n.enterAs(roleText)),
                  subtitle: Text(l10n.inSchool(profile['schoolName'])),
                  onTap: () => _selectProfile(profile),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
