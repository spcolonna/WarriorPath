import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../l10n/app_localizations.dart';
import '../../../models/technique_model.dart';
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

  late Future<Map<String, dynamic>> _progressDataFuture;

  @override
  void initState() {
    super.initState();
    _progressDataFuture = _fetchProgressData();
  }

  Future<Map<String, dynamic>> _fetchProgressData() async {
    final firestore = FirebaseFirestore.instance;

    final memberDoc = await firestore
        .collection('schools')
        .doc(widget.schoolId)
        .collection('members')
        .doc(widget.memberId)
        .get();

    final currentLevelId = memberDoc.data()?['currentLevelId'];

    DocumentSnapshot? currentLevelDoc;
    if (currentLevelId != null) {
      currentLevelDoc = await firestore
          .collection('schools')
          .doc(widget.schoolId)
          .collection('levels')
          .doc(currentLevelId)
          .get();
    }

    final allLevelsQuery = await firestore
        .collection('schools')
        .doc(widget.schoolId)
        .collection('levels')
        .orderBy('order')
        .get();

    return {
      'currentLevel': currentLevelDoc,
      'allLevels': allLevelsQuery.docs,
    };
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(l10n.myProgress)),
      body: FutureBuilder<Map<String, dynamic>>(
        future: _progressDataFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError || !snapshot.hasData) {
            return Center(child: Text(l10n.couldNotLoadProgress));
          }

          final currentLevelDoc = snapshot.data!['currentLevel'] as DocumentSnapshot?;
          final allLevels = snapshot.data!['allLevels'] as List<QueryDocumentSnapshot>;

          return SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _buildCurrentLevelHeader(currentLevelDoc),

                const Divider(height: 32, indent: 16, endIndent: 16),

                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16.0),
                  child: Text(l10n.yourPath, style: Theme.of(context).textTheme.headlineSmall),
                ),
                const SizedBox(height: 8),
                _buildProgressionPath(currentLevelDoc, allLevels),

                const Divider(height: 32, indent: 16, endIndent: 16),

                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16.0),
                  child: Text(l10n.promotionHistory, style: Theme.of(context).textTheme.headlineSmall),
                ),
                const Divider(height: 32, indent: 16, endIndent: 16),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16.0),
                  child: Text(l10n.assignedTechniques, style: Theme.of(context).textTheme.headlineSmall),
                ),
                const SizedBox(height: 8),
                _buildAssignedTechniques(context),
                const SizedBox(height: 24),
                _buildProgressionHistory(),
                const SizedBox(height: 24),
                Card(
                  margin: const EdgeInsets.symmetric(horizontal: 16.0),
                  child: ListTile(
                    leading: Icon(Icons.fact_check_outlined, color: Theme.of(context).primaryColor),
                    title: Text(l10n.myAttendanceHistory, style: TextStyle(fontWeight: FontWeight.bold)),
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
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildCurrentLevelHeader(DocumentSnapshot? currentLevelDoc) {
    if (currentLevelDoc == null || !currentLevelDoc.exists) {
      return Container(
        padding: const EdgeInsets.all(24),
        child: Text(l10n.noLevelAssignedYet),
      );
    }

    final data = currentLevelDoc.data() as Map<String, dynamic>;
    final levelName = data['name'] ?? l10n.withPutLevel;
    final levelColor = Color(data['colorValue']);

    return Container(
      width: double.infinity,
      color: levelColor.withOpacity(0.1),
      padding: const EdgeInsets.symmetric(vertical: 24.0),
      child: Column(
        children: [
          Text(l10n.yourCurrentLevel, style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            decoration: BoxDecoration(
              color: levelColor,
              borderRadius: BorderRadius.circular(30),
              boxShadow: [
                BoxShadow(color: Colors.black.withOpacity(0.2), spreadRadius: 1, blurRadius: 5, offset: const Offset(0, 3)),
              ],
            ),
            child: Text(
              levelName,
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(color: Colors.white, fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProgressionPath(DocumentSnapshot? currentLevelDoc, List<QueryDocumentSnapshot> allLevels) {
    if (allLevels.isEmpty) {
      return Text(l10n.progressionSystemNotDefined);
    }

    final currentLevelOrder = (currentLevelDoc?.data() as Map<String, dynamic>?)?['order'] ?? -1;

    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: allLevels.length,
      itemBuilder: (context, index) {
        final level = allLevels[index].data() as Map<String, dynamic>;
        final levelOrder = level['order'] as int;
        final isCompleted = levelOrder < currentLevelOrder;
        final isCurrent = levelOrder == currentLevelOrder;

        return ListTile(
          leading: isCompleted
              ? const Icon(Icons.check_circle, color: Colors.green)
              : isCurrent
              ? Icon(Icons.star, color: Theme.of(context).primaryColor)
              : const Icon(Icons.radio_button_unchecked, color: Colors.grey),
          title: Text(level['name']),
          tileColor: isCurrent ? Theme.of(context).primaryColor.withOpacity(0.1) : null,
        );
      },
    );
  }

  Widget _buildAssignedTechniques(BuildContext context) {
    return StreamBuilder<DocumentSnapshot>(
      stream: FirebaseFirestore.instance.collection('schools').doc(widget.schoolId).collection('members').doc(widget.memberId).snapshots(),
      builder: (context, memberSnapshot) {
        if (memberSnapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        if (!memberSnapshot.hasData || !memberSnapshot.data!.exists) {
          return const SizedBox.shrink();
        }

        final data = memberSnapshot.data!.data() as Map<String, dynamic>?;
        List<String> assignedIds = [];

        if (data != null && data.containsKey('assignedTechniqueIds')) {
          if (data['assignedTechniqueIds'] != null) {
            assignedIds = List<String>.from(data['assignedTechniqueIds']);
          }
        }

        if (assignedIds.isEmpty) {
          return Center(child: Padding(padding: const EdgeInsets.all(16), child: Text(l10n.teacherHasNotAssignedTechniques)));
        }

        return StreamBuilder<QuerySnapshot>(
          stream: FirebaseFirestore.instance.collection('schools').doc(widget.schoolId).collection('techniques').where(FieldPath.documentId, whereIn: assignedIds).snapshots(),
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
                  trailing: const Icon(Icons.arrow_forward_ios, size: 16, color: Colors.grey),
                  onTap: () {
                    _showTechniqueDetailsDialog(tech);
                  },
                );
              },
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
          .orderBy('date', descending: true)
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
          return Padding(
            padding: EdgeInsets.all(16.0),
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

  Widget _buildLevelPromotionEventTile(Map<String, dynamic> history) {
    final date = (history['date'] as Timestamp).toDate();
    final formattedDate = DateFormat('dd/MM/yyyy').format(date);
    final notes = history['notes'] as String?;

    return FutureBuilder<DocumentSnapshot>(
      future: FirebaseFirestore.instance.collection('schools').doc(widget.schoolId).collection('levels').doc(history['newLevelId']).get(),
      builder: (context, levelSnapshot) {
        String levelName = '...';
        if (levelSnapshot.hasData) {
          levelName = levelSnapshot.data?['name'] ?? l10n.withPutLevel;
        }
        return Card(
          margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
          child: ListTile(
            leading: const Icon(Icons.military_tech),
            title: Text(l10n.promotionTo(levelName)),
            subtitle: (notes != null && notes.isNotEmpty) ? Text(l10n.notesValue(notes)) : null,
            trailing: Text(formattedDate),
          ),
        );
      },
    );
  }

  Future<void> _launchVideoUrl(String urlString) async {
    final Uri url = Uri.parse(urlString);
    if (!await launchUrl(url, mode: LaunchMode.externalApplication)) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(l10n.couldNotOpenVideo(urlString))),
        );
      }
    }
  }

  void _showTechniqueDetailsDialog(TechniqueModel technique) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text(technique.name),
          content: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  technique.description.isEmpty
                      ? l10n.noDescriptionAvailable
                      : technique.description,
                  style: const TextStyle(height: 1.5), // Mejora la legibilidad
                ),
                if (technique.videoUrl != null && technique.videoUrl!.isNotEmpty) ...[
                  const SizedBox(height: 24),
                  const Divider(),
                  const SizedBox(height: 16),
                  Center(
                    child: ElevatedButton.icon(
                      icon: const Icon(Icons.play_circle_outline),
                      label: Text(l10n.watchTechniqueVideo),
                      onPressed: () {
                        _launchVideoUrl(technique.videoUrl!);
                      },
                    ),
                  ),
                ],
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text(l10n.close),
            ),
          ],
        );
      },
    );
  }
}
