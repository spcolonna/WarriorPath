import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:warrior_path/screens/student/application_sent_screen.dart';

class SchoolSearchScreen extends StatefulWidget {
  const SchoolSearchScreen({Key? key}) : super(key: key);

  @override
  State<SchoolSearchScreen> createState() => _SchoolSearchScreenState();
}

class _SchoolSearchScreenState extends State<SchoolSearchScreen> {
  final _searchController = TextEditingController();
  Stream<QuerySnapshot>? _searchResultsStream;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    // Al iniciar, mostramos todas las escuelas disponibles
    _searchResultsStream = FirebaseFirestore.instance.collection('schools').snapshots();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _onSearchChanged(String query) {
    final formattedQuery = query.trim();
    if (formattedQuery.isEmpty) {
      setState(() {
        _searchResultsStream = FirebaseFirestore.instance.collection('schools').snapshots();
      });
    } else {
      // Búsqueda que encuentra nombres que empiezan con la consulta.
      // Firestore es sensible a mayúsculas/minúsculas, por lo que una mejor
      // implementación futura usaría el campo 'searchKeywords' que discutimos.
      setState(() {
        _searchResultsStream = FirebaseFirestore.instance
            .collection('schools')
            .where('name', isGreaterThanOrEqualTo: formattedQuery)
            .where('name', isLessThanOrEqualTo: '$formattedQuery\uf8ff')
            .snapshots();
      });
    }
  }

  Future<void> _postulateToSchool(String schoolId, String schoolName) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    showDialog(
      context: context,
      barrierDismissible: !_isLoading, // Evita cerrar el diálogo mientras carga
      builder: (ctx) => AlertDialog(
        title: const Text('Confirmar Postulación'),
        content: Text('¿Quieres enviar tu solicitud para unirte a "$schoolName"?'),
        actions: [
          TextButton(onPressed: () => Navigator.of(ctx).pop(), child: const Text('Cancelar')),
          TextButton(
            onPressed: () async {
              Navigator.of(ctx).pop(); // Cierra el diálogo de confirmación
              setState(() { _isLoading = true; });

              try {
                final firestore = FirebaseFirestore.instance;

                // Obtenemos el nombre del usuario para mostrarlo al maestro
                final userDoc = await firestore.collection('users').doc(user.uid).get();
                final displayName = userDoc.data()?['displayName'] ?? 'Usuario sin nombre';

                // Preparamos la operación con un WriteBatch para que sea atómica (todo o nada)
                final batch = firestore.batch();

                // 1. Creamos la solicitud en la sub-colección de miembros de la escuela
                final memberRef = firestore.collection('schools').doc(schoolId).collection('members').doc(user.uid);
                batch.set(memberRef, {
                  'userId': user.uid,
                  'displayName': displayName,
                  'status': 'pending',
                  'applicationDate': FieldValue.serverTimestamp(),
                });

                // 2. Actualizamos el perfil del usuario para finalizar su wizard
                final userRef = firestore.collection('users').doc(user.uid);
                batch.update(userRef, {
                  'wizardStep': 99, // Marcamos el wizard como completado
                  'pendingApplication': { // Guardamos un registro de su postulación
                    'schoolId': schoolId,
                    'schoolName': schoolName,
                  }
                });

                // Ejecutamos ambas operaciones de escritura
                await batch.commit();

                if (!mounted) return;
                // 3. Navegamos a la pantalla de "Postulación Enviada" y borramos el historial
                Navigator.of(context).pushAndRemoveUntil(
                  MaterialPageRoute(builder: (context) => ApplicationSentScreen(schoolName: schoolName)),
                      (route) => false,
                );

              } catch (e) {
                ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error al enviar la solicitud: ${e.toString()}')));
              } finally {
                if (mounted) {
                  setState(() { _isLoading = false; });
                }
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
      appBar: AppBar(
        title: const Text('Busca tu Escuela'),
      ),
      body: AbsorbPointer(
        absorbing: _isLoading,
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: TextField(
                controller: _searchController,
                onChanged: _onSearchChanged,
                decoration: const InputDecoration(
                  labelText: 'Nombre de la escuela',
                  prefixIcon: Icon(Icons.search),
                  border: OutlineInputBorder(),
                ),
              ),
            ),
            if (_isLoading) const LinearProgressIndicator(),
            Expanded(
              child: StreamBuilder<QuerySnapshot>(
                stream: _searchResultsStream,
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  }
                  if (snapshot.hasError) {
                    return const Center(child: Text('Error al cargar las escuelas.'));
                  }
                  if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                    return const Center(child: Text('No se encontraron escuelas.'));
                  }

                  return ListView.builder(
                    itemCount: snapshot.data!.docs.length,
                    itemBuilder: (context, index) {
                      final schoolDoc = snapshot.data!.docs[index];
                      final schoolData = schoolDoc.data() as Map<String, dynamic>;

                      return Card(
                        margin: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 6.0),
                        child: ListTile(
                          title: Text(schoolData['name'] ?? 'Sin Nombre'),
                          subtitle: Text('${schoolData['martialArt']} - ${schoolData['city'] ?? 'Sin Ciudad'}'),
                          trailing: ElevatedButton(
                            child: const Text('Postularme'),
                            onPressed: () => _postulateToSchool(schoolDoc.id, schoolData['name']),
                          ),
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
