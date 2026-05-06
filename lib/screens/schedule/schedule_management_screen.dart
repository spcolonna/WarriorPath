import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:warrior_path/screens/schedule/add_edit_schedule_screen.dart';

import '../../l10n/app_localizations.dart';

// One color per schedule line
const _kColors = [
  Color(0xFF2196F3),
  Color(0xFFFF9800),
  Color(0xFF4CAF50),
  Color(0xFFE91E63),
  Color(0xFF9C27B0),
  Color(0xFF00BCD4),
  Color(0xFFFF5722),
];

// ── Main screen ───────────────────────────────────────────────────────────────

class ScheduleManagementScreen extends StatefulWidget {
  final String schoolId;
  const ScheduleManagementScreen({super.key, required this.schoolId});

  @override
  State<ScheduleManagementScreen> createState() =>
      _ScheduleManagementScreenState();
}

class _ScheduleManagementScreenState extends State<ScheduleManagementScreen> {
  late AppLocalizations l10n;
  late List<String> _dayLabels;
  late Future<Map<String, String>> _disciplinesMapFuture;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    l10n = AppLocalizations.of(context);
    _dayLabels = [
      l10n.monday, l10n.tuesday, l10n.wednesday,
      l10n.thursday, l10n.friday, l10n.saturday, l10n.sunday,
    ];
  }

  @override
  void initState() {
    super.initState();
    _disciplinesMapFuture = _fetchDisciplines();
  }

  Future<Map<String, String>> _fetchDisciplines() async {
    final snap = await FirebaseFirestore.instance
        .collection('schools').doc(widget.schoolId)
        .collection('disciplines').get();
    return {
      for (final d in snap.docs)
        d.id: (d.data()['name'] as String?) ?? '',
    };
  }

  void _deleteSchedule(String id) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(l10n.confirmDeletion),
        content: Text(l10n.confirmDeleteSchedule),
        actions: [
          TextButton(
              onPressed: () => Navigator.of(ctx).pop(),
              child: Text(l10n.cancel)),
          TextButton(
            onPressed: () {
              FirebaseFirestore.instance
                  .collection('schools').doc(widget.schoolId)
                  .collection('classSchedules').doc(id).delete();
              Navigator.of(ctx).pop();
            },
            child:
                Text(l10n.eliminate, style: const TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(l10n.manageSchedules)),
      body: FutureBuilder<Map<String, String>>(
        future: _disciplinesMapFuture,
        builder: (context, disciplinesSnap) {
          if (disciplinesSnap.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          final disciplinesMap = disciplinesSnap.data ?? {};

          return StreamBuilder<QuerySnapshot>(
            stream: FirebaseFirestore.instance
                .collection('schools').doc(widget.schoolId)
                .collection('classSchedules')
                .orderBy('dayOfWeek')
                .orderBy('startTime')
                .snapshots(),
            builder: (context, scheduleSnap) {
              if (scheduleSnap.connectionState == ConnectionState.waiting &&
                  !scheduleSnap.hasData) {
                return const Center(child: CircularProgressIndicator());
              }

              final docs = scheduleSnap.data?.docs ?? [];

              // Group by day, collect unique titles for chart filters
              final grouped = <int, List<QueryDocumentSnapshot>>{};
              final allTitles = <String>[];
              for (final doc in docs) {
                final day = doc['dayOfWeek'] as int;
                grouped.putIfAbsent(day, () => []).add(doc);
                final title = doc['title'] as String? ?? '';
                if (!allTitles.contains(title)) allTitles.add(title);
              }

              // Build per-day widgets eagerly (small list)
              final daySections = <Widget>[
                for (int i = 0; i < 7; i++)
                  if ((grouped[i + 1] ?? []).isNotEmpty)
                    _buildDaySection(context, i, grouped[i + 1]!, disciplinesMap),
              ];

              return CustomScrollView(
                slivers: [
                  // ── Attendance chart ──────────────────────────────────
                  SliverToBoxAdapter(
                    child: _AttendanceChartSection(
                      schoolId: widget.schoolId,
                      scheduleTitles: allTitles,
                    ),
                  ),

                  // ── "Horarios" divider ────────────────────────────────
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(16, 4, 16, 4),
                      child: Row(
                        children: [
                          Text(l10n.manageSchedules,
                              style: Theme.of(context).textTheme.titleLarge),
                        ],
                      ),
                    ),
                  ),

                  // ── Schedule list ─────────────────────────────────────
                  if (docs.isEmpty)
                    SliverToBoxAdapter(
                      child: Padding(
                        padding: const EdgeInsets.all(32),
                        child: Center(
                          child: Text(l10n.noSchedulesDefined,
                              textAlign: TextAlign.center),
                        ),
                      ),
                    )
                  else
                    SliverList(
                        delegate: SliverChildListDelegate(daySections)),

                  const SliverToBoxAdapter(child: SizedBox(height: 96)),
                ],
              );
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => Navigator.of(context).push(MaterialPageRoute(
          builder: (_) => AddEditScheduleScreen(schoolId: widget.schoolId),
        )),
        child: const Icon(Icons.add),
      ),
    );
  }

  Widget _buildDaySection(
    BuildContext context,
    int weekdayIndex,
    List<QueryDocumentSnapshot> docs,
    Map<String, String> disciplinesMap,
  ) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(_dayLabels[weekdayIndex],
              style: Theme.of(context).textTheme.titleLarge),
          const Divider(),
          ...docs.map((doc) {
            final data = doc.data() as Map<String, dynamic>;
            final disciplineId = data['disciplineId'] as String?;
            final disciplineName =
                disciplinesMap[disciplineId] ?? l10n.noDiscipline;
            return Card(
              child: ListTile(
                title: Text(data['title'] ?? ''),
                subtitle: Text(
                    '$disciplineName | ${data['startTime']} - ${data['endTime']}'),
                trailing: IconButton(
                  icon: const Icon(Icons.delete, color: Colors.red),
                  onPressed: () => _deleteSchedule(doc.id),
                ),
              ),
            );
          }),
        ],
      ),
    );
  }
}

// ── Attendance chart section ──────────────────────────────────────────────────

class _ChartData {
  final DateTime startDate;
  final Map<String, Map<int, int>> countsPerTitle; // title → dayIndex → count

  const _ChartData(
      {required this.startDate, required this.countsPerTitle});
}

class _AttendanceChartSection extends StatefulWidget {
  final String schoolId;
  final List<String> scheduleTitles;

  const _AttendanceChartSection({
    required this.schoolId,
    required this.scheduleTitles,
  });

  @override
  State<_AttendanceChartSection> createState() =>
      _AttendanceChartSectionState();
}

class _AttendanceChartSectionState extends State<_AttendanceChartSection> {
  int _days = 14;
  String? _selectedTitle; // null = show all
  late Future<_ChartData> _future;

  @override
  void initState() {
    super.initState();
    _future = _loadData();
  }

  @override
  void didUpdateWidget(_AttendanceChartSection old) {
    super.didUpdateWidget(old);
    if (_selectedTitle != null &&
        !widget.scheduleTitles.contains(_selectedTitle)) {
      _selectedTitle = null;
    }
  }

  Future<_ChartData> _loadData() async {
    final now = DateTime.now();
    final startDate =
        DateTime(now.year, now.month, now.day).subtract(Duration(days: _days - 1));

    final snap = await FirebaseFirestore.instance
        .collection('schools').doc(widget.schoolId)
        .collection('attendanceRecords')
        .where('date', isGreaterThanOrEqualTo: Timestamp.fromDate(startDate))
        .get();

    // title → dayIndex → Set<studentId>  (dedup per day)
    final raw = <String, Map<int, Set<String>>>{};
    for (final doc in snap.docs) {
      final d = doc.data();
      final title = d['scheduleTitle'] as String? ?? '';
      final date = (d['date'] as Timestamp).toDate();
      final dayIndex = date.difference(startDate).inDays;
      if (dayIndex < 0 || dayIndex >= _days) continue;
      final ids = Set<String>.from(d['presentStudentIds'] as List? ?? []);
      raw.putIfAbsent(title, () => {});
      raw[title]!.putIfAbsent(dayIndex, () => {}).addAll(ids);
    }

    final counts = raw.map((t, dayMap) =>
        MapEntry(t, dayMap.map((day, ids) => MapEntry(day, ids.length))));

    return _ChartData(startDate: startDate, countsPerTitle: counts);
  }

  void _reload() => setState(() => _future = _loadData());

  @override
  Widget build(BuildContext context) {
    final primary = Theme.of(context).primaryColor;

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Header ────────────────────────────────────────────────────
          Row(
            children: [
              Icon(Icons.show_chart_rounded, color: primary, size: 22),
              const SizedBox(width: 8),
              Text(
                'Asistencia',
                style: Theme.of(context)
                    .textTheme
                    .titleLarge
                    ?.copyWith(fontWeight: FontWeight.bold),
              ),
              const Spacer(),
              IconButton(
                icon: Icon(Icons.refresh, size: 20, color: Colors.grey.shade500),
                onPressed: _reload,
                tooltip: 'Actualizar',
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
              ),
            ],
          ),
          const SizedBox(height: 12),

          // ── Time range chips ───────────────────────────────────────────
          Row(
            children: [
              for (final d in [7, 14, 30]) ...[
                _RangeChip(
                  label: '${d}D',
                  selected: _days == d,
                  primary: primary,
                  onTap: () {
                    if (_days == d) return;
                    setState(() => _days = d);
                    _reload();
                  },
                ),
                const SizedBox(width: 8),
              ],
            ],
          ),
          const SizedBox(height: 10),

          // ── Class filter chips (only when > 1 schedule exists) ─────────
          if (widget.scheduleTitles.length > 1) ...[
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  _ClassFilterChip(
                    label: 'Todos',
                    selected: _selectedTitle == null,
                    color: Colors.grey.shade700,
                    onTap: () => setState(() => _selectedTitle = null),
                  ),
                  const SizedBox(width: 6),
                  ...widget.scheduleTitles.asMap().entries.map((e) {
                    final color = _kColors[e.key % _kColors.length];
                    return Padding(
                      padding: const EdgeInsets.only(right: 6),
                      child: _ClassFilterChip(
                        label: e.value,
                        selected: _selectedTitle == e.value,
                        color: color,
                        onTap: () => setState(() =>
                            _selectedTitle =
                                _selectedTitle == e.value ? null : e.value),
                      ),
                    );
                  }),
                ],
              ),
            ),
            const SizedBox(height: 12),
          ],

          // ── Chart ──────────────────────────────────────────────────────
          FutureBuilder<_ChartData>(
            future: _future,
            builder: (context, snap) {
              if (snap.connectionState == ConnectionState.waiting) {
                return const SizedBox(
                    height: 200,
                    child: Center(child: CircularProgressIndicator()));
              }
              if (!snap.hasData) {
                return const SizedBox(
                    height: 200,
                    child: Center(child: Text('Error al cargar datos')));
              }

              final data = snap.data!;
              final titlesToShow = _selectedTitle != null
                  ? [_selectedTitle!]
                  : widget.scheduleTitles;

              final hasData = titlesToShow
                  .any((t) => (data.countsPerTitle[t] ?? {}).isNotEmpty);

              if (!hasData || titlesToShow.isEmpty) {
                return _EmptyChart(days: _days);
              }

              return _ChartBody(
                data: data,
                days: _days,
                titlesToShow: titlesToShow,
                allTitles: widget.scheduleTitles,
              );
            },
          ),

          const SizedBox(height: 8),
          const Divider(),
        ],
      ),
    );
  }
}

// ── Chart body (extracted to keep build readable) ─────────────────────────────

class _ChartBody extends StatelessWidget {
  final _ChartData data;
  final int days;
  final List<String> titlesToShow;
  final List<String> allTitles;

  const _ChartBody({
    required this.data,
    required this.days,
    required this.titlesToShow,
    required this.allTitles,
  });

  Color _colorFor(String title, int fallbackIndex) {
    final idx = allTitles.indexOf(title);
    return _kColors[(idx >= 0 ? idx : fallbackIndex) % _kColors.length];
  }

  @override
  Widget build(BuildContext context) {
    // Build LineChartBarData list
    final lineBars = titlesToShow.asMap().entries.map((entry) {
      final color = _colorFor(entry.value, entry.key);
      final dayMap = data.countsPerTitle[entry.value] ?? {};
      final spots = List.generate(
        days,
        (i) => FlSpot(i.toDouble(), (dayMap[i] ?? 0).toDouble()),
      );
      return LineChartBarData(
        spots: spots,
        isCurved: true,
        curveSmoothness: 0.3,
        color: color,
        barWidth: 2.5,
        isStrokeCapRound: true,
        dotData: FlDotData(
          show: true,
          getDotPainter: (spot, pct, bar, idx) {
            if (spot.y == 0) {
              return FlDotCirclePainter(
                  radius: 0,
                  color: Colors.transparent,
                  strokeWidth: 0,
                  strokeColor: Colors.transparent);
            }
            return FlDotCirclePainter(
                radius: 3,
                color: color,
                strokeWidth: 1.5,
                strokeColor: Colors.white);
          },
        ),
        belowBarData: BarAreaData(
            show: true, color: color.withValues(alpha: 0.08)),
      );
    }).toList();

    // Max Y
    double maxY = 1;
    for (final bar in lineBars) {
      for (final spot in bar.spots) {
        if (spot.y > maxY) maxY = spot.y;
      }
    }
    maxY = (maxY + 1).ceilToDouble();

    final xInterval = days <= 7 ? 1.0 : days <= 14 ? 2.0 : 5.0;
    final yInterval = (maxY / 4).ceilToDouble().clamp(1.0, double.infinity);

    // Summary stats
    int totalSessions = 0, totalStudents = 0, peakCount = 0;
    for (final t in titlesToShow) {
      for (final count in (data.countsPerTitle[t] ?? {}).values) {
        if (count > 0) {
          totalSessions++;
          totalStudents += count;
          if (count > peakCount) peakCount = count;
        }
      }
    }
    final avg = totalSessions > 0
        ? (totalStudents / totalSessions).toStringAsFixed(1)
        : '–';

    final primary = Theme.of(context).primaryColor;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Chart
        SizedBox(
          height: 200,
          child: Padding(
            padding: const EdgeInsets.only(right: 8, top: 8),
            child: LineChart(
              LineChartData(
                minX: 0,
                maxX: (days - 1).toDouble(),
                minY: 0,
                maxY: maxY,
                gridData: FlGridData(
                  show: true,
                  drawVerticalLine: false,
                  getDrawingHorizontalLine: (_) => FlLine(
                    color: Colors.grey.shade100,
                    strokeWidth: 1,
                  ),
                ),
                borderData: FlBorderData(show: false),
                titlesData: FlTitlesData(
                  topTitles: const AxisTitles(
                      sideTitles: SideTitles(showTitles: false)),
                  rightTitles: const AxisTitles(
                      sideTitles: SideTitles(showTitles: false)),
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      interval: xInterval,
                      reservedSize: 24,
                      getTitlesWidget: (value, _) {
                        final date = data.startDate
                            .add(Duration(days: value.toInt()));
                        return Padding(
                          padding: const EdgeInsets.only(top: 4),
                          child: Text(
                            DateFormat('d/M').format(date),
                            style: TextStyle(
                                fontSize: 10,
                                color: Colors.grey.shade500),
                          ),
                        );
                      },
                    ),
                  ),
                  leftTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 28,
                      interval: yInterval,
                      getTitlesWidget: (value, _) => Text(
                        value.toInt().toString(),
                        style: TextStyle(
                            fontSize: 10, color: Colors.grey.shade500),
                      ),
                    ),
                  ),
                ),
                lineBarsData: lineBars,
                lineTouchData: LineTouchData(
                  touchTooltipData: LineTouchTooltipData(
                    getTooltipColor: (_) => Colors.black87,
                    getTooltipItems: (spots) => spots.map((s) {
                      final date = data.startDate
                          .add(Duration(days: s.x.toInt()));
                      final titleSuffix = titlesToShow.length > 1 &&
                              s.barIndex < titlesToShow.length
                          ? '\n${titlesToShow[s.barIndex]}'
                          : '';
                      return LineTooltipItem(
                        '${s.y.toInt()} alumnos\n'
                        '${DateFormat('dd/MM').format(date)}'
                        '$titleSuffix',
                        const TextStyle(
                            color: Colors.white,
                            fontSize: 11,
                            fontWeight: FontWeight.w500),
                      );
                    }).toList(),
                  ),
                ),
              ),
            ),
          ),
        ),

        // Legend (when multiple lines)
        if (titlesToShow.length > 1) ...[
          const SizedBox(height: 8),
          Wrap(
            spacing: 14,
            runSpacing: 4,
            children: titlesToShow.asMap().entries.map((e) {
              final color = _colorFor(e.value, e.key);
              return Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 16,
                    height: 3,
                    decoration: BoxDecoration(
                        color: color,
                        borderRadius: BorderRadius.circular(2)),
                  ),
                  const SizedBox(width: 4),
                  Text(e.value,
                      style: TextStyle(
                          fontSize: 11, color: Colors.grey.shade600)),
                ],
              );
            }).toList(),
          ),
        ],

        // Summary stat pills
        const SizedBox(height: 14),
        Row(
          children: [
            _StatPill(
              label: 'Promedio',
              value: avg,
              unit: 'alumnos',
              icon: Icons.people_outline,
              color: primary,
            ),
            const SizedBox(width: 8),
            _StatPill(
              label: 'Pico',
              value: '$peakCount',
              unit: 'alumnos',
              icon: Icons.trending_up,
              color: Colors.amber.shade700,
            ),
            const SizedBox(width: 8),
            _StatPill(
              label: 'Sesiones',
              value: '$totalSessions',
              unit: 'con datos',
              icon: Icons.calendar_today_outlined,
              color: Colors.teal,
            ),
          ],
        ),
      ],
    );
  }
}

// ── Empty chart placeholder ───────────────────────────────────────────────────

class _EmptyChart extends StatelessWidget {
  final int days;
  const _EmptyChart({required this.days});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 180,
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.bar_chart_outlined,
                size: 40, color: Colors.grey.shade300),
            const SizedBox(height: 8),
            Text(
              'Sin registros en los últimos $days días',
              style: TextStyle(color: Colors.grey.shade500, fontSize: 13),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Small reusable widgets ────────────────────────────────────────────────────

class _RangeChip extends StatelessWidget {
  final String label;
  final bool selected;
  final Color primary;
  final VoidCallback onTap;

  const _RangeChip(
      {required this.label,
      required this.selected,
      required this.primary,
      required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 7),
        decoration: BoxDecoration(
          color: selected ? primary : Colors.grey.shade100,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: selected ? Colors.white : Colors.grey.shade600,
            fontWeight: selected ? FontWeight.bold : FontWeight.normal,
            fontSize: 13,
          ),
        ),
      ),
    );
  }
}

class _ClassFilterChip extends StatelessWidget {
  final String label;
  final bool selected;
  final Color color;
  final VoidCallback onTap;

  const _ClassFilterChip(
      {required this.label,
      required this.selected,
      required this.color,
      required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
        decoration: BoxDecoration(
          color: selected ? color.withValues(alpha: 0.12) : Colors.transparent,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: selected ? color : Colors.grey.shade300,
            width: 1.2,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (selected) ...[
              Container(
                width: 7,
                height: 7,
                decoration:
                    BoxDecoration(color: color, shape: BoxShape.circle),
              ),
              const SizedBox(width: 5),
            ],
            Text(
              label,
              style: TextStyle(
                color: selected ? color : Colors.grey.shade600,
                fontSize: 12,
                fontWeight:
                    selected ? FontWeight.w600 : FontWeight.normal,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _StatPill extends StatelessWidget {
  final String label;
  final String value;
  final String unit;
  final IconData icon;
  final Color color;

  const _StatPill({
    required this.label,
    required this.value,
    required this.unit,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.07),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, size: 15, color: color),
            const SizedBox(height: 4),
            Text(value,
                style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                    color: color)),
            Text(unit,
                style:
                    TextStyle(fontSize: 10, color: Colors.grey.shade500)),
            Text(label,
                style:
                    TextStyle(fontSize: 10, color: Colors.grey.shade400)),
          ],
        ),
      ),
    );
  }
}
