import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

// ── Static definition helpers ─────────────────────────────────────────────────

class _StudentDef {
  final String name;
  final String emailPrefix;
  final int levelIndex; // 0=Blanca … 7=Negra
  final String planKey; // 'basic' | 'intermediate' | 'advanced'
  final int techCount; // how many techniques from index 0
  final List<String> achievements;
  final int joinMonthsAgo;
  final bool hasPromos;

  const _StudentDef(
    this.name,
    this.emailPrefix,
    this.levelIndex,
    this.planKey,
    this.techCount,
    this.achievements,
    this.joinMonthsAgo,
    this.hasPromos,
  );
}

// ── Runtime seed models ───────────────────────────────────────────────────────

class _SeedCtx {
  String schoolId = '';
  String teacherUid = '';
  String disciplineId = '';
  String disciplineName = 'Kung Fu Shaolin Tradicional';
  List<String> levelIds = []; // index == order (0=Blanca … 7=Negra)
  List<String> techIds = []; // in creation order
  String basicPlanId = '';
  String intermediatePlanId = '';
  String advancedPlanId = '';
  List<_SeedStudent> students = [];
}

class _SeedStudent {
  final String name;
  final String planKey;
  final String planId;
  final int levelIndex;
  final String levelId;
  final int techCount;
  final List<String> achievementIds;
  final int joinMonthsAgo;
  final bool hasPromos;
  final String uid;

  const _SeedStudent({
    required this.name,
    required this.planKey,
    required this.planId,
    required this.levelIndex,
    required this.levelId,
    required this.techCount,
    required this.achievementIds,
    required this.joinMonthsAgo,
    required this.hasPromos,
    required this.uid,
  });

  double get amount =>
      planKey == 'basic' ? 1500.0 : planKey == 'intermediate' ? 2200.0 : 2800.0;
}

class _StepResult {
  final String title;
  final bool ok;
  final String detail;
  _StepResult.success(this.title, this.detail) : ok = true;
  _StepResult.failure(this.title, this.detail) : ok = false;
}

// ── Screen ────────────────────────────────────────────────────────────────────

class SeedDataScreen extends StatefulWidget {
  const SeedDataScreen({super.key});

  @override
  State<SeedDataScreen> createState() => _SeedDataScreenState();
}

class _SeedDataScreenState extends State<SeedDataScreen> {
  static const _red = Color(0xFFB71C1C);
  static const _gold = Color(0xFFFFB300);
  static const _bg = Color(0xFF1A1A1A);
  static const _surface = Color(0xFF252525);

  final _db = FirebaseFirestore.instance;

  bool _checking = true;
  int _existingCount = 0;

  bool _running = false;
  bool _done = false;
  String _currentStep = '';
  final List<_StepResult> _results = [];

  @override
  void initState() {
    super.initState();
    _checkExisting();
  }

  Future<void> _checkExisting() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      setState(() => _checking = false);
      return;
    }
    final schools = await _db
        .collection('schools')
        .where('ownerId', isEqualTo: user.uid)
        .limit(1)
        .get();
    if (schools.docs.isNotEmpty) {
      final schoolId = schools.docs.first.id;
      final count = await _db
          .collection('schools')
          .doc(schoolId)
          .collection('members')
          .where('role', isEqualTo: 'alumno')
          .count()
          .get();
      _existingCount = count.count ?? 0;
    }
    setState(() => _checking = false);
  }

  // ── Seed runner ─────────────────────────────────────────────────────────────

  Future<void> _runSeed() async {
    setState(() {
      _running = true;
      _done = false;
      _results.clear();
    });

    final ctx = _SeedCtx();
    try {
      await _s1FindSchool(ctx);
      await _s2Discipline(ctx);
      await _s3Levels(ctx);
      await _s4Techniques(ctx);
      await _s5Plans(ctx);
      await _s6Schedules(ctx);
      await _s7Students(ctx);
      await _s8Payments(ctx);
      await _s9Attendance(ctx);
      await _s10AchievementsAndPromos(ctx);
    } catch (e) {
      _add(_StepResult.failure(_currentStep, e.toString()));
    }

    setState(() {
      _running = false;
      _done = true;
    });
  }

  void _add(_StepResult r) => setState(() => _results.add(r));
  void _status(String msg) => setState(() => _currentStep = msg);

  // ── Step 1: Find school ──────────────────────────────────────────────────

  Future<void> _s1FindSchool(_SeedCtx ctx) async {
    _status('Buscando escuela...');
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) throw Exception('No hay usuario autenticado');
    ctx.teacherUid = user.uid;

    final snap = await _db
        .collection('schools')
        .where('ownerId', isEqualTo: user.uid)
        .limit(1)
        .get();
    if (snap.docs.isEmpty) throw Exception('No se encontró ninguna escuela para este usuario');

    ctx.schoolId = snap.docs.first.id;
    final name = snap.docs.first.data()['name'] as String? ?? 'Escuela';
    _add(_StepResult.success('Escuela encontrada', '"$name"'));
  }

  // ── Step 2: Discipline ───────────────────────────────────────────────────

  Future<void> _s2Discipline(_SeedCtx ctx) async {
    _status('Verificando disciplina principal...');
    final snap = await _db
        .collection('schools')
        .doc(ctx.schoolId)
        .collection('disciplines')
        .where('isPrimary', isEqualTo: true)
        .limit(1)
        .get();

    if (snap.docs.isNotEmpty) {
      ctx.disciplineId = snap.docs.first.id;
      ctx.disciplineName =
          snap.docs.first.data()['name'] as String? ?? ctx.disciplineName;
      await _db
          .collection('schools')
          .doc(ctx.schoolId)
          .collection('disciplines')
          .doc(ctx.disciplineId)
          .update({'techniqueCategories': _kCategories});
      _add(_StepResult.success(
          'Disciplina', '"${ctx.disciplineName}" encontrada — categorías actualizadas'));
    } else {
      final ref = await _db
          .collection('schools')
          .doc(ctx.schoolId)
          .collection('disciplines')
          .add({
        'name': ctx.disciplineName,
        'isPrimary': true,
        'isActive': true,
        'theme': {'primaryColor': 'B71C1C', 'accentColor': 'FF8F00'},
        'techniqueCategories': _kCategories,
        'createdAt': FieldValue.serverTimestamp(),
      });
      ctx.disciplineId = ref.id;
      _add(_StepResult.success('Disciplina creada', '"${ctx.disciplineName}"'));
    }
  }

  // ── Step 3: Levels (fajas) ───────────────────────────────────────────────

  Future<void> _s3Levels(_SeedCtx ctx) async {
    _status('Creando niveles (fajas)...');
    ctx.levelIds = [];
    int created = 0;
    int reused = 0;

    for (int i = 0; i < _kLevelDefs.length; i++) {
      final def = _kLevelDefs[i];
      final existing = await _db
          .collection('schools')
          .doc(ctx.schoolId)
          .collection('disciplines')
          .doc(ctx.disciplineId)
          .collection('levels')
          .where('name', isEqualTo: def.$1)
          .limit(1)
          .get();

      if (existing.docs.isNotEmpty) {
        ctx.levelIds.add(existing.docs.first.id);
        reused++;
      } else {
        final ref = await _db
            .collection('schools')
            .doc(ctx.schoolId)
            .collection('disciplines')
            .doc(ctx.disciplineId)
            .collection('levels')
            .add({'name': def.$1, 'colorValue': def.$2, 'order': i});
        ctx.levelIds.add(ref.id);
        created++;
      }
    }

    _add(_StepResult.success('Niveles (fajas)',
        '$created creados, $reused ya existían'));
  }

  // ── Step 4: Techniques ───────────────────────────────────────────────────

  Future<void> _s4Techniques(_SeedCtx ctx) async {
    _status('Creando técnicas...');
    ctx.techIds = [];
    int created = 0;
    int reused = 0;

    for (final tech in _kTechDefs) {
      final existing = await _db
          .collection('schools')
          .doc(ctx.schoolId)
          .collection('disciplines')
          .doc(ctx.disciplineId)
          .collection('techniques')
          .where('name', isEqualTo: tech.name)
          .limit(1)
          .get();

      if (existing.docs.isNotEmpty) {
        ctx.techIds.add(existing.docs.first.id);
        reused++;
      } else {
        final ref = await _db
            .collection('schools')
            .doc(ctx.schoolId)
            .collection('disciplines')
            .doc(ctx.disciplineId)
            .collection('techniques')
            .add({
          'name': tech.name,
          'category': tech.category,
          'complexity': tech.complexity,
          'description': tech.description,
          'videoUrl': null,
        });
        ctx.techIds.add(ref.id);
        created++;
      }
    }

    _add(_StepResult.success('Técnicas', '$created creadas, $reused ya existían'));
  }

  // ── Step 5: Payment plans ────────────────────────────────────────────────

  Future<void> _s5Plans(_SeedCtx ctx) async {
    _status('Creando planes de pago...');

    Future<String> addPlan(String title, double amount, String desc) async {
      final ref = await _db
          .collection('schools')
          .doc(ctx.schoolId)
          .collection('paymentPlans')
          .add({'title': title, 'amount': amount, 'description': desc, 'currency': 'UYU'});
      return ref.id;
    }

    ctx.basicPlanId = await addPlan('Plan Básico', 1500.0, 'Acceso a clases de iniciantes');
    ctx.intermediatePlanId =
        await addPlan('Plan Intermedio', 2200.0, 'Acceso a clases de iniciantes e intermedios');
    ctx.advancedPlanId =
        await addPlan('Plan Avanzado', 2800.0, 'Acceso ilimitado a todas las clases');

    _add(_StepResult.success('Planes de pago', '3 planes: Básico \$1.500 / Intermedio \$2.200 / Avanzado \$2.800 (UYU)'));
  }

  // ── Step 6: Class schedules ──────────────────────────────────────────────

  Future<void> _s6Schedules(_SeedCtx ctx) async {
    _status('Creando horarios...');
    int count = 0;
    for (final s in _kScheduleDefs) {
      await _db
          .collection('schools')
          .doc(ctx.schoolId)
          .collection('classSchedules')
          .add({
        'title': s.$1,
        'dayOfWeek': s.$2,
        'startTime': s.$3,
        'endTime': s.$4,
        'disciplineId': ctx.disciplineId,
      });
      count++;
    }
    _add(_StepResult.success('Horarios', '$count turnos creados'));
  }

  // ── Step 7: Students ─────────────────────────────────────────────────────

  Future<void> _s7Students(_SeedCtx ctx) async {
    _status('Creando alumnos...');
    ctx.students = [];
    final now = DateTime.now();

    for (final def in _kStudentDefs) {
      final planId = def.planKey == 'basic'
          ? ctx.basicPlanId
          : def.planKey == 'intermediate'
              ? ctx.intermediatePlanId
              : ctx.advancedPlanId;
      final levelId = ctx.levelIds[def.levelIndex];

      final joinDate = DateTime(now.year, now.month - def.joinMonthsAgo, 15);
      final techList = ctx.techIds.sublist(0, def.techCount);

      // User document (uses Firestore auto-ID as the UID)
      final userRef = _db.collection('users').doc();
      final uid = userRef.id;
      await userRef.set({
        'displayName': def.name,
        'email': '${def.emailPrefix}@demo.warriorpath.app',
        'wizardStep': 99,
        'activeMemberships': {ctx.schoolId: 'alumno'},
        'createdAt': Timestamp.fromDate(joinDate),
        'role': 'alumno',
      });

      // Member document
      await _db
          .collection('schools')
          .doc(ctx.schoolId)
          .collection('members')
          .doc(uid)
          .set({
        'userId': uid,
        'displayName': def.name,
        'status': 'active',
        'role': 'alumno',
        'joinDate': Timestamp.fromDate(joinDate),
        'assignedPaymentPlanId': planId,
        'hasUnseenPromotion': false,
        'achievements': <String, dynamic>{},
        'progress': {
          ctx.disciplineId: {
            'currentLevelId': levelId,
            'enrollmentDate': Timestamp.fromDate(joinDate),
            'assignedTechniqueIds': techList,
            'role': 'alumno',
          }
        },
      });

      ctx.students.add(_SeedStudent(
        name: def.name,
        planKey: def.planKey,
        planId: planId,
        levelIndex: def.levelIndex,
        levelId: levelId,
        techCount: def.techCount,
        achievementIds: def.achievements,
        joinMonthsAgo: def.joinMonthsAgo,
        hasPromos: def.hasPromos,
        uid: uid,
      ));
    }

    _add(_StepResult.success('Alumnos', '${ctx.students.length} alumnos creados'));
  }

  // ── Step 8: Payments ─────────────────────────────────────────────────────

  Future<void> _s8Payments(_SeedCtx ctx) async {
    _status('Generando historial de pagos...');
    const monthNames = [
      '', 'enero', 'febrero', 'marzo', 'abril', 'mayo', 'junio',
      'julio', 'agosto', 'septiembre', 'octubre', 'noviembre', 'diciembre'
    ];
    // Students at index 3 (Sofía) and 8 (Nicolás) skip the most recent month
    const skipLast = {3, 8};
    final now = DateTime.now();
    int total = 0;

    for (int si = 0; si < ctx.students.length; si++) {
      final s = ctx.students[si];
      for (int mb = 6; mb >= 1; mb--) {
        if (mb == 1 && skipLast.contains(si)) continue;
        final d = DateTime(now.year, now.month - mb, 5);
        await _db
            .collection('schools')
            .doc(ctx.schoolId)
            .collection('members')
            .doc(s.uid)
            .collection('payments')
            .add({
          'paymentDate': Timestamp.fromDate(d),
          'concept': 'Cuota mensual – ${monthNames[d.month]} ${d.year}',
          'amount': s.amount,
          'currency': 'UYU',
          'recordedBy': ctx.teacherUid,
          'schoolId': ctx.schoolId,
          'paymentPlanId': s.planId,
          'studentId': s.uid,
          'studentName': s.name,
        });
        total++;
      }
    }

    _add(_StepResult.success('Pagos', '$total pagos registrados (2 alumnos con 1 cuota faltante)'));
  }

  // ── Step 9: Attendance records ───────────────────────────────────────────

  Future<void> _s9Attendance(_SeedCtx ctx) async {
    _status('Generando registros de asistencia (60 días)...');
    // Schedule title → list of eligible student indices in ctx.students
    const classMap = {
      'Clase Iniciantes': [2, 3, 4, 8, 9],
      'Clase Intermedios': [0, 2, 5, 8],
      'Clase Avanzados': [1, 6, 7],
      'Chi Kung Matutino': [0, 1, 2, 3, 4, 5, 6, 7, 8, 9],
    };
    // Schedule title → days of week (1=Monday … 7=Sunday)
    const dayMap = {
      'Clase Iniciantes': [1, 3],
      'Clase Intermedios': [2, 4],
      'Clase Avanzados': [5],
      'Chi Kung Matutino': [6],
    };

    final now = DateTime.now();
    int total = 0;

    for (int dBack = 1; dBack <= 60; dBack++) {
      final date = now.subtract(Duration(days: dBack));
      final weekday = date.weekday;

      for (final entry in dayMap.entries) {
        if (!entry.value.contains(weekday)) continue;
        final title = entry.key;
        final isChiKung = title == 'Chi Kung Matutino';
        final eligible = classMap[title]!;

        final present = <String>[];
        for (int ei = 0; ei < eligible.length; ei++) {
          // ~80% attendance for regular classes, ~60% for Chi Kung
          final skip = isChiKung
              ? (ei + dBack) % 10 >= 6
              : (ei + dBack) % 5 == 0;
          if (!skip) present.add(ctx.students[eligible[ei]].uid);
        }

        await _db
            .collection('schools')
            .doc(ctx.schoolId)
            .collection('attendanceRecords')
            .add({
          'date': Timestamp.fromDate(DateTime(date.year, date.month, date.day)),
          'scheduleTitle': title,
          'presentStudentIds': present,
        });
        total++;
      }
    }

    _add(_StepResult.success('Asistencias', '$total registros en 60 días históricos'));
  }

  // ── Step 10: Achievements + promotion history ────────────────────────────

  Future<void> _s10AchievementsAndPromos(_SeedCtx ctx) async {
    _status('Asignando logros y promociones...');
    final now = DateTime.now();
    int totalAch = 0;
    int totalPromos = 0;

    for (int si = 0; si < ctx.students.length; si++) {
      final s = ctx.students[si];

      // Achievements
      if (s.achievementIds.isNotEmpty) {
        final map = <String, dynamic>{};
        for (final id in s.achievementIds) {
          final daysAgo = _kAchDays[id] ?? 30;
          final earnedAt = now.subtract(Duration(days: daysAgo));
          final cooldown = _kAchCooldown[id];
          map[id] = {
            'earnedAt': Timestamp.fromDate(earnedAt),
            'expiresAt': cooldown != null
                ? Timestamp.fromDate(earnedAt.add(Duration(days: cooldown)))
                : null,
          };
          totalAch++;
        }
        await _db
            .collection('schools')
            .doc(ctx.schoolId)
            .collection('members')
            .doc(s.uid)
            .update({'achievements': map});
      }

      // Promotion history (only for students with hasPromos)
      if (!s.hasPromos) continue;
      final chain = _kPromoChains[si];
      if (chain == null) continue;

      for (int pi = 0; pi < chain.length; pi++) {
        final from = chain[pi][0];
        final to = chain[pi][1];
        final monthsAgo = chain[pi][2];
        final promoDate = DateTime(now.year, now.month - monthsAgo, 15);

        await _db
            .collection('schools')
            .doc(ctx.schoolId)
            .collection('members')
            .doc(s.uid)
            .collection('progressionHistory')
            .add({
          'date': Timestamp.fromDate(promoDate),
          'type': 'level_promotion',
          'previousLevelId': ctx.levelIds[from],
          'newLevelId': ctx.levelIds[to],
          'disciplineId': ctx.disciplineId,
          'disciplineName': ctx.disciplineName,
          'notes': _kPromoNotes[pi % _kPromoNotes.length],
          'promotedBy': ctx.teacherUid,
        });
        totalPromos++;
      }
    }

    _add(_StepResult.success('Logros y promociones',
        '$totalAch logros asignados, $totalPromos promociones de faja creadas'));
  }

  // ── Static seed data ─────────────────────────────────────────────────────

  static const _kCategories = [
    'Puños y Golpes', 'Patadas', 'Barridos y Derribos',
    'Formas (Taolu)', 'Defensa Personal', 'Armas', 'Chi Kung',
  ];

  // (name, colorValue ARGB int)
  static const _kLevelDefs = [
    ('Faja Blanca', 0xFFFFFFFF),
    ('Faja Amarilla', 0xFFFFEB3B),
    ('Faja Naranja', 0xFFFF9800),
    ('Faja Verde', 0xFF4CAF50),
    ('Faja Azul', 0xFF2196F3),
    ('Faja Marrón', 0xFF795548),
    ('Faja Roja', 0xFFF44336),
    ('Faja Negra', 0xFF212121),
  ];

  static const _kScheduleDefs = [
    ('Clase Iniciantes', 1, '18:00', '19:30'),
    ('Clase Iniciantes', 3, '18:00', '19:30'),
    ('Clase Intermedios', 2, '19:30', '21:00'),
    ('Clase Intermedios', 4, '19:30', '21:00'),
    ('Clase Avanzados', 5, '20:00', '21:30'),
    ('Chi Kung Matutino', 6, '08:00', '09:00'),
  ];

  static const _kStudentDefs = [
    _StudentDef('Carlos Rodríguez', 'carlos.rodriguez', 3, 'intermediate', 8,
        ['weekly_bronze', 'monthly_silver', 'first_technique', 'techniques_10'], 18, true),
    _StudentDef('Ana García', 'ana.garcia', 4, 'advanced', 12,
        ['weekly_bronze', 'monthly_silver', 'yearly_gold', 'first_technique', 'techniques_10'], 20, true),
    _StudentDef('Martín López', 'martin.lopez', 2, 'basic', 5,
        ['first_technique'], 12, false),
    _StudentDef('Sofía Martínez', 'sofia.martinez', 0, 'basic', 2,
        [], 3, false),
    _StudentDef('Diego Fernández', 'diego.fernandez', 1, 'basic', 3,
        ['first_technique', 'early_bird'], 8, false),
    _StudentDef('Valentina Pérez', 'valentina.perez', 3, 'intermediate', 8,
        ['weekly_bronze', 'first_technique', 'techniques_10'], 15, true),
    _StudentDef('Lucas González', 'lucas.gonzalez', 6, 'advanced', 17,
        ['weekly_bronze', 'monthly_silver', 'yearly_gold', 'first_technique', 'techniques_10', 'techniques_25'], 24, true),
    _StudentDef('Camila Álvarez', 'camila.alvarez', 5, 'advanced', 14,
        ['monthly_silver', 'first_technique', 'techniques_10', 'techniques_25'], 22, true),
    _StudentDef('Nicolás Torres', 'nicolas.torres', 2, 'basic', 4,
        ['first_technique', 'night_owl'], 6, false),
    _StudentDef('Isabella Díaz', 'isabella.diaz', 1, 'basic', 3,
        ['weekly_bronze'], 4, false),
  ];

  // Days ago each achievement was earned
  static const _kAchDays = {
    'weekly_bronze': 5,
    'monthly_silver': 20,
    'yearly_gold': 200,
    'first_technique': 60,
    'techniques_10': 45,
    'techniques_25': 30,
    'early_bird': 90,
    'night_owl': 75,
    'winter_warrior': 120,
  };

  // Cooldown in days (null = permanent)
  static const _kAchCooldown = <String, int?>{
    'weekly_bronze': 7,
    'monthly_silver': 30,
    'yearly_gold': 365,
  };

  static const _kPromoNotes = [
    'Excelente progreso y dedicación constante.',
    'Demuestra dominio técnico y espíritu marcial.',
    'Ha superado todos los requisitos del nivel.',
    'Actitud ejemplar dentro y fuera del dojo.',
  ];

  // Student index → list of [fromLevel, toLevel, monthsAgo]
  static const _kPromoChains = <int, List<List<int>>>{
    0: [[0, 1, 16], [1, 2, 12], [2, 3, 8]], // Carlos: Blanca→Verde
    1: [[0, 1, 18], [1, 2, 14], [2, 3, 10], [3, 4, 6]], // Ana: Blanca→Azul
    5: [[0, 1, 13], [1, 2, 9], [2, 3, 5]], // Valentina: Blanca→Verde
    6: [[0, 1, 22], [1, 2, 19], [2, 3, 16], [3, 4, 13], [4, 5, 9], [5, 6, 5]], // Lucas: Blanca→Roja
    7: [[0, 1, 20], [1, 2, 17], [2, 3, 14], [3, 4, 11], [4, 5, 7]], // Camila: Blanca→Marrón
  };

  // ── Build ─────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _bg,
      appBar: AppBar(
        backgroundColor: _red,
        foregroundColor: Colors.white,
        title: const Text('Cargador de Datos de Demo'),
      ),
      body: _checking
          ? const Center(child: CircularProgressIndicator(color: _gold))
          : _done
              ? _buildDoneView()
              : _running
                  ? _buildRunningView()
                  : _buildIdleView(),
    );
  }

  // Idle

  Widget _buildIdleView() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildHeader(),
          if (_existingCount > 0) ...[
            const SizedBox(height: 16),
            _buildWarning(),
          ],
          const SizedBox(height: 24),
          Text('Se va a cargar:',
              style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.5),
                  fontSize: 12,
                  letterSpacing: 1,
                  fontWeight: FontWeight.w600)),
          const SizedBox(height: 10),
          _buildSummaryCard(),
          const SizedBox(height: 32),
          SizedBox(
            width: double.infinity,
            child: FilledButton.icon(
              onPressed: _runSeed,
              style: FilledButton.styleFrom(
                backgroundColor: _red,
                padding: const EdgeInsets.symmetric(vertical: 18),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)),
              ),
              icon: const Icon(Icons.play_arrow_rounded, size: 26),
              label: const Text('Iniciar carga de datos',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            ),
          ),
          const SizedBox(height: 12),
          Center(
            child: Text(
              'Este proceso puede tardar 1-2 minutos',
              style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.35), fontSize: 12),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: _red.withValues(alpha: 0.2),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: _red.withValues(alpha: 0.4)),
          ),
          child: const Icon(Icons.sports_martial_arts, color: _gold, size: 38),
        ),
        const SizedBox(width: 16),
        const Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Escuela de Kung Fu',
                style: TextStyle(color: Colors.white54, fontSize: 13)),
            Text('Shaolin Tradicional',
                style: TextStyle(
                    color: Colors.white,
                    fontSize: 22,
                    fontWeight: FontWeight.bold)),
          ],
        ),
      ],
    );
  }

  Widget _buildWarning() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.orange.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: Colors.orange.withValues(alpha: 0.35)),
      ),
      child: Row(
        children: [
          const Icon(Icons.warning_amber_rounded,
              color: Colors.orange, size: 18),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              'Ya hay $_existingCount alumno${_existingCount == 1 ? '' : 's'} en la escuela. Se agregarán datos nuevos.',
              style:
                  const TextStyle(color: Colors.orange, fontSize: 13),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryCard() {
    final items = [
      (Icons.straighten_rounded, '8 Niveles (fajas)',
          'Blanca → Amarilla → Naranja → Verde → Azul → Marrón → Roja → Negra'),
      (Icons.sports_kabaddi, '17 Técnicas',
          '7 categorías: Puños, Patadas, Derribos, Taolu, Defensa, Armas, Chi Kung'),
      (Icons.credit_card_rounded, '3 Planes de pago',
          'Básico \$1.500 / Intermedio \$2.200 / Avanzado \$2.800 (UYU)'),
      (Icons.calendar_today_rounded, '6 Horarios',
          'Iniciantes L/M • Intermedios M/J • Avanzados V • Chi Kung Sáb'),
      (Icons.people_rounded, '10 Alumnos',
          'Desde Faja Blanca hasta Roja, con planes y técnicas asignadas'),
      (Icons.payments_outlined, '~58 Pagos mensuales',
          '6 meses de cuotas por alumno (Sofía y Nicolás con 1 faltante)'),
      (Icons.assignment_turned_in_rounded, '~80 Registros de asistencia',
          '60 días históricos por turno, con variación realista'),
      (Icons.emoji_events_rounded, 'Logros por alumno',
          'Hasta 6 logros según nivel: bronce semanal, plata mensual, oro anual…'),
      (Icons.trending_up_rounded, '18 Promociones de faja',
          'Carlos, Ana, Valentina, Lucas y Camila con historial completo'),
    ];

    return Container(
      decoration: BoxDecoration(
        color: _surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
      ),
      child: Column(
        children: [
          for (int i = 0; i < items.length; i++) ...[
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 13),
              child: Row(
                children: [
                  Icon(items[i].$1, color: _gold, size: 20),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(items[i].$2,
                            style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.w600,
                                fontSize: 13)),
                        Text(items[i].$3,
                            style: TextStyle(
                                color: Colors.white.withValues(alpha: 0.45),
                                fontSize: 11)),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            if (i < items.length - 1)
              Divider(
                  height: 1,
                  color: Colors.white.withValues(alpha: 0.07)),
          ],
        ],
      ),
    );
  }

  // Running

  Widget _buildRunningView() {
    return ListView(
      padding: const EdgeInsets.all(24),
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          decoration: BoxDecoration(
            color: _red.withValues(alpha: 0.15),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Row(
            children: [
              const SizedBox(
                width: 18,
                height: 18,
                child: CircularProgressIndicator(
                    strokeWidth: 2, color: _gold),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Text(_currentStep,
                    style:
                        const TextStyle(color: Colors.white70, fontSize: 14)),
              ),
            ],
          ),
        ),
        const SizedBox(height: 20),
        ..._results.map(_buildResultTile),
      ],
    );
  }

  // Done

  Widget _buildDoneView() {
    final allOk = _results.every((r) => r.ok);
    final bannerColor = allOk ? Colors.green : Colors.orange;

    return ListView(
      padding: const EdgeInsets.all(24),
      children: [
        Container(
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            color: bannerColor.withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: bannerColor.withValues(alpha: 0.35)),
          ),
          child: Row(
            children: [
              Icon(allOk ? Icons.check_circle_rounded : Icons.error_rounded,
                  color: bannerColor, size: 30),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      allOk ? '¡Carga completada!' : 'Carga con errores',
                      style: TextStyle(
                          color: bannerColor,
                          fontWeight: FontWeight.bold,
                          fontSize: 16),
                    ),
                    Text(
                      allOk
                          ? 'Todos los datos fueron cargados correctamente.'
                          : 'Algunos pasos fallaron. Revisá los detalles abajo.',
                      style: const TextStyle(
                          color: Colors.white60, fontSize: 13),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 20),
        ..._results.map(_buildResultTile),
        const SizedBox(height: 28),
        SizedBox(
          width: double.infinity,
          child: OutlinedButton.icon(
            onPressed: () => Navigator.of(context).pop(),
            style: OutlinedButton.styleFrom(
              foregroundColor: _gold,
              side: const BorderSide(color: _gold),
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12)),
            ),
            icon: const Icon(Icons.arrow_back_rounded),
            label: const Text('Volver a gestión',
                style: TextStyle(fontSize: 15)),
          ),
        ),
      ],
    );
  }

  Widget _buildResultTile(_StepResult r) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            r.ok ? Icons.check_circle_rounded : Icons.cancel_rounded,
            color: r.ok ? Colors.green : Colors.red,
            size: 20,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(r.title,
                    style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w600,
                        fontSize: 13)),
                Text(r.detail,
                    style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.45),
                        fontSize: 12)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ── Technique definition ──────────────────────────────────────────────────────

class _TechDef {
  final String name;
  final String category;
  final int complexity;
  final String description;

  const _TechDef(this.name, this.category, this.complexity, this.description);
}

const _kTechDefs = [
  _TechDef('Puño Directo (Zhí Quán)', 'Puños y Golpes', 1,
      'Golpe lineal básico que parte desde la cadera. Base de todo combate en Shaolin.'),
  _TechDef('Puño en Gancho (Gōu Quán)', 'Puños y Golpes', 2,
      'Golpe circular a corta distancia, apuntando a la mandíbula o sien del oponente.'),
  _TechDef('Puño Ascendente (Shàng Quán)', 'Puños y Golpes', 2,
      'Golpe vertical de abajo hacia arriba, ideal para el mentón del oponente.'),
  _TechDef('Patada Frontal (Zhèng Tǐ)', 'Patadas', 2,
      'Patada básica que impulsa el pie de frente al objetivo. Primer estudio de las piernas.'),
  _TechDef('Patada Circular (Cè Tǐ)', 'Patadas', 3,
      'Patada curva que golpea con el empeine. Característica del estilo Shaolin del Norte.'),
  _TechDef('Patada Lateral (Biān Tǐ)', 'Patadas', 3,
      'Patada de lado con el borde externo del pie. Potente a media y larga distancia.'),
  _TechDef('Patada Giratoria (Zhuǎn Shēn Hòu Tǐ)', 'Patadas', 4,
      'Patada con giro de 180°, golpeando por detrás. Alta potencia y sorpresa táctica.'),
  _TechDef('Barrido Bajo (Sǎo Tǐ)', 'Barridos y Derribos', 3,
      'Derribo girando en el suelo para barrer las piernas del oponente.'),
  _TechDef('Lanzamiento de Cadera (Kāo)', 'Barridos y Derribos', 4,
      'Proyección usando la cadera como palanca. Combinación de fuerza y técnica.'),
  _TechDef('Xiao Hong Quan (Forma Pequeña Roja)', 'Formas (Taolu)', 4,
      'Forma básica de Shaolin del Norte. Integra golpes, patadas y desplazamientos fundamentales.'),
  _TechDef('Lian Huan Quan (Golpes Encadenados)', 'Formas (Taolu)', 5,
      'Forma de combinaciones rápidas y fluidas. Entrena coordinación y velocidad de ataque.'),
  _TechDef('Wu Bu Quan (Forma de Cinco Pasos)', 'Formas (Taolu)', 3,
      'Forma introductoria con cinco posturas fundamentales. Ideal para principiantes avanzados.'),
  _TechDef('Defensa contra Agarre de Muñeca', 'Defensa Personal', 2,
      'Técnica para liberarse de agarre en muñeca. Aplica rotación y presión articular.'),
  _TechDef('Defensa contra Estrangulamiento', 'Defensa Personal', 4,
      'Secuencia para neutralizar estrangulamiento frontal. Requiere coordinación y precisión.'),
  _TechDef('Bastón Largo Básico (Gùn)', 'Armas', 4,
      'Manejo básico del bastón de dos metros. Incluye bloqueos, barridos y golpes lineales.'),
  _TechDef('Respiración Abdominal (Fù Shì Hū Xī)', 'Chi Kung', 1,
      'Técnica básica de Chi Kung para activar el dan tien inferior. Base de todo trabajo energético.'),
  _TechDef('Yi Jin Jing (Transformación del Músculo)', 'Chi Kung', 3,
      'Clásico ejercicio de Chi Kung atribuido a Bodhidharma. Fortalece tendones y cultiva el chi interno.'),
];
