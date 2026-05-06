import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:warrior_path/providers/session_provider.dart';
import 'package:warrior_path/screens/role_selector_screen.dart';
import 'package:warrior_path/models/event_model.dart';
import '../../../l10n/app_localizations.dart';
import '../student_event_detail_screen.dart';

class SchoolInfoTabScreen extends StatelessWidget {
  final String schoolId;
  const SchoolInfoTabScreen({super.key, required this.schoolId});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);

    return Scaffold(
      appBar: AppBar(title: Text(l10n.mySchool)),
      body: FutureBuilder<DocumentSnapshot>(
        future: FirebaseFirestore.instance.collection('schools').doc(schoolId).get(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (!snapshot.hasData || !snapshot.data!.exists) {
            return Center(child: Text(l10n.couldNotLoadSchoolInfo));
          }

          final data = snapshot.data!.data() as Map<String, dynamic>;
          final logoUrl       = data['logoUrl'] as String?;
          final schoolName    = data['name'] as String? ?? l10n.schoolNameLabel;
          final discipline    = data['primaryDisciplineName'] as String? ?? l10n.martialArt;
          final rawAddress    = '${data['address'] ?? ''}, ${data['city'] ?? ''}'.trim().replaceAll(RegExp(r'^,\s*|,\s*$'), '');
          final address       = rawAddress.replaceAll(RegExp(r'^,+|,+$'), '').trim();
          final phone         = data['phone'] as String?;

          return CustomScrollView(
            slivers: [
              // ── Header ─────────────────────────────────────────────────
              SliverToBoxAdapter(
                child: _SchoolHeader(
                  logoUrl: logoUrl,
                  schoolName: schoolName,
                  discipline: discipline,
                ),
              ),

              // ── Clase de hoy ────────────────────────────────────────────
              SliverToBoxAdapter(
                child: _TodaySection(schoolId: schoolId),
              ),

              // ── Horario semanal ─────────────────────────────────────────
              SliverToBoxAdapter(
                child: _WeekSchedule(schoolId: schoolId),
              ),

              // ── Próximos eventos ────────────────────────────────────────
              SliverToBoxAdapter(
                child: _UpcomingEvents(schoolId: schoolId),
              ),

              // ── Contacto ────────────────────────────────────────────────
              SliverToBoxAdapter(
                child: _ContactSection(address: address, phone: phone),
              ),

              // ── Switch perfil ───────────────────────────────────────────
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(20, 0, 20, 32),
                  child: Card(
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                      side: BorderSide(color: Colors.grey.shade200),
                    ),
                    child: ListTile(
                      leading: Icon(Icons.swap_horiz, color: Theme.of(context).primaryColor),
                      title: Text(l10n.switchProfileSchool),
                      trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                      onTap: () => Navigator.of(context).push(
                        MaterialPageRoute(builder: (_) => const RoleSelectorScreen()),
                      ),
                    ),
                  ),
                ),
              ),

              const SliverToBoxAdapter(child: SizedBox(height: 16)),
            ],
          );
        },
      ),
    );
  }
}

// ── Header compacto ───────────────────────────────────────────────────────────

class _SchoolHeader extends StatelessWidget {
  final String? logoUrl;
  final String schoolName;
  final String discipline;
  const _SchoolHeader({required this.logoUrl, required this.schoolName, required this.discipline});

  @override
  Widget build(BuildContext context) {
    final primary = Theme.of(context).primaryColor;
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 20),
      child: Row(
        children: [
          CircleAvatar(
            radius: 30,
            backgroundColor: primary.withValues(alpha: 0.1),
            backgroundImage: (logoUrl?.isNotEmpty == true) ? NetworkImage(logoUrl!) : null,
            child: (logoUrl?.isNotEmpty != true)
                ? Icon(Icons.school_outlined, size: 30, color: primary)
                : null,
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  schoolName,
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 4),
                Text(
                  discipline,
                  style: TextStyle(color: primary, fontWeight: FontWeight.w500, fontSize: 13),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ── Clase de hoy ──────────────────────────────────────────────────────────────

class _TodaySection extends StatelessWidget {
  final String schoolId;
  const _TodaySection({required this.schoolId});

  @override
  Widget build(BuildContext context) {
    final primary = Theme.of(context).primaryColor;
    final l10n = AppLocalizations.of(context);
    final todayWeekday = DateTime.now().weekday;

    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('schools').doc(schoolId)
          .collection('classSchedules')
          .where('dayOfWeek', isEqualTo: todayWeekday)
          .orderBy('startTime')
          .snapshots(),
      builder: (context, snapshot) {
        final classes = snapshot.data?.docs ?? [];
        final hasClass = classes.isNotEmpty;

        return Padding(
          padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
          child: Container(
            decoration: BoxDecoration(
              color: hasClass ? primary : Colors.grey.shade100,
              borderRadius: BorderRadius.circular(16),
            ),
            padding: const EdgeInsets.all(20),
            child: hasClass
                ? Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        l10n.todayClass,
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                      const SizedBox(height: 12),
                      ...classes.map((doc) {
                        final d = doc.data() as Map<String, dynamic>;
                        return Padding(
                          padding: const EdgeInsets.only(bottom: 8),
                          child: Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                                decoration: BoxDecoration(
                                  color: Colors.white.withValues(alpha: 0.2),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Text(
                                  '${d['startTime']} – ${d['endTime']}',
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.w700,
                                    fontSize: 13,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Text(
                                  d['title'] ?? '',
                                  style: const TextStyle(color: Colors.white, fontSize: 14),
                                ),
                              ),
                            ],
                          ),
                        );
                      }),
                    ],
                  )
                : Row(
                    children: [
                      Icon(Icons.event_busy_outlined, color: Colors.grey.shade400),
                      const SizedBox(width: 12),
                      Text(l10n.noSchedulerClass, style: TextStyle(color: Colors.grey.shade500)),
                    ],
                  ),
          ),
        );
      },
    );
  }
}

// ── Horario semanal con selector de día ───────────────────────────────────────

class _WeekSchedule extends StatefulWidget {
  final String schoolId;
  const _WeekSchedule({required this.schoolId});

  @override
  State<_WeekSchedule> createState() => _WeekScheduleState();
}

class _WeekScheduleState extends State<_WeekSchedule> {
  late int _selectedDay;
  late Future<Map<String, String>> _disciplinesFuture;

  @override
  void initState() {
    super.initState();
    _selectedDay = DateTime.now().weekday;
    _disciplinesFuture = _fetchDisciplines();
  }

  Future<Map<String, String>> _fetchDisciplines() async {
    final snap = await FirebaseFirestore.instance
        .collection('schools').doc(widget.schoolId)
        .collection('disciplines').get();
    return {for (var d in snap.docs) d.id: (d.data()['name'] as String?) ?? ''};
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final primary = Theme.of(context).primaryColor;
    final List<String> dayShort = ['L', 'M', 'X', 'J', 'V', 'S', 'D'];
    final today = DateTime.now().weekday;

    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('schools').doc(widget.schoolId)
          .collection('classSchedules')
          .orderBy('dayOfWeek')
          .orderBy('startTime')
          .snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const Padding(
            padding: EdgeInsets.all(32),
            child: Center(child: CircularProgressIndicator()),
          );
        }

        final Map<int, List<QueryDocumentSnapshot>> grouped = {};
        for (var doc in snapshot.data!.docs) {
          final day = doc['dayOfWeek'] as int;
          grouped.putIfAbsent(day, () => []).add(doc);
        }

        final daysWithClasses = grouped.keys.toSet();
        final selectedClasses = grouped[_selectedDay] ?? [];

        return Padding(
          padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                l10n.classSchedule,
                style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 14),

              // ── Selector de días ──────────────────────────────────────
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: List.generate(7, (i) {
                  final dayIndex = i + 1;
                  final isSelected = _selectedDay == dayIndex;
                  final isToday = today == dayIndex;
                  final hasClass = daysWithClasses.contains(dayIndex);

                  return GestureDetector(
                    onTap: () => setState(() => _selectedDay = dayIndex),
                    child: Column(
                      children: [
                        AnimatedContainer(
                          duration: const Duration(milliseconds: 200),
                          width: 38,
                          height: 38,
                          decoration: BoxDecoration(
                            color: isSelected
                                ? primary
                                : isToday
                                    ? primary.withValues(alpha: 0.12)
                                    : Colors.transparent,
                            shape: BoxShape.circle,
                            border: isToday && !isSelected
                                ? Border.all(color: primary.withValues(alpha: 0.4))
                                : null,
                          ),
                          child: Center(
                            child: Text(
                              dayShort[i],
                              style: TextStyle(
                                color: isSelected
                                    ? Colors.white
                                    : isToday
                                        ? primary
                                        : Colors.grey.shade600,
                                fontWeight: FontWeight.bold,
                                fontSize: 13,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 5),
                        Container(
                          width: 5,
                          height: 5,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: hasClass
                                ? (isSelected ? primary : primary.withValues(alpha: 0.4))
                                : Colors.transparent,
                          ),
                        ),
                      ],
                    ),
                  );
                }),
              ),

              const SizedBox(height: 16),

              // ── Clases del día seleccionado ───────────────────────────
              if (selectedClasses.isEmpty)
                Center(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 24),
                    child: Text(
                      l10n.noSchedulerClass,
                      style: TextStyle(color: Colors.grey.shade400, fontSize: 13),
                    ),
                  ),
                )
              else
                FutureBuilder<Map<String, String>>(
                  future: _disciplinesFuture,
                  builder: (context, disciplinesSnap) {
                    final disciplines = disciplinesSnap.data ?? {};
                    return Column(
                      children: selectedClasses.map((doc) {
                        final d = doc.data() as Map<String, dynamic>;
                        final disciplineName = disciplines[d['disciplineId']] ?? '';
                        return Container(
                          margin: const EdgeInsets.only(bottom: 10),
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                          decoration: BoxDecoration(
                            color: Colors.grey.shade50,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: Colors.grey.shade200),
                          ),
                          child: Row(
                            children: [
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    d['startTime'] ?? '',
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 15,
                                      color: primary,
                                    ),
                                  ),
                                  Text(
                                    d['endTime'] ?? '',
                                    style: TextStyle(fontSize: 11, color: Colors.grey.shade500),
                                  ),
                                ],
                              ),
                              const SizedBox(width: 16),
                              Container(width: 1, height: 36, color: Colors.grey.shade200),
                              const SizedBox(width: 16),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      d['title'] ?? '',
                                      style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
                                    ),
                                    if (disciplineName.isNotEmpty)
                                      Text(
                                        disciplineName,
                                        style: TextStyle(fontSize: 12, color: Colors.grey.shade500),
                                      ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        );
                      }).toList(),
                    );
                  },
                ),
            ],
          ),
        );
      },
    );
  }
}

// ── Próximos eventos ──────────────────────────────────────────────────────────

class _UpcomingEvents extends StatelessWidget {
  final String schoolId;
  const _UpcomingEvents({required this.schoolId});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final studentId = Provider.of<SessionProvider>(context, listen: false).activeProfileId;
    if (studentId == null) return const SizedBox.shrink();

    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('schools').doc(schoolId)
          .collection('events')
          .where('invitedStudentIds', arrayContains: studentId)
          .where('date', isGreaterThanOrEqualTo: Timestamp.now())
          .orderBy('date')
          .limit(3)
          .snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) return const SizedBox.shrink();
        return Padding(
          padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                l10n.upcomingEvents,
                style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 12),
              ...snapshot.data!.docs.map((doc) {
                final event = EventModel.fromFirestore(doc);
                return Container(
                  margin: const EdgeInsets.only(bottom: 8),
                  decoration: BoxDecoration(
                    color: Colors.grey.shade50,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.grey.shade200),
                  ),
                  child: ListTile(
                    leading: Icon(Icons.event_outlined, color: Theme.of(context).primaryColor),
                    title: Text(event.title, style: const TextStyle(fontWeight: FontWeight.w600)),
                    subtitle: Text(DateFormat('dd MMM yyyy').format(event.date), style: const TextStyle(fontSize: 12)),
                    trailing: const Icon(Icons.arrow_forward_ios, size: 14, color: Colors.grey),
                    onTap: () => Navigator.of(context).push(MaterialPageRoute(
                      builder: (_) => StudentEventDetailScreen(schoolId: schoolId, eventId: doc.id),
                    )),
                  ),
                );
              }),
            ],
          ),
        );
      },
    );
  }
}

// ── Contacto ──────────────────────────────────────────────────────────────────

class _ContactSection extends StatelessWidget {
  final String address;
  final String? phone;
  const _ContactSection({required this.address, required this.phone});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final primary = Theme.of(context).primaryColor;
    final hasAddress = address.isNotEmpty;
    final hasPhone = phone != null && phone!.isNotEmpty;
    if (!hasAddress && !hasPhone) return const SizedBox.shrink();

    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            l10n.contactData,
            style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 12),
          if (hasAddress)
            _ContactRow(icon: Icons.location_on_outlined, text: address, color: primary),
          if (hasAddress && hasPhone) const SizedBox(height: 8),
          if (hasPhone)
            _ContactRow(icon: Icons.phone_outlined, text: phone!, color: primary),
          const SizedBox(height: 8),
        ],
      ),
    );
  }
}

class _ContactRow extends StatelessWidget {
  final IconData icon;
  final String text;
  final Color color;
  const _ContactRow({required this.icon, required this.text, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Row(
        children: [
          Icon(icon, color: color, size: 20),
          const SizedBox(width: 14),
          Expanded(child: Text(text, style: const TextStyle(fontSize: 14))),
        ],
      ),
    );
  }
}
