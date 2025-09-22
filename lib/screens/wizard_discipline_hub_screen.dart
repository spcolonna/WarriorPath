import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:warrior_path/screens/wizard_configure_discipline_screen.dart';
import 'package:warrior_path/screens/wizard_configure_pricing_screen.dart';

import '../l10n/app_localizations.dart';

class WizardDisciplineHubScreen extends StatefulWidget {
  final String schoolId;
  const WizardDisciplineHubScreen({Key? key, required this.schoolId}) : super(key: key);

  @override
  State<WizardDisciplineHubScreen> createState() => _WizardDisciplineHubScreenState();
}

class _WizardDisciplineHubScreenState extends State<WizardDisciplineHubScreen> {
  late AppLocalizations l10n;
  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    l10n = AppLocalizations.of(context);
  }

  late Future<List<DocumentSnapshot>> _disciplinesFuture;

  @override
  void initState() {
    super.initState();
    _disciplinesFuture = _fetchDisciplines();
  }

  Future<List<DocumentSnapshot>> _fetchDisciplines() async {
    final disciplinesSnapshot = await FirebaseFirestore.instance
        .collection('schools')
        .doc(widget.schoolId)
        .collection('disciplines')
        .get();
    return disciplinesSnapshot.docs;
  }

  void _navigateToDisciplineConfiguration(DocumentSnapshot discipline) async {
    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => WizardConfigureDisciplineScreen(
          schoolId: widget.schoolId,
          disciplineDoc: discipline,
        ),
      ),
    );
    // Refresca el estado al volver
    setState(() { _disciplinesFuture = _fetchDisciplines(); });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.disciplineConfigPanel),
        automaticallyImplyLeading: false, // El usuario no debe volver atrás
      ),
      body: FutureBuilder<List<DocumentSnapshot>>(
        future: _disciplinesFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(child: Text(l10n.loading));
          }
          if (snapshot.hasError || !snapshot.hasData) {
            return const Center(child: Text('Error al cargar las disciplinas.'));
          }

          final disciplines = snapshot.data!;

          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: Text(
                  l10n.disciplineConfigMessage,
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.bodyLarge,
                ),
              ),
              const Divider(),
              Expanded(
                child: ListView.builder(
                  itemCount: disciplines.length,
                  itemBuilder: (context, index) {
                    final doc = disciplines[index];
                    final data = doc.data() as Map<String, dynamic>;
                    final bool isConfigured = data.containsKey('progressionSystemName'); // Asumimos que está configurada si tiene nombre el sistema

                    return Card(
                      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      child: ListTile(
                        leading: Icon(
                          isConfigured ? Icons.check_circle : Icons.pending_actions_outlined,
                          color: isConfigured ? Colors.green : Colors.orange,
                        ),
                        title: Text(data['name'], style: const TextStyle(fontWeight: FontWeight.bold)),
                        subtitle: Text(isConfigured ? l10n.statusConfigured : l10n.statusNotConfigured),
                        trailing: const Icon(Icons.arrow_forward_ios),
                        onTap: () => _navigateToDisciplineConfiguration(doc),
                      ),
                    );
                  },
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 16)
                  ),
                  child: Text(l10n.continueToPricing),
                  onPressed: () {
                    Navigator.of(context).push(
                      MaterialPageRoute(
                          builder: (context) => WizardConfigurePricingScreen(schoolId: widget.schoolId)
                      ),
                    );
                  },
                ),
              )
            ],
          );
        },
      ),
    );
  }
}
