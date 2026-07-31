import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:warrior_path/constants/school_roles.dart';
import 'package:warrior_path/providers/session_provider.dart';
import 'package:warrior_path/screens/teacher/add_offline_student_screen.dart';
import 'package:warrior_path/screens/teacher/student_detail_screen.dart';
import 'package:warrior_path/services/student_application_service.dart';

import '../../../l10n/app_localizations.dart';

class StudentsTabScreen extends StatefulWidget {
  final int initialTabIndex;
  const StudentsTabScreen({super.key, this.initialTabIndex = 0});

  @override
  State<StudentsTabScreen> createState() => _StudentsTabScreenState();
}

class _StudentsTabScreenState extends State<StudentsTabScreen> with SingleTickerProviderStateMixin {
  late AppLocalizations l10n;
  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    l10n = AppLocalizations.of(context);
  }

  late TabController _tabController;

  // Panel de cobros (pestaña Activos): filtro y memo de planes.
  // 0 = todos · 1 = al día · 2 = vence hoy · 3 = atrasado
  int _payFilter = 0;
  Future<Map<String, String>>? _plansFuture;
  String? _plansForSchool;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this, initialIndex: widget.initialTabIndex);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final schoolId = Provider.of<SessionProvider>(context).activeSchoolId;
    if (schoolId == null) {
      return Center(child: Text(l10n.noActiveSchoolError));
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.students),
        bottom: TabBar(
          controller: _tabController,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white.withValues(alpha: 0.55),
          indicatorColor: Colors.white,
          indicatorWeight: 3,
          tabs: [
            Tab(text: l10n.actives),
            Tab(
              child: StreamBuilder<QuerySnapshot>(
                stream: FirebaseFirestore.instance
                    .collection('schools')
                    .doc(schoolId)
                    .collection('members')
                    .where('status', isEqualTo: MemberStatus.pending)
                    .snapshots(),
                builder: (context, snap) {
                  final count = snap.data?.docs.length ?? 0;
                  if (count == 0) return Text(l10n.pending);
                  return Badge(
                    label: Text('$count'),
                    backgroundColor: Colors.red,
                    child: Padding(
                      padding: const EdgeInsets.only(right: 6),
                      child: Text(l10n.pending),
                    ),
                  );
                },
              ),
            ),
            Tab(text: l10n.inactives),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildActivosCobros(schoolId),
          _buildStudentsList(MemberStatus.pending, schoolId),
          _buildStudentsList(MemberStatus.inactive, schoolId),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        heroTag: 'fab_students_add',
        onPressed: () {
          Navigator.of(context).push(
            MaterialPageRoute(
              builder: (_) => AddOfflineStudentScreen(schoolId: schoolId),
            ),
          );
        },
        icon: const Icon(Icons.person_add_alt_1),
        label: Text(l10n.addStudent),
      ),
    );
  }

  // ── Panel de cobros (pestaña Activos) ──────────────────────────────────────
  // Convierte la lista de activos en un panel útil: cada alumno con su plan y
  // estado de pago (al día / vence hoy / atrasado). Resumen + filtros arriba.
  Widget _buildActivosCobros(String schoolId) {
    if (_plansForSchool != schoolId) {
      _plansForSchool = schoolId;
      _plansFuture = FirebaseFirestore.instance
          .collection('schools')
          .doc(schoolId)
          .collection('paymentPlans')
          .get()
          .then((s) => {
                for (final d in s.docs)
                  d.id: (d.data()['title'] as String? ?? '')
              });
    }

    return FutureBuilder<Map<String, String>>(
      future: _plansFuture,
      builder: (context, plansSnap) {
        final plans = plansSnap.data ?? {};
        return StreamBuilder<QuerySnapshot>(
          stream: FirebaseFirestore.instance
              .collection('schools')
              .doc(schoolId)
              .collection('members')
              .where('status', isEqualTo: MemberStatus.active)
              .snapshots(),
          builder: (context, memSnap) {
            if (memSnap.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }
            final members = (memSnap.data?.docs ?? [])
                .where((d) => (d.data() as Map)['role'] != SchoolRoles.maestro)
                .toList()
              ..sort((a, b) => ((a.data() as Map)['displayName'] ?? '')
                  .toString()
                  .compareTo(((b.data() as Map)['displayName'] ?? '').toString()));

            return StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collectionGroup('paymentReminders')
                  .where('schoolId', isEqualTo: schoolId)
                  .where('status', isEqualTo: 'pending')
                  .snapshots(),
              builder: (context, remSnap) {
                // studentId -> fecha de vencimiento del recordatorio pendiente
                final owing = <String, DateTime?>{};
                for (final r in remSnap.data?.docs ?? []) {
                  final d = r.data() as Map<String, dynamic>;
                  owing[d['studentId'] as String? ?? ''] =
                      (d['createdOn'] as Timestamp?)?.toDate();
                }

                int alDia = 0, vence = 0, atrasado = 0;
                for (final m in members) {
                  final data = m.data() as Map<String, dynamic>;
                  if ((data['assignedPaymentPlanId'] as String?) == null) continue;
                  final k = _payKind(m.id, owing);
                  if (k == 1) alDia++;
                  if (k == 2) vence++;
                  if (k == 3) atrasado++;
                }

                final filtered = members.where((m) {
                  if (_payFilter == 0) return true;
                  return _payKind(m.id, owing) == _payFilter;
                }).toList();

                return Column(
                  children: [
                    _cobrosHeader(members.length, alDia, vence, atrasado),
                    Expanded(
                      child: filtered.isEmpty
                          ? Center(child: Text(l10n.noStudentsWithStatus('active')))
                          : ListView.builder(
                              padding: const EdgeInsets.only(bottom: 90),
                              itemCount: filtered.length,
                              itemBuilder: (context, i) {
                                final doc = filtered[i];
                                final data = doc.data() as Map<String, dynamic>;
                                return _cobroRow(
                                    doc.id, data, plans, owing, schoolId);
                              },
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

  /// 0 = sin plan · 1 = al día · 2 = vence hoy · 3 = atrasado
  int _payKind(String memberId, Map<String, DateTime?> owing) {
    if (!owing.containsKey(memberId)) return 1; // sin recordatorio pendiente
    final due = owing[memberId];
    if (due == null) return 3;
    final now = DateTime.now();
    final isToday =
        due.year == now.year && due.month == now.month && due.day == now.day;
    return isToday ? 2 : 3;
  }

  Widget _cobrosHeader(int total, int alDia, int vence, int atrasado) {
    Widget chip(int f, String label, int count, Color color) {
      final selected = _payFilter == f;
      return GestureDetector(
        onTap: () => setState(() => _payFilter = f),
        child: Container(
          margin: const EdgeInsets.only(right: 8),
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
          decoration: BoxDecoration(
            color: selected ? color : color.withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(20),
          ),
          child: Text(
            '$label · $count',
            style: TextStyle(
              fontSize: 12.5,
              fontWeight: FontWeight.w700,
              color: selected ? Colors.white : color,
            ),
          ),
        ),
      );
    }

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
      child: Row(
        children: [
          chip(0, l10n.payFilterAll, total, Colors.blueGrey),
          chip(1, l10n.payAlDia, alDia, const Color(0xFF2E9E5B)),
          chip(2, l10n.payVenceHoy, vence, const Color(0xFFE0682B)),
          chip(3, l10n.payAtrasado, atrasado, const Color(0xFFC0392B)),
        ],
      ),
    );
  }

  Widget _cobroRow(String memberId, Map<String, dynamic> data,
      Map<String, String> plans, Map<String, DateTime?> owing, String schoolId) {
    final name = data['displayName'] as String? ?? l10n.noName;
    final planId = data['assignedPaymentPlanId'] as String?;
    final planName = planId != null ? (plans[planId] ?? '') : null;
    final isOffline = data['isOfflineStudent'] == true;
    final initials = name
        .trim()
        .split(' ')
        .take(2)
        .map((w) => w.isNotEmpty ? w[0].toUpperCase() : '')
        .join();

    // Pill de estado
    Widget pill;
    if (planId == null) {
      pill = _pill(l10n.paySinPlan, Colors.grey);
    } else {
      final k = _payKind(memberId, owing);
      pill = k == 1
          ? _pill(l10n.payAlDia, const Color(0xFF2E9E5B))
          : k == 2
              ? _pill(l10n.payVenceHoy, const Color(0xFFE0682B))
              : _pill(l10n.payAtrasado, const Color(0xFFC0392B));
    }

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 5),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: Theme.of(context).primaryColor.withValues(alpha: 0.12),
          child: Text(initials,
              style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 13,
                  color: Theme.of(context).primaryColor)),
        ),
        title: Text(name, style: const TextStyle(fontWeight: FontWeight.w600)),
        subtitle: Text(
          [
            if (planName != null && planName.isNotEmpty) planName,
            if (isOffline) l10n.offlineStudentBadge,
          ].join(' · '),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        trailing: pill,
        onTap: () {
          Navigator.of(context).push(
            MaterialPageRoute(
                builder: (context) =>
                    StudentDetailScreen(schoolId: schoolId, studentId: memberId)),
          );
        },
      ),
    );
  }

  Widget _pill(String label, Color color) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.14),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Text(label,
            style: TextStyle(
                fontSize: 11, fontWeight: FontWeight.w800, color: color)),
      );

  Widget _buildStudentsList(String status, String schoolId) {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance.collection('schools').doc(schoolId).collection('members').where('status', isEqualTo: status).snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
          return Center(child: Text(l10n.noStudentsWithStatus(status)));
        }

        return ListView.builder(
          itemCount: snapshot.data!.docs.length,
          itemBuilder: (context, index) {
            final doc = snapshot.data!.docs[index];
            if (status == 'pending') {
              return _buildPendingStudentCard(doc, schoolId);
            }
            final data = doc.data() as Map<String, dynamic>;
            final isOffline = data['isOfflineStudent'] == true;
            return Card(
              margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
              child: ListTile(
                leading: const CircleAvatar(child: Icon(Icons.person)),
                title: Text(data['displayName'] ?? l10n.noName),
                subtitle: isOffline ? _OfflineBadge(label: l10n.offlineStudentBadge) : null,
                trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                onTap: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(builder: (context) => StudentDetailScreen(schoolId: schoolId, studentId: doc.id)),
                  );
                },
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildPendingStudentCard(QueryDocumentSnapshot doc, String schoolId) {
    final data = doc.data() as Map<String, dynamic>;
    final userId = doc.id;
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      child: Padding(
        padding: const EdgeInsets.all(8.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(data['displayName'] ?? l10n.noName, style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 4),
            Text(l10n.applicationDate((data['applicationDate'] as Timestamp?)?.toDate().toLocal().toString().substring(0, 10) ?? 'N/A')),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton(
                  onPressed: () => _handleApplication(userId, false, schoolId),
                  child: Text(l10n.reject, style: const TextStyle(color: Colors.red)),
                ),
                const SizedBox(width: 8),
                ElevatedButton(
                  onPressed: () => _handleApplication(userId, true, schoolId),
                  child: Text(l10n.accept),
                ),
              ],
            )
          ],
        ),
      ),
    );
  }

  Future<void> _handleApplication(String userId, bool accept, String schoolId) async {
    if (accept) {
      await StudentApplicationService.accept(context,
          schoolId: schoolId, userId: userId);
    } else {
      await StudentApplicationService.reject(context,
          schoolId: schoolId, userId: userId);
    }
  }
}

class _OfflineBadge extends StatelessWidget {
  final String label;
  const _OfflineBadge({required this.label});

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.only(top: 4),
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
        decoration: BoxDecoration(
          color: Colors.orange.withValues(alpha: 0.15),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: Colors.orange.shade400),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.cloud_off, size: 12, color: Colors.orange.shade700),
            const SizedBox(width: 4),
            Text(
              label,
              style: TextStyle(
                fontSize: 11,
                color: Colors.orange.shade800,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
