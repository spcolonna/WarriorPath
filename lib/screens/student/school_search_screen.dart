import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:warrior_path/providers/session_provider.dart';
import 'package:warrior_path/screens/student/application_sent_screen.dart';

import '../../l10n/app_localizations.dart';

class SchoolSearchScreen extends StatefulWidget {
  final bool isFromWizard;
  const SchoolSearchScreen({super.key, this.isFromWizard = false});

  @override
  State<SchoolSearchScreen> createState() => _SchoolSearchScreenState();
}

class _SchoolSearchScreenState extends State<SchoolSearchScreen> {
  late AppLocalizations l10n;
  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    l10n = AppLocalizations.of(context);
  }

  final _searchController = TextEditingController();

  List<QueryDocumentSnapshot> _allSchools = [];
  List<QueryDocumentSnapshot> _filteredSchools = [];

  Set<String> _userSchoolIds = {};
  bool _isLoading = true;
  late String _activeProfileId;

  @override
  void initState() {
    super.initState();
    // Usamos WidgetsBinding para acceder al Provider de forma segura en initState
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final sessionProvider = Provider.of<SessionProvider>(context, listen: false);
      final currentUser = FirebaseAuth.instance.currentUser;

      // Determinamos para quién es la búsqueda (el usuario logueado o un hijo)
      _activeProfileId = sessionProvider.activeProfileId ?? currentUser!.uid;

      // Cargamos los datos iniciales
      _fetchSchoolsAndFilter();
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  // --- CAMBIO: Toda la lógica ahora usa '_activeProfileId' ---
  Future<void> _fetchSchoolsAndFilter() async {
    setState(() => _isLoading = true);

    final userDoc = await FirebaseFirestore.instance.collection('users').doc(_activeProfileId).get();
    if (userDoc.exists) {
      final memberships = userDoc.data()?['activeMemberships'] as Map<String, dynamic>? ?? {};
      final pendingApplications = userDoc.data()?['pendingApplications'] as Map<String, dynamic>? ?? {};
      _userSchoolIds = {...memberships.keys, ...pendingApplications.keys}.toSet();
    }

    final schoolsSnapshot = await FirebaseFirestore.instance.collection('schools').get();
    _allSchools = schoolsSnapshot.docs;

    _applyFilter();
    setState(() => _isLoading = false);
  }

  void _applyFilter() {
    final query = _searchController.text.toLowerCase().trim();
    setState(() {
      _filteredSchools = _allSchools.where((schoolDoc) {
        final isNotMember = !_userSchoolIds.contains(schoolDoc.id);
        if (query.isEmpty) return isNotMember;
        final schoolData = schoolDoc.data() as Map<String, dynamic>;
        final nameMatches = schoolData['name']?.toString().toLowerCase().contains(query) ?? false;
        return isNotMember && nameMatches;
      }).toList();
    });
  }

  // --- CAMBIO: Toda la lógica de postulación ahora usa '_activeProfileId' ---
  Future<void> _postulateToSchool(String schoolId, String schoolName) async {
    if (_userSchoolIds.contains(schoolId)) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(l10n.alreadyLinkedToSchool)));
      return;
    }

    showDialog(
      context: context,
      barrierDismissible: !_isLoading,
      builder: (ctx) => AlertDialog(
        title: Text(l10n.confirmApplicationTitle),
        content: Text(l10n.confirmApplicationMessage(schoolName)),
        actions: [
          TextButton(onPressed: () => Navigator.of(ctx).pop(), child: Text(l10n.cancel)),
          TextButton(
            onPressed: () async {
              Navigator.of(ctx).pop();
              setState(() { _isLoading = true; });

              try {
                final firestore = FirebaseFirestore.instance;
                final userDoc = await firestore.collection('users').doc(_activeProfileId).get();
                final displayName = userDoc.data()?['displayName'] ?? l10n.noName;

                final batch = firestore.batch();
                final userRef = firestore.collection('users').doc(_activeProfileId);
                final memberRef = firestore.collection('schools').doc(schoolId).collection('members').doc(_activeProfileId);

                batch.set(memberRef, {
                  'userId': _activeProfileId, 'displayName': displayName, 'status': 'pending', 'applicationDate': FieldValue.serverTimestamp(),
                });

                final Map<String, dynamic> userDataToUpdate = {
                  'pendingApplications.$schoolId': {
                    'schoolName': schoolName,
                    'applicationDate': FieldValue.serverTimestamp(),
                  }
                };

                if (widget.isFromWizard) {
                  userDataToUpdate['wizardStep'] = 99;
                }

                batch.update(userRef, userDataToUpdate);
                await batch.commit();

                if (!mounted) return;

                if (widget.isFromWizard) {
                  Navigator.of(context).pushAndRemoveUntil(
                    MaterialPageRoute(builder: (context) => ApplicationSentScreen(schoolName: schoolName)),
                        (route) => false,
                  );
                } else {
                  ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(l10n.applicationSentSuccess(schoolName)), backgroundColor: Colors.green));
                  Navigator.of(context).pop();
                }

              } catch (e) {
                ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(l10n.applicationSentError(e.toString()))));
              } finally {
                if (mounted) setState(() { _isLoading = false; });
              }
            },
            child: Text(l10n.send),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(l10n.searchForNewSchool)),
      body: AbsorbPointer(
        absorbing: _isLoading,
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: TextField(
                controller: _searchController,
                onChanged: (_) => _applyFilter(),
                decoration: InputDecoration(labelText: l10n.schoolNameLabel, prefixIcon: const Icon(Icons.search), border: const OutlineInputBorder()),
              ),
            ),
            if (_isLoading && _allSchools.isEmpty) // Muestra el loader solo en la carga inicial
              const Expanded(child: Center(child: CircularProgressIndicator()))
            else
              Expanded(
                child: _filteredSchools.isEmpty
                    ? Center(child: Text(l10n.noNewSchoolsFound))
                    : ListView.builder(
                  itemCount: _filteredSchools.length,
                  itemBuilder: (context, index) {
                    final schoolDoc = _filteredSchools[index];
                    final schoolData = schoolDoc.data() as Map<String, dynamic>;
                    return Card(
                      margin: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 6.0),
                      child: ListTile(
                        title: Text(schoolData['name'] ?? l10n.noName),
                        subtitle: Text('${schoolData['martialArt']} - ${schoolData['city'] ?? l10n.noCity}'),
                        trailing: ElevatedButton(
                            child: Text(l10n.apply),
                            onPressed: () => _postulateToSchool(schoolDoc.id, schoolData['name'])
                        ),
                      ),
                    );
                  },
                ),
              ),
          ],
        ),
      ),
    );
  }
}
