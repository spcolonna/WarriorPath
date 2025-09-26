import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:warrior_path/screens/teacher/curriculum/discipline_detail_screen.dart';
import 'package:warrior_path/theme/martial_art_themes.dart';

import '../../../l10n/app_localizations.dart';

class CurriculumHubScreen extends StatefulWidget {
  final String schoolId;
  const CurriculumHubScreen({Key? key, required this.schoolId}) : super(key: key);

  @override
  State<CurriculumHubScreen> createState() => _CurriculumHubScreenState();
}

class _CurriculumHubScreenState extends State<CurriculumHubScreen> {
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

  Future<void> _navigateToDisciplineDetails(DocumentSnapshot disciplineDoc) async {
    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => DisciplineDetailScreen(
          schoolId: widget.schoolId,
          disciplineDoc: disciplineDoc,
        ),
      ),
    );
    setState(() {
      _disciplinesFuture = _fetchDisciplines();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.curriculumByDiscipline),
      ),
      body: FutureBuilder<List<DocumentSnapshot>>(
        future: _disciplinesFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(child: Text(l10n.loading));
          }
          if (snapshot.hasError) {
            return Center(child: Text(l10n.errorLoadingDisciplines));
          }
          if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return Center(child: Text(l10n.noDisciplinesFound));
          }

          final disciplines = snapshot.data!;

          return ListView(
            padding: const EdgeInsets.all(16.0),
            children: [
              Padding(
                padding: const EdgeInsets.only(bottom: 16.0),
                child: Text(
                  l10n.selectDisciplineToEdit,
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.bodyLarge,
                ),
              ),
              ...disciplines.map((doc) {
                final data = doc.data() as Map<String, dynamic>;
                final disciplineName = data['name'] ?? '';

                final theme = MartialArtTheme.allThemes.firstWhere(
                      (t) => t.name == disciplineName,
                  orElse: () => MartialArtTheme.karate,
                );

                return Card(
                  margin: const EdgeInsets.symmetric(vertical: 8),
                  child: ListTile(
                    leading: CircleAvatar(
                      radius: 22, // Radio del borde (un poco más grande)
                      backgroundColor: theme.primaryColor, // El color del borde
                      child: CircleAvatar(
                        radius: 20, // Radio de la imagen (un poco más pequeño)
                        // Usamos backgroundImage para que la imagen PNG se recorte automáticamente en círculo
                        backgroundImage: AssetImage(theme.icon),
                        // Color de fondo por si la imagen PNG no carga o tiene partes transparentes
                        backgroundColor: Colors.white,
                      ),
                    ),
                    title: Text(disciplineName, style: const TextStyle(fontWeight: FontWeight.bold)),
                    trailing: const Icon(Icons.arrow_forward_ios),
                    onTap: () => _navigateToDisciplineDetails(doc),
                  ),
                );
              }),
            ],
          );
        },
      ),
    );
  }
}
