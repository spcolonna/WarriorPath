import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:warrior_path/screens/student/application_sent_screen.dart';

class SchoolSearchScreen extends StatefulWidget {
  // Añadimos un flag para saber si venimos del wizard de un nuevo usuario
  final bool isFromWizard;

  const SchoolSearchScreen({Key? key, this.isFromWizard = false}) : super(key: key);

  @override
  State<SchoolSearchScreen> createState() => _SchoolSearchScreenState();
}

class _SchoolSearchScreenState extends State<SchoolSearchScreen> {
  final _searchController = TextEditingController();

  late Future<List<QueryDocumentSnapshot>> _schoolsFuture;
  List<QueryDocumentSnapshot> _allSchools = [];
  List<QueryDocumentSnapshot> _filteredSchools = [];

  Set<String> _userSchoolIds = {};
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _schoolsFuture = _fetchSchoolsAndFilter();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<List<QueryDocumentSnapshot>> _fetchSchoolsAndFilter() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      final userDoc = await FirebaseFirestore.instance.collection('users').doc(user.uid).get();
      if (userDoc.exists) {
        final memberships = userDoc.data()?['activeMemberships'] as Map<String, dynamic>? ?? {};
        final pendingApplications = userDoc.data()?['pendingApplications'] as Map<String, dynamic>? ?? {};
        _userSchoolIds = {...memberships.keys, ...pendingApplications.keys}.toSet();
      }
    }

    final schoolsSnapshot = await FirebaseFirestore.instance.collection('schools').get();
    _allSchools = schoolsSnapshot.docs;

    _applyFilter();

    return _filteredSchools;
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

  Future<void> _postulateToSchool(String schoolId, String schoolName) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    if (_userSchoolIds.contains(schoolId)) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Ya tienes un vínculo con esta escuela.')));
      return;
    }

    showDialog(
      context: context,
      barrierDismissible: !_isLoading,
      builder: (ctx) => AlertDialog(
        title: const Text('Confirmar Postulación'),
        content: Text('¿Quieres enviar tu solicitud para unirte a "$schoolName"?'),
        actions: [
          TextButton(onPressed: () => Navigator.of(ctx).pop(), child: const Text('Cancelar')),
          TextButton(
            onPressed: () async {
              Navigator.of(ctx).pop();
              setState(() { _isLoading = true; });

              try {
                final firestore = FirebaseFirestore.instance;
                final userDoc = await firestore.collection('users').doc(user.uid).get();
                final displayName = userDoc.data()?['displayName'] ?? 'Usuario sin nombre';
                final batch = firestore.batch();
                final userRef = firestore.collection('users').doc(user.uid);

                final memberRef = firestore.collection('schools').doc(schoolId).collection('members').doc(user.uid);
                batch.set(memberRef, {
                  'userId': user.uid, 'displayName': displayName, 'status': 'pending', 'applicationDate': FieldValue.serverTimestamp(),
                });

                // Lógica unificada para guardar la postulación
                final Map<String, dynamic> userDataToUpdate = {
                  'pendingApplications.$schoolId': {
                    'schoolName': schoolName,
                    'applicationDate': FieldValue.serverTimestamp(),
                  }
                };

                // Si es un usuario nuevo, también finalizamos su wizard
                if (widget.isFromWizard) {
                  userDataToUpdate['wizardStep'] = 99;
                }

                batch.update(userRef, userDataToUpdate);
                await batch.commit();

                if (!mounted) return;

                // Lógica de navegación condicional
                if (widget.isFromWizard) {
                  // Si es usuario nuevo, lo llevamos a la pantalla final
                  Navigator.of(context).pushAndRemoveUntil(
                    MaterialPageRoute(builder: (context) => ApplicationSentScreen(schoolName: schoolName)),
                        (route) => false,
                  );
                } else {
                  // Si es un usuario existente, solo mostramos un mensaje y volvemos
                  ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('¡Solicitud para "$schoolName" enviada!'), backgroundColor: Colors.green));
                  Navigator.of(context).pop();
                }

              } catch (e) {
                ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error al enviar la solicitud: ${e.toString()}')));
              } finally {
                if (mounted) setState(() { _isLoading = false; });
              }
            },
            child: const Text('Enviar'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Buscar Nueva Escuela')),
      body: AbsorbPointer(
        absorbing: _isLoading,
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: TextField(
                controller: _searchController,
                onChanged: (_) => _applyFilter(),
                decoration: const InputDecoration(labelText: 'Nombre de la escuela', prefixIcon: Icon(Icons.search), border: OutlineInputBorder()),
              ),
            ),
            if (_isLoading) const LinearProgressIndicator(),
            Expanded(
              child: FutureBuilder<List<QueryDocumentSnapshot>>(
                future: _schoolsFuture,
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) return const Center(child: CircularProgressIndicator());
                  if (snapshot.hasError) return const Center(child: Text('Error al cargar las escuelas.'));
                  if (_filteredSchools.isEmpty) return const Center(child: Text('No se encontraron nuevas escuelas.'));

                  return ListView.builder(
                    itemCount: _filteredSchools.length,
                    itemBuilder: (context, index) {
                      final schoolDoc = _filteredSchools[index];
                      final schoolData = schoolDoc.data() as Map<String, dynamic>;
                      return Card(
                        margin: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 6.0),
                        child: ListTile(
                          title: Text(schoolData['name'] ?? 'Sin Nombre'),
                          subtitle: Text('${schoolData['martialArt']} - ${schoolData['city'] ?? 'Sin Ciudad'}'),
                          trailing: ElevatedButton(child: const Text('Postularme'), onPressed: () => _postulateToSchool(schoolDoc.id, schoolData['name'])),
                        ),
                      );
                    },
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
