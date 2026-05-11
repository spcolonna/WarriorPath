import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

enum _Filter { all, present, absent }

class AttendanceChecklistScreen extends StatefulWidget {
  final String schoolId;
  final String scheduleTitle;
  final String scheduleTime;

  const AttendanceChecklistScreen({
    super.key,
    required this.schoolId,
    required this.scheduleTitle,
    this.scheduleTime = '',
  });

  @override
  State<AttendanceChecklistScreen> createState() =>
      _AttendanceChecklistScreenState();
}

class _AttendanceChecklistScreenState
    extends State<AttendanceChecklistScreen> {
  final _db = FirebaseFirestore.instance;

  String? _recordId;
  Set<String> _presentIds = {};
  List<QueryDocumentSnapshot<Map<String, dynamic>>> _students = [];
  bool _ready = false;
  String _search = '';
  _Filter _filter = _Filter.all;

  @override
  void initState() {
    super.initState();
    _init();
  }

  Future<void> _init() async {
    await Future.wait([_loadStudents(), _loadOrCreateRecord()]);
    if (mounted) setState(() => _ready = true);
  }

  Future<void> _loadStudents() async {
    final snap = await _db
        .collection('schools')
        .doc(widget.schoolId)
        .collection('members')
        .where('status', isEqualTo: 'active')
        .get();
    final docs = snap.docs.toList()
      ..sort((a, b) {
        final aName = (a.data() as Map<String, dynamic>)['displayName'] as String? ?? '';
        final bName = (b.data() as Map<String, dynamic>)['displayName'] as String? ?? '';
        return aName.compareTo(bName);
      });
    if (mounted) setState(() => _students = docs);
  }

  Future<void> _loadOrCreateRecord() async {
    final now = DateTime.now();
    final startOfDay = DateTime(now.year, now.month, now.day);
    final endOfDay = startOfDay.add(const Duration(days: 1));

    final existing = await _db
        .collection('schools')
        .doc(widget.schoolId)
        .collection('attendanceRecords')
        .where('scheduleTitle', isEqualTo: widget.scheduleTitle)
        .where('date',
            isGreaterThanOrEqualTo: Timestamp.fromDate(startOfDay))
        .where('date', isLessThan: Timestamp.fromDate(endOfDay))
        .limit(1)
        .get();

    if (existing.docs.isNotEmpty) {
      final doc = existing.docs.first;
      final data = doc.data();
      _recordId = doc.id;
      _presentIds = Set<String>.from(
          (data['presentStudentIds'] as List<dynamic>?) ?? []);
    } else {
      final ref = await _db
          .collection('schools')
          .doc(widget.schoolId)
          .collection('attendanceRecords')
          .add({
        'date': Timestamp.now(),
        'scheduleTitle': widget.scheduleTitle,
        'presentStudentIds': <String>[],
      });
      _recordId = ref.id;
    }
  }

  Future<void> _toggle(String studentId) async {
    if (_recordId == null) return;
    final wasPresent = _presentIds.contains(studentId);
    setState(() {
      if (wasPresent) {
        _presentIds.remove(studentId);
      } else {
        _presentIds.add(studentId);
      }
    });
    await _db
        .collection('schools')
        .doc(widget.schoolId)
        .collection('attendanceRecords')
        .doc(_recordId)
        .update({
      'presentStudentIds': wasPresent
          ? FieldValue.arrayRemove([studentId])
          : FieldValue.arrayUnion([studentId]),
    });
  }

  List<QueryDocumentSnapshot> get _filtered {
    var list = _students;
    if (_search.isNotEmpty) {
      final q = _search.toLowerCase();
      list = list
          .where((d) =>
              (d.data()['displayName'] as String? ?? '')
                  .toLowerCase()
                  .contains(q))
          .toList();
    }
    if (_filter == _Filter.present) {
      list = list.where((d) => _presentIds.contains(d.id)).toList();
    } else if (_filter == _Filter.absent) {
      list = list.where((d) => !_presentIds.contains(d.id)).toList();
    }
    return list;
  }

  @override
  Widget build(BuildContext context) {
    final primaryColor = Theme.of(context).primaryColor;
    final total = _students.length;
    final present = _presentIds.length;
    final ratio = total > 0 ? present / total : 0.0;
    final filtered = _filtered;

    return Scaffold(
      backgroundColor: const Color(0xFFF2F2F7),
      body: CustomScrollView(
        slivers: [
          // ── HEADER ─────────────────────────────────────────────────────
          SliverAppBar(
            expandedHeight: 200,
            pinned: true,
            backgroundColor: primaryColor,
            flexibleSpace: FlexibleSpaceBar(
              collapseMode: CollapseMode.pin,
              background: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      primaryColor,
                      Color.lerp(primaryColor, Colors.black, 0.35)!,
                    ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                ),
                child: SafeArea(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(20, 52, 20, 20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        Text(
                          widget.scheduleTitle,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 22,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        if (widget.scheduleTime.isNotEmpty)
                          Text(
                            widget.scheduleTime,
                            style: const TextStyle(
                                color: Colors.white70, fontSize: 13),
                          ),
                        const SizedBox(height: 14),
                        if (_ready) ...[
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.baseline,
                            textBaseline: TextBaseline.alphabetic,
                            children: [
                              Text(
                                '$present',
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 44,
                                  fontWeight: FontWeight.w900,
                                  height: 1,
                                ),
                              ),
                              Text(
                                ' / $total presentes',
                                style: const TextStyle(
                                    color: Colors.white70, fontSize: 18),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          ClipRRect(
                            borderRadius: BorderRadius.circular(4),
                            child: LinearProgressIndicator(
                              value: ratio,
                              backgroundColor: Colors.white24,
                              valueColor: const AlwaysStoppedAnimation<Color>(
                                  Colors.white),
                              minHeight: 6,
                            ),
                          ),
                        ] else
                          const SizedBox(
                            height: 24,
                            width: 24,
                            child: CircularProgressIndicator(
                                color: Colors.white, strokeWidth: 2),
                          ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),

          // ── SEARCH + FILTERS ───────────────────────────────────────────
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 14, 16, 6),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  TextField(
                    decoration: InputDecoration(
                      hintText: 'Buscar alumno...',
                      hintStyle: TextStyle(color: Colors.grey[400]),
                      prefixIcon:
                          Icon(Icons.search, size: 20, color: Colors.grey[400]),
                      filled: true,
                      fillColor: Colors.white,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide.none,
                      ),
                      contentPadding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 12),
                      isDense: true,
                    ),
                    onChanged: (v) => setState(() => _search = v),
                  ),
                  const SizedBox(height: 10),
                  SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      children: [
                        _Chip(
                          label: 'Todos ($total)',
                          selected: _filter == _Filter.all,
                          onTap: () =>
                              setState(() => _filter = _Filter.all),
                        ),
                        const SizedBox(width: 8),
                        _Chip(
                          label: 'Presentes ($present)',
                          selected: _filter == _Filter.present,
                          selectedColor: Colors.green,
                          onTap: () =>
                              setState(() => _filter = _Filter.present),
                        ),
                        const SizedBox(width: 8),
                        _Chip(
                          label: 'Ausentes (${total - present})',
                          selected: _filter == _Filter.absent,
                          selectedColor: Colors.red[400]!,
                          onTap: () =>
                              setState(() => _filter = _Filter.absent),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),

          // ── STUDENT LIST ──────────────────────────────────────────────
          if (!_ready)
            const SliverFillRemaining(
              child: Center(child: CircularProgressIndicator()),
            )
          else if (filtered.isEmpty)
            SliverFillRemaining(
              hasScrollBody: false,
              child: Center(
                child: Padding(
                  padding: const EdgeInsets.all(32),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.person_search,
                          size: 56, color: Colors.grey[400]),
                      const SizedBox(height: 12),
                      Text(
                        _search.isNotEmpty
                            ? 'Sin resultados para "$_search"'
                            : 'No hay alumnos en este filtro',
                        style:
                            TextStyle(color: Colors.grey[600], fontSize: 15),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                ),
              ),
            )
          else
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(16, 6, 16, 40),
              sliver: SliverList(
                delegate: SliverChildBuilderDelegate(
                  (context, i) => _StudentCard(
                    key: ValueKey(filtered[i].id),
                    doc: filtered[i],
                    isPresent: _presentIds.contains(filtered[i].id),
                    color: primaryColor,
                    onToggle: () => _toggle(filtered[i].id),
                  ),
                  childCount: filtered.length,
                ),
              ),
            ),
        ],
      ),
    );
  }
}

// ── Helper Widgets ────────────────────────────────────────────────────────────

class _Chip extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;
  final Color? selectedColor;

  const _Chip({
    required this.label,
    required this.selected,
    required this.onTap,
    this.selectedColor,
  });

  @override
  Widget build(BuildContext context) {
    final color =
        selected ? (selectedColor ?? Theme.of(context).primaryColor) : null;
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
        decoration: BoxDecoration(
          color: selected ? color : Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: selected ? color! : Colors.grey[300]!,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 12,
            fontWeight: selected ? FontWeight.w700 : FontWeight.normal,
            color: selected ? Colors.white : Colors.grey[700],
          ),
        ),
      ),
    );
  }
}

class _StudentCard extends StatelessWidget {
  final QueryDocumentSnapshot doc;
  final bool isPresent;
  final Color color;
  final VoidCallback onToggle;

  const _StudentCard({
    super.key,
    required this.doc,
    required this.isPresent,
    required this.color,
    required this.onToggle,
  });

  @override
  Widget build(BuildContext context) {
    final data = doc.data() as Map<String, dynamic>;
    final name = data['displayName'] as String? ?? 'Sin Nombre';
    final initials = name
        .trim()
        .split(' ')
        .take(2)
        .map((w) => w.isNotEmpty ? w[0].toUpperCase() : '')
        .join();

    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Material(
        color: isPresent ? color.withValues(alpha: 0.07) : Colors.white,
        borderRadius: BorderRadius.circular(14),
        elevation: isPresent ? 0 : 0.5,
        shadowColor: Colors.black26,
        child: InkWell(
          borderRadius: BorderRadius.circular(14),
          onTap: onToggle,
          child: Padding(
            padding:
                const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
            child: Row(
              children: [
                // Avatar
                AnimatedContainer(
                  duration: const Duration(milliseconds: 230),
                  width: 46,
                  height: 46,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: isPresent ? color : Colors.grey[100],
                    border: Border.all(
                      color: isPresent ? color : Colors.grey[300]!,
                      width: 2,
                    ),
                  ),
                  alignment: Alignment.center,
                  child: AnimatedSwitcher(
                    duration: const Duration(milliseconds: 200),
                    child: isPresent
                        ? const Icon(Icons.check,
                            color: Colors.white,
                            size: 22,
                            key: ValueKey('chk'))
                        : Text(
                            initials,
                            key: const ValueKey('ini'),
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 15,
                              color: Colors.grey[500],
                            ),
                          ),
                  ),
                ),
                const SizedBox(width: 14),
                // Name
                Expanded(
                  child: Text(
                    name,
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight:
                          isPresent ? FontWeight.w600 : FontWeight.normal,
                      color: isPresent ? color : Colors.black87,
                    ),
                  ),
                ),
                // Badge
                AnimatedSwitcher(
                  duration: const Duration(milliseconds: 200),
                  transitionBuilder: (child, anim) =>
                      FadeTransition(opacity: anim, child: child),
                  child: isPresent
                      ? Container(
                          key: const ValueKey('p'),
                          padding: const EdgeInsets.symmetric(
                              horizontal: 10, vertical: 5),
                          decoration: BoxDecoration(
                            color: color,
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: const Text('Presente',
                              style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 11,
                                  fontWeight: FontWeight.w700)),
                        )
                      : Container(
                          key: const ValueKey('a'),
                          padding: const EdgeInsets.symmetric(
                              horizontal: 10, vertical: 5),
                          decoration: BoxDecoration(
                            color: Colors.grey[200],
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Text('Ausente',
                              style: TextStyle(
                                  color: Colors.grey[600], fontSize: 11)),
                        ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
