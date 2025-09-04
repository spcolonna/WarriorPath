import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:warrior_path/providers/session_provider.dart';
import 'package:warrior_path/screens/teacher_dashboard_screen.dart';
import 'package:warrior_path/theme/martial_art_themes.dart';

class WizardReviewScreen extends StatefulWidget {
  final String schoolId;
  final MartialArtTheme martialArtTheme;

  const WizardReviewScreen({
    Key? key,
    required this.schoolId,
    required this.martialArtTheme,
  }) : super(key: key);

  @override
  _WizardReviewScreenState createState() => _WizardReviewScreenState();
}

class _WizardReviewScreenState extends State<WizardReviewScreen> {
  late Future<Map<String, dynamic>> _schoolDataFuture;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _schoolDataFuture = _fetchSchoolData();
  }

  // --- FUNCIÓN DE CARGA DE DATOS ACTUALIZADA ---
  Future<Map<String, dynamic>> _fetchSchoolData() async {
    final schoolRef = FirebaseFirestore.instance.collection('schools').doc(widget.schoolId);

    // Ahora también buscamos los planes de pago que se crearon
    final results = await Future.wait([
      schoolRef.get(),
      schoolRef.collection('levels').orderBy('order').get(),
      schoolRef.collection('techniques').get(),
      schoolRef.collection('paymentPlans').get(), // <-- AÑADIDO
    ]);

    final schoolDoc = results[0] as DocumentSnapshot<Map<String, dynamic>>;
    final levelsQuery = results[1] as QuerySnapshot<Map<String, dynamic>>;
    final techniquesQuery = results[2] as QuerySnapshot<Map<String, dynamic>>;
    final paymentPlansQuery = results[3] as QuerySnapshot<Map<String, dynamic>>;

    return {
      'school': schoolDoc.data(),
      'levels': levelsQuery.docs,
      'techniques': techniquesQuery.docs,
      'paymentPlans': paymentPlansQuery.docs, // <-- AÑADIDO
    };
  }

  Future<void> _finalizeSetup() async {
    setState(() { _isLoading = true; });
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) throw Exception("Usuario no autenticado.");
      await FirebaseFirestore.instance.collection('users').doc(user.uid).update({'wizardStep': 99});
      Provider.of<SessionProvider>(context, listen: false).setActiveSession(widget.schoolId, 'maestro');
      if (!mounted) return;
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (context) => const TeacherDashboardScreen()),
            (Route<dynamic> route) => false,
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error al finalizar: ${e.toString()}')));
      setState(() { _isLoading = false; });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Revisar y Finalizar (Paso 6)'),
        backgroundColor: widget.martialArtTheme.primaryColor,
      ),
      body: FutureBuilder<Map<String, dynamic>>(
        future: _schoolDataFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(child: Text('Error al cargar los datos: ${snapshot.error}'));
          }
          if (!snapshot.hasData || snapshot.data == null) {
            return const Center(child: Text('No se encontraron datos.'));
          }

          final school = snapshot.data!['school'] as Map<String, dynamic>;
          final levels = snapshot.data!['levels'] as List<QueryDocumentSnapshot>;
          final techniques = snapshot.data!['techniques'] as List<QueryDocumentSnapshot>;
          final paymentPlans = snapshot.data!['paymentPlans'] as List<QueryDocumentSnapshot>;
          final financials = school['financials'] as Map<String, dynamic>? ?? {};

          return AbsorbPointer(
            absorbing: _isLoading,
            child: Column(
              children: [
                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Text('¡Casi listo! Revisa que toda la información de tu escuela sea correcta.', style: Theme.of(context).textTheme.titleMedium, textAlign: TextAlign.center),
                        const SizedBox(height: 20),

                        _buildReviewCard(title: 'Datos de la Escuela', icon: Icons.school, children: [
                          _buildInfoRow('Nombre:', school['name'] ?? 'N/A'),
                          _buildInfoRow('Arte Marcial:', school['martialArt'] ?? 'N/A'),
                          _buildInfoRow('Dirección:', '${school['address']}, ${school['city']}'),
                          _buildInfoRow('Teléfono:', school['phone'] ?? 'N/A'),
                        ]),

                        _buildReviewCard(title: 'Sistema de Progresión', icon: Icons.leaderboard, children: [
                          _buildInfoRow('Sistema:', school['progressionSystemName'] ?? 'N/A'),
                          const SizedBox(height: 8),
                          Text('Niveles:', style: Theme.of(context).textTheme.titleSmall),
                          ...levels.map((levelDoc) {
                            final level = levelDoc.data() as Map<String, dynamic>;
                            return ListTile(dense: true, leading: CircleAvatar(backgroundColor: Color(level['colorValue']), radius: 12), title: Text(level['name']));
                          }).toList(),
                        ]),

                        _buildReviewCard(title: 'Currículo Inicial', icon: Icons.menu_book, children: [
                          _buildInfoRow('Técnicas añadidas:', '${techniques.length}'),
                          const SizedBox(height: 8),
                          Text('Categorías:', style: Theme.of(context).textTheme.titleSmall),
                          Wrap(spacing: 8.0, children: List<Widget>.from((school['techniqueCategories'] as List<dynamic>? ?? []).map((cat) => Chip(label: Text(cat))))),
                        ]),

                        // --- TARJETA DE PRECIOS CORREGIDA ---
                        _buildReviewCard(
                          title: 'Precios y Planes',
                          icon: Icons.price_check,
                          children: [
                            _buildInfoRow('Inscripción:', '${financials['inscriptionFee']} ${financials['currency']}'),
                            _buildInfoRow('Precio por Examen:', '${financials['examFee']} ${financials['currency']}'),
                            const Divider(height: 20),
                            Text('Planes de Pago Mensual:', style: Theme.of(context).textTheme.titleSmall),
                            const SizedBox(height: 8),
                            if (paymentPlans.isEmpty)
                              const Text('No se crearon planes de pago.')
                            else
                              Column(
                                children: paymentPlans.map((planDoc) {
                                  final plan = planDoc.data() as Map<String, dynamic>;
                                  return ListTile(
                                    dense: true,
                                    title: Text(plan['title'], style: const TextStyle(fontWeight: FontWeight.bold)),
                                    trailing: Text('${plan['amount']} ${plan['currency']}'),
                                    subtitle: plan['description'] != '' ? Text(plan['description']) : null,
                                  );
                                }).toList(),
                              )
                          ],
                        ),
                      ],
                    ),
                  ),
                ),

                Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: _isLoading ? const Center(child: CircularProgressIndicator()) : ElevatedButton.icon(
                    icon: const Icon(Icons.rocket_launch, color: Colors.white),
                    label: const Text('Finalizar y Abrir mi Escuela', style: TextStyle(color: Colors.white, fontSize: 18)),
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      backgroundColor: widget.martialArtTheme.primaryColor,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    onPressed: _finalizeSetup,
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildReviewCard({required String title, required IconData icon, required List<Widget> children}) {
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(children: [Icon(icon, color: widget.martialArtTheme.primaryColor), const SizedBox(width: 8), Text(title, style: Theme.of(context).textTheme.titleLarge)]),
            const Divider(height: 20),
            ...children,
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(label, style: const TextStyle(fontWeight: FontWeight.bold)),
        const SizedBox(width: 8),
        Expanded(child: Text(value.isEmpty ? 'No especificado' : value)),
      ]),
    );
  }
}
