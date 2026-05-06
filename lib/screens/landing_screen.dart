import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:location/location.dart';
import 'package:warrior_path/screens/WelcomeScreen.dart';

class LandingScreen extends StatefulWidget {
  const LandingScreen({super.key});

  @override
  State<LandingScreen> createState() => _LandingScreenState();
}

class _LandingScreenState extends State<LandingScreen> with TickerProviderStateMixin {
  static const _gold = Color(0xFFFFD700);
  static const _darkBg = Color(0xFF1C1C1E);
  static const _cardBg = Color(0xFF2A2A2C);

  // Rivera y Soca, Montevideo (fallback sin GPS)
  static const _fallbackCenter = LatLng(-34.8971, -56.1643);

  final MapController _mapController = MapController();

  late AnimationController _animController;
  late Animation<double> _logoScale;
  late Animation<double> _titleFade;
  late Animation<Offset> _titleSlide;
  late Animation<double> _ctaFade;

  List<_SchoolMarkerData> _schools = [];
  bool _loadingSchools = false;
  String? _selectedDiscipline;
  Set<String> _allDisciplines = {};

  @override
  void initState() {
    super.initState();
    _setupAnimations();
    _animController.forward();
    _fetchSchools();
    _locateUser();
  }

  Future<void> _locateUser() async {
    try {
      final loc = Location();
      final serviceEnabled = await loc.serviceEnabled();
      if (!serviceEnabled && !await loc.requestService()) return;

      final permission = await loc.hasPermission();
      final granted = permission == PermissionStatus.granted ||
          permission == PermissionStatus.grantedLimited;
      final requested = granted
          ? permission
          : await loc.requestPermission();

      if (requested == PermissionStatus.granted ||
          requested == PermissionStatus.grantedLimited) {
        final data = await loc.getLocation();
        if (data.latitude != null && data.longitude != null && mounted) {
          _mapController.move(LatLng(data.latitude!, data.longitude!), 13);
        }
      }
    } catch (_) {
      // Mantiene el centro por defecto (Rivera y Soca)
    }
  }

  void _setupAnimations() {
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1400),
    );

    _logoScale = CurvedAnimation(
      parent: _animController,
      curve: const Interval(0.0, 0.45, curve: Curves.elasticOut),
    );

    _titleFade = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(
        parent: _animController,
        curve: const Interval(0.3, 0.65, curve: Curves.easeIn),
      ),
    );

    _titleSlide = Tween<Offset>(
      begin: const Offset(0, 0.35),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _animController,
      curve: const Interval(0.3, 0.65, curve: Curves.easeOut),
    ));

    _ctaFade = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(
        parent: _animController,
        curve: const Interval(0.65, 1.0, curve: Curves.easeIn),
      ),
    );
  }

  Future<void> _fetchSchools() async {
    setState(() => _loadingSchools = true);
    try {
      // Fetch only schools that have a valid latitude stored
      final snapshot = await FirebaseFirestore.instance
          .collection('schools')
          .where('latitude', isGreaterThan: -91)
          .get();

      final schoolsData = await Future.wait(
        snapshot.docs.map((doc) async {
          final data = doc.data();
          final lat = (data['latitude'] as num?)?.toDouble();
          final lng = (data['longitude'] as num?)?.toDouble();
          if (lat == null || lng == null) return null;

          final disciplinesSnap = await doc.reference
              .collection('disciplines')
              .get();

          final disciplines = disciplinesSnap.docs
              .map((d) => d.data()['name'] as String? ?? '')
              .where((n) => n.isNotEmpty)
              .toList();

          return _SchoolMarkerData(
            id: doc.id,
            name: data['name'] as String? ?? '',
            logoUrl: data['logoUrl'] as String?,
            location: LatLng(lat, lng),
            disciplines: disciplines,
          );
        }),
      );

      final validSchools = schoolsData.whereType<_SchoolMarkerData>().toList();
      final disciplines = validSchools.expand((s) => s.disciplines).toSet();

      if (mounted) {
        setState(() {
          _schools = validSchools;
          _allDisciplines = disciplines;
        });
      }
    } catch (_) {
      // Si Firestore no permite acceso público aún, el mapa queda vacío
    } finally {
      if (mounted) setState(() => _loadingSchools = false);
    }
  }

  List<_SchoolMarkerData> get _filteredSchools {
    if (_selectedDiscipline == null) return _schools;
    return _schools
        .where((s) => s.disciplines.contains(_selectedDiscipline))
        .toList();
  }

  void _showSchoolDetail(_SchoolMarkerData school) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: _cardBg,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => _SchoolDetailSheet(school: school),
    );
  }

  void _goToLogin() {
    Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => const WelcomeScreen()),
    );
  }

  @override
  void dispose() {
    _animController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _darkBg,
      body: SafeArea(
        child: Column(
          children: [
            // ── Header animado ──────────────────────────────────────
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 32, 24, 20),
              child: Column(
                children: [
                  ScaleTransition(
                    scale: _logoScale,
                    child: ClipOval(
                      child: Image.asset(
                        'assets/logo/Logo.png',
                        height: 80,
                        width: 80,
                        fit: BoxFit.cover,
                        errorBuilder: (_, _, _) => const Icon(
                          Icons.sports_martial_arts,
                          size: 80,
                          color: _gold,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  FadeTransition(
                    opacity: _titleFade,
                    child: SlideTransition(
                      position: _titleSlide,
                      child: Column(
                        children: [
                          const Text(
                            'WARRIOR PATH',
                            style: TextStyle(
                              color: _gold,
                              fontSize: 28,
                              fontWeight: FontWeight.w900,
                              letterSpacing: 4,
                            ),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            'Encontrá tu escuela de artes marciales',
                            style: TextStyle(
                              color: Colors.white.withValues(alpha: 0.7),
                              fontSize: 14,
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // ── Mapa de escuelas ────────────────────────────────────
            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(16),
                  child: Stack(
                    children: [
                      FlutterMap(
                        mapController: _mapController,
                        options: const MapOptions(
                          initialCenter: _fallbackCenter,
                          initialZoom: 13,
                        ),
                        children: [
                          TileLayer(
                            urlTemplate:
                                'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                            userAgentPackageName: 'com.warriorpath.app',
                          ),
                          MarkerLayer(
                            markers: _filteredSchools.map((school) {
                              return Marker(
                                point: school.location,
                                width: 44,
                                height: 44,
                                child: GestureDetector(
                                  onTap: () => _showSchoolDetail(school),
                                  child: const Icon(
                                    Icons.location_pin,
                                    color: _gold,
                                    size: 44,
                                    shadows: [
                                      Shadow(blurRadius: 4, color: Colors.black54)
                                    ],
                                  ),
                                ),
                              );
                            }).toList(),
                          ),
                        ],
                      ),
                      if (_loadingSchools)
                        const Positioned(
                          top: 12,
                          right: 12,
                          child: CircularProgressIndicator(
                            color: _gold,
                            strokeWidth: 2,
                          ),
                        ),
                    ],
                  ),
                ),
              ),
            ),

            // ── Filtros por disciplina ──────────────────────────────
            if (_allDisciplines.isNotEmpty)
              SizedBox(
                height: 48,
                child: ListView(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                  children: [
                    _DisciplineChip(
                      label: 'Todas',
                      selected: _selectedDiscipline == null,
                      onTap: () => setState(() => _selectedDiscipline = null),
                    ),
                    ..._allDisciplines.map((d) => _DisciplineChip(
                          label: d,
                          selected: _selectedDiscipline == d,
                          onTap: () => setState(() => _selectedDiscipline = d),
                        )),
                  ],
                ),
              ),

            // ── CTAs ────────────────────────────────────────────────
            FadeTransition(
              opacity: _ctaFade,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(24, 16, 24, 12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    ElevatedButton(
                      onPressed: _goToLogin,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: _gold,
                        foregroundColor: Colors.black,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        textStyle: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      child: const Text('Ingresar / Registrarse'),
                    ),
                  ],
                ),
              ),
            ),

            // ── Footer SPC ───────────────────────────────────────────
            FadeTransition(
              opacity: _ctaFade,
              child: Padding(
                padding: const EdgeInsets.only(bottom: 16),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      'Developed by ',
                      style: TextStyle(
                          fontSize: 10,
                          color: Colors.white.withValues(alpha: 0.5)),
                    ),
                    Container(
                      width: 26,
                      height: 26,
                      decoration: const BoxDecoration(
                        shape: BoxShape.circle,
                        color: Colors.white,
                      ),
                      clipBehavior: Clip.antiAlias,
                      child: Image.asset(
                        'assets/logo/spc_logo_compressed.jpg',
                        fit: BoxFit.cover,
                        errorBuilder: (_, _, _) => const SizedBox.shrink(),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Chip de filtro ─────────────────────────────────────────────────────────────

class _DisciplineChip extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;

  const _DisciplineChip({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  static const _gold = Color(0xFFFFD700);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
          decoration: BoxDecoration(
            color: selected ? _gold : Colors.white12,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: selected ? _gold : Colors.white24,
            ),
          ),
          child: Text(
            label,
            style: TextStyle(
              color: selected ? Colors.black : Colors.white70,
              fontWeight: selected ? FontWeight.bold : FontWeight.normal,
              fontSize: 13,
            ),
          ),
        ),
      ),
    );
  }
}

// ── Datos de un marker ─────────────────────────────────────────────────────────

class _SchoolMarkerData {
  final String id;
  final String name;
  final String? logoUrl;
  final LatLng location;
  final List<String> disciplines;

  const _SchoolMarkerData({
    required this.id,
    required this.name,
    this.logoUrl,
    required this.location,
    required this.disciplines,
  });
}

// ── Bottom sheet con detalle de escuela ────────────────────────────────────────

class _SchoolDetailSheet extends StatefulWidget {
  final _SchoolMarkerData school;

  const _SchoolDetailSheet({required this.school});

  @override
  State<_SchoolDetailSheet> createState() => _SchoolDetailSheetState();
}

class _SchoolDetailSheetState extends State<_SchoolDetailSheet> {
  static const _gold = Color(0xFFFFD700);

  List<Map<String, dynamic>> _schedules = [];
  bool _loadingSchedules = true;

  @override
  void initState() {
    super.initState();
    _fetchSchedules();
  }

  Future<void> _fetchSchedules() async {
    try {
      final snap = await FirebaseFirestore.instance
          .collection('schools')
          .doc(widget.school.id)
          .collection('classSchedules')
          .limit(5)
          .get();
      if (mounted) {
        setState(() {
          _schedules = snap.docs.map((d) => d.data()).toList();
        });
      }
    } catch (_) {
      // schedules no disponibles
    } finally {
      if (mounted) setState(() => _loadingSchedules = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final school = widget.school;
    return DraggableScrollableSheet(
      expand: false,
      initialChildSize: 0.5,
      maxChildSize: 0.85,
      builder: (_, controller) => ListView(
        controller: controller,
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 32),
        children: [
          Center(
            child: Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.white24,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              CircleAvatar(
                radius: 30,
                backgroundColor: Colors.white12,
                backgroundImage: (school.logoUrl != null && school.logoUrl!.isNotEmpty)
                    ? NetworkImage(school.logoUrl!)
                    : null,
                child: (school.logoUrl == null || school.logoUrl!.isEmpty)
                    ? const Icon(Icons.school, color: _gold, size: 30)
                    : null,
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Text(
                  school.name,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          if (school.disciplines.isNotEmpty) ...[
            const SizedBox(height: 16),
            Wrap(
              spacing: 8,
              runSpacing: 6,
              children: school.disciplines.map((d) => Chip(
                label: Text(d, style: const TextStyle(color: Colors.black, fontSize: 12)),
                backgroundColor: _gold,
                padding: EdgeInsets.zero,
                materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
              )).toList(),
            ),
          ],
          const SizedBox(height: 20),
          const Text(
            'Horarios',
            style: TextStyle(
              color: _gold,
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          if (_loadingSchedules)
            const Center(child: Padding(
              padding: EdgeInsets.all(16),
              child: CircularProgressIndicator(color: _gold, strokeWidth: 2),
            ))
          else if (_schedules.isEmpty)
            Text(
              'No hay horarios cargados aún.',
              style: TextStyle(color: Colors.white.withValues(alpha: 0.5)),
            )
          else
            ..._schedules.map((s) => _ScheduleTile(schedule: s)),
        ],
      ),
    );
  }
}

class _ScheduleTile extends StatelessWidget {
  final Map<String, dynamic> schedule;

  const _ScheduleTile({required this.schedule});

  static const _days = ['Lun', 'Mar', 'Mié', 'Jue', 'Vie', 'Sáb', 'Dom'];

  @override
  Widget build(BuildContext context) {
    final day = schedule['dayOfWeek'] as int?;
    final start = schedule['startTime'] as String? ?? '';
    final end = schedule['endTime'] as String? ?? '';
    final title = schedule['title'] as String? ?? 'Clase';
    final dayLabel = (day != null && day >= 1 && day <= 7) ? _days[day - 1] : '';

    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: Colors.white10,
          borderRadius: BorderRadius.circular(10),
        ),
        child: Row(
          children: [
            Text(
              dayLabel,
              style: const TextStyle(
                color: Color(0xFFFFD700),
                fontWeight: FontWeight.bold,
                fontSize: 13,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(title, style: const TextStyle(color: Colors.white)),
            ),
            Text(
              '$start - $end',
              style: TextStyle(color: Colors.white.withValues(alpha: 0.6), fontSize: 12),
            ),
          ],
        ),
      ),
    );
  }
}
