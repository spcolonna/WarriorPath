import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:warrior_path/providers/session_provider.dart';
import 'package:warrior_path/screens/teacher_dashboard_screen.dart';

import '../l10n/app_localizations.dart';

class WizardReviewScreen extends StatefulWidget {
  final String schoolId;
  const WizardReviewScreen({
    Key? key,
    required this.schoolId,
  }) : super(key: key);

  @override
  _WizardReviewScreenState createState() => _WizardReviewScreenState();
}

class _WizardReviewScreenState extends State<WizardReviewScreen> {
  late AppLocalizations l10n;
  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    l10n = AppLocalizations.of(context);
  }

  late Future<Map<String, dynamic>> _schoolDataFuture;
  bool _isLoading = false;
  Color _primaryColor = Colors.blue;

  @override
  void initState() {
    super.initState();
    _schoolDataFuture = _fetchSchoolData();
  }

  // --- CAMBIO: La función de carga ahora es mucho más compleja ---
  Future<Map<String, dynamic>> _fetchSchoolData() async {
    final firestore = FirebaseFirestore.instance;
    final schoolRef = firestore.collection('schools').doc(widget.schoolId);

    // 1. Obtenemos los datos principales de la escuela y los planes de pago
    final schoolDocFuture = schoolRef.get();
    final paymentPlansFuture = schoolRef.collection('paymentPlans').get();
    // Obtenemos todas las disciplinas
    final disciplinesFuture = schoolRef.collection('disciplines').get();

    final results = await Future.wait([schoolDocFuture, paymentPlansFuture, disciplinesFuture]);
    final schoolDoc = results[0] as DocumentSnapshot<Map<String, dynamic>>;
    final paymentPlansQuery = results[1] as QuerySnapshot<Map<String, dynamic>>;
    final disciplinesQuery = results[2] as QuerySnapshot<Map<String, dynamic>>;

    // Lista para guardar los datos completos de cada disciplina
    final List<Map<String, dynamic>> disciplinesData = [];

    // 2. Para cada disciplina, buscamos sus niveles y técnicas
    for (final disciplineDoc in disciplinesQuery.docs) {
      // Si es la disciplina principal, guardamos su color para la UI
      if (disciplineDoc.data()['isPrimary'] == true) {
        final themeData = disciplineDoc.data()['theme'] as Map<String, dynamic>;
        _primaryColor = Color(int.parse('FF${themeData['primaryColor']}', radix: 16));
      }

      final levelsFuture = disciplineDoc.reference.collection('levels').orderBy('order').get();
      final techniquesFuture = disciplineDoc.reference.collection('techniques').get();
      final disciplineDetails = await Future.wait([levelsFuture, techniquesFuture]);

      disciplinesData.add({
        'discipline': disciplineDoc.data(),
        'levels': (disciplineDetails[0] as QuerySnapshot).docs,
        'techniques': (disciplineDetails[1] as QuerySnapshot).docs,
      });
    }

    return {
      'school': schoolDoc.data(),
      'disciplinesData': disciplinesData,
      'paymentPlans': paymentPlansQuery.docs,
    };
  }

  Future<void> _finalizeSetup() async {
    setState(() { _isLoading = true; });
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) throw Exception(l10n.notAuthenticatedUser);

      // Marcamos el wizard como 100% completo
      await FirebaseFirestore.instance.collection('users').doc(user.uid).update({'wizardStep': 99});

      Provider.of<SessionProvider>(context, listen: false)
          .setFullActiveSession(widget.schoolId, 'maestro', user.uid);

      if (!mounted) return;
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (context) => const TeacherDashboardScreen()),
            (Route<dynamic> route) => false,
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(l10n.errorFinalizing(e.toString()))));
      setState(() { _isLoading = false; });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.reviewAndFinalizeStep6),
        backgroundColor: _primaryColor,
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
          final disciplinesData = snapshot.data!['disciplinesData'] as List<Map<String, dynamic>>;
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
                        Text(l10n.almostDoneReviewInfo, style: Theme.of(context).textTheme.titleMedium, textAlign: TextAlign.center),
                        const SizedBox(height: 20),

                        _buildReviewCard(title: l10n.schoolData, icon: Icons.school, children: [
                          _buildInfoRow('Nombre:', school['name'] ?? 'N/A'),
                          _buildInfoRow('Dirección:', '${school['address']}, ${school['city']}'),
                          _buildInfoRow('Teléfono:', school['phone'] ?? 'N/A'),
                        ]),

                        ...disciplinesData.map((data) {
                          final discipline = data['discipline'] as Map<String, dynamic>;
                          final levels = data['levels'] as List<QueryDocumentSnapshot>;
                          final techniques = data['techniques'] as List<QueryDocumentSnapshot>;
                          final categories = List<String>.from(discipline['techniqueCategories'] ?? []);

                          return _buildReviewCard(
                            title: l10n.disciplineLabel(discipline['name']),
                            icon: Icons.sports_martial_arts,
                            children: [
                              _buildInfoRow('${l10n.progressionSystem}:', discipline['progressionSystemName'] ?? 'N/A'),
                              _buildInfoRow('${l10n.levelsCreated}:', levels.length.toString()),
                              const SizedBox(height: 8),
                              _buildInfoRow('${l10n.techniquesAdded}:', techniques.length.toString()),
                              Text('${l10n.categoriesLabel}:', style: const TextStyle(fontWeight: FontWeight.bold)),
                              Wrap(spacing: 8.0, children: categories.map((cat) => Chip(label: Text(cat))).toList()),
                            ],
                          );
                        }).toList(),

                        _buildReviewCard(
                          title: l10n.pricingAndPlans,
                          icon: Icons.price_check,
                          children: [
                            _buildInfoRow('${l10n.inscriptionFee}:', '${financials['inscriptionFee']} ${financials['currency']}'),
                            _buildInfoRow('${l10n.examFee}:', '${financials['examFee']} ${financials['currency']}'),
                            const Divider(height: 20),
                            Text('${l10n.monthlyFeePlans}:', style: Theme.of(context).textTheme.titleSmall),
                            if (paymentPlans.isEmpty) const Text('No se crearon planes de pago.')
                            else Column(
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
                    label: Text(l10n.finalizeAndOpenSchool, style: const TextStyle(color: Colors.white, fontSize: 18)),
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      backgroundColor: _primaryColor,
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
            Row(children: [Icon(icon, color: _primaryColor), const SizedBox(width: 8), Text(title, style: Theme.of(context).textTheme.titleLarge)]),
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
        Expanded(child: Text(value.isEmpty ? l10n.noSpecify : value)),
      ]),
    );
  }
}
