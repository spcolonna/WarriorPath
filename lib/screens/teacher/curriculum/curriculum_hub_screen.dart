import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

import '../../../l10n/app_localizations.dart';
import 'discipline_detail_screen.dart';

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

  late Future<List<QueryDocumentSnapshot>> _disciplinesFuture;

  @override
  void initState() {
    super.initState();
    _disciplinesFuture = _fetchDisciplines();
  }

  Future<List<QueryDocumentSnapshot>> _fetchDisciplines() async {
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
                final themeData = data['theme'] as Map<String, dynamic>? ?? {};
                final color = themeData.containsKey('primaryColor')
                    ? Color(int.parse('FF${themeData['primaryColor']}', radix: 16))
                    : Theme.of(context).primaryColor;

                return Card(
                  margin: const EdgeInsets.symmetric(vertical: 8),
                  child: ListTile(
                    leading: CircleAvatar(
                      backgroundColor: color,
                      child: const Icon(Icons.sports_martial_arts, color: Colors.white),
                    ),
                    title: Text(data['name'], style: const TextStyle(fontWeight: FontWeight.bold)),
                    trailing: const Icon(Icons.arrow_forward_ios),
                    onTap: () => _navigateToDisciplineDetails(doc),
                  ),
                );
              }).toList(),
            ],
          );
        },
      ),
    );
  }
}
