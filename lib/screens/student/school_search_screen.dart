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

  // schoolId -> status del member doc propio en esa escuela ('pending' |
  // 'active' | 'inactive' | null si no hay relación). Se lee directo de cada
  // escuela (fuente de verdad) en vez de confiar en los mapas denormalizados
  // de users.activeMemberships/pendingApplications, que pueden desincronizarse.
  Map<String, String?> _schoolStatus = {};

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

  Future<void> _fetchSchoolsAndFilter() async {
    setState(() => _isLoading = true);

    final schoolsSnapshot = await FirebaseFirestore.instance.collection('schools').get();
    _allSchools = schoolsSnapshot.docs;

    // GetOptions(server): este estado decide qué botón mostrar (Postular vs
    // Reenviar vs "ya pertenecés"), así que no puede quedar servido desde la
    // caché local si quedó desactualizada por una prueba anterior.
    final statusEntries = await Future.wait(_allSchools.map((schoolDoc) async {
      final memberDoc = await FirebaseFirestore.instance
          .collection('schools')
          .doc(schoolDoc.id)
          .collection('members')
          .doc(_activeProfileId)
          .get(const GetOptions(source: Source.server));
      return MapEntry(schoolDoc.id, memberDoc.data()?['status'] as String?);
    }));
    _schoolStatus = Map.fromEntries(statusEntries);

    _applyFilter();
    setState(() => _isLoading = false);
  }

  void _applyFilter() {
    final query = _searchController.text.toLowerCase().trim();
    setState(() {
      _filteredSchools = _allSchools.where((schoolDoc) {
        // Siempre se muestran TODAS las escuelas, sin importar el estado de
        // la relación (sin relación, pendiente, activa, inactiva): el
        // trailing de cada card refleja ese estado en vez de ocultarla.
        if (query.isEmpty) return true;
        final schoolData = schoolDoc.data() as Map<String, dynamic>;
        final nameMatches = schoolData['name']?.toString().toLowerCase().contains(query) ?? false;
        return nameMatches;
      }).toList();
    });
  }

  Future<void> _postulateToSchool(String schoolId, String schoolName) async {
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
                  'gender': userDoc.data()?['gender'],
                  'powerLevel': 0,
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
                setState(() => _schoolStatus[schoolId] = 'pending');

                if (widget.isFromWizard) {
                  Navigator.of(context).pushAndRemoveUntil(
                    MaterialPageRoute(builder: (context) => ApplicationSentScreen(schoolName: schoolName)),
                        (route) => false,
                  );
                } else {
                  ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(l10n.applicationSentSuccess(schoolName)), backgroundColor: Colors.green));
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

  Future<void> _resendApplication(String schoolId, String schoolName) async {
    showDialog(
      context: context,
      barrierDismissible: !_isLoading,
      builder: (ctx) => AlertDialog(
        title: Text(l10n.confirmResendTitle),
        content: Text(l10n.confirmResendMessage(schoolName)),
        actions: [
          TextButton(onPressed: () => Navigator.of(ctx).pop(), child: Text(l10n.cancel)),
          TextButton(
            onPressed: () async {
              Navigator.of(ctx).pop();
              setState(() => _isLoading = true);

              try {
                final firestore = FirebaseFirestore.instance;
                final batch = firestore.batch();

                // El member doc ya existe (status pending): sólo refrescamos
                // la fecha para que el maestro lo vea como recién reenviado.
                batch.update(
                  firestore.collection('schools').doc(schoolId).collection('members').doc(_activeProfileId),
                  {'applicationDate': FieldValue.serverTimestamp()},
                );
                batch.set(
                  firestore.collection('users').doc(_activeProfileId),
                  {
                    'pendingApplications': {
                      schoolId: {
                        'schoolName': schoolName,
                        'applicationDate': FieldValue.serverTimestamp(),
                      }
                    }
                  },
                  SetOptions(merge: true),
                );

                await batch.commit();
                if (!mounted) return;
                ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                  content: Text(l10n.applicationResentSuccess(schoolName)),
                  backgroundColor: Colors.green,
                ));
              } catch (e) {
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(l10n.applicationSentError(e.toString()))));
                }
              } finally {
                if (mounted) setState(() => _isLoading = false);
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
                    final status = _schoolStatus[schoolDoc.id];
                    return Card(
                      margin: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 6.0),
                      child: ListTile(
                        title: Text(schoolData['name'] ?? l10n.noName),
                        subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(schoolData['city'] ?? l10n.noCity),
                            if (status == 'pending')
                              Text(
                                l10n.applicationStatusPending,
                                style: TextStyle(
                                  color: Colors.orange.shade700,
                                  fontWeight: FontWeight.w600,
                                  fontSize: 12,
                                ),
                              )
                            else if (status == 'active')
                              Text(
                                l10n.alreadyLinkedToSchool,
                                style: TextStyle(
                                  color: Colors.green.shade700,
                                  fontWeight: FontWeight.w600,
                                  fontSize: 12,
                                ),
                              ),
                          ],
                        ),
                        isThreeLine: status == 'pending' || status == 'active',
                        trailing: _buildTrailing(status, schoolDoc.id, schoolData['name']),
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

  Widget _buildTrailing(String? status, String schoolId, String? schoolName) {
    if (status == 'pending') {
      return OutlinedButton(
        onPressed: () => _resendApplication(schoolId, schoolName ?? ''),
        child: Text(l10n.resendApplication),
      );
    }
    if (status == null) {
      return ElevatedButton(
        onPressed: () => _postulateToSchool(schoolId, schoolName ?? ''),
        child: Text(l10n.apply),
      );
    }
    if (status == 'active') {
      return const Icon(Icons.check_circle, color: Colors.green);
    }
    // Otro estado (ej. inactivo por el maestro): informativo, sin acción.
    return Chip(label: Text(status));
  }
}
