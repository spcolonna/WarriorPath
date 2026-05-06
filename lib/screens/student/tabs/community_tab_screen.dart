import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../l10n/app_localizations.dart';
import '../../../models/technique_model.dart';
import '../../teacher/student_detail_screen.dart';

class CommunityTabScreen extends StatefulWidget {
  final String schoolId;
  const CommunityTabScreen({super.key, required this.schoolId});

  @override
  State<CommunityTabScreen> createState() => _CommunityTabScreenState();
}

class _CommunityTabScreenState extends State<CommunityTabScreen>
    with SingleTickerProviderStateMixin {
  late AppLocalizations l10n;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    l10n = AppLocalizations.of(context);
  }

  late TabController _tabController;
  late Future<Map<String, String>> _disciplinesMapFuture;
  late Future<List<_DisciplineWithTechniques>> _techniquesFuture;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _disciplinesMapFuture = _fetchDisciplinesAsMap();
    _techniquesFuture = _fetchAllTechniques();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<Map<String, String>> _fetchDisciplinesAsMap() async {
    final snap = await FirebaseFirestore.instance
        .collection('schools')
        .doc(widget.schoolId)
        .collection('disciplines')
        .get();
    return {for (final doc in snap.docs) doc.id: doc.data()['name'] as String? ?? ''};
  }

  Future<List<_DisciplineWithTechniques>> _fetchAllTechniques() async {
    final disciplinesSnap = await FirebaseFirestore.instance
        .collection('schools')
        .doc(widget.schoolId)
        .collection('disciplines')
        .get();

    final results = await Future.wait(disciplinesSnap.docs.map((disciplineDoc) async {
      final data = disciplineDoc.data();
      final themData = data['theme'] as Map<String, dynamic>? ?? {};
      final color = _parseColor(themData['primaryColor'] as String?);

      final techniquesSnap = await disciplineDoc.reference
          .collection('techniques')
          .orderBy('category')
          .orderBy('name')
          .get();

      final techniques = techniquesSnap.docs
          .map((d) => TechniqueModel.fromFirestore(d))
          .toList();

      final Map<String, List<TechniqueModel>> byCategory = {};
      for (final t in techniques) {
        byCategory.putIfAbsent(t.category, () => []).add(t);
      }

      return _DisciplineWithTechniques(
        id: disciplineDoc.id,
        name: data['name'] as String? ?? '',
        color: color,
        techniquesByCategory: byCategory,
      );
    }));

    return results.where((d) => d.techniquesByCategory.isNotEmpty).toList();
  }

  Color _parseColor(String? hex) {
    if (hex == null || hex.isEmpty) return Colors.blueGrey;
    try {
      final value = int.parse(hex.padLeft(8, 'f'), radix: 16);
      return Color(value);
    } catch (_) {
      return Colors.blueGrey;
    }
  }

  // ── MEMBERS TAB ─────────────────────────────────────────────────────────────

  Widget _buildMembersTab() {
    return FutureBuilder<Map<String, String>>(
      future: _disciplinesMapFuture,
      builder: (context, disciplinesSnapshot) {
        if (disciplinesSnapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        if (disciplinesSnapshot.hasError) {
          return Center(child: Text(l10n.errorLoadingDisciplines));
        }
        final disciplinesMap = disciplinesSnapshot.data ?? {};

        return StreamBuilder<QuerySnapshot>(
          stream: FirebaseFirestore.instance
              .collection('schools')
              .doc(widget.schoolId)
              .collection('members')
              .where('status', isEqualTo: 'active')
              .orderBy('role')
              .orderBy('displayName')
              .snapshots(),
          builder: (context, membersSnapshot) {
            if (membersSnapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }
            if (membersSnapshot.hasError) {
              return Center(child: Text(l10n.errorLoadingMembers));
            }
            if (!membersSnapshot.hasData || membersSnapshot.data!.docs.isEmpty) {
              return Center(child: Text(l10n.noActiveMembersYet));
            }

            final members = membersSnapshot.data!.docs;
            String currentRole = '';

            return ListView.builder(
              padding: const EdgeInsets.only(bottom: 16),
              itemCount: members.length,
              itemBuilder: (context, index) {
                final memberDoc = members[index];
                final memberData = memberDoc.data() as Map<String, dynamic>;
                final memberRole = memberData['role'] as String? ?? 'alumno';
                final bool showHeader = memberRole != currentRole;
                currentRole = memberRole;

                final progressMap =
                    memberData['progress'] as Map<String, dynamic>? ?? {};
                final enrolledDisciplineNames = progressMap.keys
                    .map((id) => disciplinesMap[id] ?? '?')
                    .join(', ');

                String roleHeader;
                switch (memberRole) {
                  case 'alumno':
                    roleHeader = l10n.students;
                    break;
                  case 'instructor':
                    roleHeader = l10n.instructor;
                    break;
                  case 'maestro':
                    roleHeader = l10n.teacher;
                    break;
                  default:
                    roleHeader = memberRole;
                }

                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (showHeader)
                      Padding(
                        padding:
                            const EdgeInsets.only(left: 16, top: 20, bottom: 8),
                        child: Text(
                          roleHeader,
                          style: Theme.of(context).textTheme.headlineSmall,
                        ),
                      ),
                    Card(
                      margin:
                          const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      child: ListTile(
                        onTap: () {
                          Navigator.of(context).push(MaterialPageRoute(
                            builder: (_) => StudentDetailScreen(
                              schoolId: widget.schoolId,
                              studentId: memberDoc.id,
                            ),
                          ));
                        },
                        leading: FutureBuilder<DocumentSnapshot>(
                          future: FirebaseFirestore.instance
                              .collection('users')
                              .doc(memberDoc.id)
                              .get(),
                          builder: (context, userSnapshot) {
                            if (!userSnapshot.hasData) {
                              return const CircleAvatar(radius: 20);
                            }
                            final photoUrl = (userSnapshot.data?.data()
                                    as Map<String, dynamic>?)?['photoUrl']
                                as String?;
                            return CircleAvatar(
                              radius: 20,
                              backgroundImage: (photoUrl != null &&
                                      photoUrl.isNotEmpty)
                                  ? NetworkImage(photoUrl)
                                  : null,
                              child: (photoUrl == null || photoUrl.isEmpty)
                                  ? const Icon(Icons.person)
                                  : null,
                            );
                          },
                        ),
                        title: Text(
                          memberData['displayName'] as String? ?? l10n.noName,
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                        subtitle: Text(
                          enrolledDisciplineNames.isNotEmpty
                              ? enrolledDisciplineNames
                              : 'Sin disciplinas',
                        ),
                        trailing: const Icon(Icons.arrow_forward_ios,
                            size: 16, color: Colors.grey),
                      ),
                    ),
                  ],
                );
              },
            );
          },
        );
      },
    );
  }

  // ── TECHNIQUES TAB ───────────────────────────────────────────────────────────

  Widget _buildTechniquesTab() {
    return FutureBuilder<List<_DisciplineWithTechniques>>(
      future: _techniquesFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        if (snapshot.hasError) {
          return Center(child: Text('Error al cargar técnicas'));
        }
        final disciplines = snapshot.data ?? [];
        if (disciplines.isEmpty) {
          return Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.sports_martial_arts,
                    size: 64, color: Colors.grey.shade300),
                const SizedBox(height: 16),
                Text(
                  'La escuela aún no tiene\ntécnicas publicadas.',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: Colors.grey.shade500, fontSize: 15),
                ),
              ],
            ),
          );
        }

        return ListView.builder(
          padding: const EdgeInsets.fromLTRB(12, 16, 12, 32),
          itemCount: disciplines.length,
          itemBuilder: (context, i) =>
              _DisciplineCard(discipline: disciplines[i]),
        );
      },
    );
  }

  // ── BUILD ────────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.schoolCommunity),
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: Colors.white,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white70,
          tabs: const [
            Tab(icon: Icon(Icons.groups), text: 'Compañeros'),
            Tab(icon: Icon(Icons.sports_martial_arts), text: 'Técnicas'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildMembersTab(),
          _buildTechniquesTab(),
        ],
      ),
    );
  }
}

// ── Data class ───────────────────────────────────────────────────────────────

class _DisciplineWithTechniques {
  final String id;
  final String name;
  final Color color;
  final Map<String, List<TechniqueModel>> techniquesByCategory;

  const _DisciplineWithTechniques({
    required this.id,
    required this.name,
    required this.color,
    required this.techniquesByCategory,
  });

  int get totalCount =>
      techniquesByCategory.values.fold(0, (acc, list) => acc + list.length);
}

// ── Discipline card with expandable categories ───────────────────────────────

class _DisciplineCard extends StatelessWidget {
  final _DisciplineWithTechniques discipline;

  const _DisciplineCard({required this.discipline});

  @override
  Widget build(BuildContext context) {
    final color = discipline.color;
    final categories = discipline.techniquesByCategory.keys.toList()..sort();

    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      clipBehavior: Clip.antiAlias,
      elevation: 3,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      child: Column(
        children: [
          // Discipline header
          Container(
            width: double.infinity,
            color: color,
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
            child: Row(
              children: [
                const Icon(Icons.sports_martial_arts,
                    color: Colors.white, size: 26),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    discipline.name,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 0.5,
                    ),
                  ),
                ),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    '${discipline.totalCount} técnica${discipline.totalCount == 1 ? '' : 's'}',
                    style: const TextStyle(
                        color: Colors.white,
                        fontSize: 12,
                        fontWeight: FontWeight.w500),
                  ),
                ),
              ],
            ),
          ),
          // Categories as expansion tiles
          ...categories.map((category) {
            final techniques = discipline.techniquesByCategory[category]!;
            return _CategoryTile(
              category: category,
              techniques: techniques,
              accentColor: color,
            );
          }),
        ],
      ),
    );
  }
}

// ── Category expandable tile ─────────────────────────────────────────────────

class _CategoryTile extends StatelessWidget {
  final String category;
  final List<TechniqueModel> techniques;
  final Color accentColor;

  const _CategoryTile({
    required this.category,
    required this.techniques,
    required this.accentColor,
  });

  @override
  Widget build(BuildContext context) {
    return Theme(
      data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
      child: ExpansionTile(
        tilePadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 2),
        leading: CircleAvatar(
          radius: 16,
          backgroundColor: accentColor.withValues(alpha: 0.12),
          child: Icon(Icons.folder_outlined, color: accentColor, size: 18),
        ),
        title: Text(
          category,
          style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 15),
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
              decoration: BoxDecoration(
                color: accentColor.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Text(
                '${techniques.length}',
                style: TextStyle(
                    color: accentColor,
                    fontWeight: FontWeight.bold,
                    fontSize: 13),
              ),
            ),
            const SizedBox(width: 4),
            Icon(Icons.expand_more, color: Colors.grey.shade500),
          ],
        ),
        children: techniques
            .map((t) => _TechniqueTile(technique: t, accentColor: accentColor))
            .toList(),
      ),
    );
  }
}

// ── Technique list tile ──────────────────────────────────────────────────────

class _TechniqueTile extends StatelessWidget {
  final TechniqueModel technique;
  final Color accentColor;

  const _TechniqueTile({required this.technique, required this.accentColor});

  void _showDetail(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => _TechniqueDetailSheet(
          technique: technique, accentColor: accentColor),
    );
  }

  @override
  Widget build(BuildContext context) {
    final hasVideo = technique.videoUrl != null && technique.videoUrl!.isNotEmpty;
    return InkWell(
      onTap: () => _showDetail(context),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        child: Row(
          children: [
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: accentColor.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(Icons.self_improvement, color: accentColor, size: 20),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(technique.name,
                      style: const TextStyle(
                          fontWeight: FontWeight.w600, fontSize: 14)),
                  if (technique.description.isNotEmpty)
                    Text(
                      technique.description,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                          color: Colors.grey.shade500, fontSize: 12),
                    ),
                ],
              ),
            ),
            if (hasVideo)
              Padding(
                padding: const EdgeInsets.only(right: 8),
                child: Icon(Icons.play_circle_outline,
                    color: accentColor, size: 20),
              ),
            Icon(Icons.chevron_right, color: Colors.grey.shade400, size: 18),
          ],
        ),
      ),
    );
  }
}

// ── Technique detail bottom sheet ────────────────────────────────────────────

class _TechniqueDetailSheet extends StatelessWidget {
  final TechniqueModel technique;
  final Color accentColor;

  const _TechniqueDetailSheet(
      {required this.technique, required this.accentColor});

  @override
  Widget build(BuildContext context) {
    final hasVideo =
        technique.videoUrl != null && technique.videoUrl!.isNotEmpty;

    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
      ),
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(24, 16, 24, 32),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey.shade300,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 20),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 52,
                  height: 52,
                  decoration: BoxDecoration(
                    color: accentColor.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Icon(Icons.self_improvement,
                      color: accentColor, size: 30),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        technique.name,
                        style: const TextStyle(
                            fontSize: 20, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 4),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 10, vertical: 3),
                        decoration: BoxDecoration(
                          color: accentColor.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          technique.category,
                          style: TextStyle(
                              color: accentColor,
                              fontSize: 12,
                              fontWeight: FontWeight.w600),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            if (technique.description.isNotEmpty) ...[
              const SizedBox(height: 20),
              const Text('Descripción',
                  style: TextStyle(
                      fontWeight: FontWeight.bold, fontSize: 14)),
              const SizedBox(height: 6),
              Text(
                technique.description,
                style: TextStyle(
                    color: Colors.grey.shade700,
                    fontSize: 14,
                    height: 1.5),
              ),
            ],
            if (hasVideo) ...[
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  icon: const Icon(Icons.play_circle_fill),
                  label: const Text('Ver video tutorial'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: accentColor,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12)),
                  ),
                  onPressed: () async {
                    final uri = Uri.tryParse(technique.videoUrl!);
                    if (uri != null && await canLaunchUrl(uri)) {
                      await launchUrl(uri,
                          mode: LaunchMode.externalApplication);
                    }
                  },
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
