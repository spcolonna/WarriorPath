import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:warrior_path/providers/session_provider.dart';
import 'package:warrior_path/screens/student/student_dashboard_screen.dart';
import 'package:warrior_path/screens/teacher_dashboard_screen.dart';

import '../l10n/app_localizations.dart';

class RoleSelectorScreen extends StatefulWidget {
  const RoleSelectorScreen({Key? key}) : super(key: key);

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

  late Future<List<Map<String, dynamic>>> _profilesFuture;

  @override
  void initState() {
    super.initState();
    _profilesFuture = _fetchUserProfiles();
  }

  Future<List<Map<String, dynamic>>> _fetchUserProfiles() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return [];

    final userDoc = await FirebaseFirestore.instance.collection('users').doc(user.uid).get();
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

    // 1. Guardamos la sesión activa
    sessionProvider.setActiveSession(schoolId, role);

    // 2. Navegamos al dashboard correspondiente
    Widget destination;
    if (role == 'maestro') {
      destination = const TeacherDashboardScreen();
    } else { // alumno o instructor
      destination = const StudentDashboardScreen();
    }

    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (context) => destination),
          (route) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(l10n.selectProfile)),
      body: FutureBuilder<List<Map<String, dynamic>>>(
        future: _profilesFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError || !snapshot.hasData || snapshot.data!.isEmpty) {
            return Center(child: Text(l10n.noActiveProfilesFound));
          }

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
