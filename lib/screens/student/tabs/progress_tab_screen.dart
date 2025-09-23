import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:warrior_path/models/discipline_model.dart';
import 'package:warrior_path/models/level_model.dart';
import 'package:warrior_path/models/technique_model.dart';
import 'package:collection/collection.dart';
import '../../../l10n/app_localizations.dart';
import '../my_attendance_history_screen.dart';

class ProgressTabScreen extends StatefulWidget {
  final String schoolId;
  final String memberId;

  const ProgressTabScreen({
    super.key,
    required this.schoolId,
    required this.memberId,
  });

  @override
  State<ProgressTabScreen> createState() => _ProgressTabScreenState();
}


class _ProgressTabScreenState extends State<ProgressTabScreen> {
  late AppLocalizations l10n;
  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    l10n = AppLocalizations.of(context);
  }

  bool _isLoading = true;
  List<DisciplineModel> _enrolledDisciplines = [];
  DisciplineModel? _selectedDiscipline;
  Map<String, dynamic> _memberProgress = {};

  @override
  void initState() {
    super.initState();
    _loadInitialData();
  }

  Future<void> _loadInitialData() async {
    try {
      final memberDoc = await FirebaseFirestore.instance.collection('schools').doc(widget.schoolId).collection('members').doc(widget.memberId).get();
      if (!memberDoc.exists || !mounted) {
        setState(() => _isLoading = false);
        return;
      }
      _memberProgress = memberDoc.data()?['progress'] as Map<String, dynamic>? ?? {};
      final enrolledDisciplineIds = _memberProgress.keys.toList();
      if (enrolledDisciplineIds.isNotEmpty) {
        final disciplinesSnapshot = await FirebaseFirestore.instance.collection('schools').doc(widget.schoolId).collection('disciplines').where(FieldPath.documentId, whereIn: enrolledDisciplineIds).get();
        _enrolledDisciplines = disciplinesSnapshot.docs.map((doc) => DisciplineModel.fromFirestore(doc)).toList();
        if (_enrolledDisciplines.isNotEmpty) {
          _selectedDiscipline = _enrolledDisciplines.first;
        }
      }
    } catch (e) {
      print('Error al cargar progreso del alumno: $e');
    } finally {
      if(mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(l10n.myProgress)),
      body: _isLoading
          ? Center(child: Text(l10n.loading))
          : (_selectedDiscipline == null
          ? Center(child: Text(l10n.noDisciplinesEnrolledStudent))
          : SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (_enrolledDisciplines.length > 1) _buildDisciplineSelector(),
            _buildCurrentLevelHeader(),
            const Divider(height: 32, indent: 16, endIndent: 16),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              child: Text(l10n.yourPath, style: Theme.of(context).textTheme.headlineSmall),
            ),
            const SizedBox(height: 8),
            _buildProgressionPath(),
            const Divider(height: 32, indent: 16, endIndent: 16),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              child: Text(l10n.promotionHistory, style: Theme.of(context).textTheme.headlineSmall),
            ),
            _buildProgressionHistory(),
            const Divider(height: 32, indent: 16, endIndent: 16),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              child: Text(l10n.assignedTechniques, style: Theme.of(context).textTheme.headlineSmall),
            ),
            const SizedBox(height: 8),
            _buildAssignedTechniques(),
            const SizedBox(height: 24),
            Card(
              margin: const EdgeInsets.symmetric(horizontal: 16.0),
              child: ListTile(
                leading: Icon(Icons.fact_check_outlined, color: Theme.of(context).primaryColor),
                title: Text(l10n.myAttendanceHistory, style: const TextStyle(fontWeight: FontWeight.bold)),
                trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                onTap: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (context) => MyAttendanceHistoryScreen(
                        schoolId: widget.schoolId,
                        studentId: widget.memberId,
                      ),
                    ),
                  );
                },
              ),
            ),
            const SizedBox(height: 24),
          ],
        ),
      )),
    );
  }

  Widget _buildLevelPromotionEventTile(Map<String, dynamic> history) {
    final date = (history['date'] as Timestamp).toDate();
    final formattedDate = DateFormat('dd/MM/yyyy').format(date);
    final notes = history['notes'] as String?;
    final levelId = history['newLevelId'];

    return FutureBuilder<DocumentSnapshot>(
      future: FirebaseFirestore.instance
          .collection('schools').doc(widget.schoolId)
          .collection('disciplines').doc(_selectedDiscipline!.id) // <-- Busca en la disciplina correcta
          .collection('levels').doc(levelId).get(),
      builder: (context, levelSnapshot) {
        String levelName = l10n.loading;
        if (levelSnapshot.connectionState == ConnectionState.done) {
          levelName = levelSnapshot.data?['name'] ?? l10n.deleteLevel;
        }
        return Card(
          margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
          child: ListTile(
            leading: const Icon(Icons.military_tech, color: Colors.amber), // <-- El ícono de la medalla
            title: Text(l10n.promotionTo(levelName)),
            subtitle: (notes != null && notes.isNotEmpty) ? Text(l10n.notesValue(notes)) : null,
            trailing: Text(formattedDate),
          ),
        );
      },
    );
  }

  Widget _buildRoleChangeEventTile(Map<String, dynamic> history) {
    final date = (history['date'] as Timestamp).toDate();
    final formattedDate = DateFormat('dd/MM/yyyy').format(date);
    final newRole = history['newRole'] ?? '';
    final roleText = l10n.rolUpdatedTo(newRole[0].toUpperCase() + newRole.substring(1));

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      child: ListTile(
        leading: const Icon(Icons.admin_panel_settings),
        title: Text(roleText),
        trailing: Text(formattedDate),
      ),
    );
  }

  Widget _buildDisciplineSelector() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
      child: DropdownButton<DisciplineModel>(
        value: _selectedDiscipline,
        isExpanded: true,
        underline: Container(height: 2, color: Theme.of(context).primaryColor.withOpacity(0.5)),
        items: _enrolledDisciplines.map((discipline) {
          return DropdownMenuItem(value: discipline, child: Text(discipline.name, style: Theme.of(context).textTheme.titleLarge));
        }).toList(),
        onChanged: (discipline) => setState(() => _selectedDiscipline = discipline),
      ),
    );
  }

  Widget _buildCurrentLevelHeader() {
    final progressInDiscipline = _memberProgress[_selectedDiscipline!.id] as Map<String, dynamic>? ?? {};
    final currentLevelId = progressInDiscipline['currentLevelId'] as String?;

    if (currentLevelId == null) return Container(padding: const EdgeInsets.all(24), child: Text(l10n.noLevelAssignedYet));

    return FutureBuilder<DocumentSnapshot>(
      // --- CORRECCIÓN: Reconstruimos la referencia al documento ---
      future: FirebaseFirestore.instance.collection('schools').doc(widget.schoolId).collection('disciplines').doc(_selectedDiscipline!.id).collection('levels').doc(currentLevelId).get(),
      builder: (context, levelSnapshot) {
        if (!levelSnapshot.hasData || !levelSnapshot.data!.exists) return Container(width: double.infinity, color: Colors.grey.withOpacity(0.1), padding: const EdgeInsets.symmetric(vertical: 24.0), child: Center(child: Text(l10n.deleteLevel)));

        final data = levelSnapshot.data!.data() as Map<String, dynamic>;
        final levelName = data['name'] ?? l10n.withPutLevel;
        final levelColor = Color(data['colorValue']);

        return Container(
          width: double.infinity,
          color: levelColor.withOpacity(0.1),
          padding: const EdgeInsets.symmetric(vertical: 24.0),
          child: Column(children: [
            Text(l10n.yourCurrentLevel, style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              decoration: BoxDecoration(color: levelColor, borderRadius: BorderRadius.circular(30)),
              child: Text(levelName, style: Theme.of(context).textTheme.headlineSmall?.copyWith(color: Colors.white, fontWeight: FontWeight.bold)),
            ),
          ]),
        );
      },
    );
  }

  Widget _buildProgressionPath() {
    final progressInDiscipline = _memberProgress[_selectedDiscipline!.id] as Map<String, dynamic>? ?? {};
    final currentLevelId = progressInDiscipline['currentLevelId'] as String?;

    return FutureBuilder<QuerySnapshot>(
      // --- CORRECCIÓN: Reconstruimos la referencia a la colección ---
      future: FirebaseFirestore.instance.collection('schools').doc(widget.schoolId).collection('disciplines').doc(_selectedDiscipline!.id).collection('levels').orderBy('order').get(),
      builder: (context, levelsSnapshot) {
        if (!levelsSnapshot.hasData) return const Center(child: CircularProgressIndicator());
        if (levelsSnapshot.data!.docs.isEmpty) return Center(child: Text(l10n.progressionSystemNotDefined, textAlign: TextAlign.center));

        final allLevels = levelsSnapshot.data!.docs;
        final currentLevelDoc = allLevels.firstWhereOrNull((doc) => doc.id == currentLevelId);
        final currentLevelOrder = currentLevelDoc != null ? (currentLevelDoc.data() as Map<String, dynamic>)['order'] : -1;
        final primaryColor = Color(int.parse('FF${_selectedDiscipline!.theme['primaryColor']}', radix: 16));

        return ListView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: allLevels.length,
          itemBuilder: (context, index) {
            final level = LevelModel.fromFirestore(allLevels[index]);
            final isCompleted = level.order < currentLevelOrder;
            final isCurrent = level.order == currentLevelOrder;
            return ListTile(
              leading: Icon(isCompleted ? Icons.check_circle : (isCurrent ? Icons.star : Icons.radio_button_unchecked), color: isCurrent ? primaryColor : (isCompleted ? Colors.green : Colors.grey)),
              title: Text(level.name),
              tileColor: isCurrent ? primaryColor.withOpacity(0.1) : null,
            );
          },
        );
      },
    );
  }

  Widget _buildProgressionHistory() {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('schools').doc(widget.schoolId)
          .collection('members').doc(widget.memberId)
          .collection('progressionHistory')
          .where('disciplineId', isEqualTo: _selectedDiscipline!.id)
          .orderBy('date', descending: true)
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
          return Padding(
            padding: const EdgeInsets.all(16.0),
            child: Center(child: Text(l10n.noPromotionsRegisteredYet)),
          );
        }

        return ListView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: snapshot.data!.docs.length,
          itemBuilder: (context, index) {
            final history = snapshot.data!.docs[index].data() as Map<String, dynamic>;
            final eventType = history['type'] ?? 'level_promotion';

            if (eventType == 'role_change') {
              return _buildRoleChangeEventTile(history);
            } else {
              return _buildLevelPromotionEventTile(history);
            }
          },
        );
      },
    );
  }

  Widget _buildAssignedTechniques() {
    final progressInDiscipline = _memberProgress[_selectedDiscipline!.id] as Map<String, dynamic>? ?? {};
    final assignedTechniqueIds = List<String>.from(progressInDiscipline['assignedTechniqueIds'] ?? []);

    if (assignedTechniqueIds.isEmpty) {
      return Center(child: Padding(padding: const EdgeInsets.all(16), child: Text(l10n.teacherHasNotAssignedTechniques)));
    }

    return StreamBuilder<QuerySnapshot>(
      // --- CORRECCIÓN: Reconstruimos la referencia a la colección ---
      stream: FirebaseFirestore.instance.collection('schools').doc(widget.schoolId).collection('disciplines').doc(_selectedDiscipline!.id).collection('techniques').where(FieldPath.documentId, whereIn: assignedTechniqueIds).snapshots(),
      builder: (context, techSnapshot) {
        if (!techSnapshot.hasData) return const Center(child: CircularProgressIndicator());
        return ListView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: techSnapshot.data!.docs.length,
          itemBuilder: (context, index) {
            final tech = TechniqueModel.fromFirestore(techSnapshot.data!.docs[index]);
            return ListTile(
              leading: const Icon(Icons.menu_book),
              title: Text(tech.name),
              subtitle: Text(tech.category),
              onTap: () => _showTechniqueDetailsDialog(tech),
            );
          },
        );
      },
    );
  }

  void _showTechniqueDetailsDialog(TechniqueModel technique) {
    showDialog(context: context, builder: (context) => AlertDialog(
      title: Text(technique.name),
      content: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(technique.description.isEmpty ? l10n.noDescriptionAvailable : technique.description),
            if (technique.videoUrl != null && technique.videoUrl!.isNotEmpty) ...[
              const SizedBox(height: 24), const Divider(), const SizedBox(height: 16),
              Center(child: ElevatedButton.icon(
                icon: const Icon(Icons.play_circle_outline),
                label: Text(l10n.watchTechniqueVideo),
                onPressed: () => _launchVideoUrl(technique.videoUrl!),
              ),
              ),
            ],
          ],
        ),
      ),
      actions: [ TextButton(onPressed: () => Navigator.of(context).pop(), child: Text(l10n.close)) ],
    ),
    );
  }

  Future<void> _launchVideoUrl(String urlString) async {
    final Uri url = Uri.parse(urlString);
    if (!await launchUrl(url, mode: LaunchMode.externalApplication)) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(l10n.couldNotOpenVideo(urlString))));
      }
    }
  }
}
