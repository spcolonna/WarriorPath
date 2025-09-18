import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:warrior_path/models/user_model.dart';
import 'package:warrior_path/providers/session_provider.dart';
import 'package:warrior_path/screens/parent/add_child_screen.dart';
import 'package:warrior_path/screens/role_selector_screen.dart';

import '../../l10n/app_localizations.dart';

class GuardianDashboardScreen extends StatefulWidget {
  const GuardianDashboardScreen({super.key});

  @override
  State<GuardianDashboardScreen> createState() => _GuardianDashboardScreenState();
}

class _GuardianDashboardScreenState extends State<GuardianDashboardScreen> {
  late AppLocalizations l10n;
  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    l10n = AppLocalizations.of(context);
  }

  late Future<Map<String, dynamic>> _dashboardDataFuture;

  @override
  void initState() {
    super.initState();
    _dashboardDataFuture = _fetchDashboardData();
  }

  /// Carga el perfil del tutor y los perfiles de todos sus hijos.
  Future<Map<String, dynamic>> _fetchDashboardData() async {
    final guardianUser = FirebaseAuth.instance.currentUser;
    if (guardianUser == null) throw Exception('Usuario no autenticado');

    final firestore = FirebaseFirestore.instance;

    // 1. Preparamos la búsqueda del perfil del tutor
    final guardianProfileFuture = firestore.collection('users').doc(guardianUser.uid).get();

    // 2. Preparamos la búsqueda de los vínculos de tutela
    final guardianshipsFuture = firestore.collection('guardianships').where('guardianId', isEqualTo: guardianUser.uid).get();

    // Ejecutamos ambas búsquedas en paralelo
    final results = await Future.wait([guardianProfileFuture, guardianshipsFuture]);

    final guardianProfileDoc = results[0] as DocumentSnapshot;
    final guardianProfile = UserModel.fromSnap(guardianProfileDoc);

    final guardianshipsSnap = results[1] as QuerySnapshot;
    final childIds = guardianshipsSnap.docs.map((doc) => doc['childId'] as String).toList();

    List<UserModel> childProfiles = [];
    if (childIds.isNotEmpty) {
      // 3. Si hay hijos, buscamos todos sus perfiles de una vez
      final childrenSnap = await firestore.collection('users').where(FieldPath.documentId, whereIn: childIds).get();
      childProfiles = childrenSnap.docs.map((doc) => UserModel.fromSnap(doc)).toList();
    }

    return {
      'guardian': guardianProfile,
      'children': childProfiles,
    };
  }

  /// Establece el perfil activo y navega al selector de roles.
  void _navigateToProfile(String profileId) {
    Provider.of<SessionProvider>(context, listen: false).setActiveProfileId(profileId);
    Navigator.of(context).push(
      MaterialPageRoute(builder: (context) => const RoleSelectorScreen()),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.guardianPanel),
        automaticallyImplyLeading: false,
      ),
      body: FutureBuilder<Map<String, dynamic>>(
        future: _dashboardDataFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(child: Text(l10n.loading));
          }
          if (snapshot.hasError) {
            return Center(child: Text(l10n.errorLoadingChildren));
          }
          if (!snapshot.hasData) {
            return const Center(child: Text('No se encontraron datos.'));
          }

          final guardianProfile = snapshot.data!['guardian'] as UserModel;
          final childrenProfiles = snapshot.data!['children'] as List<UserModel>;

          return RefreshIndicator(
            onRefresh: () {
              setState(() {
                _dashboardDataFuture = _fetchDashboardData();
              });
              return _dashboardDataFuture;
            },
            child: ListView(
              padding: const EdgeInsets.all(16),
              children: [
                Text(l10n.manageProfiles, style: Theme.of(context).textTheme.headlineSmall),
                const SizedBox(height: 16),

                // --- SECCIÓN PARA "MI USUARIO" (EL PADRE) ---
                Text(l10n.myUser, style: Theme.of(context).textTheme.titleLarge),
                const SizedBox(height: 8),
                Card(
                  margin: const EdgeInsets.only(bottom: 24),
                  child: ListTile(
                    leading: CircleAvatar(
                      radius: 25,
                      backgroundImage: (guardianProfile.photoUrl != null && guardianProfile.photoUrl!.isNotEmpty)
                          ? NetworkImage(guardianProfile.photoUrl!) : null,
                      child: (guardianProfile.photoUrl == null || guardianProfile.photoUrl!.isEmpty)
                          ? const Icon(Icons.person) : null,
                    ),
                    title: Text(guardianProfile.displayName ?? l10n.noName, style: const TextStyle(fontWeight: FontWeight.bold)),
                    subtitle: const Text('Mi Perfil de Tutor'), // TODO: Localizar
                    trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                    onTap: () => _navigateToProfile(guardianProfile.uid),
                  ),
                ),

                // --- SECCIÓN PARA "MIS HIJOS" ---
                Text(l10n.myChildren, style: Theme.of(context).textTheme.titleLarge),
                const SizedBox(height: 8),

                if (childrenProfiles.isEmpty)
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 24.0),
                    child: Center(child: Text(l10n.noChildrenAdded, textAlign: TextAlign.center)),
                  )
                else
                  ...childrenProfiles.map((child) {
                    return Card(
                      margin: const EdgeInsets.only(bottom: 12),
                      child: ListTile(
                        leading: CircleAvatar(
                          radius: 25,
                          backgroundImage: (child.photoUrl != null && child.photoUrl!.isNotEmpty)
                              ? NetworkImage(child.photoUrl!) : null,
                          child: (child.photoUrl == null || child.photoUrl!.isEmpty)
                              ? const Icon(Icons.child_care) : null,
                        ),
                        title: Text(child.displayName ?? l10n.noName, style: const TextStyle(fontWeight: FontWeight.bold)),
                        subtitle: Text('${_calculateAge(child.dateOfBirth)} ${l10n.years}'),
                        trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                        onTap: () => _navigateToProfile(child.uid),
                      ),
                    );
                  }).toList(),
              ],
            ),
          );
        },
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          Navigator.of(context).push(
            MaterialPageRoute(builder: (context) => const AddChildScreen()),
          );
        },
        label: Text(l10n.addChild),
        icon: const Icon(Icons.add),
      ),
    );
  }

  String _calculateAge(DateTime? birthDate) {
    if (birthDate == null) return '?';
    final today = DateTime.now();
    int age = today.year - birthDate.year;
    if (today.month < birthDate.month || (today.month == birthDate.month && today.day < birthDate.day)) {
      age--;
    }
    return age.toString();
  }
}
